extends SceneTree
## Integration checks using the actual arena, controller, and physics engine.

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func run() -> void:
	var arena := load("res://scenes/levels/single_raider_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	var robot := arena.get_node("Robot") as RobotController
	var adapter := robot.input_adapter
	adapter.set_physics_process(false)
	adapter.set_process_input(false)
	await frames(30)
	check(robot.is_on_floor(), "Robot settles on arena floor")
	check(absf(robot.position.y) < 0.05, "Capsule rests at floor height")

	robot.camera_rig.rotation.y = PI / 2.0
	var start := robot.position
	adapter.move_intent = Vector2(0, -1)
	await frames(30)
	check(robot.position.x < start.x - 2.0, "W movement follows camera yaw")
	check(absf(robot.position.z - start.z) < 0.1, "Camera-relative movement stays on intended axis")
	adapter.clear_intent()
	await frames(15)
	check(Vector2(robot.velocity.x, robot.velocity.z).length() < 0.01, "Robot brakes promptly to rest")

	robot.camera_rig.apply_look(Vector2(0, 100000))
	check(is_equal_approx(robot.camera_rig.pitch_pivot.rotation.x, deg_to_rad(-60)), "Lower pitch limit enforced")
	robot.camera_rig.apply_look(Vector2(0, -100000))
	check(is_equal_approx(robot.camera_rig.pitch_pivot.rotation.x, deg_to_rad(25)), "Upper pitch limit enforced")
	adapter.aim_intent = true
	await frames(20)
	check((-robot.visuals.global_basis.z).dot(robot.camera_rig.aim_direction()) > 0.999, "Stationary aiming faces camera direction")
	adapter.move_intent = Vector2(0, 1)
	await frames(15)
	check((-robot.visuals.global_basis.z).dot(robot.camera_rig.aim_direction()) > 0.999, "Aiming keeps facing while moving backward")
	check(is_equal_approx(robot.camera_rig.rotation.y, PI / 2.0), "Robot turning does not rotate the camera")

	adapter.clear_intent()
	robot.position = Vector3(0, 0.05, 13)
	robot.velocity = Vector3.ZERO
	robot.camera_rig.rotation.y = 0
	robot.camera_rig.pitch_pivot.rotation.x = 0
	adapter.move_intent = Vector2(0, 1)
	await frames(60)
	check(robot.position.z < 14.5 and robot.position.z > 14.0, "South boundary blocks robot movement")
	check(robot.camera_rig.spring_arm.get_hit_length() < 2.0, "Spring arm retracts at arena wall")

	adapter.clear_intent()
	robot.position = Vector3(8, 0.05, 9)
	robot.velocity = Vector3.ZERO
	adapter.move_intent = Vector2(0, -1)
	await frames(60)
	check(robot.position.z > 6.9 and robot.position.z < 7.2, "Arena obstacle blocks robot movement")
	adapter.clear_intent()
	robot.position = Vector3(0, 0.05, 0)
	robot.velocity = Vector3.ZERO
	await frames(20)
	check(robot.camera_rig.spring_arm.get_hit_length() > 4.9, "Spring arm returns to full length in clear space")

	arena.queue_free()
	await process_frame
	print("Controller integration checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
