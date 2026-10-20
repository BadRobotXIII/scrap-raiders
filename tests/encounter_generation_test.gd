extends SceneTree

var failures: int = 0
var directory: String


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func freeze(arena: Node3D) -> void:
	arena.set_physics_process(false)
	if arena.encounter != null:
		arena.encounter.set_physics_process(false)
	if arena.flare_director != null:
		arena.flare_director.set_physics_process(false)
	if arena.recall != null:
		arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			if actor.combat != null:
				actor.combat.weapon.set_physics_process(false)
	if arena.ecosystem != null:
		for machine in arena.ecosystem.machines:
			machine.set_physics_process(false)
			if machine.weapon != null:
				machine.weapon.set_physics_process(false)


func create(seed_value: int = 87017) -> Node3D:
	var arena := load("res://scenes/levels/emergent_encounters_arena.tscn").instantiate() as Node3D
	arena.seed_override = seed_value
	arena.stash_path = directory + "/%d.json" % seed_value
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)
	return arena


func run() -> void:
	directory = "res://.godot/stage_p_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var arena: Node3D = await create()
	check(not arena.mission.is_finished() and arena.raiders.size() == 2, "Valid seeded encounter starts two initial actors")
	check(arena.ledger.total_materials == 14 and arena.ledger.protected_materials == 14 and arena.encounter.navigation_checked, "Twelve salvage units and two installed components are allocated once on valid routes")
	var original: Dictionary = arena.encounter.snapshot.duplicate(true)
	var layouts := {arena.encounter.layout.layout_id: true}
	var layout_seeds := {str(arena.encounter.layout.layout_id): 87017}
	for point in arena.salvage_points:
		check(arena.encounter.ground_valid(point.position), "Authored salvage is supported and connected to extraction")
	var config: MissionConfig = arena.config
	var invalid := config.encounter_layouts[0].duplicate() as EncounterLayout
	invalid.salvage_quantities = PackedInt32Array([-1, 3, 3])
	check(not invalid.validation_error(config).is_empty(), "Malformed finite stock is rejected")
	invalid = config.encounter_layouts[0].duplicate()
	invalid.salvage_markers = PackedStringArray(["same", "same", "same"])
	check(not invalid.validation_error(config).is_empty(), "Duplicate objective identities are rejected")
	var invalid_config := config.duplicate() as MissionConfig
	invalid_config.max_active_raiders = 0
	check(not invalid_config.validation_error().is_empty(), "Invalid population limit is rejected")
	var reordered := config.duplicate() as MissionConfig
	reordered.encounter_layouts = config.encounter_layouts.duplicate()
	reordered.encounter_layouts.reverse()
	check(EncounterSetup.choose_layout(reordered, 87017).layout_id == arena.encounter.layout.layout_id, "Layout choice depends on stable text IDs rather than resource insertion order")
	var point: Node3D = arena.salvage_points[0]
	var saved_position := point.position
	point.position = Vector3(100, 0, 100)
	check(not arena.encounter.validate_navigation().is_empty(), "Off-map salvage is rejected instead of creating an unreachable objective")
	point.position = saved_position
	var patrol_point: Node3D = arena.get_node(NodePath(arena.machine_routes[1])).get_child(0)
	saved_position = patrol_point.position
	patrol_point.position = Vector3(-8, 1, 3)
	check(not arena.encounter.validate_navigation().is_empty(), "Ground patrol points inside collision geometry are rejected")
	patrol_point.position = saved_position
	check(arena.encounter.validate_navigation().is_empty(), "Restored authored surfaces and patrols remain valid")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.encounter.snapshot == original and arena.debug_seed == 87017, "Restart reproduces the exact resolved setup without mutating shared resources")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F5
	key.pressed = true
	key.shift_pressed = true
	key.ctrl_pressed = true
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 13 and arena.debug_seed == 87018 and arena.config.seed == 87017 and not arena.mission.is_finished(), "Ctrl+Shift+F5 advances runtime seed without editing shared mission definitions")
	arena.robot.position = arena.get_node("RecallDock").position + Vector3.UP * 0.1
	arena.robot.set_physics_process(true)
	await frames(10)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.recover_held = true
	arena.recall.step(0)
	arena.recall.step(5)
	check(arena.mission.player_extracted and arena.summary.visible and arena.pending_ids.size() == 3 and arena.ledger.protected_materials == 14, "Living player can recall successfully without waiting for every future encounter arrival")
	arena.select_scenario(0)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.encounter == null and arena.ledger.total_materials == 9 and arena.resolved_profiles.is_empty(), "Switching to an earlier preset discards encounter overrides and preserves original stock")
	key.shift_pressed = false
	key.ctrl_pressed = false
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 12 and arena.encounter == null and arena.ledger.total_materials == 11, "Plain F5 retains the accepted Integrated Extraction preset")
	arena.queue_free()
	await frames(30)
	for seed_value in range(87018, 87050):
		layout_seeds[str(EncounterSetup.choose_layout(config, seed_value).layout_id)] = seed_value
	var selected_seeds: Array = layout_seeds.values()
	selected_seeds.sort()
	for seed_value in selected_seeds:
		arena = await create(seed_value)
		check(not arena.mission.is_finished() and arena.encounter.navigation_checked and arena.config.seed == 87017, "Seed override resolves valid layout while authored seed remains unchanged")
		layouts[arena.encounter.layout.layout_id] = true
		arena.queue_free()
		await frames(15)
	check(layouts.size() == 2, "Seed corpus produces both authored opportunity arrangements")
	arena = await create()
	var first := arena.raiders[1] as Raider
	var second := arena.raiders[2] as Raider
	# Contention is independent from relationships and finite stock ownership.
	arena.robot.position = Vector3(100, 0.1, 100)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(20, 3.5, -18)
	var guard := arena.ecosystem.machines[1] as SupportMachine
	guard.position = Vector3(0, 0.1, 14)
	first.position = Vector3(0, 0.1, 8)
	second.position = Vector3(-20, 0.1, -20)
	await frames(3)
	first.decide()
	first.combat.profile = first.combat.profile.duplicate()
	first.combat.profile.spread_degrees = 0
	first.combat.tick(0.7)
	check(first.current_target() == guard and guard.health.current == 70, "Encounter actors independently select and damage nearby patrol machines")
	guard.position = Vector3(20, 3.5, -18)
	first.position = arena.get_node("Salvage").position + Vector3(0.1, 0.1, 0)
	second.position = first.position + Vector3(0.6, 0, 0)
	await frames(3)
	for actor in [first, second]:
		actor.salvage = arena.get_node("Salvage")
		actor.transition(Raider.State.SCAVENGING)
		actor.task_elapsed = actor.scavenge_seconds
		arena._on_collection_requested(actor)
	check(first.carried_materials + second.carried_materials == 6 and arena.ledger.available(&"Salvage") == 0 and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED and arena.ledger.is_conserved(), "Competing allies cannot duplicate or share the same finite six-unit source")
	# Entry must wait both for schedule time and physical clearance.
	check(not arena.raiders.has(3) and arena.pending_ids.size() == 3, "Later opportunities remain pending before their authored arrival")
	var marker: Node3D = arena.get_node("RaiderSpawns/" + arena.encounter.layout.entry_markers[2])
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 2)
	collision.shape = shape
	blocker.add_child(collision)
	blocker.position = marker.position + Vector3.UP
	arena.add_child(blocker)
	await frames(3)
	arena.elapsed = 35
	arena.process_entries()
	check(not arena.raiders.has(3), "Blocked authored entry waits without fallback teleport or collision overlap")
	blocker.queue_free()
	await frames(3)
	arena.process_entries()
	freeze(arena)
	check(arena.raiders.has(3) and arena.raiders[3].position.is_equal_approx(marker.position), "Unblocked entry retries at the same validated marker")
	arena.elapsed = 105
	arena.process_entries()
	freeze(arena)
	check(arena.raiders.size() == 5 and arena.flare_director.living_count() == 5 and not arena.population_has_room(), "Five initial actors saturate the shared live cap alongside two finite machines")
	# A controlled hostile opportunity proves the reused combat/loot path.
	var rival := arena.raiders[4] as Raider
	first.position = Vector3(0, 0.1, 8)
	rival.position = Vector3(0, 0.1, 14)
	for id in [2, 3, 5]:
		arena.raiders[id].position = Vector3(-20, 0.1, -20)
	await frames(3)
	arena.ledger.collect(4, &"Salvage2", 3)
	first.transition(Raider.State.SELECTING)
	first.decide()
	first.combat.profile = first.combat.profile.duplicate()
	first.combat.profile.spread_degrees = 0
	first.combat.weapon.cooldown = 0
	first.combat.tick(0.7)
	check(first.current_target() == rival and rival.health.current == 90, "Existing hostile Raider logic acquires and damages a rival within encounter conditions")
	for index in range(9):
		first.combat.weapon.cooldown = 0
		first.combat.weapon.try_fire_at(first.target_point(rival))
	check(arena.flare_director.committed == 1 and arena.ledger.dropped_materials == 3, "Ordinary rival death creates finite cargo and exactly one flare ticket")
	await frames(3)
	var drop := arena.drops.values()[0] as MaterialDrop
	# Greedy actor already carries six; use a different empty registered survivor.
	var looter := arena.raiders[3] as Raider
	looter.position = drop.position + Vector3(0.4, 0, 0)
	await frames(3)
	looter.social.sense()
	looter.salvage = drop
	looter.transition(Raider.State.SCAVENGING)
	looter.task_elapsed = looter.scavenge_seconds
	arena._on_collection_requested(looter)
	check(looter.carried_materials == 3 and arena.ledger.dropped_materials == 0 and arena.ledger.lost_materials == 0, "A survivor physically scavenges fallen rival cargo without creating an extraction loss")
	looter._choose_exit()
	looter.position = looter.extraction.position + Vector3.UP * 0.1
	looter.transition(Raider.State.EXTRACTING)
	looter.task_elapsed = 0
	looter.extraction_seconds = 0.1
	looter.threat_remaining = 0
	looter.set_physics_process(true)
	await frames(20)
	check(arena.ledger.lost_materials == 3 and arena.ledger.is_conserved(), "Looted finite cargo becomes Lost only through actual timed physical extraction")
	arena.elapsed = 113
	arena.flare_director.process_responses()
	freeze(arena)
	check(arena.raiders.has(6) and arena.flare_director.living_count() <= 5 and arena.ledger.total_materials == 14, "Flare admits a bounded responder through shared capacity without material stock creation")
	var response := arena.raiders[6] as Raider
	response.health.apply_damage(1000)
	check(arena.flare_director.committed == 2, "Responder death consumes at most the final finite ticket")
	arena.elapsed = 121
	arena.flare_director.process_responses()
	freeze(arena)
	arena.raiders[7].health.apply_damage(1000)
	check(arena.flare_director.committed == 2 and arena.flare_director.tickets.is_empty() and arena.flare_director.equipment.is_valid(), "Finite response chain cannot replenish budget or duplicate equipment")
	for index in range(100):
		arena.encounter.record("bounded diagnostic")
	check(arena.encounter.events.size() == 64, "Diagnostics retain a bounded event history")
	arena.queue_free()
	await frames(30)
	# Full-cap initial arrivals and responses contend for the same capacity.
	arena = await create()
	arena.max_active_raiders = 2
	var before_observation := FileAccess.get_file_as_string(arena.stash_path) if FileAccess.file_exists(arena.stash_path) else ""
	arena.elapsed = 35
	arena.process_entries()
	check(not arena.raiders.has(3), "Initial admission respects configured cap even before any flare")
	arena.raiders[1].health.apply_damage(1000)
	arena.process_entries()
	freeze(arena)
	arena.elapsed = 43
	arena.flare_director.process_responses()
	check(arena.raiders.has(3) and not arena.raiders.has(6) and arena.flare_director.tickets.size() == 1, "Initial and response work cannot each claim the same final population slot")
	arena.raiders[3].health.apply_damage(1000)
	arena.flare_director.process_responses()
	freeze(arena)
	check(arena.raiders.has(6) and arena.flare_director.living_count() == 2, "Pending response retries when actual live capacity becomes available")
	arena.robot.get_node("Health").apply_damage(1000)
	check(arena.post_death.enter() and arena.mission.is_finished() and not arena.mission.is_world_finished(), "Pending encounter schedule survives permanent player-deployment failure")
	arena.post_death.set_physics_process(false)
	arena.max_active_raiders = 5
	arena.raiders[6].position = Vector3(0, 0.1, 14)
	await frames(3)
	arena.spectator_view.camera.position = Vector3(1000, 1000, 1000)
	arena.elapsed = 105
	arena.process_entries()
	freeze(arena)
	check(arena.raiders.has(4) and arena.raiders.has(5) and not arena.post_death.indicator.text.contains("ENCOUNTERS"), "Late entries continue while spectating without using camera position or exposing diagnostics")
	arena.elapsed = arena.mission_duration
	arena._physics_process(0.01)
	var after_observation := FileAccess.get_file_as_string(arena.stash_path) if FileAccess.file_exists(arena.stash_path) else ""
	check(arena.world_shutdown and arena.ledger.is_conserved() and before_observation == after_observation, "Deadline seals bounded encounter work without changing previously banked stash")
	arena.queue_free()
	await frames(30)
	# Reproducible setups still allow independent natural outcomes.
	var previous_scale := Engine.time_scale
	for seed_value in selected_seeds:
		arena = await create(seed_value)
		for actor in arena.raiders.values():
			actor.set_physics_process(true)
			actor.combat.weapon.set_physics_process(true)
		for machine in arena.ecosystem.machines:
			machine.set_physics_process(true)
			if machine.weapon != null:
				machine.weapon.set_physics_process(true)
		arena.set_physics_process(true)
		arena.flare_director.set_physics_process(true)
		arena.encounter.set_physics_process(true)
		arena.spectator.enter()
		Engine.time_scale = 8
		var started := Time.get_ticks_msec()
		await frames(1100)
		Engine.time_scale = previous_scale
		check(arena.entry_log.size() == 5 and arena.encounter.observed_sites.size() >= 2 and arena.elapsed >= 105, "Natural scheduled actors operate across multiple independent areas and arrival times")
		check(arena.encounter.peak_autonomous_actors <= 7 and arena.flare_director.committed <= 2 and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Natural simulation preserves live limits, finite response and both ledgers")
		print("PERF seed ", seed_value, " elapsed ", arena.elapsed, " wall ms ", Time.get_ticks_msec() - started, " peak actors ", arena.encounter.peak_autonomous_actors)
		arena.queue_free()
		await frames(30)
	print("Stage P encounter generation checks complete; failures: ", failures)
	quit(1 if failures else 0)
