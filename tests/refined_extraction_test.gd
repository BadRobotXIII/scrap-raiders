extends "res://tests/integrated_extraction_test.gd"
## Exercises the R composition, optional observer and authoritative transfers.


func create_refined(enabled: bool) -> Node3D:
	var arena := load("res://scenes/levels/refined_extraction_arena.tscn").instantiate() as Node3D
	arena.capture_metrics = enabled
	arena.stash_path = test_directory + "/stash_%s.json" % enabled
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)
	return arena


func run() -> void:
	test_directory = "res://.godot/stage_r_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var off := await create_refined(false)
	check(off.metrics == null, "Capture is disabled in ordinary play")
	var off_id: int = off.ledger.release_source(&"Salvage")
	var off_amount: int = off.ledger.recover(off_id)
	var off_settled: bool = off.ledger.settle_player(false)
	var off_forfeited: int = off.ledger.forfeited_materials
	off.queue_free()
	await frames(3)
	var on := await create_refined(true)
	check(on.metrics != null, "Explicit capture creates a mission-local observer")
	check(on.scenario_index == 15 and on.ledger.total_materials == 14 and on.config.validation_error().is_empty(), "R reuses the finite integrated composition")
	var q: MissionConfig = load("res://resources/missions/personality_encounters.tres")
	check(q.entry_times == PackedFloat32Array([0, 0, 35, 70, 105]), "Q reference timing is unchanged")
	check(on.config.encounter_layouts == q.encounter_layouts and on.config.fallback_profiles == q.fallback_profiles and on.config.raider_count == q.raider_count, "R shares Q layouts and profiles without modifying reference resources")
	var metrics: DeploymentMetrics = on.metrics
	check(metrics.actors.size() == 2 and metrics.counters.equipment_assign_loadout_items == 4, "Observer starts before admissions and finite loadout allocation")
	metrics.register_actor(on.raiders[1])
	check(metrics.counters.admissions == 2, "Duplicate actor callback cannot double-count admission")
	var before := metrics.snapshot()
	before.setup["seed"] = -1
	before.actors.clear()
	check(metrics.snapshot().setup.seed == on.debug_seed and metrics.actors.size() == 2, "Export snapshots are detached")
	for arena in [on]:
		var id: int = arena.ledger.release_source(&"Salvage")
		check(arena.ledger.recover(id) == 6 and arena.ledger.recover(id) == 0, "Accepted recovery transfers once; duplicate rejected")
		check(arena.ledger.settle_player(false) and not arena.ledger.settle_player(false), "Deployment forfeiture settles exactly once")
		check(arena.ledger.is_conserved() and arena.ledger.forfeited_materials == 6, "Capture does not alter authoritative totals")
	check(off_amount == 6 and off_settled and on.ledger.forfeited_materials == off_forfeited, "Capture on/off produces identical accepted accounting")
	check(metrics.counters.material_recover_events == 1 and metrics.counters.material_recover_units == 6 and metrics.counters.material_settle_player_events == 1, "Metrics count accepted deltas, never cumulative cargo or rejected callbacks")
	metrics.on_material(&"recover", {"serial": metrics.material_serial, "amount": 6})
	check(metrics.counters.material_recover_events == 1, "Repeated accepted-event callback serial is ignored")
	var actor: Raider = on.raiders[1]
	actor.recover_navigation(actor.global_position + Vector3.RIGHT * 5)
	check(metrics.counters.navigation_recoveries == 1, "Navigation recovery is observed at the actual decision path")
	actor.transition(Raider.State.ENGAGING)
	on.elapsed += 1.5
	metrics.sample()
	for index in range(300):
		metrics.record("fixture", {"nested": {"value": index}})
	metrics.finish("Bounded test stop")
	metrics.finish("Duplicate stop")
	check(metrics.events.size() == 256 and metrics.discarded_events > 0, "Detailed history is bounded and truncation explicit")
	check(metrics.censored_count == 1 and metrics.open_episodes.is_empty() and metrics.episode_seconds == 1.5, "Unfinished combat duration is censored exactly once")
	check(metrics.export_json(test_directory + "/metrics.json") == OK, "Explicit local snapshot exports successfully")
	var readback: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_directory + "/metrics.json"))
	check(readback is Dictionary and readback.materials.valid and readback.materials.forfeited == 6, "Export reports authoritative final accounting")
	on.queue_free()
	await frames(30)
	await recovery_and_recall()
	await lifecycle()
	await terminal_machine_death()
	print("Stage R refined extraction failures: ", failures)
	quit(0 if failures == 0 else 1)


