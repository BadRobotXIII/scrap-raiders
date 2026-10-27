class_name RobotInput
extends Node
## Translates devices into intent. Movement execution never reads Input directly.

signal look_requested(relative_motion: Vector2)
signal intents_cleared

var move_intent: Vector2 = Vector2.ZERO
var aim_intent: bool = false
var fire_intent: bool = false
var pickup_intent: bool = false
var recover_held: bool = false
var jump_requested: bool = false
var boost_requested: bool = false
var gameplay_enabled: bool = true
var suppress_fire_until_release: bool = false


func _ready() -> void:
	process_physics_priority = -20
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	if not gameplay_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		clear_intent()
		return
	move_intent = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	aim_intent = Input.is_action_pressed("aim")
	if not Input.is_action_pressed("fire"): suppress_fire_until_release = false
	fire_intent = Input.is_action_pressed("fire") and not suppress_fire_until_release
	pickup_intent = Input.is_action_just_pressed("recover")
	recover_held = Input.is_action_pressed("recover")
	jump_requested = Input.is_action_just_pressed("jump")
	boost_requested = Input.is_action_just_pressed("boost")


func _input(event: InputEvent) -> void:
	if not gameplay_enabled:
		return
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		clear_intent()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_requested.emit(event.screen_relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		clear_intent()


func clear_intent() -> void:
	move_intent = Vector2.ZERO
	aim_intent = false
	fire_intent = false
	pickup_intent = false
	recover_held = false
	jump_requested = false
	boost_requested = false
	intents_cleared.emit()
