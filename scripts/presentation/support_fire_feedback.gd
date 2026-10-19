extends Node
## Cosmetic shot cue only; weapon execution owns all hits and damage.


func show_shot(origin: Vector3, endpoint: Vector3, _damaged: bool) -> void:
	var tracer := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.3, 1, 0.6)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(origin)
	mesh.surface_add_vertex(endpoint)
	mesh.surface_end()
	tracer.mesh = mesh
	get_parent().get_parent().add_child(tracer)
	get_tree().create_timer(0.08).timeout.connect(tracer.queue_free)
