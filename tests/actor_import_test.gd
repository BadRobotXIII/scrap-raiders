extends SceneTree
## Runtime-import evidence: a static GLB load is insufficient for a skinned actor.

var failures: int = 0
const KINDS: Array[String] = ["raider", "player", "ground_machine", "flying_scout"]


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func skin_is_normalized(mesh: MeshInstance3D) -> bool:
	if mesh.skin == null:
		return true
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if weights.is_empty() or vertices.is_empty():
			return false
		var stride: int = weights.size() / vertices.size()
		if stride != 4:
			return false
		for vertex in range(vertices.size()):
			var total := 0.0
			for index in range(stride):
				var weight := weights[vertex * stride + index]
				if weight < 0 or not is_finite(weight):
					return false
				total += weight
			if absf(total - 1.0) > 0.001:
				return false
	return true


func socket_transform(model: Node3D, label: String) -> Transform3D:
	for value in model.find_children("*", "Node3D", true, false):
		if String(value.name).to_lower() != label:
			continue
		var node := value as Node3D
		var transform := Transform3D.IDENTITY
		while node != model:
			transform = node.transform * transform
			node = node.get_parent() as Node3D
		return transform
	return Transform3D(Basis.IDENTITY, Vector3.INF)


func inspect_actor(kind: String) -> void:
	var path := "res://assets/characters/exports/%s/%s.glb" % [kind, kind]
	var packed := load(path) as PackedScene
	check(packed != null, "Runtime export loads independently of Blender: " + kind)
	if packed == null:
		return
	var first := packed.instantiate() as Node3D
	var second := packed.instantiate() as Node3D
	check(first.transform.is_equal_approx(Transform3D.IDENTITY), "Imported model root retains metre-scale identity: " + kind)
	var visual_only := true
	for node in first.find_children("*", "", true, false):
		visual_only = visual_only and node.get_script() == null and not node is CollisionObject3D and not node is CollisionShape3D and not node is NavigationAgent3D and not node is NavigationRegion3D and not node is Camera3D and not node is Light3D
	check(visual_only, "Imported hierarchy has no gameplay, physics, camera or light authority: " + kind)
	var valid_meshes := true
	var skin_count := 0
	var meshes := first.find_children("*", "MeshInstance3D", true, false)
	check(not meshes.is_empty(), "Imported actor contains actual render geometry: " + kind)
	for value in meshes:
		var mesh := value as MeshInstance3D
		if mesh.skin != null:
			skin_count += 1
		valid_meshes = valid_meshes and skin_is_normalized(mesh)
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var material := mesh.get_active_material(surface)
			valid_meshes = valid_meshes and not arrays[Mesh.ARRAY_TEX_UV].is_empty() and not arrays[Mesh.ARRAY_NORMAL].is_empty() and material != null and (material.resource_path.begins_with("res://resources/materials/environment/") or material.resource_path.begins_with("res://resources/characters/materials/"))
	check(valid_meshes, "UVs, normals, shared material remaps and skin weights are usable: " + kind)
	var expected_muzzles := {"raider": Vector3(0.35, 1.15, -0.7), "player": Vector3(0.6, 1.15, -0.7), "ground_machine": Vector3(0, 0.7, -0.65)}
	if expected_muzzles.has(kind):
		check(socket_transform(first, "visual_muzzle").origin.distance_to(expected_muzzles[kind]) < 0.002, "Visual barrel socket meets the existing fixed gameplay muzzle: " + kind)
	if kind == "raider":
		var skeletons := first.find_children("*", "Skeleton3D", true, false)
		check(skeletons.size() == 1 and skin_count > 0, "Human Raider imports one deform rig and genuinely skinned geometry")
		if skeletons.size() == 1:
			var skeleton := skeletons[0] as Skeleton3D
			check(skeleton.get_bone_count() >= 20 and skeleton.get_bone_count() <= 28, "Raider uses a bounded humanoid deform skeleton")
		for socket in ["weapon_grip", "pack_mount", "head_mount"]:
			check(socket_transform(first, socket).origin.is_finite(), "Stable named Raider attachment survives import: " + socket)
		var players := first.find_children("*", "AnimationPlayer", true, false)
		check(players.size() == 1, "Raider exports one explicit animation library")
		if players.size() == 1:
			var player := players[0] as AnimationPlayer
			var clips: Array[String] = []
			var tracks_safe := true
			for name in player.get_animation_list():
				var short_name := String(name).get_file().to_lower()
				clips.append(short_name)
				var clip := player.get_animation(name)
				if short_name in ["idle", "walk", "run", "aim", "fire", "death"]:
					check(clip.loop_mode == (Animation.LOOP_LINEAR if short_name in ["idle", "walk", "run", "aim"] else Animation.LOOP_NONE), "Imported repeat/one-shot mode matches clip ownership: " + short_name)
				for track in range(clip.get_track_count()):
					tracks_safe = tracks_safe and clip.track_get_type(track) in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D] and not String(clip.track_get_path(track)).contains("Muzzle")
			for name in ["idle", "walk", "run", "aim", "fire", "death"]:
				check(clips.has(name), "Raider named animation is imported: " + name)
			check(tracks_safe, "Imported animations have no method, audio, gameplay-muzzle or authority tracks")
	else:
		check(skin_count == 0 and first.find_children("*", "Skeleton3D", true, false).is_empty(), "Mechanical actor preserves a rigid articulated hierarchy: " + kind)
	# Resource sharing is safe; mutable playback belongs to each instance.
	var other_meshes := second.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == other_meshes.size() and meshes[0].mesh == other_meshes[0].mesh and meshes[0] != other_meshes[0], "Instances share mesh resources without sharing mutable scene nodes: " + kind)
	first.free()
	second.free()


func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/actor_manifest.json"))
	check(manifest.schema == 2 and manifest.assets.size() == 4, "Actor inventory identifies all four source-backed visual identities")
	for definition in manifest.assets:
		check(FileAccess.get_sha256("res://" + definition.source) == definition.source_sha256 and FileAccess.get_sha256("res://" + definition.export) == definition.export_sha256, "Editable source and runtime export match actor inventory: " + definition.id)
	for kind in KINDS:
		inspect_actor(kind)
	var accepted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/development/baselines/stage_v_delivery/source_manifest.json"))
	var preserved := true
	for path in accepted:
		if String(path).begins_with("assets/environment/") or String(path).begins_with("resources/materials/environment/"):
			if path == "assets/environment/asset_manifest.json":
				# Y extends the inventory. Authenticate the original V manifest,
				# then require its exact entries and metadata within the extension.
				var baseline_path := "res://docs/development/baselines/stage_y_delivery/accepted_environment_manifest.json"
				var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(baseline_path))
				var extended: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://" + path))
				var ids: Array = []
				for entry in before.assets: ids.append(entry.id)
				extended.assets = extended.assets.filter(func(entry): return ids.has(entry.id))
				preserved = preserved and FileAccess.get_sha256(baseline_path) == accepted[path] and extended == before
			else:
				preserved = preserved and FileAccess.get_sha256("res://" + path) == accepted[path]
	check(preserved, "Actor-mode pipeline changes preserve every accepted environment asset and shared material byte")
	print("Actor import failures: ", failures)
	quit(1 if failures else 0)
