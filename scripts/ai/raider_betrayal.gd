class_name RaiderBetrayal
extends Node
## Assessment timing/eligibility only; Raider owns activity and physical movement.

var actor: Raider
var encounter: SocialEncounter
var profile: RaiderBetrayalProfile
var candidate: Raider
var elapsed: float = 0
var spent: bool = false
var stopped: bool = false
var victim_id: int = 0
var reason: String = "waiting for a richer visible ally"


func _ready() -> void:
	actor.state_changed.connect(_on_state_changed)


func can_assess() -> bool:
	return not spent and not stopped and actor.combat != null and actor.combat.weapon.enabled and actor.combat.retreat_remaining <= 0 and not encounter.arena.mission.is_world_finished() and actor.ledger.is_active(actor.raider_id) and actor.health.current > actor.health.maximum * profile.minimum_health_fraction and actor.loot_progress() < actor.profile.cargo_target and actor.state in [Raider.State.SELECTING, Raider.State.SCAVENGING, Raider.State.ASSESSING_BETRAYAL] and encounter.choose_target(actor) == null


func qualifies(other: Raider) -> bool:
	return is_instance_valid(other) and other != actor and encounter.arena.raiders.get(other.raider_id) == other and actor.ledger.is_active(other.raider_id) and other.health.current > 0 and encounter.relations.attitude(actor.raider_id, other.raider_id) == RaiderRelations.Attitude.ALLIED and other.loot_progress() >= profile.minimum_victim_cargo and other.loot_progress() > actor.loot_progress() and actor.global_position.distance_to(other.global_position) <= profile.range_limit and actor.detects_actor(other)


func decide() -> bool:
	if actor.state == Raider.State.ASSESSING_BETRAYAL:
		if not is_instance_valid(candidate) or not can_assess() or not qualifies(candidate):
			cancel("qualification interrupted")
			return false
		return true
	if not can_assess():
		return false
	var selected: Raider
	var nearest := INF
	for other in encounter.arena.raiders.values():
		if not is_instance_valid(other) or not qualifies(other):
			continue
		var distance := actor.global_position.distance_squared_to(other.global_position)
		if selected == null or other.loot_progress() > selected.loot_progress() or (other.loot_progress() == selected.loot_progress() and (distance < nearest - 0.000001 or (is_equal_approx(distance, nearest) and other.raider_id < selected.raider_id))):
			selected = other
			nearest = distance
	if selected == null:
		return false
	candidate = selected
	elapsed = 0
	reason = "eyeing R%02d cargo %d versus %d" % [selected.raider_id, selected.loot_progress(), actor.loot_progress()]
	actor.transition(Raider.State.ASSESSING_BETRAYAL)
	return true


func tick(delta: float) -> void:
	if stopped or spent or actor.state != Raider.State.ASSESSING_BETRAYAL:
		return
	if not is_instance_valid(candidate) or not can_assess() or not qualifies(candidate):
		cancel("qualification interrupted")
		return
	elapsed += delta
	if elapsed + 0.000001 < profile.assessment_seconds:
		return
	var target := candidate
	var event_reason := "betrayal: R%02d wants R%02d cargo (%d > %d)" % [actor.raider_id, target.raider_id, target.loot_progress(), actor.loot_progress()]
	if not encounter.relations.set_attitude(actor.raider_id, target.raider_id, RaiderRelations.Attitude.HOSTILE, event_reason, encounter.arena.elapsed):
		cancel("relation change rejected")
		return
	spent = true
	victim_id = target.raider_id
	reason = event_reason
	actor.combat_target = target
	actor.target_reason = "opportunistic betrayal"
	actor.combat.aim_elapsed = 0
	actor.transition(Raider.State.SELECTING)
	actor.decide()


func cancel(cause: String) -> void:
	candidate = null
	elapsed = 0
	if actor.state == Raider.State.ASSESSING_BETRAYAL and not encounter.arena.mission.is_world_finished():
		actor.transition(Raider.State.SELECTING)
	reason = cause


func stop() -> void:
	stopped = true
	candidate = null
	elapsed = 0
	if not spent:
		reason = "deployment ended"


func _on_state_changed(previous: Raider.State, next: Raider.State) -> void:
	if previous == Raider.State.ASSESSING_BETRAYAL and next != Raider.State.ASSESSING_BETRAYAL:
		candidate = null
		elapsed = 0
		if not spent:
			reason = "interrupted by %s" % Raider.State.keys()[next]
