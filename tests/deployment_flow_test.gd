extends "res://tests/integrated_extraction_test.gd"
## Actual S scene/physics, interaction, attribution and persistence boundaries.


func create_s(label: String, seed_value: int = 87017) -> Node3D:
	var arena := load("res://scenes/levels/asset_recovery_arena.tscn").instantiate() as Node3D
	# Preserve the accepted S/T scalar-content fixture; Stage Z's real normal
	# configuration is exercised separately by the inventory integration suites.
	arena.mission_config_override = load("res://resources/missions/asset_recovery.tres").duplicate(true)
	arena.mission_config_override.hybrid_inventory = false
	arena.stash_path = test_directory + "/" + label + ".json"
	arena.seed_override = seed_value
	root.add_child(arena)
	current_scene = arena
	return arena


func start_frozen(arena: Node3D) -> void:
	check(arena.start_deployment() and not arena.start_deployment(), "Deploy starts exactly once")
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)


func recover_from_raider(arena: Node3D, units: int, player_kill: bool = false) -> void:
	var victim: Raider = arena.raiders[1]
	victim.position = Vector3(0, 0.1, 8)
	arena.robot.position = victim.position
	arena.ledger.collect(1, &"Salvage", units)
	victim.health.apply_damage(1000, victim.position, arena.robot.get_instance_id() if player_kill else 0)
	await frames(3)
	check(arena.try_recover(), "Finite physical cargo recovery uses accepted interaction")


func finish_recall(arena: Node3D) -> void:
	await dock_robot(arena)
	arena.recall.step(0.1)
	for index in range(60):
		if arena.mission.is_finished():
			break
		arena.recall.step(0.1)


