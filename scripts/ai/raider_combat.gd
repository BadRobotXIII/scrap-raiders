class_name RaiderCombat
extends Node
## Combat decisions use the Raider's FSM. This component owns aim timers and intent.

var actor: Raider
var profile: RaiderCombatProfile
var weapon: ShotExecutor
var reserve_cover: Callable
var release_cover: Callable
var cover: Node3D
var destination: Node3D
var aim_elapsed: float = 0.0
var reposition_elapsed: float = 0.0
var retreat_remaining: float = 0.0
var return_fire_remaining: float = 0.0
var pressure_remaining: float = 0.0
var attacker_focus_remaining: float = 0.0
var random := RandomNumberGenerator.new()
enum PolicyDecision { COMBAT, OBJECTIVES, HANDLED }
var commit_remaining: float = 0.0
var escape_remaining: float = 0.0
var observation_remaining: float = 0.0
var observed_position: Vector3
var observed_target_id: int = 0
var escaping: bool = false
var escape_blocked: bool = false
var defending: bool = false
var pursuing: bool = false
var decision_reason: String = "baseline combat"


func setup(owner_actor: Raider, definition: RaiderCombatProfile, seed_value: int) -> void:
	actor = owner_actor
	profile = definition
	random.seed = seed_value + actor.raider_id * 7919
	weapon = ShotExecutor.new()
	weapon.definition = profile.weapon
	weapon.shooter = actor
	weapon.muzzle = actor.get_node("Visuals/RifleMuzzle")
	weapon.shot_mask = 3
	weapon.damage_mask = 2
	add_child(weapon)
	actor.get_node("RaiderFeedback").setup_weapon(weapon)
	actor.get_node("Visuals/Rifle").show()
	actor.state_changed.connect(_on_state_changed)


func owns_state() -> bool:
	return actor.state in [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]


