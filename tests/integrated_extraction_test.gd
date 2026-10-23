extends SceneTree

var failures: int = 0
var test_directory: String


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func freeze(arena: Node3D) -> void:
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			actor.combat.weapon.set_physics_process(false)


func create_arena(save_name: String) -> Node3D:
	var arena := load("res://scenes/levels/integrated_extraction_arena.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/" + save_name
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)
	return arena


func dock_robot(arena: Node3D) -> void:
	arena.robot.position = arena.get_node("RecallDock").position + Vector3.UP * 0.1
	arena.robot.velocity = Vector3.ZERO
	arena.robot.input_adapter.clear_intent()
	arena.robot.set_physics_process(true)
	await frames(10)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.recover_held = true


func run() -> void:
	test_directory = "res://.godot/stage_n_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var arena: Node3D = await create_arena("successful.json")
	check(arena.scenario_index == 12 and arena.config.validation_error().is_empty() and arena.raiders.size() == 3, "Integrated preset deploys three valid scheduled Raiders")
	check(arena.mission.requires_extraction and arena.robot.traversal_enabled and arena.spectator != null and arena.social != null and arena.ecosystem.machines.size() == 2, "Recall, traversal, spectator, social AI and support machines coexist")
	check(arena.ledger.total_materials == 11 and arena.ledger.protected_materials == 11 and arena.ledger.carried_materials == 0, "Nine salvage units plus two installed components are allocated once upfront")
	var a := arena.raiders[1] as Raider
	var b := arena.raiders[2] as Raider
	var c := arena.raiders[3] as Raider
	check(a.profile != b.profile and b.profile != c.profile and a.betrayal != null and b.betrayal == null and c.betrayal == null and a.social != null, "Existing personalities stay distinct with one opportunist and local cooperation")
	var scout := arena.ecosystem.machines[0] as SupportMachine
	var guard := arena.ecosystem.machines[1] as SupportMachine
	arena.robot.position = Vector3(100, 0.1, 100)
	scout.position = Vector3(18, 3.5, -18)
	guard.position = Vector3(3, 0.1, 8)
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(18, 0.1, -18)
	c.position = Vector3(0, 0.1, 14)
	await frames(3)
	a.decide()
	check(a.current_target() == guard and a.state == Raider.State.ENGAGING, "Social target selection still recognizes nearby machine threats alongside human rivals")
	a.combat.profile = a.combat.profile.duplicate()
	a.combat.profile.spread_degrees = 0
	a.combat.tick(0.7)
	check(guard.health.current == 70 and guard.health.last_damage_instigator_id == a.get_instance_id(), "Relation-aware weapon predicate permits ordinary damage to support machines")
	guard.position = Vector3(18, 0.1, -18)
	await frames(3)
	check(arena.social.choose_target(a) == guard, "Brief loss of guard sight preserves the integrated engagement")
	a.threat_remaining = 0
	a.decide()
	check(a.current_target() == c and arena.social.eligible(c, a) and not arena.social.eligible(b, a), "Rival selection and allied damage protection remain active with machine support enabled")
	c.position = Vector3(20, 0.1, -18)
	b.position = Vector3(0, 0.1, 14)
	a.threat_remaining = 0
	a.transition(Raider.State.SELECTING)
	arena.ledger.collect(2, &"Salvage", 3)
	await frames(3)
	a.decide()
	check(a.state == Raider.State.ASSESSING_BETRAYAL, "An actual quiet opportunity can start assessment in the combined mission")
	a.betrayal.tick(2)
	check(a.betrayal.spent and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.HOSTILE and b.carried_materials == 3, "Betrayal changes only hostility while loaded victim retains ledger cargo")
	var death_position := b.position
	b.health.apply_damage(1000, a.position, a.get_instance_id())
	await frames(3)
	check(arena.ledger.dropped_materials == 3 and arena.flare_director.equipment.ground_count(2) == 2 and arena.flare_director.tickets.size() == 1, "Loaded social death produces ordinary material cargo, equipment and one bounded response")
	arena.elapsed = 8
	arena.flare_director.process_responses()
	var responder := arena.raiders.get(4) as Raider
	check(is_instance_valid(responder) and responder.social != null and responder.betrayal == null and arena.flare_director.committed == 1, "Integrated flare admits a finite cooperating responder without granting a new betrayal capability")
	freeze(arena)
	check(arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.HOSTILE and arena.social.relations.attitude(1, 4) == RaiderRelations.Attitude.ALLIED and arena.social.relations.attitude(3, 4) == RaiderRelations.Attitude.HOSTILE, "Responder initialization does not reconcile betrayed pair and retains explicit rival policy")
	# Material pickup takes priority over equipment hold at the same death location.
	arena.robot.position = death_position
	arena.robot.input_adapter.recover_held = true
	await frames(3)
	arena.flare_director.update_recovery(2)
	check(arena.flare_director.equipment.ground_count(2) == 2 and arena.try_recover(), "Overlapping material cargo blocks equipment channel until material recovery")
	arena.flare_director.update_recovery(0)
	arena.flare_director.update_recovery(1.6)
	check(arena.ledger.recovered_materials == 3 and arena.flare_director.equipment.count_at(EquipmentLedger.Location.RECOVERED) == 2, "Existing material pickup and timed equipment hold recover separate finite allocations")
	guard.health.apply_damage(1000)
	await frames(3)
	var component_id: int = arena.ecosystem.component_drop_ids[0]
	arena.robot.position = arena.drops[component_id].position
	await frames(3)
	check(arena.try_recover() and arena.ledger.recovered_materials == 4 and arena.ledger.is_conserved(), "Support destruction releases its preallocated component into the same recovery and banking ledger")
	# A second pending ticket must not prevent voluntary extraction.
	c.health.apply_damage(1000)
	await frames(3)
	check(arena.flare_director.committed == 2 and arena.flare_director.tickets.size() == 1, "Further death consumes the final response budget without replenishment")
	await dock_robot(arena)
	arena.recall.step(0)
	arena.recall.step(2)
	arena.robot.get_node("Health").apply_damage(10)
	check(arena.recall.channeling and arena.recall.elapsed == 2, "Nonlethal damage preserves extraction progress in the combined mission")
	check(arena.ledger.active_raiders > 0 and not arena.flare_director.tickets.is_empty(), "Recall fixture retains active Raiders and an outstanding response")
	arena.recall.step(3)
	check(arena.mission.player_extracted and arena.ledger.banked_materials == 4 and arena.recall.stash.snapshot().materials == 4 and arena.recall.stash.snapshot().equipment.size() == 2, "Five-second recall banks combined cargo and equipment while threats remain")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid() and not arena.recall.complete() and not a.combat.weapon.enabled and not scout.active, "Extraction seals ownership and stops all systems without duplicate rewards")
	var save_path: String = arena.stash_path
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 12 and arena.stash_path == save_path and arena.recall.stash.snapshot().materials == 4 and arena.ledger.total_materials == 11 and arena.flare_director.committed == 0, "Restart preserves isolated stash and reconstructs fresh integrated deployment")
	check(arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED, "Restart restores authored alliances independently of prior betrayal")
	arena.queue_free()
	await frames(30)
	# Deadline and destruction retain separate loss categories and never credit stash.
	for ending in ["deadline", "destruction"]:
		arena = await create_arena(ending + ".json")
		a = arena.raiders[1]
		b = arena.raiders[2]
		arena.ledger.collect(1, &"Salvage", 3)
		arena.ledger.collect(2, &"Salvage2", 3)
		a.health.apply_damage(1000)
		b.health.apply_damage(1000)
		await frames(3)
		var first_drop := arena.drops.values()[0] as MaterialDrop
		arena.robot.position = first_drop.position
		await frames(3)
		check(arena.try_recover(), "%s fixture recovers deployment cargo through physical eligibility" % ending)
		if ending == "deadline":
			arena.elapsed = arena.mission_duration
			arena._physics_process(0.01)
		else:
			arena.robot.get_node("Health").apply_damage(1000)
		check(arena.mission.phase == MissionRules.Phase.FAILED and arena.ledger.forfeited_materials == 3 and arena.ledger.dropped_materials == 3 and arena.ledger.lost_materials == 0 and arena.ledger.is_conserved(), "%s preserves forfeited cargo versus unrecovered ground versus actual extraction loss" % ending)
		check(not FileAccess.file_exists(arena.stash_path) and not arena.recall.complete(), "%s cannot bank loot or accept a late extraction" % ending)
		arena.queue_free()
		await frames(30)
	# Resolve the whole human population and recover the death loot: no auto victory.
	arena = await create_arena("quiet.json")
	for actor in arena.raiders.values():
		actor.health.apply_damage(1000)
	await frames(3)
	arena.elapsed = 8
	arena.flare_director.process_responses()
	freeze(arena)
	for actor in arena.raiders.values():
		if is_instance_valid(actor) and actor.health.current > 0:
			actor.health.apply_damage(1000)
	for id in arena.flare_director.equipment_drops:
		arena.flare_director.equipment.recover(id)
	arena.evaluate_mission()
	check(arena.ledger.active_raiders == 0 and arena.flare_director.tickets.is_empty() and arena.mission.phase == MissionRules.Phase.RECOVERING and not arena.mission.is_finished(), "All Raiders and bounded responders resolving with no ground loot still requires player recall")
	check(arena.ledger.protected_materials == 11 and arena.ledger.is_conserved(), "Untouched salvage/components neither duplicate nor prevent voluntary recall")
	await dock_robot(arena)
	arena.recall.step(0)
	arena.recall.step(5)
	check(arena.mission.player_extracted, "Player can choose extraction after the arena becomes quiet")
	arena.queue_free()
	await frames(30)
	# Natural simultaneous simulation, without forced cargo or activity transitions.
	arena = await create_arena("natural.json")
	for actor in arena.raiders.values():
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(true)
		if machine.weapon != null:
			machine.weapon.set_physics_process(true)
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	arena.recall.set_physics_process(true)
	arena.robot.set_physics_process(true)
	var start_scout: Vector3 = arena.ecosystem.machines[0].position
	check(arena.spectator.enter(), "Integrated mission supports spectator observation during normal simulation")
	await frames(600)
	check(arena.elapsed > 8 and arena.ecosystem.machines[0].position.distance_to(start_scout) > 0.5 and arena.ledger.accepted_transfers > 0, "Natural combined run advances support patrol, AI combat/scavenging and finite transfers")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid() and arena.flare_director.committed <= 2, "Natural combined run maintains both ledgers and finite response budget")
	arena.spectator.leave()
	if not arena.mission.is_finished():
		freeze(arena)
		await dock_robot(arena)
		arena.recall.step(0)
		arena.recall.step(5)
		check(arena.mission.player_extracted, "Natural simulation can finish through ordinary grounded recall")
	arena.queue_free()
	await frames(30)
	print("Stage N integrated extraction checks complete; failures: ", failures)
	quit(1 if failures else 0)
