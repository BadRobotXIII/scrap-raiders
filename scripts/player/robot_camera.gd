class_name RobotCamera
extends Node3D
## Owns camera yaw/pitch; follows the body's translation through scene parenting.

@export var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 0.0) var minimum_pitch_degrees: float = -60.0
@export_range(0.0, 89.0) var maximum_pitch_degrees: float = 25.0

@onready var pitch_pivot: Node3D = $Pitch
@onready var spring_arm: SpringArm3D = $Pitch/SpringArm3D
@onready var camera: Camera3D = $Pitch/SpringArm3D/Camera3D


func _ready() -> void:
	var robot := get_parent() as CharacterBody3D
	spring_arm.add_excluded_object(robot.get_rid())
	var input_adapter := robot.get_node("Input") as RobotInput
	input_adapter.look_requested.connect(apply_look)


func apply_look(relative_motion: Vector2) -> void:
	rotation.y = wrapf(rotation.y - relative_motion.x * mouse_sensitivity, -PI, PI)
	pitch_pivot.rotation.x = clampf(
		pitch_pivot.rotation.x - relative_motion.y * mouse_sensitivity,
		deg_to_rad(minimum_pitch_degrees), deg_to_rad(maximum_pitch_degrees)
	)


func movement_direction(intent: Vector2) -> Vector3:
	return global_basis * Vector3(intent.x, 0.0, intent.y)


func aim_direction() -> Vector3:
	return -global_basis.z
