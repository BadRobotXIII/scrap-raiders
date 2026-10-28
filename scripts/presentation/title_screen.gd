class_name TitleScreen
extends Control
var session: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.025, 0.04, 0.055)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var content := ApplicationTheme.panel(self, "SCRAP Raiders", 640)
	ApplicationTheme.label(content, "BADROBOT STUDIOS\nEngineering Bad Behavior\n\nRecover. Rebuild. Return home.")
	var failed: bool = session.preparation == null
	ApplicationTheme.label(content, "Your workshop is always safe. Choose a path into the same preparation and extraction loop." if not failed else session.last_error)
	var enter := ApplicationTheme.button(content, "Enter Sanctuary", session.enter_sanctuary)
	enter.disabled = failed
	var quick := ApplicationTheme.button(content, "Quick Deploy", session.quick_prepare)
	quick.disabled = failed
	var settings := ApplicationTheme.button(content, "Settings", session.settings)
	settings.disabled = failed
	if failed: ApplicationTheme.button(content, "Retry profile", session.retry_profile)
	ApplicationTheme.button(content, "Quit", func() -> void: get_tree().quit())
	enter.grab_focus()
