extends SceneTree

var failures: int = 0
var arena: Node3D
var robot: RobotController
var input: RobotInput


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


func isolate() -> void:
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			actor.combat.stop()
	robot = arena.robot
	input = robot.input_adapter
	input.set_physics_process(false)
	input.set_process_input(false)


func reset_at(point: Vector3) -> void:
	input.clear_intent()
	robot.stop_traversal()
	robot.position = point
	robot.camera_rig.rotation.y = 0
	await frames(8)


func run() -> void:
	check(InputMap.action_get_events("jump")[0].physical_keycode == KEY_SPACE and InputMap.action_get_events("boost")[0].physical_keycode == KEY_SHIFT, "Physical Space and Shift map to traversal actions")
	arena = load("res://scenes/levels/traversal_arena.tscn").instantiate()
	var directory := "res://.godot/stage_i_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	arena.stash_path = directory + "/stash.json"
	root.add_child(arena)
	current_scene = arena
	isolate()
	await frames(12)
	check(robot.traversal_enabled and arena.config.experimental_traversal, "Dedicated preset enables experimental movement")
	await reset_at(Vector3(0, 0.1, 12))
	var floor_y := robot.position.y
	input.jump_requested = true
	await frames(1)
	check(not robot.is_on_floor() and robot.velocity.y > 0 and not input.jump_requested, "Grounded jump launches once and consumes request")
	var peak := robot.position.y
	for index in range(75):
		if index == 6:
			input.jump_requested = true
		var before := robot.velocity.y
		await frames(1)
		if index == 6:
			check(robot.velocity.y < before, "Airborne jump request cannot reset vertical velocity")
		peak = maxf(peak, robot.position.y)
	check(peak - floor_y > 1.4 and peak - floor_y < 1.65, "Jump apex stays near the approved 1.5 metres")
	check(robot.is_on_floor() and absf(robot.position.y - floor_y) < 0.05, "Jump returns cleanly to the same floor")
	var ceiling := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 0.2, 4)
	collision.shape = shape
	ceiling.add_child(collision)
	ceiling.position = Vector3(0, 2.4, 12)
	arena.add_child(ceiling)
	await frames(3)
	input.jump_requested = true
	var under_ceiling_peak := robot.position.y
	for index in range(45):
		await frames(1)
		under_ceiling_peak = maxf(under_ceiling_peak, robot.position.y)
	check(under_ceiling_peak < 0.55 and robot.is_on_floor(), "Jump hits a low ceiling and settles without tunnelling")
	ceiling.queue_free()
	await frames(2)
	await reset_at(Vector3(0, 0.1, 12))
	robot.camera_rig.rotation.y = PI / 2
	input.move_intent = Vector2(0, -1)
	input.boost_requested = true
	var origin := robot.position
	await frames(1)
	check(robot.boost_state == RobotController.BoostState.BOOSTING and is_equal_approx(robot.velocity.x, -16), "Boost starts immediately in camera-relative WASD direction")
	input.move_intent = Vector2(0, 1)
	await frames(13)
	check(robot.position.x < origin.x - 3.5 and absf(robot.position.z - origin.z) < 0.05, "Boost direction stays fixed during the short burst")
	input.move_intent = Vector2.ZERO
	await frames(2)
	check(robot.boost_state == RobotController.BoostState.COOLDOWN, "Quarter-second burst enters cooldown")
	input.boost_requested = true
	await frames(1)
	check(robot.boost_state == RobotController.BoostState.COOLDOWN, "Boost cannot restart during cooldown")
	await frames(94)
	check(robot.boost_state == RobotController.BoostState.READY and robot.velocity.length() < 0.01, "Cooldown restores readiness and normal braking stops movement")
	await reset_at(Vector3(0, 0.1, 12))
	input.move_intent = Vector2(1, -1)
	input.boost_requested = true
	await frames(1)
	check(is_equal_approx(Vector2(robot.velocity.x, robot.velocity.z).length(), 16), "Diagonal boost is normalized to the same speed")
	robot.camera_rig.apply_look(Vector2(250, 100))
	await frames(1)
	check(robot.boost_direction.is_equal_approx(Vector3(1, 0, -1).normalized()), "Orbiting the camera does not steer an active boost")
	await reset_at(Vector3(0, 0.1, 12))
	input.jump_requested = true
	await frames(8)
	input.aim_intent = true
	input.boost_requested = true
	var yaw := robot.camera_rig.rotation.y
	await frames(10)
	check(robot.position.z < 10 and robot.position.y > 0.4, "Air boost preserves jump arc while moving horizontally")
	check((-robot.visuals.global_basis.z).dot(robot.camera_rig.aim_direction()) > 0.999 and robot.camera_rig.rotation.y == yaw, "Airborne aiming faces camera without rotating the camera rig")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	input._input(event)
	check(robot.boost_state == RobotController.BoostState.COOLDOWN and not input.boost_requested and not input.jump_requested and input.move_intent.is_zero_approx(), "Releasing mouse cancels active boost and clears pending traversal")
	await reset_at(Vector3(0, 0.1, 21))
	input.move_intent = Vector2(0, 1)
	input.boost_requested = true
	await frames(20)
	check(robot.position.z < 23 and robot.position.z > 22, "Boost collision cannot pass through arena boundary")
	await reset_at(Vector3(8, 0.1, 9))
	input.move_intent = Vector2(0, -1)
	input.boost_requested = true
	await frames(20)
	check(robot.position.z > 6.9 and robot.position.z < 7.3, "Boost collision cannot tunnel through arena obstacle")
	await reset_at(Vector3(15, 0.1, -1))
	input.move_intent = Vector2(0, -1)
	input.boost_requested = true
	await frames(40)
	check(robot.position.y > 0.5 and robot.position.z < -4, "Boost and normal movement climb the authored ramp physically")
	await reset_at(arena.get_node("RecallDock").position + Vector3.UP * 0.1)
	input.recover_held = true
	arena.recall.step(0.1)
	arena.recall.step(1)
	check(arena.recall.channeling and arena.recall.elapsed == 1, "Stationary grounded robot can channel recall")
	input.jump_requested = true
	await frames(1)
	arena.recall.step(0.1)
	check(not arena.recall.channeling and arena.recall.elapsed == 0, "Jump cancels recall immediately before displacement threshold")
	await frames(75)
	input.recover_held = true
	arena.recall.step(0.1)
	arena.recall.step(1)
	input.boost_requested = true
	await frames(1)
	arena.recall.step(0.1)
	check(not arena.recall.channeling, "Boost cancels recall even with no WASD intent")
	robot.get_node("Health").apply_damage(1000)
	check(arena.mission.player_destroyed and robot.boost_state == RobotController.BoostState.READY and robot.velocity == Vector3.ZERO and not robot.is_physics_processing(), "Death stops traversal and clears physical velocity")
	var death_position := robot.position
	await frames(10)
	check(robot.position == death_position and arena.ledger.is_conserved(), "Terminal actor cannot move or change material accounting")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	isolate()
	check(robot.traversal_enabled and robot.boost_state == RobotController.BoostState.READY and robot.is_on_floor() and robot.get_node("Health").current == 100, "Restart preserves experiment and resets movement, health and cooldown")
	check(not FileAccess.file_exists(arena.stash_path), "Traversal test leaves persistent rewards untouched")
	arena.select_scenario(0)
	await frames(12)
	arena = current_scene
	robot = arena.robot
	input = robot.input_adapter
	input.set_physics_process(false)
	input.set_process_input(false)
	check(not robot.traversal_enabled, "Returning to Intercept restores baseline controller configuration")
	input.jump_requested = true
	input.boost_requested = true
	await frames(2)
	check(robot.is_on_floor() and robot.boost_state == RobotController.BoostState.READY, "Baseline scenario ignores experimental traversal requests")
	arena.queue_free()
	await frames(3)
	print("Stage I traversal checks complete; failures: ", failures)
	quit(1 if failures else 0)
