extends SceneTree

var failures: int = 0
var extracted_materials: int = -1


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


func create_arena() -> Node3D:
	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var robot := arena.get_node("Robot") as RobotController
	robot.input_adapter.set_physics_process(false)
	robot.input_adapter.set_process_input(false)
	return arena


func run() -> void:
	var arena := create_arena()
	var robot := arena.get_node("Robot") as RobotController
	var raider := arena.get_node("Raider") as Raider
	var camera := robot.camera_rig.camera
	await frames(10)
	check(NavigationServer3D.map_get_iteration_id(raider.agent.get_navigation_map()) > 0, "Navigation map synchronized")
	var start := raider.position
	await frames(60)
	check(raider.position.distance_to(start) > 1.0, "Raider follows navigation toward salvage")
	check(raider.state == Raider.State.SCAVENGING, "Distant robot does not trigger fleeing")

	for pitch in [-60.0, -8.0, 0.0, 25.0]:
		robot.camera_rig.pitch_pivot.rotation_degrees.x = pitch
		await frames(2)
		var center := camera.get_viewport().get_visible_rect().size * 0.5
		var origin := camera.project_ray_origin(center)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(center) * 20, 2)
		check(robot.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Shoulder reticle clears robot capsule at pitch %d" % pitch)

	# Put the machine behind an obstacle, then in unobstructed detection range.
	raider.set_physics_process(false)
	raider.position = Vector3(-7, 0, -8)
	robot.position = Vector3(-7, 0, -2)
	await frames(3)
	check(not raider.detects_robot(), "Solid cover blocks threat detection")
	robot.position = Vector3(-10, 0, -8)
	await frames(3)
	check(raider.detects_robot(), "Nearby visible robot is detected")
	raider.set_physics_process(true)
	await frames(15)
	check(raider.state == Raider.State.FLEEING, "Visible threat transitions scavenging to fleeing")
	raider.position = arena.get_node("Extraction").position
	await frames(20)
	check(raider.state == Raider.State.EXTRACTING, "Fleeing Raider begins extraction at exit")
	raider.health.apply_damage(1000)
	await frames(2)
	check(get_nodes_in_group("material_drops").is_empty(), "Empty Raider drops no invented materials")
	arena.queue_free()
	await frames(3)

	arena = create_arena()
	raider = arena.get_node("Raider") as Raider
	raider.scavenge_seconds = 0.1
	raider.extraction_seconds = 0.1
	raider.walk_speed = 8
	raider.position = arena.get_node("Salvage").position
	raider.extracted.connect(func(amount: int) -> void: extracted_materials = amount)
	await frames(25)
	check(raider.carried_materials == 3 and raider.state == Raider.State.EXTRACTING, "Scavenging grants cargo once and selects extraction")
	# Exercise a full obstacle-crossing route rather than teleporting to the exit.
	for index in range(500):
		if not is_instance_valid(raider):
			break
		await frames(1)
	check(extracted_materials == 3 and not is_instance_valid(raider), "Loaded Raider navigates around obstacles and extracts cargo")
	check(get_nodes_in_group("material_drops").is_empty(), "Successful extraction produces no loot drop")
	arena.queue_free()
	await frames(3)

	arena = create_arena()
	raider = arena.get_node("Raider") as Raider
	raider.scavenge_seconds = 0.1
	raider.position = arena.get_node("Salvage").position
	await frames(20)
	raider.health.apply_damage(25)
	check(raider.state == Raider.State.FLEEING, "Nonlethal damage causes fleeing")
	raider.health.apply_damage(1000)
	check(raider.state == Raider.State.DEAD and raider.carried_materials == 0, "Death is terminal and transfers cargo out of Raider")
	raider.transition(Raider.State.SCAVENGING)
	check(raider.state == Raider.State.DEAD, "Dead Raider cannot re-enter active states")
	await frames(2)
	var drops := get_nodes_in_group("material_drops")
	check(drops.size() == 1 and drops[0].get("materials") == 3, "Loaded Raider drops exactly one cargo stack")
	check(arena.get_node("Overlay/RaiderStatus").text.begins_with("3 materials dropped"), "HUD confirms actual cargo dropped")
	arena.queue_free()
	await frames(3)

	# Reproduce the normal player path: default spawn/timing, then actual weapon hits.
	arena = create_arena()
	raider = arena.get_node("Raider") as Raider
	for index in range(600):
		if raider.carried_materials > 0:
			break
		await frames(1)
	check(raider.carried_materials == 3, "Default Raider reaches salvage and collects cargo without teleporting")
	check(arena.get_node("Overlay/RaiderStatus").text.contains("carrying 3"), "HUD announces cargo ready for interception")
	raider.set_physics_process(false)
	robot = arena.get_node("Robot") as RobotController
	robot.position = raider.position + Vector3(0, 0, 5)
	await frames(3)
	var death_position := raider.global_position
	var weapon := robot.get_node("Weapon") as HitscanWeapon
	robot.camera_rig.camera.look_at(death_position + Vector3.UP)
	for index in range(4):
		weapon.try_fire()
		await frames(15)
	drops = get_nodes_in_group("material_drops")
	check(not is_instance_valid(raider), "Actual blaster shots kill a loaded Raider")
	check(drops.size() == 1 and drops[0].get("materials") == 3, "Normal scavenging followed by blaster death drops cargo")
	if drops.size() == 1:
		check(drops[0].global_position.is_equal_approx(death_position), "Cargo spawns at death location")
		check(drops[0].get_node("Mesh").is_visible_in_tree(), "Cargo mesh remains visible after Raider removal")
	arena.queue_free()
	await frames(3)
	print("Raider checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
