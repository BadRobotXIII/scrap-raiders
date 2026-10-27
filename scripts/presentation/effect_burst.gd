class_name EffectBurst
extends Node3D
## Small batched, collision-free ballistic ribbons. Private seed; no gameplay RNG.

var count: int = 12
var lifetime: float = 0.36
var color: Color = Color(1, 0.65, 0.2)
var normal: Vector3 = Vector3.UP
var seed_value: int = 1
var age: float = 0
var velocities: Array[Vector3] = []
var geometry := ImmediateMesh.new()
var material := StandardMaterial3D.new()

func _ready() -> void:
	add_to_group("presentation_bursts")
	var mesh := MeshInstance3D.new()
	mesh.mesh = geometry
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if lifetime > 1:
		material.albedo_texture = preload("res://resources/presentation/soft_mote.tres")
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in range(count):
		var direction := normal.normalized() * random.randf_range(0.8, 2.3) + Vector3(random.randf_range(-1, 1), random.randf_range(-0.5, 1), random.randf_range(-1, 1))
		velocities.append(direction * (1.7 if lifetime < 1 else 0.35))
	_draw_ribbons()

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	else:
		_draw_ribbons()

func _draw_ribbons() -> void:
	geometry.clear_surfaces()
	geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var fade := 1.0 - age / lifetime
	for velocity in velocities:
		var point := velocity * age + Vector3.DOWN * age * age * (1.6 if lifetime < 1 else -0.2)
		var tail := point - velocity.normalized() * (0.08 if lifetime < 1 else 0.12)
		var side := velocity.cross(Vector3.FORWARD).normalized() * (0.012 if lifetime < 1 else 0.1 + age * 0.1)
		if side.is_zero_approx(): side = Vector3.RIGHT * 0.012
		geometry.surface_set_color(Color(color, fade * 0.85))
		var vertices := [point + side, point - side, tail - side, point + side, tail - side, tail + side]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]
		for index in range(vertices.size()):
			geometry.surface_set_uv(uvs[index])
			geometry.surface_add_vertex(vertices[index])
	geometry.surface_end()
