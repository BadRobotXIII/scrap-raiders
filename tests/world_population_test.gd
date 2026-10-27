extends "res://tests/asset_pipeline_test.gd"
## Stage Y: static art must preserve source binding, physical truth and authority.

const ART_SCENES: Array[String] = [
	"res://scenes/levels/environment/processing_facility_art.tscn",
	"res://scenes/levels/environment/salvage_yard_art.tscn",
	"res://scenes/levels/environment/storage_area_art.tscn",
	"res://scenes/levels/environment/service_perimeter_art.tscn",
	"res://scenes/presentation/salvage_complex_dressing.tscn",
	"res://scenes/levels/environment/staging_clusters.tscn",
]

func source_and_batch_contract() -> void:
	var accepted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/development/baselines/stage_y_delivery/accepted_environment_manifest.json"))
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/asset_manifest.json"))
	var unchanged := true
	for entry in accepted.assets:
		var found := false
		for candidate in current.assets:
			if candidate.id == entry.id:
				found = candidate == entry
		unchanged = unchanged and found
	check(unchanged and current.materials == accepted.materials and current.textures == accepted.textures, "Original eight source/export identities and shared surface foundations are preserved")
	seed(24025)
	var expected := randi()
	seed(24025)
	var bound := 0
	var instances := 0
	var labels := 0
	for path in ART_SCENES:
		var scene := load(path).instantiate() as Node3D
		root.add_child(scene)
		for item in scene.find_children("*", "", true, false):
			if item is Label3D: labels += 1
			if not item is EnvironmentMeshBatch: continue
			bound += 1
			instances += item.instance_transforms.size()
			var mesh: Mesh = item.multimesh.mesh
			var count: int = item.instance_transforms.size()
			item.rebuild()
			check(item.multimesh.mesh == mesh and item.multimesh.instance_count == count, "Static batch rebuild is idempotent: " + str(item.name))
			if item.model_scene != null:
				var original: Node = item.model_scene.instantiate()
				var part: MeshInstance3D = original.find_children("*", "MeshInstance3D", true, false)[0]
				check(mesh == part.mesh, "Batches use the live shared GLB mesh rather than embedded copies")
				original.free()
				item.model_scene.changed.emit()
				await process_frame
				check(item.multimesh.mesh == mesh, "Reimport notification refreshes the existing source binding")
		scene.free()
	check(randi() == expected, "Static dressing and reimport refresh consume no gameplay random numbers")
	check(bound > 0 and instances > bound and labels <= 24, "World uses bounded shared instancing and restrained signage")

func point_in_body(item: Node3D, point: Vector3, envelope: AABB, collision: CollisionShape3D) -> bool:
	return envelope.has_point(collision.to_local(item.to_global(point)))

func approved_refinement_contract(current: Dictionary, accepted: Dictionary) -> bool:
	# The director approved exactly three new blockers. Every original physical
	# input remains pinned; unrelated additions or edits still fail this check.
	var expected := accepted.duplicate(true)
	var clusters := {"Receiving": Vector3(5, 0.6, -24), "Shipping": Vector3(30, 0.6, 15), "Maintenance": Vector3(-32, 0.6, 14)}
	for name in clusters:
		expected["Geometry/StagingClusters/" + name + "/Collision"] = [str(Transform3D(Basis.IDENTITY, clusters[name])), str(Vector3(2, 1.2, 2)), 1, 1]
	expected = JSON.parse_string(JSON.stringify(expected))
	if current != expected:
		for key in current:
			if not expected.has(key) or current[key] != expected[key]: print("REFINEMENT CONTRACT DIFFERENCE ", key, " current ", current[key], " expected ", expected.get(key))
	return current == expected

