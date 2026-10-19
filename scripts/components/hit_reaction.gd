extends Node
## Owns only visual scale and mesh overlays; cannot change health or physical motion.

@export var health: Health
@export var visuals: Node3D
@export var duration: float = 0.12
var remaining: float = 0.0
var base_scale: Vector3
var meshes: Array[MeshInstance3D] = []
var original_overlays: Array[Material] = []
var flash_material: StandardMaterial3D


func _ready() -> void:
	assert(health != null and visuals != null)
	base_scale = visuals.scale
	for node in visuals.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
		original_overlays.append(node.material_overlay)
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1, 0.85, 0.6)
	health.damaged.connect(_on_damaged)
	set_process(false)


func _on_damaged(_amount: float) -> void:
	if health.current <= 0:
		return
	remaining = duration
	visuals.scale = base_scale * Vector3(1.08, 0.9, 1.08)
	for mesh in meshes:
		mesh.material_overlay = flash_material
	set_process(true)


func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	var weight := remaining / maxf(duration, 0.001)
	visuals.scale = base_scale * Vector3.ONE.lerp(Vector3(1.08, 0.9, 1.08), weight)
	if remaining <= 0.0:
		visuals.scale = base_scale
		for index in range(meshes.size()):
			meshes[index].material_overlay = original_overlays[index]
		set_process(false)
