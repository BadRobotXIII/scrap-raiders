class_name SpectatorCamera
extends Node3D
## Shared camera motion only. Callers own eligibility and input permissions.

var camera: Camera3D
var arm: SpringArm3D


func _ready() -> void:
	arm = SpringArm3D.new()
	arm.collision_mask = 1
	arm.margin = 0.15
	add_child(arm)
	camera = Camera3D.new()
	camera.current = false
	arm.add_child(camera)
	free_mode()


func free_mode() -> void:
	var previous := camera.global_transform
	camera.reparent(self)
	camera.global_transform = previous
	arm.set_physics_process(false)


func follow_mode() -> void:
	camera.reparent(arm)
	camera.transform = Transform3D.IDENTITY
	arm.spring_length = 5
	arm.set_physics_process(true)


func look(yaw: float, pitch: float, orbit: bool) -> void:
	if orbit:
		global_rotation = Vector3(pitch, yaw, 0)
	else:
		camera.global_rotation = Vector3(pitch, yaw, 0)


func translate_view(offset: Vector3) -> void:
	camera.global_position += offset


func follow_actor(actor: Node3D) -> void:
	global_position = actor.global_position + Vector3.UP * 1.3
	arm.clear_excluded_objects()
	if actor is CollisionObject3D:
		arm.add_excluded_object(actor.get_rid())