func populated_contract() -> void:
	var baselines: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/development/baselines/stage_y_environment_audit/inventory_headless.json"))
	for baseline in baselines:
		var arena := create_u("population_%d" % int(baseline.seed), int(baseline.seed))
		check(approved_refinement_contract(JSON.parse_string(JSON.stringify(DeploymentMetrics.serializable(snapshot_contract(arena)))), baseline.physical_contract), "Seed %d retains every accepted physical input plus exactly three approved staging boxes" % int(baseline.seed))
		var contained := true
		var visuals := 0
		for item in arena.get_node("Geometry").find_children("*", "", true, false):
			if not item is MeshInstance3D and not item is EnvironmentMeshBatch: continue
			if not item.is_visible_in_tree(): continue
			visuals += 1
			var body: Node = item.get_parent()
			while body != null and not body is StaticBody3D: body = body.get_parent()
			if body == null:
				# Shared batches have explicit physical owners per instance.
				if item is EnvironmentMeshBatch:
					var candidates: Array[Node] = []
					if item == arena.get_node("Geometry/StagingClusters/PalletLoads"):
						for path in ["SalvageYard/LowCrates", "StagingClusters/Receiving", "StagingClusters/Shipping", "StagingClusters/Maintenance"]:
							candidates.append(arena.get_node("Geometry/" + path + "/Collision"))
					else:
						for candidate in arena.get_node("Geometry/ServicePerimeter").find_children("*", "CollisionShape3D", true, false):
							if String(candidate.get_parent().name).ends_with("Screen"): candidates.append(candidate)
					for transform in item.instance_transforms:
						var supported := false
						for candidate in candidates:
							var extent: Vector3 = candidate.shape.size
							var volume := AABB(-extent * 0.5, extent).grow(0.012)
							var inside := true
							for corner in range(8):
								inside = inside and point_in_body(item, transform * item.multimesh.mesh.get_aabb().get_endpoint(corner), volume, candidate)
							supported = supported or inside
						contained = contained and supported
						if not supported: print("UNSUPPORTED BATCH INSTANCE ", item.get_path(), " ", transform)
				continue
			var collision: CollisionShape3D = body.get_node("Collision")
			var size: Vector3 = collision.shape.size
			var envelope := AABB(-size * 0.5, size).grow(0.012)
			var mesh: Mesh = item.multimesh.mesh if item is EnvironmentMeshBatch else item.mesh
			var bounds := mesh.get_aabb()
			var transforms: Array = item.instance_transforms if item is EnvironmentMeshBatch else [Transform3D.IDENTITY]
			for transform in transforms:
				for corner in range(8):
					if not point_in_body(item, transform * bounds.get_endpoint(corner), envelope, collision):
						contained = false
						print("Y OUTSIDE ", arena.get_path_to(item), " ", transform * bounds.get_endpoint(corner))
		check(contained, "Every dressed solid and every batch instance fits its actual rotated collision envelope")
		var filled := true
		for name in ["WestBay", "EastBay"]:
			var bulk: EnvironmentMeshBatch = arena.get_node("Geometry/SalvageYard/" + name + "/Dressing/scrap_infill_1m")
			for x in [-0.9, 0.0, 0.9]:
				for z in [-2.9, -1.5, 0.0, 1.5, 2.9]:
					var covered := false
					# Only absorb floating-point roundoff at the touching tile seam.
					for transform in bulk.instance_transforms:
						covered = covered or bulk.multimesh.mesh.get_aabb().grow(0.0001).has_point(transform.affine_inverse() * Vector3(x, 1.4, z))
					filled = filled and covered
		check(filled, "Pressed bulk covers both solid retainer tops instead of leaving sparse detail over empty space")
		check(visuals <= 161, "Full dressing stays within 120 added geometry nodes over the 41-node baseline")
		await start_frozen(arena)
		check(arena.encounter.validate_navigation().is_empty(), "Both populated layouts retain reachable stock and patrols")
		var clear := true
		for marker in arena.get_node("EncounterSites").get_children():
			clear = clear and arena.encounter.ground_valid(marker.position) and arena.encounter.geometry_clear(marker.position, false)
		check(clear and arena.ledger.total_materials == 14 and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "All six staging pads remain clear and decorative material creates no ledger supply")
		var contract := snapshot_contract(arena)
		arena.queue_free()
		await frames(10)
		var gray := load("res://scenes/levels/expanded_salvage_complex_graybox.tscn").instantiate() as Node3D
		gray.stash_path = test_directory + "/gray_%d.json" % int(baseline.seed)
		gray.seed_override = int(baseline.seed)
		root.add_child(gray)
		current_scene = gray
		var hidden: bool = not gray.get_node("EnvironmentalPresentation/Details").visible
		for zone in ["ProcessingFacility", "SalvageYard", "StorageArea", "ServicePerimeter", "StagingClusters"]:
			var view: Node3D = gray.get_node("Geometry/" + zone)
			for path in view.production_visuals: hidden = hidden and not view.get_node(path).visible
			for path in view.graybox_visuals: hidden = hidden and view.get_node(path).visible
		check(hidden and snapshot_contract(gray) == contract, "Explicit graybox restores all original surfaces with the same physical contract")
		gray.queue_free()
		await frames(30)
	check(get_nodes_in_group("mission_presentations").is_empty(), "Repeated populated/graybox teardown releases mission presentation listeners")

