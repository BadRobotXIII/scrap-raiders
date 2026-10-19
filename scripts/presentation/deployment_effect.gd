extends Node3D
## Self-contained spawn presentation. Never reads or changes gameplay state.


func _ready() -> void:
	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	dust.amount = 28
	dust.lifetime = 1.0
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.7
	dust.direction = Vector3.UP
	dust.spread = 75.0
	dust.gravity = Vector3(0, -0.7, 0)
	dust.initial_velocity_min = 0.8
	dust.initial_velocity_max = 2.0
	dust.scale_amount_min = 0.2
	dust.scale_amount_max = 0.6
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.45, 0.5, 0.52, 0.2), Color(0.5, 0.55, 0.57, 0.18), Color(0.6, 0.65, 0.67, 0.0)])
	dust.color_ramp = gradient
	var dust_material := StandardMaterial3D.new()
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.vertex_color_use_as_albedo = true
	var particle_mesh := SphereMesh.new()
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	particle_mesh.material = dust_material
	dust.mesh = particle_mesh
	add_child(dust)
	dust.position.y = 0.15
	dust.restart()

	var ring := MeshInstance3D.new()
	ring.name = "ArrivalRing"
	ring.position.y = 0.08
	ring.scale = Vector3.ONE * 0.2
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color = Color(0.3, 0.85, 1.0, 0.65)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.8
	ring_mesh.outer_radius = 0.88
	ring_mesh.material = ring_material
	ring.mesh = ring_mesh
	add_child(ring)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(2.4, 1, 2.4), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_material, "albedo_color:a", 0.0, 0.8)
	get_tree().create_timer(1.3).timeout.connect(queue_free)