func preview(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(test_directory + "/" + label + ".png")


func run() -> void:
	test_directory = "res://.godot/stage_s_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	print("Stage S artifact directory: ", test_directory)
	var arena := await create_s("early")
	var robot_position: Vector3 = arena.robot.position
	var guard_position: Vector3 = arena.ecosystem.machines[1].position
	var transfers: int = arena.ledger.accepted_transfers
	await frames(65)
	arena.process_entries()
	arena.flare_director.process_responses()
	check(not arena.deployment_started and arena.elapsed == 0 and arena.raiders.is_empty() and arena.pending_ids.size() == 5, "Briefing prevents time, entries and scheduler progression")
	check(arena.robot.position == robot_position and arena.ecosystem.machines[1].position == guard_position and arena.ledger.accepted_transfers == transfers and not arena.try_recover() and not arena.recall.eligible(), "Entire world and authoritative player interactions are gated before Deploy")
	check(not arena.robot.get_node("Weapon").try_fire_at(Vector3.ZERO) and not arena.robot.input_adapter.gameplay_enabled, "Briefing cannot fire or consume player movement")
	await preview("briefing")
	if DisplayServer.get_name() == "headless":
		# Headless window coordinates are not a graphical GUI acceptance test.
		arena.objective_view.deploy_button.pressed.emit()
	else:
		var position: Vector2 = arena.objective_view.deploy_button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = position
		motion.global_position = position
		root.push_input(motion)
		for pressed in [true, false]:
			var mouse := InputEventMouseButton.new()
			mouse.position = position
			mouse.global_position = position
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = pressed
			root.push_input(mouse)
			await frames(1)
	await frames(1)
	freeze(arena)
	check(arena.deployment_started and not arena.start_deployment(), "Deploy button starts exactly once while the world is disabled")
	if not arena.deployment_started:
		quit(1)
		return
	await frames(10)
	arena.process_entries()
	freeze(arena)
	check(arena.ledger.total_materials == 14 and arena.raiders.size() == 2 and arena.robot.traversal_enabled, "S retains finite R composition and accepted traversal")
	await recover_from_raider(arena, 1)
	check(arena.mission_objectives.snapshot()[0].progress == 0 and arena.mission_objectives.snapshot()[0].carried == 1, "Pickup readiness is not banked completion")
	await preview("active")
	await finish_recall(arena)
	check(arena.mission.player_extracted and arena.mission.phase == MissionRules.Phase.FAILED and arena.ledger.banked_materials == 1 and arena.recall.stash.snapshot().materials == 1, "Real early recall preserves inventory while reporting incomplete primary")
	check(arena.mission_objectives.result().objectives[0].status == "incomplete" and arena.mission_objectives.result().equipment_banked == 0, "Optional equipment and combat never block extraction")
	await preview("early_result")
	var receipt: String = arena.recall.deployment_id
	var frozen: Dictionary = arena.mission_objectives.result()
	arena.finish_mission()
	arena.refresh_hud()
	check(arena.mission_objectives.result() == frozen and not arena.recall.complete(), "Results display and repeated finish cannot resettle or change results")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	check(arena.scenario_index == 16 and not arena.deployment_started and arena.elapsed == 0 and arena.debug_seed == 87017 and arena.recall.deployment_id != receipt and not arena.mission_objectives.is_closed() and arena.recall.stash.snapshot().materials == 1, "Restart returns to briefing with fresh objectives/receipt and preserved stash/seed")
	arena.queue_free()
	await frames(3)
	await success_and_save_retry()
	await death_and_continuation()
	await physical_credit()
	await seed_and_deadline()
	await replacement_and_routing()
	print("Stage S deployment-flow failures: ", failures)
	quit(0 if failures == 0 else 1)


func success_and_save_retry() -> void:
	var arena := await create_s("success")
	await start_frozen(arena)
	await recover_from_raider(arena, 3)
	arena.robot.input_adapter.recover_held = true
	for index in range(17):
		arena.flare_director.update_recovery(0.1)
	check(arena.flare_director.equipment.count_at(EquipmentLedger.Location.RECOVERED) == 2, "Existing timed equipment interaction transfers a finite loadout")
	# Make the save parent an ordinary file, not a directory; preserve the real stash.
	var blocker_path := test_directory + "/blocked"
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	blocker.store_string("fixture")
	blocker.close()
	arena.recall.stash.path = blocker_path + "/stash.json"
	await finish_recall(arena)
	check(not arena.mission.is_finished() and not arena.mission_objectives.is_closed() and arena.ledger.recovered_materials == 3 and arena.mission_objectives.snapshot()[0].progress == 0, "Save failure preserves open objectives and cargo for retry")
	arena.recall.stash.path = arena.stash_path
	await finish_recall(arena)
	check(arena.mission.phase == MissionRules.Phase.SUCCEEDED and arena.ledger.banked_materials == 3 and arena.flare_director.equipment.count_at(EquipmentLedger.Location.BANKED) == 2, "Successful recall and required objectives produce mission success")
	check(arena.mission_objectives.result().equipment_banked == 2 and arena.mission_objectives.result().objectives[2].status == "completed", "Optional recovery counts actual items, not bundles")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "S success retains both conservation guarantees")
	await preview("success_result")
	arena.queue_free()
	await frames(3)


func death_and_continuation() -> void:
	var arena := await create_s("death")
	await start_frozen(arena)
	await recover_from_raider(arena, 3, true)
	arena.flare_director.equipment.recover(1)
	var killer: Raider = arena.raiders[2]
	arena.robot.get_node("Health").apply_damage(1000, killer.position, killer.get_instance_id())
	var result: Dictionary = arena.mission_objectives.result()
	var transfers: int = arena.ledger.accepted_transfers
	check(result.destroyed and not result.success and result.materials_forfeited == 3 and result.equipment_forfeited == 2 and result.objectives[3].status == "completed", "Death freezes failed deployment while preserving earned optional kill status")
	arena.finish_mission()
	arena._on_player_destroyed()
	check(arena.ledger.accepted_transfers == transfers and not FileAccess.file_exists(arena.stash_path) and not arena.mission.is_world_finished(), "Death forfeits once without banking or stopping autonomous world")
	check(arena.post_death.enter() and arena.post_death.selected == killer, "S retains restricted follow and lethal-instigator preference")
	arena.post_death.cycle(1)
	arena.elapsed = 35
	arena.process_entries()
	check(arena.raiders.has(3), "Remaining scheduled Raiders enter after deployment settlement")
	var machine: SupportMachine = arena.ecosystem.machines[0]
	var start: Vector3 = machine.position
	machine.set_physics_process(true)
	await frames(40)
	check(machine.position.distance_to(start) > 0.1, "World physically simulates after S player death")
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.health.apply_damage(1000, actor.position, arena.robot.get_instance_id())
	check(arena.mission_objectives.result() == result, "Later kills and spectating cannot rewrite settled objectives or rewards")
	arena.post_death.return_to_summary()
	check(arena.mission.is_world_finished() and arena.summary.visible and arena.mission_objectives.result() == result and arena.ledger.is_conserved(), "Return presents the frozen result without another settlement")
	await preview("failed_result")
	arena.queue_free()
	await frames(3)


