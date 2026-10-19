extends SceneTree

var failures: int = 0


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


func create_arena(index: int) -> Node3D:
	var arena := load("res://scenes/levels/mission_arena.tscn").instantiate() as Node3D
	arena.scenario_index = index
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	return arena


func run() -> void:
	var invalid := MissionConfig.new()
	invalid.entry_times = PackedFloat32Array([0, 8, 2])
	check(not invalid.validation_error().is_empty(), "Unordered mission schedule is rejected")
	invalid.entry_times = PackedFloat32Array([0, 2, 180])
	check(not invalid.validation_error().is_empty(), "Entries at or beyond deadline are rejected")
	var ledger := MaterialLedger.new({&"A": 3}, [1], {1: 2, 2: 2})
	check(ledger.total_materials == 7 and ledger.dropped_materials == 4 and ledger.is_conserved(), "Initial ground stock is allocated once by the ledger")
	check(ledger.recover(1) == 2 and ledger.recover(1) == 0 and ledger.is_conserved(), "Initial ground recovery cannot double-credit materials")
	ledger.collect(1, &"A", 3)
	var death_drop := ledger.defeat(1)
	check(death_drop == 3 and ledger.drop_source(death_drop) == 1 and ledger.ground_for(2) == 2 and ledger.is_conserved(), "Death drop IDs cannot collide with initial ground stacks")

	var arena := create_arena(0)
	await frames(8)
	check(arena.pending_ids.size() == 3 and arena.raiders.is_empty() and arena.ledger.active_raiders == 3, "Scheduled Raiders are unresolved before physical entry")
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	var origin: Vector3 = arena.robot.global_position
	var all_reachable := true
	for point in arena.salvage_points + arena.extraction_points + arena.spawn_order:
		var single: Array[Node3D] = [point]
		all_reachable = all_reachable and arena.reaches_any(map, origin, single)
	check(all_reachable, "All authored salvage, entry and exit locations connect to the expanded arena")
	var lookout := Marker3D.new()
	arena.add_child(lookout)
	lookout.position = Vector3(15, 1, -12)
	var elevated: Array[Node3D] = [lookout]
	check(arena.reaches_any(map, origin, elevated), "Sloped access connects the raised lookout to navigation")
	check(not arena.entry_is_valid(Vector3(100, 0.1, 100)), "Unsupported off-map spawn is rejected")
	check(not arena.entry_is_valid(arena.robot.global_position), "Spawn overlapping robot is rejected")
	check(not arena.entry_is_valid(Vector3(-8, 0.1, 3)), "Spawn inside graybox obstacle is rejected")
	var marker := arena.spawn_order[0] as Node3D
	check(arena.entry_is_valid(marker.global_position), "Authored supported empty spawn is valid")
	arena.process_entries()
	var first_log: Array[StringName] = arena.entry_log.duplicate()
	check(arena.raiders.size() == 1 and arena.pending_ids.size() == 2, "Intercept admits only the first scheduled Raider at time zero")
	var first := arena.raiders[1] as Raider
	first.set_physics_process(false)
	check(not arena.entry_is_valid(first.global_position), "Spawn overlapping an entered Raider is rejected")
	# Follow the baked route with actual CharacterBody movement, including the ramp.
	first.dynamic_ai = false
	first.extraction = lookout
	first.extraction_seconds = 999
	first.transition(Raider.State.EXTRACTING)
	Engine.time_scale = 3
	first.set_physics_process(true)
	for index in range(600):
		if first.global_position.distance_to(lookout.global_position) < 0.8:
			break
		await frames(1)
	first.set_physics_process(false)
	Engine.time_scale = 1
	check(first.global_position.distance_to(lookout.global_position) < 0.8 and first.global_position.y > 0.7, "Raider physically traverses the ramp to the raised lookout")
	first.health.apply_damage(100)
	await frames(3)
	check(not arena.mission.is_finished() and arena.ledger.active_raiders == 2, "Defeating an early entry cannot finish pending waves")
	arena.elapsed = 8
	arena.process_entries()
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
	check(arena.pending_ids.is_empty() and arena.entry_log.size() == 3 and arena.ledger.is_conserved(), "Later entries use the original ledger without creating stock")
	arena.queue_free()
	await frames(3)

	arena = create_arena(0)
	await frames(8)
	arena.process_entries()
	check(arena.entry_log == first_log, "Same mission seed and state reproduce initial entry")
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
	arena.queue_free()
	await frames(3)

	arena = create_arena(1)
	await frames(8)
	var original_positions: Array[Vector3] = []
	for point in arena.spawn_order:
		original_positions.append(point.position)
		point.position = Vector3(-8, 0.1, 3)
	arena.elapsed = 6
	arena.process_entries()
	check(arena.raiders.is_empty() and arena.pending_ids.size() == 5 and arena.entry_status.contains("blocked"), "Blocked entries remain pending with an explicit retry status")
	for index in range(arena.spawn_order.size()):
		arena.spawn_order[index].position = original_positions[index]
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
	check(arena.raiders.size() == 5 and arena.pending_ids.is_empty() and arena.ledger.total_materials == 15, "Clearing entry obstruction admits all five Swarm Raiders")
	var separated := true
	for a in arena.raiders.values():
		for b in arena.raiders.values():
			if a != b:
				separated = separated and a.global_position.distance_to(b.global_position) >= 0.9
	check(separated, "Same-tick entries do not overlap one another")
	arena.queue_free()
	await frames(3)

	arena = create_arena(2)
	await frames(8)
	check(arena.drops.size() == 3 and arena.ledger.total_materials == 12 and arena.ledger.dropped_materials == 6, "Recovery starts with six protected and six ground materials")
	check(arena.extraction_points.size() == 1 and arena.extraction_points[0].name == &"Extraction2", "Recovery honors its restricted available exit")
	for drop in arena.drops.values().duplicate():
		arena.robot.position = drop.position
		await frames(3)
		check(arena.can_recover() and arena.try_recover(), "Initial mission cargo uses normal proximity recovery")
	check(arena.ledger.recovered_materials == 6 and arena.ledger.is_conserved() and not arena.mission.is_finished(), "Recovering initial stock preserves scheduled Raider objectives")
	# Preserve scenario through restart, replacing all previous runtime allocations.
	arena.restart_mission()
	await frames(8)
	arena = current_scene
	arena.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	check(arena.scenario_index == 2 and arena.ledger.recovered_materials == 0 and arena.ledger.dropped_materials == 6, "Restart retains selected scenario with fresh ledger and cargo")
	arena.elapsed = arena.mission_duration
	arena._physics_process(0.01)
	check(arena.mission.is_finished() and arena.ledger.dropped_materials == 6 and arena.ledger.lost_materials == 0 and arena.pending_ids.size() == 2, "Deadline preserves unrecovered ground and unresolved scheduled entries without inventing extraction")
	arena.process_entries() # Terminal schedule must not create actors.
	check(arena.raiders.is_empty(), "No scheduled actor can enter after mission completion")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F7
	key.pressed = true
	arena._unhandled_input(key)
	await frames(8)
	arena = current_scene
	check(arena.scenario_index == 1 and arena.ledger.total_materials == 15, "Debug scenario key switches to a fresh Swarm deployment")
	arena.queue_free()
	await frames(3)

	# Natural runs include real entry timing, path following, collection and extraction.
	Engine.time_scale = 3
	for scenario in range(3):
		arena = create_arena(scenario)
		arena.robot.position = Vector3(0, 0, 100)
		arena.set_physics_process(true)
		for index in range(2200):
			if arena.mission.is_finished() or (arena.pending_ids.is_empty() and arena.ledger.active_raiders == 0):
				break
			await frames(1)
		check(arena.pending_ids.is_empty() and arena.ledger.active_raiders == 0 and arena.ledger.is_conserved(), "%s resolves every scheduled Raider naturally with conserved materials" % arena.config.display_name)
		if scenario == 2:
			check(arena.mission.phase == MissionRules.Phase.RECOVERING and arena.ledger.dropped_materials == 6, "Recovery waits for ground cargo after all natural Raider resolutions")
		arena.queue_free()
		await frames(3)
	Engine.time_scale = 1
	print("Stage C checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