func recovery_and_recall() -> void:
	var arena := await create_refined(true)
	var victim: Raider = arena.raiders[1]
	victim.position = Vector3(0, 0.1, 8)
	arena.robot.position = victim.position
	arena.ledger.collect(1, &"Salvage", 3)
	victim.health.apply_damage(1000)
	await frames(3)
	check(arena.try_recover() and arena.ledger.recovered_materials == 3, "R recovers physical cargo through the existing range/collision interaction")
	check(arena.flare_director.equipment.recover(1), "R finite equipment recovery remains compatible")
	await dock_robot(arena)
	arena.recall.step(0.1)
	for index in range(60):
		if arena.mission.is_finished():
			break
		if index % 10 == 0:
			arena.robot.get_node("Health").apply_damage(1)
		arena.recall.step(0.1)
	check(arena.mission.player_extracted and arena.ledger.banked_materials == 3 and arena.flare_director.equipment.count_at(EquipmentLedger.Location.BANKED) == 2, "Timed R recall banks material/equipment once despite nonlethal damage")
	await frames(1)
	check(arena.metrics.stopped and arena.metrics.counters.material_settle_player_events == 1 and arena.ledger.is_conserved(), "Successful R deployment finalizes observation after authoritative settlement")
	arena.queue_free()
	await frames(30)


func lifecycle() -> void:
	var arena := await create_refined(true)
	var source: int = arena.ledger.release_source(&"Salvage")
	arena.ledger.recover(source)
	arena.flare_director.equipment.resolve(2)
	arena.flare_director.equipment.recover(2)
	var killer: Raider = arena.raiders[1]
	var robot_position: Vector3 = arena.robot.position
	arena.robot.get_node("Health").apply_damage(1000, killer.position, killer.get_instance_id())
	check(arena.ledger.forfeited_materials == 6 and arena.flare_director.equipment.count_at(EquipmentLedger.Location.FORFEITED) == 2, "R death forfeits material and equipment deployment cargo")
	var transfers: int = arena.ledger.accepted_transfers
	arena.finish_mission()
	arena._on_player_destroyed()
	check(arena.ledger.accepted_transfers == transfers and not arena.metrics.stopped and not arena.mission.is_world_finished(), "Death settles once while world and observer continue")
	check(arena.post_death.enter() and arena.post_death.selected == killer, "R restricted follow prefers the lethal Raider")
	arena.post_death.cycle(1)
	check(arena.robot.position == robot_position and arena.ledger.accepted_transfers == transfers and not arena.spectator.enter(), "Post-death observing cannot move robot, transfer loot or enter developer flight")
	arena.elapsed = 35
	arena.process_entries()
	check(arena.raiders.has(3), "Scheduled arrivals continue after deployment death")
	var machine: SupportMachine = arena.ecosystem.machines[0]
	var before: Vector3 = machine.position
	machine.set_physics_process(true)
	await frames(40)
	check(machine.position.distance_to(before) > 0.1, "Autonomous machine physically patrols after player death")
	arena.post_death.return_to_summary()
	await frames(1)
	check(arena.metrics.stopped and arena.mission.is_world_finished() and arena.ledger.is_conserved(), "Return ends observation, finalizes capture and preserves accounting")
	var seed_value: int = arena.debug_seed
	arena.restart_mission()
	await frames(12)
	var restarted := current_scene
	check(restarted != arena and restarted.scenario_index == 15 and restarted.debug_seed == seed_value and restarted.metrics != null and not restarted.metrics.stopped and restarted.ledger.forfeited_materials == 0, "Restart preserves R seed/capture selection with fresh mission state")
	restarted.queue_free()
	await frames(30)


func terminal_machine_death() -> void:
	var arena := await create_refined(true)
	arena.elapsed = 106
	arena.process_entries()
	freeze(arena)
	for actor in arena.raiders.values():
		actor.transition(Raider.State.EXTRACTED)
		actor.extracted.emit(actor.carried_materials)
		actor.queue_free()
	arena.robot.get_node("Health").apply_damage(1000)
	for machine in arena.ecosystem.machines.duplicate():
		machine.health.apply_damage(1000)
	await frames(2)
	check(arena.mission.is_world_finished() and arena.metrics.stopped and arena.metrics.counters.machine_deaths == 2, "Final machine death is captured even when its coordinator callback ends the world")
	arena.queue_free()
	await frames(30)