func _on_state_changed(previous: Raider.State, next: Raider.State) -> void:
	aim_elapsed = 0
	if next == Raider.State.ENGAGING and previous == Raider.State.REPOSITIONING:
		# Give the completed peek a warning and two firing opportunities before
		# another noncritical hit can request cover again.
		return_fire_remaining = profile.warning_time + profile.weapon.shot_interval * 2
	if next not in [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		return_fire_remaining = 0
		pressure_remaining = 0
		release()
	if next in [Raider.State.DEAD, Raider.State.EXTRACTED]:
		stop()


func release() -> void:
	if release_cover.is_valid():
		release_cover.call(actor.raider_id)
	cover = null
	destination = null


func stop() -> void:
	commit_remaining = 0
	escape_remaining = 0
	observation_remaining = 0
	observed_target_id = 0
	attacker_focus_remaining = 0
	escaping = false
	escape_blocked = false
	defending = false
	pursuing = false
	decision_reason = "simulation stopped"
	weapon.enabled = false
	weapon.set_physics_process(false)
	release()


func choose_cover() -> bool:
	release()
	cover = reserve_cover.call(actor.raider_id) if reserve_cover.is_valid() else null
	if cover == null:
		return false
	destination = cover
	actor.transition(Raider.State.TAKING_COVER)
	return true


func decide() -> bool:
	if actor.profile.combat_policy != RaiderProfile.CombatPolicy.BASELINE:
		var decision := decide_policy()
		if decision != PolicyDecision.COMBAT:
			return decision == PolicyDecision.HANDLED
	if actor.health.current <= actor.health.maximum * profile.retreat_health_fraction or retreat_remaining > 0:
		if actor.state == Raider.State.EXTRACTING:
			return true
		if actor.state == Raider.State.FLEEING and is_instance_valid(actor.extraction) and actor.global_position.distance_to(actor.extraction.global_position) < 0.8:
			actor.transition(Raider.State.EXTRACTING)
		elif actor.state != Raider.State.FLEEING and actor._choose_exit():
			actor.transition(Raider.State.FLEEING)
		return true
	if actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		# Finish the selected route using the stored observation. Shooting still
		# requires fresh visibility, and the navigation watchdog can abandon it.
		return true
	if owns_state() and actor.threat_remaining <= 0:
		actor.transition(Raider.State.SELECTING)
		return false
	if actor.threat_visible and actor.global_position.distance_to(actor.current_target().global_position) <= profile.engagement_range:
		if actor.state != Raider.State.ENGAGING:
			actor.transition(Raider.State.ENGAGING)
		return true
	if actor.state == Raider.State.ENGAGING:
		if not choose_cover():
			actor.begin_investigation()
		return true
	return false


func on_damaged() -> void:
	pressure_remaining = profile.reposition_interval
	if actor.profile.combat_policy != RaiderProfile.CombatPolicy.BASELINE and policy_damage_handled():
		return
	if actor.health.current <= actor.health.maximum * profile.retreat_health_fraction:
		retreat_remaining = 4.0
		if actor._choose_exit():
			actor.transition(Raider.State.FLEEING)
	elif actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		return # Repeated hits must not restart the route or its cover dwell.
	elif return_fire_remaining > 0 and actor.detects_current_target():
		return
	elif not choose_cover():
		if actor.detects_current_target():
			# No useful cover is not a reason for a healthy fighter to run
			# into its attacker indefinitely without returning fire.
			retreat_remaining = 0
			actor.transition(Raider.State.ENGAGING)
		else:
			retreat_remaining = 2.0
			if actor._choose_exit():
				actor.transition(Raider.State.FLEEING)


func can_redirect_to_attacker() -> bool:
	# The first observed attacker can interrupt. Alternating hits must then
	# leave enough time to finish warning and respond instead of resetting aim.
	if attacker_focus_remaining > 0 and actor.state == Raider.State.ENGAGING and actor.detects_current_target():
		return false
	attacker_focus_remaining = profile.warning_time + profile.weapon.shot_interval * 2
	return true


func on_arrived(_delta: float) -> void:
	if actor.state == Raider.State.TAKING_COVER and actor.task_elapsed >= profile.cover_hold:
		destination = cover.get_node("Peek")
		actor.transition(Raider.State.REPOSITIONING)
	elif actor.state == Raider.State.REPOSITIONING:
		reposition_elapsed = 0
		actor.transition(Raider.State.ENGAGING)


func tick(delta: float) -> void:
	attacker_focus_remaining = maxf(0, attacker_focus_remaining - delta)
	commit_remaining = maxf(0, commit_remaining - delta)
	escape_remaining = maxf(0, escape_remaining - delta)
	observation_remaining = maxf(0, observation_remaining - delta)
	retreat_remaining = maxf(0, retreat_remaining - delta)
	return_fire_remaining = maxf(0, return_fire_remaining - delta)
	pressure_remaining = maxf(0, pressure_remaining - delta)
	if actor.state != Raider.State.ENGAGING:
		aim_elapsed = 0
		return
	# Recheck visibility at firing time, not just the slower perception interval.
	if not actor.detects_current_target() or actor.global_position.distance_to(actor.current_target().global_position) > profile.engagement_range:
		aim_elapsed = 0
		return
	var facing := actor.current_target().global_position - actor.global_position
	actor.visuals.rotation.y = atan2(-facing.x, -facing.z)
	aim_elapsed += delta
	reposition_elapsed += delta
	if reposition_elapsed >= profile.reposition_interval:
		reposition_elapsed = 0
		if pressure_remaining > 0 and return_fire_remaining <= 0 and choose_cover():
			return
	if aim_elapsed < profile.warning_time or weapon.cooldown > 0:
		return
	var aim := actor.target_point(actor.current_target())
	var distance := weapon.muzzle.global_position.distance_to(aim)
	var spread := tan(deg_to_rad(profile.spread_degrees)) * distance
	aim += Vector3(random.randf_range(-spread, spread), random.randf_range(-spread, spread), random.randf_range(-spread, spread))
	weapon.try_fire_at(aim)


func spacing_position() -> Vector3:
	# Physical movement stays in Raider; combat supplies a short retreat intent
	# when a grounded opponent is too close, rather than standing body-to-body.
	var target := actor.current_target()
	if not actor.detects_current_target() or absf(actor.global_position.y - target.global_position.y) > 2:
		return actor.global_position
	var away := actor.global_position - target.global_position
	away.y = 0
	if away.length() >= 2.5:
		return actor.global_position
	if away.is_zero_approx():
		away = actor.visuals.global_basis.z
	var desired := target.global_position + away.normalized() * 3.0
	return NavigationServer3D.map_get_closest_point(actor.agent.get_navigation_map(), desired)


func remember_visible_target() -> void:
	if actor.detects_current_target():
		observed_target_id = actor.current_target().get_instance_id()
		observed_position = actor.current_target().global_position
		observation_remaining = actor.profile.threat_memory


func observation_valid() -> bool:
	var target := instance_from_id(observed_target_id) as Node3D if observed_target_id > 0 else null
	return observation_remaining > 0 and is_instance_valid(target) and target.get_node("Health").current > 0 and (not actor.combat_target_allowed.is_valid() or actor.combat_target_allowed.call(target))


func begin_escape(reason: String) -> void:
	if not escaping:
		escape_remaining = actor.profile.escape_commit_seconds
	escaping = true
	defending = false
	pursuing = false
	decision_reason = reason
	try_escape_route()


func try_escape_route() -> void:
	escape_blocked = not actor._choose_exit(owns_state())
	if escape_blocked:
		decision_reason = "escape blocked; defend while retrying"
		if actor.detects_current_target() and not owns_state():
			actor.transition(Raider.State.ENGAGING)
	else:
		actor.transition(Raider.State.FLEEING)


func escape_decision(critical: bool) -> PolicyDecision:
	if actor.state == Raider.State.EXTRACTING:
		return PolicyDecision.HANDLED
	var heard_danger := actor.threat_remaining > 0 and actor.threat_source in ["damage", "gunfire"]
	if not critical and escape_remaining <= 0 and not observation_valid() and not heard_danger and actor.carried_materials == 0:
		escaping = false
		escape_blocked = false
		commit_remaining = 0
		decision_reason = "safe after escape commitment; resume objectives"
		actor.transition(Raider.State.SELECTING)
		return PolicyDecision.OBJECTIVES
	if actor.state == Raider.State.STRANDED:
		escape_blocked = true
	if escape_blocked:
		if actor._retry_remaining <= 0:
			actor.blocked_exits.clear()
			try_escape_route()
		elif actor.detects_current_target() and not owns_state():
			actor.transition(Raider.State.ENGAGING)
		elif not actor.detects_current_target() and actor.state not in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
			actor.transition(Raider.State.STRANDED)
		return PolicyDecision.HANDLED
	if actor.state == Raider.State.FLEEING and is_instance_valid(actor.extraction) and actor.global_position.distance_to(actor.extraction.global_position) < 0.8:
		actor.transition(Raider.State.EXTRACTING)
	elif actor.state != Raider.State.FLEEING:
		try_escape_route()
	return PolicyDecision.HANDLED


func release_interest(reason: String) -> PolicyDecision:
	defending = false
	pursuing = false
	commit_remaining = 0
	observation_remaining = 0
	observed_target_id = 0
	decision_reason = reason
	actor.threat_remaining = 0
	actor.threat_source = "none"
	actor.combat_target = null
	actor.transition(Raider.State.SELECTING)
	return PolicyDecision.OBJECTIVES


func decide_policy() -> PolicyDecision:
	if actor.threat_visible:
		remember_visible_target()
	elif not observation_valid():
		observation_remaining = 0
	var critical := actor.health.current <= actor.health.maximum * profile.retreat_health_fraction
	if critical and not escaping:
		begin_escape("critical health; escape overrides combat")
	if escaping:
		return escape_decision(critical)
	var style := actor.profile.combat_policy
	if style == RaiderProfile.CombatPolicy.CAUTIOUS:
		if actor.threat_visible or (actor.threat_remaining > 0 and actor.threat_source in ["damage", "gunfire"]):
			begin_escape("cautious: avoid optional fight")
			return PolicyDecision.HANDLED
		decision_reason = "cautious: no immediate threat; independent objective"
		return PolicyDecision.OBJECTIVES
	if style == RaiderProfile.CombatPolicy.GREEDY:
		if defending and commit_remaining > 0 and observation_valid():
			decision_reason = "greedy: finish bounded defense before reconsidering cargo"
			return PolicyDecision.COMBAT
		if actor.threat_visible and (actor.carried_materials > 0 or actor.health.current <= actor.health.maximum * actor.profile.combat_retreat_fraction):
			begin_escape("greedy: preserve cargo or damaged hull")
			return PolicyDecision.HANDLED
		if not owns_state() and not defending and actor.threat_visible and actor.global_position.distance_to(actor.current_target().global_position) > actor.profile.defense_distance:
			decision_reason = "greedy: salvage before optional distant fight"
			return PolicyDecision.OBJECTIVES
		if actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
			decision_reason = "greedy: complete selected cover route before reconsidering objective"
			return PolicyDecision.COMBAT
		if not observation_valid() and (owns_state() or defending):
			return release_interest("greedy: threat observation expired or resolved")
		if not actor.threat_visible and not owns_state():
			decision_reason = "greedy: no immediate threat; independent salvage objective"
			return PolicyDecision.OBJECTIVES
		decision_reason = "greedy: defend nearby opportunity"
		return PolicyDecision.COMBAT
	if actor.threat_visible:
		if not owns_state() and not pursuing:
			commit_remaining = actor.profile.combat_commit_seconds
		pursuing = false
		decision_reason = "aggressive: commit to observed opponent"
		return PolicyDecision.COMBAT
	if actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		decision_reason = "aggressive: complete selected cover route; no unseen tracking"
		return PolicyDecision.COMBAT
	if observation_valid():
		if pursuing and actor.state != Raider.State.INVESTIGATING:
			return release_interest("aggressive: pursuit route blocked or search completed")
		if not pursuing:
			var snapshot := Vector3(observed_position.x, actor.global_position.y, observed_position.z)
			var away := (actor.global_position - snapshot).normalized()
			actor.investigation_position = NavigationServer3D.map_get_closest_point(actor.agent.get_navigation_map(), snapshot + away * 2)
			actor.transition(Raider.State.INVESTIGATING)
			pursuing = true
		decision_reason = "aggressive: investigate last observed position until memory expires"
		return PolicyDecision.HANDLED
	if owns_state() or pursuing:
		return release_interest("aggressive: target resolved or observation expired")
	decision_reason = "aggressive: no observed enemy; independent objective"
	return PolicyDecision.OBJECTIVES


func policy_damage_handled() -> bool:
	remember_visible_target()
	if actor.health.current <= actor.health.maximum * profile.retreat_health_fraction:
		if not escaping:
			begin_escape("critical damage; escape overrides combat")
		return true
	if escaping:
		# Hits never restart escape commitment or the physical extraction clock.
		return not escape_blocked
	if actor.profile.combat_policy == RaiderProfile.CombatPolicy.CAUTIOUS:
		begin_escape("cautious: damage confirms escape priority")
		return true
	if actor.profile.combat_policy == RaiderProfile.CombatPolicy.GREEDY:
		if actor.detects_current_target():
			if not defending:
				defending = true
				commit_remaining = actor.profile.combat_commit_seconds
			decision_reason = "greedy: observed attacker interrupts salvage or cargo plans"
		else:
			begin_escape("greedy: unseen damage; escape without revealing attacker")
			return true
	return false


func describe_policy() -> String:
	return "Policy %s | %s | commit %.1fs | escape %.1fs | observation %.1fs" % [RaiderProfile.CombatPolicy.keys()[actor.profile.combat_policy], decision_reason, commit_remaining, escape_remaining, observation_remaining]
