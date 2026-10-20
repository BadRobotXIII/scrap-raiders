extends Label
## Reads traversal state; never changes movement, input, or camera transforms.

var robot: RobotController


func _ready() -> void:
	name = "TraversalFeedback"
	position = Vector2(24, 560)
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	visible = robot.is_physics_processing() and not robot.debug_movement_locked
	var status := "READY"
	match robot.boost_state:
		RobotController.BoostState.BOOSTING:
			status = "BOOSTING"
		RobotController.BoostState.COOLDOWN:
			status = "RECHARGING %.1fs" % robot.boost_remaining
	text = "[Space] Jump | [Shift] Boost: %s" % status
	modulate = Color(0.4, 1, 0.85) if robot.boost_state == RobotController.BoostState.BOOSTING else Color.WHITE
