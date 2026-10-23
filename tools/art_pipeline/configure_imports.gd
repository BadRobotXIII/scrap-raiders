extends SceneTree
## Applies the same Advanced Import Settings material remaps reproducibly.
## Run after initial GLB import, then run editor --quit to perform reimport.

func _initialize() -> void:
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
