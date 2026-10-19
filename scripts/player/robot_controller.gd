class_name RobotController
extends CharacterBody3D
## Sole owner of physical movement/velocity and the robot's visual facing.

@export var move_speed: float = 7.0
@export var acceleration: float = 45.0
@export var braking: float = 60.0
@export var turn_speed: float = 18.0

@onready var input_adapter: RobotInput = $Input
@onready var camera_rig: RobotCamera = $CameraRig
@onready var visuals: Node3D = $Visuals


func _physics_process(delta: float) -> void:
	var direction := camera_rig.movement_direction(input_adapter.move_intent)
	var target_velocity := direction * move_speed
	var rate := acceleration if direction.length_squared() > 0.0 else braking
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(
		Vector2(target_velocity.x, target_velocity.z), rate * delta
	)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()

	var facing := camera_rig.aim_direction() if input_adapter.aim_intent else direction
	if facing.length_squared() > 0.0001:
		var target_yaw := atan2(-facing.x, -facing.z)
		visuals.rotation.y = rotate_toward(visuals.rotation.y, target_yaw, turn_speed * delta)