func opaque_cover_shots() -> void:
	var arena := create_u("opaque_cover")
	await start_frozen(arena)
	park_world(arena)
	var shooter: Raider = arena.raiders[1]
	var target: SupportMachine = arena.ecosystem.machines[1]
	for row in [
		[Vector3(-8, 0.1, -3), Vector3(-2, 0.1, -3), Vector3(-8, 0.1, -7)],
		[Vector3(22, 0.1, -20), Vector3(22, 0.1, -12), Vector3(25, 0.1, -20)],
		[Vector3(-18, 0.1, 13), Vector3(-18, 0.1, 19), Vector3(-14, 0.1, 13)],
	]:
		shooter.position = row[0]
		target.position = row[1]
		await frames(3)
		var before := target.health.current
		shooter.combat.weapon.cooldown = 0
		shooter.combat.weapon.try_fire_at(target.get_aim_position())
		check(target.health.current == before, "Opaque yard, freight and utility cover blocks actual rifle damage")
		target.position = row[2]
		await frames(3)
		shooter.combat.weapon.cooldown = 0
		shooter.combat.weapon.try_fire_at(target.get_aim_position())
		check(target.health.current < before, "Adjacent clear approach permits actual physical fire")
	arena.queue_free()
	await frames(30)
	check(accounting_valid, "Physical cover shots preserve authoritative finite accounting")

func recall_screen_visible_collision() -> void:
	var arena := create_u("recall_screen_boundary")
	await start_frozen(arena)
	park_world(arena)
	await frames(3)
	var wall: StaticBody3D = arena.get_node("Geometry/ServicePerimeter/RecallScreen")
	var surface: MeshInstance3D = wall.get_node("Dressing/Surface")
	var matches := surface.is_visible_in_tree()
	# The long axis is Z. Test both ends and side approaches near both ends;
	# containment alone misses a tiny visual inside an oversized collision box.
	var approaches: Array = []
	for side in [-1.0, 1.0]:
		approaches.append([Vector3(0, 0, side * 4), Vector3.ZERO])
		for z in [-2.75, 0.0, 2.75]:
			approaches.append([Vector3(side * 2, 0, z), Vector3(0, 0, z)])
	for approach in approaches:
		var start := wall.to_global(approach[0])
		var end := wall.to_global(approach[1])
		var visible_hit: Variant = surface.get_aabb().intersects_segment(surface.to_local(start), surface.to_local(end))
		var query := PhysicsRayQueryParameters3D.create(start, end, 1)
		var physical_hit := wall.get_world_3d().direct_space_state.intersect_ray(query)
		matches = matches and visible_hit != null and not physical_hit.is_empty()
		if visible_hit != null and not physical_hit.is_empty():
			matches = matches and physical_hit.collider == wall and surface.to_global(visible_hit).distance_to(physical_hit.position) < 0.002
	check(matches, "Site 07 Recall wall visible sides and ends match actual collision ray hits")
	arena.queue_free()
	await frames(30)

func run() -> void:
	test_directory = "res://.godot/stage_y_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await source_and_batch_contract()
	await populated_contract()
	await opaque_cover_shots()
	await recall_screen_visible_collision()
	print("World population failures: ", failures)
	quit(1 if failures else 0)
