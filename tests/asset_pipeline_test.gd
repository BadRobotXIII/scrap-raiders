extends "res://tests/expanded_world_test.gd"
## Validates imported presentation without giving it physics or mission authority.


func snapshot_contract(arena: Node3D) -> Dictionary:
	var snapshot := {}
	for node in arena.get_node("Geometry").find_children("*", "CollisionShape3D", true, false):
		var shape := node.shape as BoxShape3D
		var body := node.get_parent() as CollisionObject3D
		snapshot[str(arena.get_path_to(node))] = [str(node.global_transform), str(shape.size), body.collision_layer, body.collision_mask]
	for marker in arena.find_children("*", "Marker3D", true, false):
		if marker.owner == arena: # Authored markers; not generated machine muzzle names.
			snapshot[str(arena.get_path_to(marker))] = str(marker.global_transform)
	var mesh: NavigationMesh = arena.get_node("NavigationRegion3D").navigation_mesh
	snapshot["navigation"] = [mesh.agent_radius, mesh.agent_height, mesh.geometry_parsed_geometry_type, mesh.geometry_source_geometry_mode, mesh.geometry_source_group_name]
	return snapshot


func inspect_imports() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/asset_manifest.json"))
	check(manifest.assets.size() == 8 and manifest.materials.size() == 6, "Eight source-backed assets use the six shared material foundations")
	var accepted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/development/baselines/stage_u_delivery/source_manifest.json"))
	var unchanged := true
	for path in accepted:
		if path != "scenes/levels/expanded_salvage_complex.tscn":
			unchanged = unchanged and FileAccess.get_sha256("res://" + path) == accepted[path]
	check(unchanged, "All accepted U gameplay, collision modules, configs and earlier tests remain byte-identical")
	var total := 0
	for value in manifest.assets:
		var definition: Dictionary = value
		check(FileAccess.get_sha256("res://" + definition.source) == definition.source_sha256 and FileAccess.get_sha256("res://" + definition.export) == definition.export_sha256, "Editable source/export identities match inventory: " + definition.id)
		var packed := load("res://" + definition.export) as PackedScene
		var first := packed.instantiate() as Node3D
		var second := packed.instantiate() as Node3D
		var a := first.find_children("*", "MeshInstance3D", true, false)
		var b := second.find_children("*", "MeshInstance3D", true, false)
		check(a.size() == 1 and b.size() == 1 and a[0].mesh == b[0].mesh, "Repeated instances share imported mesh resources: " + definition.id)
		var valid := first.find_children("*", "CollisionObject3D", true, false).is_empty() and first.find_children("*", "NavigationRegion3D", true, false).is_empty()
		var model := a[0] as MeshInstance3D
		valid = valid and model.transform.is_equal_approx(Transform3D.IDENTITY)
		var expected := Vector3(definition.dimensions[0], definition.dimensions[1], definition.dimensions[2])
		valid = valid and model.get_aabb().size.distance_to(expected) < 0.002
		for index in range(model.mesh.get_surface_count()):
			var material := model.mesh.surface_get_material(index)
			var arrays := model.mesh.surface_get_arrays(index)
			valid = valid and material != null and material.resource_path.begins_with("res://resources/materials/environment/") and not arrays[Mesh.ARRAY_TEX_UV].is_empty()
		check(valid, "Import preserves scale, UVs, remapped materials and visual-only ownership: " + definition.id)
		total += int(definition.triangles)
		first.free()
		second.free()
	check(total <= 25000, "Small library stays below its initial aggregate geometry review threshold")
	for value in manifest.textures:
		var texture := load("res://" + value.path) as Texture2D
		check(texture != null and texture.get_size() == Vector2(1024, 1024) and FileAccess.get_sha256("res://" + value.path) == value.sha256, "Shared original surface texture is available and identified")


func comparison_and_physics() -> void:
	var art := create_u("art_contract")
	var art_contract := snapshot_contract(art)
	var contained := true
	for mesh in art.get_node("Geometry/ProcessingFacility").find_children("*", "MeshInstance3D", true, false):
		var owner_body: Node = mesh.get_parent()
		while owner_body != null and not owner_body is StaticBody3D:
			owner_body = owner_body.get_parent()
		if owner_body == null:
			continue # Floor markings / presentation outside a body are checked separately.
		var collision := owner_body.get_node("Collision") as CollisionShape3D
		var size: Vector3 = collision.shape.size
		var envelope := AABB(-size * 0.5, size).grow(0.012)
		for index in range(8):
			var local: Vector3 = collision.to_local(mesh.to_global(mesh.get_aabb().get_endpoint(index)))
			contained = contained and envelope.has_point(local)
	check(contained, "Dressed solid geometry stays within accepted collision envelopes plus surface-detail tolerance")
	art.queue_free()
	await frames(5)
	var gray := load("res://scenes/levels/expanded_salvage_complex_graybox.tscn").instantiate() as Node3D
	gray.stash_path = test_directory + "/gray.json"
	root.add_child(gray)
	current_scene = gray
	var gray_contract := snapshot_contract(gray)
	check(gray_contract == art_contract, "Art and explicit graybox retain identical collision, markers and navigation inputs")
	check(not gray.get_node("Geometry/ProcessingFacility/Visuals").visible and gray.get_node("Geometry/ProcessingFacility/SouthEast/Mesh").visible, "Graybox selection shows original surfaces and disables all production visuals")
	gray.queue_free()
	await frames(5)
	art = create_u("physical_bay")
	await start_frozen(art)
	park_world(art)
	var shooter: Raider = art.raiders[1]
	var target: SupportMachine = art.ecosystem.machines[1]
	shooter.position = Vector3(-18, 0.1, 1)
	target.position = Vector3(-18, 0.1, 5.5)
	await frames(3)
	var before := target.health.current
	shooter.combat.weapon.cooldown = 0
	shooter.combat.weapon.try_fire_at(target.get_aim_position())
	check(target.health.current == before, "Visually enclosed sorting machine still blocks an actual low rifle shot")
	shooter.position = Vector3(-21, 0.1, 5.5)
	await frames(3)
	shooter.combat.weapon.cooldown = 0
	shooter.combat.weapon.try_fire_at(target.get_aim_position())
	check(target.health.current < before, "Clear side approach to dressed equipment permits a valid physical shot")
	art.robot.position = Vector3(-18, 0.1, 7)
	for yaw in [0.0, PI / 2, PI]:
		art.robot.camera_rig.rotation.y = yaw
		await frames(8)
		var length: float = art.robot.camera_rig.spring_arm.get_hit_length()
		check(length > 0.1 and length <= art.robot.camera_rig.spring_arm.spring_length, "Player shoulder camera remains usable near dressed walls and ceiling")
	art.spectator.enter()
	check(art.spectator.active and not art.robot.input_adapter.gameplay_enabled, "Art retains independent developer camera permissions")
	art.spectator.leave()
	art.queue_free()
	await frames(30)


func run() -> void:
	test_directory = "res://.godot/stage_v_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	inspect_imports()
	await comparison_and_physics()
	check(accounting_valid, "Accepted transfers in art tests preserve the original ledgers")
	print("Asset pipeline failures: ", failures)
	quit(1 if failures else 0)
