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


func create_arena(count: int = 3) -> Node3D:
	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	arena.raider_count = count
	root.add_child(arena)
	current_scene = arena
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
	return arena


func run() -> void:
	var arena := create_arena()
	await frames(6)
	var greedy := arena.raiders[1] as Raider
	var coward := arena.raiders[2] as Raider
	var aggressive := arena.raiders[3] as Raider
	check(greedy.profile.display_name == "Greedy" and coward.profile.display_name == "Cowardly" and aggressive.profile.display_name == "Aggressive", "Three resource profiles share one Raider implementation")
	check(arena.extraction_points.size() == 2, "Two authored extraction choices are available")
	arena.robot.position = Vector3.ZERO
	greedy.position = Vector3(0, 0.1, -6)
	coward.position = Vector3(3, 0.1, -6)
	aggressive.position = Vector3(-3, 0.1, -6)
	for actor in [greedy, coward, aggressive]:
		actor.transition(Raider.State.SCAVENGING)
	await frames(3)
	greedy.decide()
	coward.decide()
	aggressive.decide()
	check(greedy.state == Raider.State.SCAVENGING, "Greedy continues looting under a non-close visible threat")
	check(coward.state == Raider.State.FLEEING, "Cowardly retreats from the same medium-distance threat")
	check(aggressive.state == Raider.State.INVESTIGATING, "Aggressive investigates rather than immediately retreating")
	aggressive.health.apply_damage(25)
	check(aggressive.state == Raider.State.FLEEING and aggressive.task_elapsed == 0, "Damage interrupts investigation and resets task progress")
	greedy.position = Vector3(0, 0.1, -2)
	await frames(3)
	greedy.decide()
	check(greedy.state == Raider.State.FLEEING, "Even Greedy retreats from a close visible threat")
	coward.position = Vector3(11, 0.1, -3)
	arena.robot.position = Vector3(0, 0, 14)
	coward.threat_remaining = 0
	await frames(3)
	coward.decide()
	check(coward.state == Raider.State.SCAVENGING, "Empty fleeing Raider resumes scavenging when threat memory expires")
	check(arena.ledger.is_conserved() and arena.ledger.protected_materials == 9, "Threat transitions do not change material quantities")
	aggressive.transition(Raider.State.INVESTIGATING)
	aggressive.investigation_position = aggressive.global_position
	aggressive.task_elapsed = 1.99
	aggressive._physics_process(0.02)
	aggressive.decide()
	check(aggressive.state == Raider.State.SCAVENGING and arena.ledger.protected_materials == 9, "Completed investigation returns to objectives without collecting phantom cargo")
	var first_choice: Node3D = arena.choose_salvage(1)
	var second_choice: Node3D = arena.choose_salvage(1)
	check(first_choice == second_choice and arena.selection_jitter(1, 0) == arena.selection_jitter(1, 0), "Identical seed and state reproduce objective scoring")
	var jitter: float = arena.selection_jitter(1, 0)
	arena.debug_seed += 1
	check(jitter != arena.selection_jitter(1, 0), "Debug seed controls local tie-break variation")
	arena.debug_seed -= 1
	var invalid := Marker3D.new()
	arena.add_child(invalid)
	invalid.position = Vector3(100, 0, 100)
	check(is_inf(arena.route_cost(greedy, invalid)), "Unreachable off-map objectives are rejected")
	arena.extraction_points.append(invalid)
	greedy.blocked_exits[&"Extraction"] = true
	check(arena.choose_extraction(1) == arena.get_node("Extraction2"), "Blocked primary exit selects reachable alternate, excluding off-map candidate")
	greedy.blocked_exits.clear()
	# A known threat on a route increases cost according to profile risk preference.
	greedy.position = Vector3(0, 0, 0)
	coward.position = greedy.position
	greedy.threat_visible = false
	greedy.threat_remaining = 0
	coward.threat_visible = false
	coward.threat_remaining = 0
	var base_cost: float = arena.route_cost(coward, arena.get_node("Extraction"))
	coward.threat_visible = true
	coward.last_threat_position = Vector3(5, 0, -5)
	var safer_cost: float = arena.route_cost(coward, arena.get_node("Extraction"))
	greedy.threat_visible = true
	greedy.last_threat_position = coward.last_threat_position
	check(safer_cost > base_cost and safer_cost > arena.route_cost(greedy, arena.get_node("Extraction")), "Cowardly weights known path danger more strongly than Greedy")
	coward.last_threat_position = Vector3(9, 0, -10)
	check(arena.choose_extraction(2) == arena.get_node("Extraction2"), "Known danger on primary route makes Cowardly choose the safer alternate exit")
	coward.last_threat_position = Vector3(-10, 0, 10)
	check(arena.choose_extraction(2) == arena.get_node("Extraction"), "Extraction scoring responds to danger on the alternate route")
	arena.queue_free()
	await frames(3)

	# Real collection requests accumulate cargo from two finite locations.
	arena = create_arena()
	await frames(6)
	arena.robot.position = Vector3(14, 0, 14)
	greedy = arena.raiders[1]
	greedy.salvage = arena.get_node("Salvage")
	greedy.position = greedy.salvage.position
	greedy.scavenge_seconds = 0.1
	greedy.transition(Raider.State.SCAVENGING)
	greedy.set_physics_process(true)
	await frames(20)
	greedy.set_physics_process(false)
	check(greedy.carried_materials == 3 and greedy.state == Raider.State.SCAVENGING and greedy.salvage != arena.get_node("Salvage"), "Greedy seeks a second finite salvage point below its six-unit cargo target")
	greedy.position = greedy.salvage.position
	greedy.task_elapsed = 0
	greedy.set_physics_process(true)
	await frames(20)
	greedy.set_physics_process(false)
	check(greedy.carried_materials == 6 and greedy.state == Raider.State.EXTRACTING and arena.ledger.is_conserved(), "Second accepted transfer reaches cargo target without creating materials")
	var chosen := greedy.extraction
	greedy.recover_navigation(chosen.global_position)
	check(greedy.navigation_status == "REPATH REQUESTED", "First navigation stall requests a retry")
	greedy.recover_navigation(chosen.global_position)
	check(greedy.extraction != chosen and greedy.extraction != null and greedy.carried_materials == 6, "Repeated exit stall chooses an alternate without losing cargo")
	greedy.blocked_exits[&"Extraction"] = true
	greedy.blocked_exits[&"Extraction2"] = true
	greedy.recover_navigation(greedy.extraction.global_position)
	greedy.recover_navigation(greedy.extraction.global_position)
	check(greedy.state == Raider.State.STRANDED and arena.ledger.is_active(1) and greedy.carried_materials == 6, "No reachable exit enters explicit stranded state without teleport or invented extraction")
	greedy._retry_remaining = 0
	greedy.decide()
	check(greedy.state == Raider.State.EXTRACTING and greedy.extraction != null, "Stranded retry can recover when an exit becomes available")
	arena.queue_free()
	await frames(3)

	# Exercise the watchdog through actual physics with movement deliberately blocked.
	arena = create_arena()
	await frames(6)
	arena.robot.position = Vector3(14, 0, 14)
	greedy = arena.raiders[1]
	greedy.salvage = arena.get_node("Salvage")
	greedy.transition(Raider.State.SCAVENGING)
	greedy.walk_speed = 0
	greedy.flee_speed = 0
	greedy.navigation_stall_seconds = 0.1
	var start := greedy.position
	greedy.set_physics_process(true)
	await frames(25)
	check(greedy.blocked_salvage.has(&"Salvage") and greedy.position.distance_to(start) < 0.2 and arena.ledger.is_conserved(), "Watchdog detects no physical progress and abandons a blocked objective without teleporting")
	arena.queue_free()
	await frames(3)

	# Natural no-threat scenarios verify profiles can still resolve with finite stock.
	Engine.time_scale = 3
	for count in [3, 5]:
		arena = create_arena(count)
		arena.robot.position = Vector3(0, 0, 100)
		for actor in arena.raiders.values():
			actor.set_physics_process(true)
		for index in range(1200):
			if arena.mission.is_finished():
				break
			await frames(1)
		check(arena.mission.is_finished() and arena.ledger.active_raiders == 0 and arena.ledger.is_conserved(), "%d profiled Raiders resolve naturally with valid accounting" % count)
		if arena.ledger.active_raiders > 0:
			for actor in arena.raiders.values():
				if is_instance_valid(actor):
					print("Remaining R", actor.raider_id, " ", actor.state, " ", actor.position, " ", actor.navigation_status)
		arena.queue_free()
		await frames(3)
	Engine.time_scale = 1
	print("Stage B checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
