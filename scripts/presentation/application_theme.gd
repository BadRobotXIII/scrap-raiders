class_name ApplicationTheme
extends RefCounted

static func theme() -> Theme:
	var value := Theme.new()
	value.default_font_size = 17
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.23, 0.26) if state in ["hover", "focus"] else Color(0.07, 0.12, 0.15)
		style.border_color = Color(0.35, 0.7, 0.76) if state != "disabled" else Color(0.2, 0.25, 0.27)
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		value.set_stylebox(state, "Button", style)
	return value

static func panel(parent: Node, heading: String, width: float = 820) -> VBoxContainer:
	var panel_control := PanelContainer.new()
	parent.add_child(panel_control)
	panel_control.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel_control.offset_left = -width / 2
	panel_control.offset_right = width / 2
	panel_control.offset_top = -340
	panel_control.offset_bottom = 340
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.07, 0.99)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel_control.add_theme_stylebox_override("panel", style)
	panel_control.theme = theme()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_control.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = width - 64
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	return content

static func button(parent: Node, caption: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = caption
	control.pressed.connect(action)
	parent.add_child(control)
	return control

static func label(parent: Node, caption: String) -> Label:
	var control := Label.new()
	control.text = caption
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(control)
	return control
