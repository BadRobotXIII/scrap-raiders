extends "res://tests/deployment_flow_test.gd"
## Normal Asset Recovery resources; deliberate fixture positions/cargo are explicit.

var accepted_events: int = 0
var accounting_valid: bool = true


func audit_transfer(_kind: StringName, _details: Dictionary, arena: Node3D) -> void:
	accepted_events += 1
	accounting_valid = accounting_valid and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid()


func isolated_s(label: String, seed_value: int = 87017) -> Node3D:
	var arena := create_s(label, seed_value)
	await start_frozen(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(100, 3, 100)
	arena.ledger.transfer_accepted.connect(audit_transfer.bind(arena))
	arena.flare_director.equipment.transfer_accepted.connect(audit_transfer.bind(arena))
	return arena


func park_actors(arena: Node3D) -> void:
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.position = Vector3(100 + actor.raider_id * 3, 0.1, 120)


func all_entries(arena: Node3D) -> void:
	park_actors(arena)
	await frames(3) # Let the physics server release occupied entry capsules.
	arena.elapsed = 105.5
	arena.process_entries()
	freeze(arena)
	park_actors(arena)
	check(arena.raiders.size() == 5 and arena.pending_ids.is_empty(), "Normal S schedule admits all five finite IDs under its configured live cap")
	var policies: Array = []
	for actor in arena.raiders.values():
		if not policies.has(actor.profile.combat_policy):
			policies.append(actor.profile.combat_policy)
	check(policies.size() == 3 and not policies.has(RaiderProfile.CombatPolicy.BASELINE), "One normal mission contains all three accepted armed personality policies")


func barrier(arena: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.4)
	collision.shape = shape
	body.add_child(collision)
	body.position = Vector3(0, 1.5, 11)
	arena.add_child(body)
	return body


func dead_target_reports() -> void:
	var arena := await isolated_s("reports")
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 14)
	check(a.social.receive(b, arena.robot, Vector3(0, 0.1, 20), arena.elapsed + 3), "S accepts a live eligible ally sighting")
	var observation: Dictionary = a.social.best_report()
	arena.robot.position += Vector3(10, 0, 0)
	check(a.social.best_report().position == observation.position, "Unseen living target movement cannot relocate shared observation")
	arena.elapsed += 3.1
	check(a.social.best_report().is_empty(), "Live target reports expire without becoming permanent knowledge")
	check(a.social.receive(b, arena.robot, observation.position, arena.elapsed + 3), "Fresh direct observation can renew expired knowledge")
	arena.robot.get_node("Health").apply_damage(1000, b.position, b.get_instance_id())
	var result: Dictionary = arena.mission_objectives.result()
	check(not arena.mission.is_world_finished() and arena.mission.player_destroyed, "S deployment death preserves independent world simulation")
	check(not arena.social.eligible(arena.robot, a) and a.social.best_report().is_empty(), "Destroyed player immediately invalidates cached allied report")
	check(not a.social.receive(b, arena.robot, Vector3.ZERO, arena.elapsed + 3), "New reports cannot reintroduce destroyed player")
	check(arena.mission_objectives.result() == result and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Report invalidation cannot change frozen result or accounting")
	arena.queue_free()
	await frames(30)


func shared_machine_threat() -> void:
	var arena := await isolated_s("cooperation")
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(-4, 0.1, 8)
	guard.position = Vector3(0, 0.1, 14)
	var blocker := barrier(arena)
	await frames(3)
	b.decide()
	a.decide()
	check(b.current_target() == guard and b.threat_visible and not a.detects_actor(guard), "Normal allied observer sees a machine physically occluded from its ally")
	check(a.state == Raider.State.INVESTIGATING and a.threat_source == "ally report" and not a.threat_visible, "Normal S cooperation initiates independent last-known-position investigation")
	var origin := a.position
	a.set_physics_process(true)
	b.set_physics_process(true)
	b.combat.weapon.set_physics_process(true)
	await frames(150)
	freeze(arena)
	check(a.position.distance_to(origin) > 0.3 and guard.health.current < guard.health.maximum, "Shared-threat investigation physically moves while the observing ally fires actual machine hits")
	check(a.squad_id.is_empty() and b.squad_id.is_empty(), "Cooperation does not assign a permanent squad")
	guard.health.apply_damage(1000, b.position, b.get_instance_id())
	check(not arena.social.eligible(guard, a) and a.social.best_report().is_empty() and arena.ledger.dropped_materials == 1, "Machine death invalidates allied targeting and releases only its preallocated component")
	blocker.queue_free()
	arena.queue_free()
	await frames(30)


func physical_rivals() -> void:
	var arena := await isolated_s("rivals", 87018)
	await all_entries(arena)
	var a: Raider = arena.raiders[1]
	var rival: Raider = arena.raiders[4]
	a.position = Vector3(0, 0.1, 8)
	rival.position = Vector3(0, 0.1, 14)
	await frames(3)
	a.set_physics_process(true)
	rival.set_physics_process(true)
	a.combat.weapon.set_physics_process(true)
	rival.combat.weapon.set_physics_process(true)
	for index in range(900):
		await frames(1)
		if a.health.current < a.health.maximum and rival.health.current < rival.health.maximum:
			break
	freeze(arena)
	check(a.health.current < a.health.maximum and rival.health.current < rival.health.maximum, "Normal S hostile pair physically exchanges damage through Q decisions and live weapon cadence")
	check(a.health.last_damage_instigator_id == rival.get_instance_id() and rival.health.last_damage_instigator_id == a.get_instance_id(), "Rival combat records the actual independent attacking actors")
	arena.social.relations.set_attitude(1, 4, RaiderRelations.Attitude.NEUTRAL, "fixture ceasefire", arena.elapsed)
	a.decide()
	rival.decide()
	check(not arena.social.eligible(a, rival) and not arena.social.eligible(rival, a), "Changed normal relationship releases reciprocal combat eligibility")
	arena.queue_free()
	await frames(30)


func contested_salvage() -> void:
	var arena := await isolated_s("contested")
	await all_entries(arena)
	var cautious: Raider = arena.raiders[3]
	var greedy: Raider = arena.raiders[4]
	var point: Node3D = arena.get_node("Salvage2")
	check(arena.ledger.collect(3, &"Salvage3", 2) == 2, "Partial-capacity fixture loads two existing units without changing the Cowardly profile")
	cautious.position = point.position + Vector3(0.3, 0.1, 0)
	greedy.position = point.position + Vector3(-0.3, 0.1, 0)
	await frames(3)
	for actor in [cautious, greedy]:
		actor.salvage = point
		actor.transition(Raider.State.SCAVENGING)
		actor.task_elapsed = actor.scavenge_seconds
		arena._on_collection_requested(actor)
	check(cautious.carried_materials == 3 and greedy.carried_materials == 2 and arena.ledger.available(point.name) == 0, "Normal neutral competitors split only the finite three-unit stock within their actual capacities")
	var transfers: int = arena.ledger.accepted_transfers
	arena._on_collection_requested(greedy)
	check(arena.ledger.accepted_transfers == transfers and arena.social.relations.attitude(3, 4) == RaiderRelations.Attitude.NEUTRAL, "Depleted contest neither duplicates stock nor manufactures hostility")
	greedy.health.apply_damage(1000, cautious.position, cautious.get_instance_id())
	arena.robot.position = greedy.position
	await frames(3)
	check(arena.try_recover() and arena.ledger.recovered_materials == 2 and not arena.try_recover() and arena.ledger.lost_materials == 0, "Player recovery consumes a conflict drop once without recording an invented Raider extraction")
	arena.queue_free()
	await frames(30)


func betrayal_loot_and_recall() -> void:
	var arena := await isolated_s("betrayal")
	await all_entries(arena)
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 14)
	check(arena.ledger.collect(2, &"Salvage", 3) == 3, "Richer ally fixture transfers existing stock through the normal material owner")
	a.transition(Raider.State.SELECTING)
	await frames(3)
	a.decide()
	a.betrayal.tick(1)
	check(a.state == Raider.State.ASSESSING_BETRAYAL and not a.betrayal.spent, "Normal Q Greedy preserves the existing visible betrayal assessment")
	b.position.z = 18
	await frames(3)
	a.betrayal.tick(1)
	check(not a.betrayal.spent and a.betrayal.elapsed == 0, "Leaving valid range cancels normal-scene assessment without hostility")
	b.position.z = 14
	await frames(3)
	a.decide()
	a.betrayal.tick(2)
	check(a.betrayal.spent and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.HOSTILE and arena.social.relations.attitude(4, 5) == RaiderRelations.Attitude.ALLIED, "Valid assessment changes only its pair, with no cargo reward")
	a.combat.tick(0.7)
	b.decide()
	b.combat.tick(0.7)
	check(b.health.current < 100 and b.health.last_damage_instigator_id == a.get_instance_id() and (b.combat.owns_state() or b.combat.escaping), "Betrayal fires a real shot and victim independently chooses existing Q defense")
	# The player deliberately intervenes with the real weapon, rather than forcing an AI winner.
	a.position.x = 8
	arena.robot.position = Vector3(0, 0.1, 8)
	await frames(3)
	var weapon: HitscanWeapon = arena.robot.get_node("Weapon")
	for index in range(10):
		if b.health.current <= 0:
			break
		weapon.cooldown = 0
		weapon.try_fire_at(b.target_point(b))
	check(b.health.current <= 0 and arena.mission_objectives.snapshot()[3].progress == 1, "Player can intervene in social combat and receive only its actual lethal-hit objective credit")
	await frames(3)
	check(arena.ledger.dropped_materials == 3 and arena.flare_director.equipment.ground_count(2) == 2 and arena.flare_director.committed == 1, "Social conflict death creates ordinary finite cargo, equipment and one response ticket")
	arena.robot.position = Vector3(100, 0.1, 100)
	a.position = Vector3(0, 0.1, 8)
	a.set_physics_process(true)
	a.combat.weapon.set_physics_process(true)
	var recovered := false
	for index in range(900):
		await frames(1)
		recovered = recovered or arena.ledger.cargo_for(1) >= 3
		if recovered:
			break
	freeze(arena)
	check(recovered and arena.ledger.dropped_materials == 0, "Surviving Raider physically approaches and scavenges conflict cargo through the unchanged S selector")
	# Recovered cargo reaches an actual exit using ordinary movement and extraction dwell.
	a._choose_exit()
	a.transition(Raider.State.EXTRACTING)
	a.set_physics_process(true)
	for index in range(1800):
		await frames(1)
		if not arena.ledger.is_active(1):
			break
	freeze(arena)
	check(not arena.ledger.is_active(1) and arena.ledger.lost_materials >= 3, "Re-looted material becomes extraction loss only after physical exit travel and dwell")
	# The director's completed/early objective and save/retry paths remain in deployment_flow_test.
	arena.elapsed += 8
	arena.flare_director.process_responses()
	freeze(arena)
	var responder: Raider = arena.raiders.get(6)
	check(is_instance_valid(responder) and responder.profile.combat_policy == RaiderProfile.CombatPolicy.AGGRESSIVE and arena.social.relations.attitude(6, 4) == RaiderRelations.Attitude.HOSTILE, "Normal flare response retains finite Q profile and authored social eligibility")
	arena.queue_free()
	await frames(30)


