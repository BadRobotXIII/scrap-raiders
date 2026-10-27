extends "res://tests/world_population_test.gd"
## Approved Y footprints: real navigation, collision, traversal and graybox truth.

const CLUSTER_ORIGINS: Array[Vector3] = [Vector3(5, 0, -24), Vector3(30, 0, 15), Vector3(-32, 0, 14)]

func visible_load_envelopes() -> void:
	var arena := create_u("load_envelopes")
	await start_frozen(arena)
	park_world(arena)
	await frames(3)
	var batch: EnvironmentMeshBatch = arena.get_node("Geometry/StagingClusters/PalletLoads")
	var bounds: AABB = batch.multimesh.mesh.get_aabb()
	for name in ["Receiving", "Shipping", "Maintenance"]:
		var body: StaticBody3D = arena.get_node("Geometry/StagingClusters/" + name)
		var envelope := AABB(Vector3(-1, -0.6, -1), Vector3(2, 1.2, 2))
		var visible_bounds := AABB()
		var instances := 0
		for transform in batch.instance_transforms:
			var local := body.global_transform.affine_inverse() * batch.global_transform * transform
			var part: AABB = local * bounds
			if not envelope.grow(0.012).encloses(part): continue
			visible_bounds = part if instances == 0 else visible_bounds.merge(part)
			instances += 1
		check(instances == 2 and visible_bounds.position.distance_to(envelope.position) < 0.002 and visible_bounds.size.distance_to(envelope.size) < 0.002, "Two visible loads fill the actual staging collision envelope: " + name)
		var matched := true
		for side in [-1.0, 1.0]:
			# Keep ray origins in the adjacent lane; the maintenance load's
			# eastern approach is near an existing processing wall.
			for start in [Vector3(side * 2, 0, 0), Vector3(0, 0, side * 2)]:
				var visible_hit: Variant = visible_bounds.intersects_segment(start, Vector3.ZERO)
				var query := PhysicsRayQueryParameters3D.create(body.to_global(start), body.global_position, 1)
				var physical_hit := body.get_world_3d().direct_space_state.intersect_ray(query)
				matched = matched and visible_hit != null and not physical_hit.is_empty()
				if visible_hit != null and not physical_hit.is_empty():
					matched = matched and physical_hit.collider == body and body.to_global(visible_hit).distance_to(physical_hit.position) < 0.002
		check(matched, "Visible staging extents match physical hits from four approaches: " + name)
	arena.queue_free()
	await frames(30)

func cluster_routes() -> void:
	var arena := create_u("cluster_routes")
	await start_frozen(arena)
	park_world(arena)
	var actor: Raider = arena.raiders[1]
	var stock: Node3D = arena.get_node("Salvage3")
	# Hold a chosen objective in this physical fixture. The production FSM,
	# NavigationAgent, steering, gravity and stall recovery still run normally.
	actor.scavenge_seconds = 1000
	for origin in CLUSTER_ORIGINS:
		for sign in [-1.0, 1.0]:
			actor.set_physics_process(false)
			actor.position = origin + Vector3(0, 0.1, sign * 4)
			actor.velocity = Vector3.ZERO
			stock.position = origin - Vector3(0, 0, sign * 4)
			actor.salvage = stock
			actor.transition(Raider.State.SELECTING)
			actor.transition(Raider.State.SCAVENGING)
			actor.decision_remaining = 1000
			await frames(3)
			actor.set_physics_process(true)
			var reached := false
			var went_around := false
			var penetrated := false
			for tick in range(1200):
				await frames(1)
				var offset := actor.position - origin
				went_around = went_around or absf(offset.x) > 1.35
				penetrated = penetrated or (absf(offset.x) < 0.99 and absf(offset.z) < 0.99 and offset.y < 1.19)
				if actor.position.distance_to(stock.position) < 0.8:
					reached = true
					break
			print("CLUSTER ROUTE ", origin, " direction ", sign, " final ", actor.position, " status ", actor.navigation_status)
			check(reached and went_around and not penetrated, "Raider physically routes around staging load in both directions: " + str(origin))
			actor.set_physics_process(false)
	arena.queue_free()
	await frames(30)

func player_cluster_contact() -> void:
	var arena := create_u("cluster_contact")
	await start_frozen(arena)
	park_world(arena)
	var robot: RobotController = arena.robot
	var input: RobotInput = robot.input_adapter
	input.gameplay_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for origin in CLUSTER_ORIGINS:
		robot.position = origin + Vector3(0, 0.1, -4)
		robot.stop_traversal()
		robot.camera_rig.rotation.y = 0
		input.clear_intent()
		input.move_intent = Vector2(0, 1)
		robot.set_physics_process(true)
		await frames(50)
		input.boost_requested = true
		await frames(18)
		check(robot.position.z < origin.z - 1.3 and robot.position.z > origin.z - 2, "Walking and boost respect the visible staging collision: " + str(origin))
		input.clear_intent()
		for yaw in [0.0, PI * 0.5, PI, -PI * 0.5]:
			robot.camera_rig.rotation.y = yaw
			await frames(2)
			var length: float = robot.camera_rig.spring_arm.get_hit_length()
			check(length > 0.1 and length <= robot.camera_rig.spring_arm.spring_length, "Shoulder camera stays usable beside the new load")
		# Jump beside the load in a clear supported lane, then land. Decorative
		# ground seams/channels must not create steps or airborne floor contact.
		robot.position = origin + Vector3(2.2, 0.1, -2)
		robot.stop_traversal()
		await frames(12)
		input.jump_requested = true
		await frames(2)
		check(robot.position.y > 0.15 and robot.velocity.y > 0, "Grounded jump remains available beside staged equipment")
		await frames(90)
		check(robot.is_on_floor() and absf(robot.position.y) < 0.1, "Jump settles on unchanged concrete physics")
		robot.set_physics_process(false)
	arena.queue_free()
	await frames(30)

func load_cover_shots() -> void:
	var arena := create_u("load_cover")
	await start_frozen(arena)
	park_world(arena)
	var shooter: Raider = arena.raiders[1]
	var target: SupportMachine = arena.ecosystem.machines[1]
	for origin in CLUSTER_ORIGINS:
		shooter.position = origin + Vector3(0, 0.1, -4)
		target.position = origin + Vector3(0, 0.1, 4)
		await frames(3)
		var before := target.health.current
		shooter.combat.weapon.cooldown = 0
		shooter.combat.weapon.try_fire_at(target.get_aim_position())
		check(target.health.current == before, "Staged load blocks a physical rifle shot")
		# Maintenance's east side meets the pre-existing processing wall;
		# its western lane is the unobstructed comparison shot.
		var lane := -2.3 if origin.x < -30 else 3.0
		shooter.position.x += lane
		target.position.x += lane
		await frames(3)
		shooter.combat.weapon.cooldown = 0
		shooter.combat.weapon.try_fire_at(target.get_aim_position())
		check(target.health.current < before, "Clear lane beside staged load permits physical damage")
	arena.queue_free()
	await frames(30)

func run() -> void:
	test_directory = "res://.godot/stage_y_refinement_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await visible_load_envelopes()
	await cluster_routes()
	await player_cluster_contact()
	await load_cover_shots()
	check(accounting_valid, "Approved staging collision never creates or duplicates finite resources")
	print("Environment refinement failures: ", failures)
	quit(1 if failures else 0)
