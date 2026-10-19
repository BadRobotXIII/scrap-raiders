extends SceneTree

var failures: int = 0
var deaths: int = 0
var shots: int = 0


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
	var health := Health.new()
	root.add_child(health)
	health.died.connect(func() -> void: deaths += 1)
	check(not health.apply_damage(-10) and not health.apply_damage(NAN), "Invalid damage rejected")
	check(health.apply_damage(25) and health.current == 75, "Damage reduces health")
	check(health.apply_damage(1000) and health.current == 0, "Lethal damage clamps health to zero")
	check(not health.apply_damage(1) and deaths == 1, "Death emitted once; dead health rejects damage")
	health.queue_free()

	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var robot := arena.get_node("Robot") as RobotController
	robot.input_adapter.set_physics_process(false)
	robot.position = Vector3.ZERO
	robot.camera_rig.pitch_pivot.rotation.x = 0
	var weapon := robot.get_node("Weapon") as HitscanWeapon
	weapon.fired.connect(func(_a: Vector3, _b: Vector3, _c: bool) -> void: shots += 1)
	var target := arena.get_node("TargetA") as StaticBody3D
	target.position.x = 1.0
	var target_health := target.get_node("Health") as Health
	await frames(20)
	check(weapon.try_fire(), "Ready weapon fires")
	check(target_health.current == 75, "Camera-centered shot damages target")
	check(not weapon.try_fire() and target_health.current == 75, "Cooldown blocks repeated same-tick damage")
	await frames(15)
	check(weapon.try_fire() and target_health.current == 50, "Cooldown expires and permits next shot")
	await frames(15)

	var cover := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.4, 2.0, 0.3)
	collision.shape = shape
	cover.add_child(collision)
	arena.add_child(cover)
	cover.position = Vector3(0.55, 1, -1.1)
	await frames(3)
	weapon.try_fire()
	check(target_health.current == 50, "Muzzle-side cover blocks shot despite clear camera ray")
	cover.queue_free()
	await frames(15)
	weapon.try_fire()
	await frames(15)
	weapon.try_fire()
	await frames(2)
	check(not is_instance_valid(target), "Lethal hits remove target and collision body")
	await frames(15)
	var before := shots
	check(weapon.try_fire() and shots == before + 1, "Misses still emit firing feedback")
	robot.input_adapter.fire_intent = true
	await frames(30)
	check(shots >= before + 3 and shots <= before + 4, "Held fire respects configured cadence")
	robot.input_adapter.clear_intent()
	check(not robot.input_adapter.fire_intent, "Clearing input clears fire intent")
	await frames(10)
	arena.queue_free()
	await process_frame
	print("Combat checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
