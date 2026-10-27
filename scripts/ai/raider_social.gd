class_name RaiderSocial
extends Node
## Per-actor observations only. The common Raider FSM chooses movement/actions.

var actor: Raider
var encounter: SocialEncounter
var reports: Dictionary[int, Dictionary] = {}
var loot_memory: Dictionary[int, Dictionary] = {}


func receive(source: Raider, target: Node3D, position: Vector3, expires: float) -> bool:
	if not position.is_finite() or not is_finite(expires) or expires <= encounter.arena.elapsed:
		return false
	if not encounter.rules.cooperation_enabled or encounter.arena.mission.is_world_finished() or not is_instance_valid(source) or not actor.ledger.is_active(actor.raider_id) or not actor.ledger.is_active(source.raider_id):
		return false
	if source == actor or encounter.relations.attitude(actor.raider_id, source.raider_id) != RaiderRelations.Attitude.ALLIED or actor.global_position.distance_to(source.global_position) > encounter.rules.communication_radius or not encounter.eligible(target, actor):
		return false
	reports[source.raider_id] = {"position": position, "target": target.get_instance_id(), "expires": expires}
	return true


func best_report() -> Dictionary:
	var result := {}
	var nearest := INF
	for id in reports.keys():
		var report: Dictionary = reports[id]
		var target := instance_from_id(report.target) as Node3D
		if report.expires <= encounter.arena.elapsed or not actor.ledger.is_active(id) or encounter.relations.attitude(actor.raider_id, id) != RaiderRelations.Attitude.ALLIED or not encounter.eligible(target, actor):
			reports.erase(id)
			continue
		var distance := actor.global_position.distance_squared_to(report.position)
		if distance < nearest:
			nearest = distance
			result = report.duplicate(true)
			result["source_id"] = id
	return result


func sees_drop(drop: MaterialDrop) -> bool:
	if not is_instance_valid(drop) or drop.is_queued_for_deletion() or encounter.arena.drops.get(drop.drop_id) != drop or drop.ledger != actor.ledger or actor.global_position.distance_to(drop.global_position) > encounter.rules.loot_radius:
		return false
	if drop.content_count() <= 0 and not (drop is WorldLoot and drop.drop_id < 0): return false
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, drop.global_position + Vector3.UP * 0.3, 1, [actor.get_rid()])
	query.hit_from_inside = true
	return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func knows_drop(drop: MaterialDrop) -> bool:
	if not encounter.rules.loot_enabled or not is_instance_valid(drop) or not loot_memory.has(drop.drop_id):
		return false
	var memory: Dictionary = loot_memory[drop.drop_id]
	return memory.expires > encounter.arena.elapsed and memory.position.distance_to(drop.global_position) < 0.1 and encounter.arena.drops.get(drop.drop_id) == drop and (drop.content_count() > 0 or (drop is WorldLoot and drop.drop_id < 0)) and not drop.is_queued_for_deletion()

func searched_empty_cache(drop: MaterialDrop) -> bool:
	# A remembered visit is not a claim about the cache's unseen current
	# contents. Avoid repeating a completed empty search; fresh sight can
	# discover deposited loot and make this location interesting again.
	return is_instance_valid(drop) and drop is WorldLoot and drop.drop_id < 0 and loot_memory.get(drop.drop_id, {}).get("empty", false)


func known_drops() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for id in loot_memory.keys():
		var drop = encounter.arena.drops.get(id)
		if not is_instance_valid(drop) or not knows_drop(drop):
			if not searched_empty_cache(drop): loot_memory.erase(id)
		else:
			result.append(drop)
	return result


func sense() -> void:
	if encounter.arena.mission.is_world_finished():
		return
	if encounter.rules.loot_enabled:
		for drop in encounter.arena.drops.values():
			if sees_drop(drop):
				loot_memory[drop.drop_id] = {"position": drop.global_position, "expires": encounter.arena.elapsed + encounter.rules.memory_seconds, "empty": drop.content_count() == 0}
		known_drops()
	if encounter.rules.cooperation_enabled and actor.threat_visible and actor.detects_current_target():
		for other in encounter.arena.raiders.values():
			if is_instance_valid(other) and other.social != null:
				other.social.receive(actor, actor.current_target(), actor.current_target().global_position, encounter.arena.elapsed + encounter.rules.memory_seconds)
	var report := best_report()
	if not report.is_empty():
		actor.consider_allied_report(report.position, report.expires - encounter.arena.elapsed)
	elif actor.threat_source == "ally report" and actor.threat_remaining <= 0 and actor.state == Raider.State.INVESTIGATING:
		actor.transition(Raider.State.SELECTING)
