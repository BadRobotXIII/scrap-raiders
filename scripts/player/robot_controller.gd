class_name RobotController
extends CharacterBody3D
## Sole owner of physical movement/velocity and the robot's visual facing.

@export var move_speed: float = 7.0
@export var acceleration: float = 45.0
@export var braking: float = 60.0
@export var turn_speed: float = 18.0
@export var traversal_enabled: bool = false
@export var jump_height: float = 1.5
@export var boost_speed: float = 16.0
@export var boost_duration: float = 0.25
@export var boost_cooldown: float = 1.5

enum BoostState { READY, BOOSTING, COOLDOWN }
var boost_state: BoostState = BoostState.READY
var boost_remaining: float = 0.0
var boost_direction: Vector3 = Vector3.ZERO

@onready var input_adapter: RobotInput = $Input
@onready var camera_rig: RobotCamera = $CameraRig
@onready var visuals: Node3D = $Visuals


func _ready() -> void:
	input_adapter.intents_cleared.connect(cancel_boost)


func transition_boost(next: BoostState) -> void:
	boost_state = next
	match next:
		BoostState.READY:
			boost_remaining = 0
		BoostState.BOOSTING:
			boost_remaining = boost_duration
		BoostState.COOLDOWN:
			boost_remaining = boost_cooldown


func cancel_boost() -> void:
	if boost_state == BoostState.BOOSTING:
		transition_boost(BoostState.COOLDOWN)


func stop_traversal() -> void:
	transition_boost(BoostState.READY)
	boost_direction = Vector3.ZERO
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	var direction := camera_rig.movement_direction(input_adapter.move_intent)
	var jump := input_adapter.jump_requested
	var boost := input_adapter.boost_requested
	input_adapter.jump_requested = false
	input_adapter.boost_requested = false
	if boost_state != BoostState.READY:
		boost_remaining = maxf(0, boost_remaining - delta)
		if boost_remaining <= 0.00001:
			transition_boost(BoostState.COOLDOWN if boost_state == BoostState.BOOSTING else BoostState.READY)
	if traversal_enabled:
		if jump and is_on_floor():
			velocity.y = sqrt(2.0 * get_gravity().length() * jump_height)
		if boost and boost_state == BoostState.READY:
			boost_direction = direction.normalized() if not direction.is_zero_approx() else camera_rig.aim_direction()
			transition_boost(BoostState.BOOSTING)
	var target_velocity := direction * move_speed
	var rate := acceleration if direction.length_squared() > 0.0 else braking
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(
		Vector2(target_velocity.x, target_velocity.z), rate * delta
	)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if traversal_enabled and boost_state == BoostState.BOOSTING:
		velocity.x = boost_direction.x * boost_speed
		velocity.z = boost_direction.z * boost_speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()

	var facing := camera_rig.aim_direction() if input_adapter.aim_intent or input_adapter.fire_intent else direction
	if facing.length_squared() > 0.0001:
		var target_yaw := atan2(-facing.x, -facing.z)
		visuals.rotation.y = rotate_toward(visuals.rotation.y, target_yaw, turn_speed * delta)
