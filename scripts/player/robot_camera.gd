class_name RobotCamera
extends Node3D
## Owns camera yaw/pitch; follows the body's translation through scene parenting.

@export var mouse_sensitivity: float = 0.0025
@export var shoulder_offset: float = 1.0
@export_range(-89.0, 0.0) var minimum_pitch_degrees: float = -60.0
@export_range(0.0, 89.0) var maximum_pitch_degrees: float = 25.0
@export var sanctuary_preset: bool = false

@onready var pitch_pivot: Node3D = $Pitch
@onready var spring_arm: SpringArm3D = $Pitch/SpringArm3D
@onready var camera: Camera3D = $Pitch/SpringArm3D/Camera3D


func _ready() -> void:
	var robot := get_parent() as CharacterBody3D
	spring_arm.add_excluded_object(robot.get_rid())
	var input_adapter := robot.get_node("Input") as RobotInput
	input_adapter.look_requested.connect(apply_look)
	process_physics_priority = 5
	if sanctuary_preset:
		shoulder_offset = 0
		minimum_pitch_degrees = -55
		maximum_pitch_degrees = -40
		pitch_pivot.rotation.x = deg_to_rad(-48)
		spring_arm.spring_length = 10


func _physics_process(_delta: float) -> void:
	# Keep the shoulder pivot on this side of walls before the rear arm sweeps.
	var desired := global_position + global_basis.x * shoulder_offset
	var query := PhysicsRayQueryParameters3D.create(global_position, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var offset := shoulder_offset
	if not hit.is_empty():
		offset = maxf(0.0, global_position.distance_to(hit.position) - 0.25)
	pitch_pivot.position.x = offset


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

func _unhandled_input(event: InputEvent) -> void:
	if not sanctuary_preset or not get_parent().input_adapter.gameplay_enabled: return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		spring_arm.spring_length = clampf(spring_arm.spring_length + (-0.75 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.75), 7, 14)
		get_viewport().set_input_as_handled()
