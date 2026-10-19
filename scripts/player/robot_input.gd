class_name RobotInput
extends Node
## Translates devices into intent. Movement execution never reads Input directly.

signal look_requested(relative_motion: Vector2)

var move_intent: Vector2 = Vector2.ZERO
var aim_intent: bool = false


func _ready() -> void:
	process_physics_priority = -20
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		clear_intent()
		return
	move_intent = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	aim_intent = Input.is_action_pressed("aim")


func _input(event: InputEvent) -> void:
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
