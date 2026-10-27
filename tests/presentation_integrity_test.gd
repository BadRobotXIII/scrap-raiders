extends "res://tests/gameplay_integration_test.gd"
## Actual autonomous deployment replay plus simulation-free inspection controls.

func deployment(enabled: bool, seed_value: int, expanded: bool = false) -> Dictionary:
	seed(90210)
	var arena := load("res://scenes/levels/expanded_salvage_complex.tscn" if expanded else "res://scenes/levels/asset_recovery_arena.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/%d_%s_%s.json" % [seed_value, enabled, expanded]
	arena.seed_override = seed_value
	arena.enhanced_presentation = enabled
	arena.capture_metrics = true
	root.add_child(arena)
	current_scene = arena
	await start_frozen(arena)
	# Keep the player stationary and out of this autonomous comparison. Only
	# the test fixture does this; presentation has no actor-position API.
	arena.robot.position = Vector3(100, 0.1, 100)
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	for actor in arena.raiders.values():
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(true)
		if machine.weapon != null: machine.weapon.set_physics_process(true)
	var timeline: Array = []
	var conserved := true
	for tick in range(2400):
		await frames(1)
		conserved = conserved and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid()
		if tick % 30 == 0:
			var sample: Array = []
			for id in arena.raiders:
				var actor = arena.raiders[id]
				if is_instance_valid(actor): sample.append([id, actor.state, actor.position.snapped(Vector3.ONE * 0.001), actor.health.current, actor.carried_materials])
			timeline.append(sample)
	var data := {"timeline": timeline, "counters": arena.metrics.counters.duplicate(true), "events": arena.metrics.events.duplicate(true), "transfers": arena.ledger.accepted_transfers}
	var output := FileAccess.open(test_directory + "/replay_%d_%s_%s.json" % [seed_value, enabled, expanded], FileAccess.WRITE)
	output.store_string(JSON.stringify(DeploymentMetrics.serializable(data), "\t"))
	output.close()
	check(conserved, "On/off autonomous replay preserves both conservation invariants on every physics tick")
	check(float(data.counters.get("shots", 0)) > 0, "Replay exercises real autonomous firing rather than an idle presentation fixture")
	arena.queue_free()
	await frames(30)
	return data

func inspection() -> void:
	var scene := load("res://scenes/characters/actor_inspection.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await frames(2)
	check(scene.find_children("*", "Health", true, false).is_empty() and scene.find_children("*", "ShotExecutor", true, false).is_empty() and scene.find_children("*", "Raider", true, false).is_empty(), "Inspection creates no gameplay Health, weapons or Raider controllers")
	scene.select_view(3)
	scene.demonstrate("Fire")
	scene.demonstrate("Damage")
	scene.demonstrate("Armor")
	check(scene.presentation.shots_presented == 1 and scene.presentation.impacts_presented == 1, "Inspection uses production presenters for discharge, damage and impact")
	scene.demonstrate("Destroy")
	check(scene.presentation.deaths_presented == 1 and is_instance_valid(scene.terminal), "Inspection previews the accepted terminal visual and world destruction")
	scene.demonstrate("Reset")
	await frames(2)
	check(not is_instance_valid(scene.terminal) and scene.presentation.snapshot().bursts == 0 and scene.presentation.snapshot().voices == 0, "Reset removes the preview terminal, effects and audition audio")
	scene.select_view(5)
	scene.demonstrate("Fire")
	check(scene.presentation.shots_presented == 1, "Flying scout preview remains unarmed")
	scene.queue_free()
	await frames(30)
	check(get_nodes_in_group("mission_presentations").is_empty(), "Inspection exits without a stale listener or presentation owner")

func run() -> void:
	test_directory = "res://.godot/stage_x_tests/integrity_" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	for seed_value in [87017, 87018]:
		var baseline := await deployment(false, seed_value)
		var effects := await deployment(true, seed_value)
		check(baseline == effects, "Seed %d: effects on/off retain the same physical trajectory, state/event sequence, shots and transfers" % seed_value)
	var expanded_baseline := await deployment(false, 87018, true)
	var expanded_effects := await deployment(true, 87018, true)
	check(expanded_baseline == expanded_effects, "Expanded seed 87018: atmosphere and combat presentation retain identical autonomous replay")
	await inspection()
	OS.delay_msec(200) # Test-only wall-time mixer release in accelerated runs.
	await process_frame
	print("Presentation integrity failures: ", failures)
	quit(1 if failures else 0)