func crowd_and_post_death() -> void:
	var arena := await isolated_s("crowd", 87018)
	await all_entries(arena)
	var positions: Array[Vector3] = [Vector3(-2, 0.1, 7), Vector3(0, 0.1, 7), Vector3(2, 0.1, 7), Vector3(-2, 0.1, 5), Vector3(0, 0.1, 5)]
	for id in range(1, 6):
		var actor: Raider = arena.raiders[id]
		actor.position = positions[id - 1]
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	for index in range(arena.ecosystem.machines.size()):
		var machine: SupportMachine = arena.ecosystem.machines[index]
		machine.position = Vector3(-2, 3.5, 9) if machine.flying else Vector3(0, 0.1, 9)
		machine.set_physics_process(true)
		if machine.weapon != null:
			machine.weapon.set_physics_process(true)
	var peak: int = arena.flare_director.living_count()
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	var caps_valid := true
	for index in range(300):
		await frames(1)
		caps_valid = caps_valid and arena.flare_director.living_count() <= 5 and arena.flare_director.committed <= 2
	freeze(arena)
	var moved := 0
	for id in range(1, 6):
		var actor: Raider = arena.raiders[id]
		if is_instance_valid(actor) and actor.position.distance_to(positions[id - 1]) > 0.3:
			moved += 1
	check(peak == 5 and moved >= 3 and caps_valid, "Configured five-Raider/two-machine crowd executes physical combat/navigation within population bounds")
	var victim: Raider = arena.raiders[5]
	check(arena.ledger.collect(5, &"Salvage", 3) == 3, "Failure fixture loads finite cargo before ordinary death")
	victim.health.apply_damage(1000, victim.position, arena.robot.get_instance_id())
	arena.robot.position = victim.position
	await frames(3)
	check(arena.try_recover(), "Player physically recovers cargo after intervening in a crowded encounter")
	arena.robot.input_adapter.recover_held = true
	arena.flare_director.update_recovery(0)
	arena.flare_director.update_recovery(1.6)
	check(arena.flare_director.equipment.count_at(EquipmentLedger.Location.RECOVERED) == 2, "Timed interaction recovers the conflict's finite equipment allocation")
	var second: Raider = arena.raiders[4]
	second.health.apply_damage(1000)
	var killer: Raider = arena.raiders[1]
	arena.robot.get_node("Health").apply_damage(1000, killer.position, killer.get_instance_id())
	var result: Dictionary = arena.mission_objectives.result()
	var transfers: int = arena.ledger.accepted_transfers
	var equipment_transfers: int = arena.flare_director.equipment.accepted_transfers
	arena.finish_mission()
	arena._on_player_destroyed()
	check(result.materials_forfeited == 3 and result.equipment_forfeited == 2 and arena.ledger.accepted_transfers == transfers and arena.flare_director.equipment.accepted_transfers == equipment_transfers, "Player destruction forfeits both conflict rewards exactly once")
	check(arena.post_death.enter() and arena.post_death.selected == killer and not arena.spectator.enter(), "Player follow prefers the lethal Raider and cannot acquire developer flight permissions")
	for index in range(10):
		arena.post_death.cycle(1)
		arena.post_death.step()
	check(arena.ledger.accepted_transfers == transfers and arena.flare_director.equipment.accepted_transfers == equipment_transfers and not arena.social.eligible(arena.spectator_view.camera, killer), "Normal target cycling and camera proximity cannot influence accounting or combat eligibility")
	arena.elapsed += 8.1
	arena.flare_director.process_responses()
	freeze(arena)
	check(arena.raiders.has(6) and arena.raiders.has(7) and arena.flare_director.living_count() == 5 and arena.flare_director.committed == 2, "Both finite responses can arrive after player death without exceeding the shared five-live cap")
	check(arena.social.relations.attitude(6, 7) == RaiderRelations.Attitude.ALLIED and arena.raiders[7].profile.combat_policy == RaiderProfile.CombatPolicy.GREEDY, "Post-death responders retain independent Q policies and explicit alliance")
	var survivor: Raider = arena.raiders[6]
	var origin := survivor.position
	var activity := {"shots": 0}
	survivor.combat.weapon.fired.connect(func(_origin: Vector3, _end: Vector3, _hit: bool) -> void: activity.shots += 1)
	survivor.set_physics_process(true)
	survivor.combat.weapon.set_physics_process(true)
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	await frames(120)
	freeze(arena)
	check(survivor.position.distance_to(origin) > 0.3 or activity.shots > 0, "Autonomous response physically moves or executes live weapon shots after player death")
	check(arena.mission_objectives.result() == result, "Continuing autonomous activity cannot reopen player objectives")
	arena.post_death.selected = survivor
	survivor.health.apply_damage(1000)
	arena.post_death.step()
	check(arena.post_death.selected != survivor and arena.flare_director.committed == 2, "Follow target death safely switches view and cannot replenish reinforcements")
	var extracting := arena.post_death.selected as Raider
	check(extracting != null and extracting._choose_exit(), "Another eligible followed Raider retains a reachable extraction")
	if extracting != null:
		# Arrange a loaded, uncontested exit; a still-visible threat may legitimately interrupt an empty actor.
		for point in arena.salvage_points:
			arena.ledger.collect(extracting.raider_id, point.name, extracting.profile.cargo_target)
		for other in arena.raiders.values():
			if is_instance_valid(other) and other != extracting:
				other.position = Vector3(100 + other.raider_id * 3, 0.1, 120)
		for machine in arena.ecosystem.machines:
			machine.position = Vector3(100, 3, 100)
		await frames(3)
		extracting.position = extracting.extraction.position + Vector3.UP * 0.1
		extracting.transition(Raider.State.EXTRACTING)
		extracting.set_physics_process(true)
		var id := extracting.raider_id
		for index in range(600):
			await frames(1)
			if not arena.ledger.is_active(id):
				break
		arena.post_death.step()
		check(not arena.ledger.is_active(id) and (not is_instance_valid(extracting) or not arena.post_death.eligible(extracting)), "Physical extraction dwell removes a followed target without reviving deployment")
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(arena.mission.is_world_finished() and not arena.post_death.active and arena.mission_objectives.result() == result, "World deadline closes observation while preserving the one settled player result")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	check(not arena.deployment_started and arena.debug_seed == 87018 and arena.flare_director.committed == 0 and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED and arena.raiders.is_empty() and arena.recall.stash.snapshot().materials == 0, "Normal replay rebuilds clean briefing, authored relations and budgets without banking forfeited loot")
	arena.queue_free()
	await frames(30)


func run() -> void:
	test_directory = "res://.godot/stage_t_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	print("Stage T artifacts: ", test_directory)
	await dead_target_reports()
	await shared_machine_threat()
	await physical_rivals()
	await contested_salvage()
	await betrayal_loot_and_recall()
	await crowd_and_post_death()
	check(accepted_events > 0 and accounting_valid, "Both authoritative ledgers remain valid after every accepted integration transfer")
	print("Stage T integration checks complete; failures: ", failures)
	quit(1 if failures else 0)
