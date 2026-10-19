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
	arena.get_node("Robot/Input").set_physics_process(false)
	var raider := arena.get_node("Raider") as Raider
	raider.set_physics_process(false)
	var target := arena.get_node("TargetA") as StaticBody3D
	target.get_node("DeathTumble").lifetime = 0.5
	var expected_origin: Vector3 = target.get_node("CollisionShape3D").global_position
	target.get_node("Health").apply_damage(1000)
	var bodies := get_nodes_in_group("death_tumbles")
	check(bodies.size() == 1, "Death creates exactly one cosmetic physics body")
	var body := bodies[0] as RigidBody3D
	check(body.global_position.is_equal_approx(expected_origin), "Physics copy preserves collider world position")
	check(body.collision_layer == 0 and body.collision_mask == 1, "Cosmetic body is excluded from gameplay collision queries")
	check(body.find_children("*", "MeshInstance3D", true, false).size() == 1 and body.find_children("*", "Health", true, false).is_empty(), "Target copy contains visual geometry without health")
	await frames(5)
	check(not is_instance_valid(target), "Original gameplay target is removed normally")
	check(body.position.y > expected_origin.y and body.rotation.length() > 0.05, "Physics copy launches and tumbles")
	var query := PhysicsRayQueryParameters3D.create(body.position + Vector3.UP * 4, body.position, 1)
	check(arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Gameplay ray ignores the cosmetic body")
	await frames(35)
	check(not is_instance_valid(body) and get_nodes_in_group("death_tumbles").is_empty(), "Expired tumble body cleans itself up")

	raider.position = arena.get_node("Salvage").position
	raider.scavenge_seconds = 0.1
	raider.set_physics_process(true)
	await frames(20)
	var death_position := raider.global_position
	raider.health.apply_damage(1000)
	await frames(4)
	bodies = get_nodes_in_group("death_tumbles")
	var drops := get_nodes_in_group("material_drops")
	check(bodies.size() == 1 and bodies[0].find_children("*", "MeshInstance3D", true, false).size() == 3, "Raider physics copy includes body, head, and backpack")
	check(drops.size() == 1 and drops[0].materials == 3 and drops[0].global_position.is_equal_approx(death_position), "Cargo remains separate and stationary at the death position")
	check(arena.mission.phase == MissionRules.Phase.RECOVERING and arena.mission.dropped_materials == 3, "Destruction presentation preserves mission state and material totals")
	arena.restart_mission()
	await frames(5)
	check(get_nodes_in_group("death_tumbles").is_empty() and get_nodes_in_group("material_drops").is_empty(), "Restart clears both cosmetic bodies and previous cargo")
	current_scene.queue_free()
	await frames(2)
	print("Destruction checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
