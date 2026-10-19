extends Node
## Spawns a cosmetic physics copy. No health, loot, navigation, or gameplay collision.

@export var health: Health
@export var visuals: Node3D
@export var body_collision: CollisionShape3D
@export_range(0.1, 10.0) var lifetime: float = 4.0
@export var launch_velocity: Vector3 = Vector3(1.8, 4.0, 1.2)


func _ready() -> void:
	assert(health != null and visuals != null and body_collision != null)
	health.died.connect(_on_died)


func _on_died() -> void:
	var source := health.get_parent() as Node3D
	var world := source.get_parent() as Node3D
	var body := RigidBody3D.new()
	body.name = "DeathTumble"
	body.add_to_group("death_tumbles")
	# Environment can stop the copy, but gameplay queries/characters ignore it.
	body.collision_layer = 0
	body.collision_mask = 1
	body.mass = 8.0
	body.linear_damp = 0.4
	body.angular_damp = 0.7
	body.linear_velocity = launch_velocity
	body.angular_velocity = Vector3(3.0, 1.5, 2.0)
	body.transform = world.global_transform.affine_inverse() * body_collision.global_transform
	var collision := CollisionShape3D.new()
	collision.shape = body_collision.shape.duplicate() as Shape3D
	body.add_child(collision)

	var source_meshes: Array[Node] = visuals.find_children("*", "MeshInstance3D", true, false)
	if visuals is MeshInstance3D:
		source_meshes.append(visuals)
	for node in source_meshes:
		var original := node as MeshInstance3D
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh
		copy.material_override = original.material_override
		copy.cast_shadow = original.cast_shadow
		copy.transform = body_collision.global_transform.affine_inverse() * original.global_transform
		body.add_child(copy)

	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(body.queue_free)
	body.add_child(timer)
	world.add_child(body)
