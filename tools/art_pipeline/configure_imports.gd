extends SceneTree
## Applies the same Advanced Import Settings material remaps reproducibly.
## Run after initial GLB import, then run editor --quit to perform reimport.

func _initialize() -> void:
	if "--actors" in OS.get_cmdline_user_args():
		_configure_actors()
		quit()
		return
	for directory in ["structures", "machinery", "props"]:
		var path: String = "res://assets/environment/exports/" + directory
		for file in DirAccess.get_files_at(path):
			if not file.ends_with(".glb"):
				continue
			var filename: String = path + "/" + file + ".import"
			var settings := ConfigFile.new()
			assert(settings.load(filename) == OK, "Initial Godot import required: " + filename)
			settings.set_value("params", "nodes/root_type", "Node3D")
			settings.set_value("params", "nodes/root_scale", 1.0)
			settings.set_value("params", "nodes/use_name_suffixes", false)
			settings.set_value("params", "nodes/use_node_type_suffixes", false)
			settings.set_value("params", "meshes/generate_lods", false)
			settings.set_value("params", "meshes/light_baking", 0)
			settings.set_value("params", "animation/import", false)
			var materials := {}
			for name in ["concrete", "painted_steel_bluegray", "weathered_steel", "galvanized_steel", "rubber", "safety_yellow"]:
				materials[name] = {"use_external/enabled": true, "use_external/path": "res://resources/materials/environment/" + name + ".tres"}
			settings.set_value("params", "_subresources", {"materials": materials})
			assert(settings.save(filename) == OK)
			# External edits to .import settings need a reimport. Invalidate only
			# this library asset's generated checksum, never a source or whole cache.
			var checksum: String = str(settings.get_value("remap", "path")).get_basename() + ".md5"
			if checksum.begins_with("res://.godot/imported/") and FileAccess.file_exists(checksum):
				assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(checksum)) == OK)
			print("ART_IMPORT_CONFIG ", filename)
	quit()


func _configure_actors() -> void:
	for directory in ["raider", "player", "ground_machine", "flying_scout"]:
		var path: String = "res://assets/characters/exports/" + directory
		if not DirAccess.dir_exists_absolute(path):
			continue
		for file in DirAccess.get_files_at(path):
			if not file.ends_with(".glb"):
				continue
			var filename: String = path + "/" + file + ".import"
			var settings := ConfigFile.new()
			assert(settings.load(filename) == OK, "Initial actor import required: " + filename)
			settings.set_value("params", "nodes/root_type", "Node3D")
			settings.set_value("params", "nodes/root_scale", 1.0)
			settings.set_value("params", "nodes/use_name_suffixes", false)
			settings.set_value("params", "nodes/use_node_type_suffixes", false)
			settings.set_value("params", "meshes/generate_lods", false)
			settings.set_value("params", "meshes/light_baking", 0)
			settings.set_value("params", "animation/import", directory == "raider")
			settings.set_value("params", "animation/fps", 30)
			var materials := {}
			for material_name in ["concrete", "painted_steel_bluegray", "weathered_steel", "galvanized_steel", "rubber", "safety_yellow"]:
				materials[material_name] = {"use_external/enabled": true, "use_external/path": "res://resources/materials/environment/" + material_name + ".tres"}
			for material_name in ["cloth_olive", "protective_polymer", "salvaged_metal", "opaque_lens"]:
				materials[material_name] = {"use_external/enabled": true, "use_external/path": "res://resources/characters/materials/" + material_name + ".tres"}
			var subresources := {"materials": materials}
			if directory == "raider":
				var animations := {}
				for clip in ["idle", "walk", "run", "aim", "fire", "death"]:
					animations[clip] = {"settings/loop_mode": 1 if clip in ["idle", "walk", "run", "aim"] else 0}
				subresources["animations"] = animations
			settings.set_value("params", "_subresources", subresources)
			assert(settings.save(filename) == OK)
			var checksum: String = str(settings.get_value("remap", "path")).get_basename() + ".md5"
			if checksum.begins_with("res://.godot/imported/") and FileAccess.file_exists(checksum):
				assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(checksum)) == OK)
			print("ACTOR_IMPORT_CONFIG ", filename)
