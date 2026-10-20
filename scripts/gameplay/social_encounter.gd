class_name SocialEncounter
extends Node
## Supplies eligible targets and diagnostics, never movement or material transfers.

var arena: Node3D
var relations: RaiderRelations
var rules: RaiderSocialConfig


func setup(definition: RaiderSocialConfig) -> void:
	rules = definition
	relations = RaiderRelations.new(arena.ledger)
	for pair in rules.allied_pairs:
		relations.set_attitude(pair.x, pair.y, RaiderRelations.Attitude.ALLIED, "authored alliance", 0)
	for pair in rules.hostile_pairs:
		relations.set_attitude(pair.x, pair.y, RaiderRelations.Attitude.HOSTILE, "authored rivalry", 0)


func register_actor(actor: Raider) -> void:
	if rules.cooperation_enabled or rules.loot_enabled:
		actor.social = RaiderSocial.new()
		actor.social.actor = actor
		actor.social.encounter = self
		actor.add_child(actor.social)
	if rules.opportunist_ids.has(actor.raider_id) and rules.betrayal_profile != null:
		actor.betrayal = RaiderBetrayal.new()
		actor.betrayal.actor = actor
		actor.betrayal.encounter = self
		actor.betrayal.profile = rules.betrayal_profile
		actor.add_child(actor.betrayal)


func responder_relations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in arena.raiders:
		if not arena.ledger.is_active(id):
			continue
		var attitude := RaiderRelations.Attitude.NEUTRAL
		if rules.responder_allied_to.has(id) or (rules.responders_allied and arena.flare_director.responder_ids.has(id)):
			attitude = RaiderRelations.Attitude.ALLIED
		elif rules.responder_hostile_to.has(id):
			attitude = RaiderRelations.Attitude.HOSTILE
		result.append({"other": id, "attitude": attitude})
	return result


func initialize_responder(id: int, snapshot: Array) -> void:
	for entry in snapshot:
		relations.set_attitude(id, entry.other, entry.attitude, "authored responder policy", arena.elapsed)
	if rules.responders_allied:
		for other in arena.flare_director.responder_ids:
			if other != id:
				relations.set_attitude(id, other, RaiderRelations.Attitude.ALLIED, "authored responder alliance", arena.elapsed)


func eligible(target: Node3D, actor: Raider) -> bool:
	if arena.mission.is_world_finished() or not is_instance_valid(target) or not arena.ledger.is_active(actor.raider_id):
		return false
	if target is Raider:
		return target != actor and arena.raiders.get(target.raider_id) == target and arena.ledger.is_active(target.raider_id) and relations.attitude(actor.raider_id, target.raider_id) == RaiderRelations.Attitude.HOSTILE
	return target == arena.robot or (arena.ecosystem != null and arena.ecosystem.machines.has(target))


func choose_target(actor: Raider) -> Node3D:
	var candidates: Array[Node3D] = [arena.robot]
	for other in arena.raiders.values():
		if is_instance_valid(other):
			candidates.append(other)
	if arena.ecosystem != null:
		candidates.append_array(arena.ecosystem.machines)
	var best := INF
	var selected: Node3D
	for candidate in candidates:
		if not eligible(candidate, actor) or not actor.detects_actor(candidate):
			continue
		var score := actor.global_position.distance_squared_to(candidate.global_position)
		if candidate == actor.combat_target:
			score *= 0.7
		if score < best:
			best = score
			selected = candidate
	return selected


func describe(actor: Raider) -> String:
	var entries: Array[String] = []
	for id in arena.raiders:
		if id != actor.raider_id and arena.ledger.is_active(id):
			entries.append("R%02d %s (%s)" % [id, RaiderRelations.Attitude.keys()[relations.attitude(actor.raider_id, id)], relations.last_reason(actor.raider_id, id)])
	var instigator: Object = instance_from_id(actor.health.last_damage_instigator_id) if actor.health.last_damage_instigator_id > 0 else null
	var source := "R%02d" % instigator.raider_id if instigator is Raider else str(actor.health.last_damage_instigator_id)
	var details := "Relations: %s\nSquad: %s | competition: independent\nLast damage instigator: %s" % [", ".join(entries), str(actor.squad_id) if not actor.squad_id.is_empty() else "none", source]
	if actor.social != null:
		details += "\nReports %d | Known drops %d | Source %s" % [actor.social.reports.size(), actor.social.loot_memory.size(), actor.threat_source]
		for id in actor.social.reports:
			var report: Dictionary = actor.social.reports[id]
			if report.expires > arena.elapsed:
				details += "\nAlly R%02d reports (%.0f, %.0f), %.1fs left" % [id, report.position.x, report.position.z, report.expires - arena.elapsed]
	if actor.betrayal != null:
		details += "\nBetrayal spent: %s | %.1f/%.1fs\n%s" % [actor.betrayal.spent, actor.betrayal.elapsed, actor.betrayal.profile.assessment_seconds, actor.betrayal.reason]
	return details