func physical_credit() -> void:
	var arena := await create_s("shots")
	await start_frozen(arena)
	# Reuse clear physical firing corridor from accepted combat scenarios.
	var victim: Raider = arena.raiders[1]
	var other: Raider = arena.raiders[2]
	arena.robot.position = Vector3(0, 0.1, 8)
	victim.position = Vector3(0, 0.1, 14)
	other.position = Vector3(18, 0.1, -18)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(20, 3, 20)
	await frames(3)
	var weapon := arena.robot.get_node("Weapon") as ShotExecutor
	for index in range(8):
		if victim.health.current <= 0:
			break
		weapon.cooldown = 0
		weapon.try_fire_at(victim.global_position + Vector3.UP)
	check(arena.mission_objectives.snapshot()[3].progress == 1 and not arena.mission.is_finished(), "Physical player lethal hits produce credit without auto-completing deployment")
	var credit := {"deployment_id": arena.recall.deployment_id, "victim": 1, "eligible": true, "instigator": arena.robot.get_instance_id()}
	arena.raider_defeat_accepted.emit(credit)
	check(arena.mission_objectives.snapshot()[3].progress == 1, "Repeated accepted notification cannot duplicate kill credit")
	other.health.apply_damage(1000, other.position, arena.ecosystem.machines[1].get_instance_id())
	arena.ecosystem.machines[0].health.apply_damage(1000, arena.robot.position, arena.robot.get_instance_id())
	check(arena.mission_objectives.snapshot()[3].progress == 1, "AI lethal hits and allied machine destruction do not grant Raider objective credit")
	arena.queue_free()
	await frames(3)


func replacement_and_routing() -> void:
	var arena := await create_s("replacement")
	await start_frozen(arena)
	await recover_from_raider(arena, 3)
	var old_objectives: MissionObjectives = arena.mission_objectives
	arena.select_scenario(13)
	await frames(3)
	check(old_objectives.is_closed() and old_objectives.result().materials_forfeited == 3 and not old_objectives.result().success, "Leaving an active S deployment settles abandonment and freezes its result")
	check(current_scene.scenario_index == 13 and current_scene.deployment_started and current_scene.mission_objectives == null, "Developer encounter preset keeps legacy immediate start and policy")
	current_scene.queue_free()
	await frames(3)
	arena = await create_s("seed_cycle", 87018)
	await start_frozen(arena)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F5
	key.pressed = true
	key.ctrl_pressed = true
	key.shift_pressed = true
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	check(arena.scenario_index == 16 and arena.debug_seed == 87019 and not arena.deployment_started and arena.config.seed == 87017, "S debug seed cycling returns to its own briefing without editing shared config")
	await start_frozen(arena)
	key.ctrl_pressed = false
	key.shift_pressed = false
	arena._unhandled_input(key)
	await frames(12)
	check(current_scene.scenario_index == 12 and current_scene.deployment_started and current_scene.ledger.total_materials == 11, "Plain in-game F5 retains accepted N reference routing from S")
	current_scene.queue_free()
	await frames(3)


func seed_and_deadline() -> void:
	var arena := await create_s("deadline", 87018)
	var setup: Dictionary = arena.encounter.snapshot.duplicate(true)
	check(arena.debug_seed == 87018 and arena.config.seed == 87017 and arena.ledger.total_materials == 14, "S runtime seed override preserves authored config and stock")
	await start_frozen(arena)
	await recover_from_raider(arena, 3)
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(arena.mission_objectives.result().expired and arena.mission_objectives.snapshot()[0].status == "expired" and arena.ledger.forfeited_materials == 3, "Deadline freezes expiration and one-time forfeiture")
	arena.queue_free()
	await frames(3)
	arena = await create_s("repeat", 87018)
	check(arena.encounter.snapshot == setup and arena.mission_objectives.snapshot()[0].progress == 0, "Repeated seed reproduces configuration with fresh objective state")
	arena.queue_free()
	await frames(3)
