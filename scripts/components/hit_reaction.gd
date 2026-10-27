extends Node
## Owns only visual scale and mesh overlays; cannot change health or physical motion.

@export var health: Health
@export var visuals: Node3D
@export var duration: float = 0.12
var remaining: float = 0.0
var base_scale: Vector3
var meshes: Array[MeshInstance3D] = []
var original_overlays: Array[Material] = []
var original_transforms: Array[Transform3D] = []
var flash_material: StandardMaterial3D


func _ready() -> void:
	assert(health != null and visuals != null)
	base_scale = visuals.scale
	for node in visuals.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
		original_overlays.append(node.material_overlay)
		original_transforms.append(node.transform)
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1, 0.85, 0.6)
	health.damaged.connect(_on_damaged)
	set_process(false)


func _on_damaged(_amount: float) -> void:
	if health.current <= 0:
		return
	remaining = duration
	_deform(1.0)
	for mesh in meshes:
		mesh.material_overlay = flash_material
	set_process(true)


func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	var weight := remaining / maxf(duration, 0.001)
	_deform(weight)
	if remaining <= 0.0:
		for index in range(meshes.size()):
			meshes[index].material_overlay = original_overlays[index]
		set_process(false)


func _deform(weight: float) -> void:
	# Never scale Visuals: it also owns the authoritative RifleMuzzle marker.
	# Imported skinned geometry gets the flash; squash only the static primitive
	# body fixtures. Animated mesh transforms and held weapons stay untouched.
	var squash := Basis.from_scale(Vector3.ONE.lerp(Vector3(1.08, 0.9, 1.08), weight))
	for index in range(meshes.size()):
		var mesh := meshes[index]
		if mesh.skin == null and mesh.get_parent() == visuals and mesh.name not in ["Rifle", "Blaster"]:
			mesh.transform = Transform3D(squash, Vector3.ZERO) * original_transforms[index]
