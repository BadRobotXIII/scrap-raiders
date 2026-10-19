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


func run() -> void:
	var board := MachineAwareness.new()
	board.observe(&"scout", 1, Vector3(1, 2, 3), 0)
	var snapshot := board.observations(1)
	snapshot[0].position = Vector3.ZERO
	board.observe(&"guard", 2, Vector3.ONE, 1)
	check(board.observations(1)[0].position == Vector3(1, 2, 3), "Reports return detached snapshots")
	check(board.observations(3).size() == 1 and board.observations(3)[0].target_id == 2, "Reports expire independently at their deadline")
	board.forget_source(&"guard")
	check(board.observations(3).is_empty(), "Destroyed sources can revoke their reports")
	var arena := load("res://scenes/levels/ecosystem_arena.tscn").instantiate() as Node3D
	var directory := "res://.godot/stage_h_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	arena.stash_path = directory + "/stash.json"
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(8)
	arena.elapsed = 8
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.combat.weapon.set_physics_process(false)
	var scout := arena.ecosystem.machines[0] as SupportMachine
	var guard := arena.ecosystem.machines[1] as SupportMachine
	check(scout.flying and scout.health.current == 50 and guard.health.current == 80 and guard.weapon != null, "Scout and guard have independent roles and health")
	check(arena.ledger.total_materials == 11 and arena.ledger.protected_materials == 11 and arena.ledger.dropped_materials == 0, "Nine salvage and two installed components are allocated upfront")
	var actor := arena.raiders[1] as Raider
	for other in arena.raiders.values():
		other.position = Vector3(18, 0.1, -18)
	arena.robot.position = Vector3(100, 0.1, 100)
	scout.position = Vector3(18, 3.5, -18)
	guard.position = Vector3(0, 0.1, 14)
	actor.position = Vector3(0, 0.1, 8)
	await frames(3)
	actor.decide()
	check(actor.current_target() == guard and actor.state == Raider.State.ENGAGING, "Raider hunts a visible machine while player is absent")
	actor.combat.profile = actor.combat.profile.duplicate()
	actor.combat.profile.spread_degrees = 0
	actor.combat.tick(actor.combat.profile.warning_time + 0.01)
	check(guard.health.current == 70 and arena.robot.get_node("Health").current == arena.robot.get_node("Health").maximum, "Shared Raider weapon damages selected guard instead of player")
	guard.scan()
	check(guard.state == SupportMachine.State.ENGAGING, "Guard independently engages a visible Raider")
	var previous := actor.health.current
	guard.scan_remaining = 10
	guard._physics_process(0.5)
	check(actor.health.current == previous - 5, "Guard fires a limited defensive shot through shared damage execution")
	guard._physics_process(0.5)
	check(actor.health.current == previous - 5, "Guard weapon cadence prevents repeated immediate damage")
	actor.position = Vector3(18, 0.1, -18)
	await frames(3)
	arena.ecosystem.awareness = MachineAwareness.new()
	guard.awareness = arena.ecosystem.awareness
	scout.awareness = arena.ecosystem.awareness
	guard.awareness.observe(scout.source_id, 1, Vector3(2, 0.1, 10), arena.elapsed)
	guard.scan()
	check(guard.state == SupportMachine.State.INVESTIGATING and guard.observed_position == Vector3(2, 0.1, 10), "Guard investigates an allied last-known snapshot without direct sight")
	arena.refresh_hud()
	check(arena.get_node("Overlay/RaiderStatus").text.begins_with("Machine report:"), "Player receives contextual threat report")
	arena.elapsed += 3.1
	guard.scan()
	arena.refresh_hud()
	check(guard.state == SupportMachine.State.PATROLLING and not arena.get_node("Overlay/RaiderStatus").text.begins_with("Machine report:"), "Expired reports release investigation and player warning")
	actor.position = Vector3(0, 0.1, 8)
	arena.robot.position = Vector3(0, 0.1, 10)
	await frames(3)
	actor.decide()
	check(actor.current_target() == arena.robot and actor.combat.aim_elapsed == 0, "Closer player can replace machine target and resets aim warning")
	var flare_count: int = arena.flare_director.handled_deaths.size()
	guard.health.apply_damage(1000)
	guard.health.apply_damage(1000)
	check(arena.ecosystem.component_drop_ids.size() == 1 and arena.ledger.dropped_materials == 1 and arena.ledger.is_conserved(), "Machine death exposes preallocated components exactly once")
	check(arena.flare_director.handled_deaths.size() == flare_count and arena.ecosystem.machines.size() == 1, "Machine destruction removes actor without a human death flare")
	await frames(3)
	var drop := arena.ecosystem.component_drops()[0] as MaterialDrop
	arena.robot.position = Vector3(100, 0.1, 100)
	actor.position = drop.position
	await frames(3)
	check(arena.choose_salvage(1) == drop, "Normal objective scoring can select nearby machine components")
	actor.salvage = drop
	actor.transition(Raider.State.SCAVENGING)
	actor.task_elapsed = actor.scavenge_seconds
	arena._on_collection_requested(actor)
	check(arena.ledger.cargo_for(1) == 1 and arena.ledger.dropped_materials == 0 and arena.ledger.is_conserved(), "Validated Raider collection transfers component ground stock into cargo")
	arena._on_collection_requested(actor)
	check(arena.ledger.cargo_for(1) == 1, "Duplicate collection cannot duplicate components")
	await frames(3)
	actor.combat_target = scout
	scout.health.apply_damage(1000)
	await frames(3)
	actor.decide()
	check(actor.current_target() == arena.robot, "Destroyed machine target safely falls back after node cleanup")
	actor.health.apply_damage(1000)
	await frames(3)
	check(arena.ledger.dropped_materials == 2 and arena.ledger.is_conserved(), "Carried components drop again on Raider death with conserved totals")
	for other in arena.raiders.values():
		if is_instance_valid(other):
			other.position = Vector3(-18, 0.1, -18)
	await frames(3)
	for id in arena.drops.keys():
		var cargo = arena.drops[id]
		arena.robot.position = cargo.position
		await frames(3)
		check(arena.try_recover(), "Player can recover machine components using normal pickup")
	check(arena.ledger.recovered_materials == 2 and arena.ledger.total_materials == 11 and arena.ledger.is_conserved(), "Recovery retains exact original component and salvage totals")
	arena.restart_mission()
	await frames(10)
	arena = current_scene
	freeze(arena)
	check(arena.ecosystem.machines.size() == 2 and arena.ecosystem.awareness.observations(0).is_empty() and arena.ledger.protected_materials == 11 and arena.ledger.dropped_materials == 0, "Restart rebuilds independent machines, reports and component allocations")
	var initial: Vector3 = arena.ecosystem.machines[0].position
	var guard_initial: Vector3 = arena.ecosystem.machines[1].position
	arena.robot.position = Vector3(100, 0.1, 100)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(true)
	await frames(120)
	check(arena.ecosystem.machines[0].position.distance_to(initial) > 1, "Flying scout follows its authored route under natural physics")
	check(arena.ecosystem.machines[1].position.distance_to(guard_initial) > 1, "Ground guard independently follows navigable patrol route")
	scout = arena.ecosystem.machines[0]
	guard = arena.ecosystem.machines[1]
	scout.set_physics_process(false)
	scout.position = Vector3(0, 3.5, 14)
	guard.position = Vector3(0, 0.1, 14)
	actor = arena.raiders[1]
	actor.position = Vector3(0, 0.1, 8)
	actor.combat.profile = actor.combat.profile.duplicate()
	actor.combat.profile.spread_degrees = 0
	actor.combat_target = null
	actor.transition(Raider.State.SELECTING)
	guard.weapon.enabled = false
	actor.set_physics_process(true)
	actor.combat.weapon.set_physics_process(true)
	await frames(65)
	check(guard.health.current < 80, "Natural Raider physics acquires and damages an autonomous support machine")
	scout.scan()
	check(not arena.ecosystem.awareness.observations(arena.elapsed).is_empty(), "Flying scout publishes real visible Raider observations")
	guard.weapon.enabled = true
	guard.weapon.set_physics_process(true)
	await frames(80)
	check(actor.health.current < actor.health.maximum and arena.ledger.is_conserved(), "Natural guard physics defends against Raider without modifying material totals")
	arena.mission.fail_setup("test terminal")
	arena.finish_mission()
	check(not arena.ecosystem.machines[0].active and not arena.ecosystem.machines[1].weapon.enabled, "Terminal mission stops both support actors and defensive fire")
	check(not FileAccess.file_exists(arena.stash_path), "Ecosystem tests never bank rewards into any stash")
	arena.queue_free()
	await frames(3)
	print("Machine ecosystem tests: ", failures, " failures")
	quit(1 if failures else 0)
