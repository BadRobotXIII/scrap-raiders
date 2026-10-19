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


func run() -> void:
	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
	await frames(8)
	var greedy := arena.raiders[1] as Raider
	var coward := arena.raiders[2] as Raider
	var aggressive := arena.raiders[3] as Raider
	arena.robot.position = Vector3.ZERO
	greedy.position = Vector3(-2, 0.1, -8)
	coward.position = Vector3(3, 0.1, -14)
	aggressive.position = Vector3(-3, 0.1, -14)
	for actor in [greedy, coward, aggressive]:
		actor.transition(Raider.State.SCAVENGING)
	await frames(3)
	var weapon := arena.robot.get_node("Weapon") as HitscanWeapon
	weapon.camera.look_at(weapon.camera.global_position + Vector3.UP, Vector3.FORWARD)
	var shots := [0]
	weapon.fired.connect(func(_origin: Vector3, _endpoint: Vector3, _damaged: bool) -> void: shots[0] += 1)
	check(not aggressive.detects_robot() and not coward.detects_robot(), "Sound scenario starts outside visual perception")
	check(weapon.try_fire(), "A real missed shot emits the existing weapon event")
	check(aggressive.state == Raider.State.INVESTIGATING and aggressive.threat_source == "gunfire", "Aggressive investigates an audible shot without seeing the robot")
	check(coward.state == Raider.State.FLEEING and greedy.state == Raider.State.SCAVENGING, "Cowardly flees while Greedy tolerates a distant audible shot")
	check(not aggressive.threat_visible and aggressive.threat_remaining > 0, "Hearing records memory without granting visual detection")
	coward.transition(Raider.State.EXTRACTING)
	coward.task_elapsed = 1.0
	coward.hear_gunfire(weapon.muzzle.global_position)
	check(coward.state == Raider.State.EXTRACTING and coward.task_elapsed == 1.0, "Repeated gunfire does not loop retreat and reset extraction progress")
	coward.transition(Raider.State.FLEEING)
	var known := aggressive.last_threat_position
	var goal := aggressive.investigation_position
	var memory := aggressive.threat_remaining
	check(not weapon.try_fire() and shots[0] == 1 and aggressive.threat_remaining == memory, "Cooldown-rejected trigger emits no extra awareness event")
	arena.robot.position = Vector3(14, 0, 14)
	await frames(3)
	aggressive.decide()
	check(aggressive.last_threat_position == known and aggressive.investigation_position == goal, "Unseen robot movement does not update the heard location")
	coward.threat_remaining = 0
	coward.decide()
	check(coward.state == Raider.State.SCAVENGING, "Empty Cowardly resumes scavenging after gunfire memory expires")
	# Complete the current investigation, then repeat sound from the same source.
	aggressive.investigation_position = aggressive.global_position
	aggressive.task_elapsed = 1.99
	aggressive._physics_process(0.02)
	aggressive.decide()
	check(aggressive.state == Raider.State.SCAVENGING, "Completed sound investigation resumes salvage objectives")
	check(aggressive.hear_gunfire(known) and aggressive.state == Raider.State.SCAVENGING, "Repeated stationary gunfire does not loop the completed investigation")
	check(aggressive.hear_gunfire(known + Vector3(2.5, 0, 0)) and aggressive.state == Raider.State.INVESTIGATING, "A meaningfully moved sound source can trigger a new investigation")
	var heard_position := aggressive.last_threat_position
	check(not aggressive.hear_gunfire(Vector3(100, 0, 100)) and aggressive.last_threat_position == heard_position, "Distant shots cannot change threat memory or objectives")
	aggressive.health.apply_damage(25)
	var damage_memory := aggressive.threat_remaining
	aggressive.task_elapsed = 0.5
	aggressive.hear_gunfire(heard_position)
	check(aggressive.state == Raider.State.FLEEING and aggressive.task_elapsed == 0.5 and aggressive.threat_remaining >= damage_memory, "Gunfire cannot override damage retreat or reset its task clock")
	# Sound through solid cover uses the source location, not the shot endpoint.
	arena.robot.position = Vector3(-9, 0.1, -5)
	aggressive.position = Vector3(-5, 0.1, -5)
	aggressive.transition(Raider.State.SCAVENGING)
	aggressive.threat_remaining = 0
	aggressive.threat_visible = false
	await frames(3)
	check(not aggressive.detects_robot(), "Solid obstacle blocks sight in hearing-through-cover scenario")
	check(aggressive.hear_gunfire(arena.robot.global_position) and aggressive.state == Raider.State.INVESTIGATING, "Nearby gunfire is audible through cover under the simple radius rule")
	await frames(2)
	check(aggressive.get_node("Alert").visible and aggressive.get_node("Alert").text == "? GUNFIRE", "World alert communicates investigation and its audible cause")
	var task := aggressive.task_elapsed
	aggressive.get_node("RaiderFeedback").refresh()
	check(aggressive.task_elapsed == task and arena.ledger.is_conserved(), "Presentation cannot advance task progress or material totals")
	aggressive.threat_remaining = 0
	aggressive.get_node("RaiderFeedback").refresh()
	check(not aggressive.get_node("Alert").visible, "Alert clears when threat memory expires")
	arena.ledger.collect(1, &"Salvage", 3)
	arena.refresh_hud()
	greedy.get_node("RaiderFeedback").refresh()
	var pack := greedy.get_node("Visuals/Backpack") as MeshInstance3D
	check(pack.material_override.emission != Color.BLACK, "Loaded cargo pack receives a visible emission cue")
	check(not arena.get_node("Salvage/Crate").visible and arena.get_node("Salvage/Label3D").text.contains("DEPLETED"), "Depleted salvage loses its crate and clearly labels empty stock")
	greedy.health.apply_damage(100)
	var dead_memory := greedy.threat_remaining
	check(not greedy.hear_gunfire(greedy.global_position) and greedy.threat_remaining == dead_memory, "Dead Raider rejects auditory events")
	arena.mission.evaluate(arena.ledger, true)
	arena.finish_mission()
	await frames(2)
	check(not coward.get_node("Alert").visible and not coward.get_node("RaiderFeedback").is_processing(), "Terminal deployment clears and stops alert presentation")
	var terminal_memory := coward.threat_remaining
	arena._on_weapon_fired(coward.global_position, Vector3.ZERO, false)
	check(coward.threat_remaining == terminal_memory and arena.ledger.is_conserved(), "Terminal mission ignores late weapon events with conserved accounting")
	arena.queue_free()
	await frames(3)
	# Legacy one-Raider behavior retains its existing perception and reaction rules.
	arena = load("res://scenes/levels/single_raider_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var legacy := arena.raiders[1] as Raider
	legacy.set_physics_process(false)
	check(not legacy.hear_gunfire(legacy.global_position) and legacy.state == Raider.State.SCAVENGING, "Single-Raider regression mode preserves original behavior")
	arena.queue_free()
	await frames(3)
	print("Stage D checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
