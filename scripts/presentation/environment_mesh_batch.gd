@tool
class_name EnvironmentMeshBatch
extends MultiMeshInstance3D
## Static visual binding. Keeps GLB reimport authoritative; no simulation access.

@export var model_scene: PackedScene:
	set(value):
		if model_scene != null and model_scene.changed.is_connected(_on_source_changed):
			model_scene.changed.disconnect(_on_source_changed)
		model_scene = value
		if model_scene != null: model_scene.changed.connect(_on_source_changed)
		if is_node_ready(): rebuild.call_deferred()
@export var source_mesh: Mesh:
	set(value):
		source_mesh = value
		if is_node_ready(): rebuild.call_deferred()
@export var instance_transforms: Array[Transform3D] = []:
	set(value):
		instance_transforms = value
		if is_node_ready(): rebuild.call_deferred()

func _ready() -> void:
	rebuild()

func _on_source_changed() -> void:
	if is_node_ready(): rebuild.call_deferred()

func rebuild() -> void:
	var mesh: Mesh = source_mesh
	if model_scene != null:
		if not model_scene.resource_path.begins_with("res://assets/environment/exports/"):
			push_error("Environment batches require a static environment export")
			return
		var model := model_scene.instantiate()
		var parts := model.find_children("*", "MeshInstance3D", true, false)
		if parts.size() == 1: mesh = parts[0].mesh
		model.free()
	if mesh == null:
		multimesh = null
		return
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = instance_transforms.size()
	for index in range(instance_transforms.size()):
		batch.set_instance_transform(index, instance_transforms[index])
	multimesh = batch
