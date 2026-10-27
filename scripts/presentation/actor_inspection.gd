extends Node3D
## Presentation-only preview. There are no gameplay actors or simulation systems.

const TITLES: Array[String] = ["Raider A / idle", "Raider B / walk", "Raider C / run", "Player machine", "Ground support", "Flying scout"]
@onready var camera: Camera3D = $Camera3D
@onready var previews: Array[ActorVisual] = [$RaiderA, $RaiderB, $RaiderC, $PlayerMachine, $GroundMachine, $FlyingScout]
var paused: bool = false
var selected: int = -1
var status: Label
var world_labels: Array[Label3D] = []
var presentation: MissionPresentation
var demo_feedback: Array[WeaponFeedback] = []
var demo_muzzles: Array[Node3D] = []
var terminal: Node3D
var repeat_demo: bool = false
var repeat_remaining: float = 0
var fire_button: Button


func _ready() -> void:
	presentation = MissionPresentation.new()
	presentation.name = "Presentation"
	add_child(presentation)
	for index in range(previews.size()):
		var muzzle := Marker3D.new()
		muzzle.position = Vector3(0.35, 1.15, -0.7) if index < 3 else (Vector3(0.6, 1.15, -0.7) if index == 3 else Vector3(0, 0.7, -0.65))
		previews[index].add_child(muzzle)
		demo_muzzles.append(muzzle)
		var feedback := WeaponFeedback.new()
		add_child(feedback)
		if index < 5: feedback.configure_preview(muzzle, presentation, &"raider" if index < 3 else (&"player" if index == 3 else &"ground_machine"), index + 87017)
		demo_feedback.append(feedback)
	for index in range(3):
		var visual_id: StringName
		for candidate in range(24):
			var value := StringName("inspection_%d" % candidate)
			if ActorVisual.appearance_for(87017, value) == index:
				visual_id = value
				break
		previews[index].configure(null, null, 87017, visual_id)
		previews[index].set_armed(true)
		previews[index].set_cargo(1)
	_add_grid()
	_add_controls()
	select_view(-1)


func _add_grid() -> void:
	var lines := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.28, 0.33, 0.36)
	lines.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for x in range(-7, 8):
		lines.surface_add_vertex(Vector3(x, 0.003, -7))
		lines.surface_add_vertex(Vector3(x, 0.003, 4))
	for z in range(-7, 5):
		lines.surface_add_vertex(Vector3(-7, 0.003, z))
		lines.surface_add_vertex(Vector3(7, 0.003, z))
	lines.surface_end()
	var grid := MeshInstance3D.new()
	grid.name = "MetreGrid"
	grid.mesh = lines
	grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grid)
	for index in range(previews.size()):
		var label := Label3D.new()
		label.text = "%d  %s" % [index + 1, TITLES[index]]
		label.position = previews[index].position + Vector3.UP * (2.18 if index < 4 else 1.7)
		label.font_size = 30
		label.pixel_size = 0.004
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = false
		add_child(label)
		world_labels.append(label)


func _add_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PreviewControls"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "ACTOR / COMBAT PRESENTATION INSPECTION"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	var explanation := Label.new()
	explanation.text = "1 m grid. Original models; appearance does not identify AI personality.\n0: overview  |  1-6: close view  |  arrows: turn selected model  |  Space: pause preview"
	column.add_child(explanation)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	var overview := Button.new()
	overview.text = "0  Overview"
	overview.focus_mode = Control.FOCUS_NONE
	overview.pressed.connect(select_view.bind(-1))
	buttons.add_child(overview)
	for index in range(TITLES.size()):
		var button := Button.new()
		button.text = "%d  %s" % [index + 1, TITLES[index]]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_view.bind(index))
		buttons.add_child(button)
	status = Label.new()
	column.add_child(status)
	var effects := HBoxContainer.new()
	column.add_child(effects)
	for cue in ["Fire", "Metal", "Concrete", "Armor", "Damage", "Destroy", "Reset", "Motor", "Repeat"]:
		var button := Button.new()
		button.text = cue
		if cue == "Fire": fire_button = button
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(demonstrate.bind(cue))
		effects.add_child(button)


func select_view(index: int) -> void:
	reset_demo()
	selected = index
	fire_button.disabled = index == 5
	for label in world_labels:
		label.visible = index < 0
	if index < 0:
		camera.position = Vector3(6.4, 5.0, -11.5)
		camera.look_at(Vector3(0, 0.8, -1.5))
		camera.fov = 48.0
	else:
		var target := previews[index].position + Vector3.UP * (0.95 if index < 4 else 0.65)
		camera.position = target + Vector3(1.8, 0.7, -3.4)
		camera.look_at(target)
		camera.fov = 43.0
	_refresh_status()

func reset_demo() -> void:
	if is_instance_valid(terminal): terminal.queue_free()
	for feedback in demo_feedback: feedback.stop()
	for preview in previews: preview.show()
	if presentation != null:
		for burst in presentation.bursts:
			if is_instance_valid(burst): burst.queue_free()
		presentation.bursts.clear()
		for player in presentation.spatial:
			player.stop()
			player.stream = null

func demonstrate(cue: String) -> void:
	var index := maxi(0, selected)
	var preview := previews[index]
	var kind: StringName = &"raider" if index < 3 else preview.kind
	var origin := demo_muzzles[index].global_position
	if cue == "Repeat":
		repeat_demo = not repeat_demo
		return
	if cue == "Reset":
		repeat_demo = false
		reset_demo()
		return
	if cue == "Fire" and index < 5:
		preview.present_fire()
		demo_feedback[index]._on_fired(origin, origin + preview.global_basis * Vector3(0, 0, -2), false)
	elif cue in ["Metal", "Concrete", "Armor"]:
		presentation.impact(preview.global_position + Vector3(0, 1, -1.4), Vector3.UP, &"machine_armor" if cue == "Armor" else StringName(cue.to_lower()), Vector3.DOWN)
	elif cue == "Damage":
		preview.present_damage()
		presentation.play_spatial("actors/raider_hurt" if kind == &"raider" else "actors/machine_hurt", preview.global_position)
	elif cue == "Destroy":
		reset_demo()
		terminal = preview.create_death_visual()
		if terminal != null:
			presentation.add_child(terminal)
			terminal.global_transform = preview.global_transform
			preview.hide()
		presentation.destruction(preview.global_position, kind)
	elif cue == "Motor" and kind != &"raider":
		presentation.play_spatial("machines/" + ({&"player": "player_servo_loop", &"ground_machine": "guard_drive_loop", &"flying_scout": "scout_rotor_loop"}[kind]), preview.global_position, &"Machines", -26)
	_refresh_status()

func _process(delta: float) -> void:
	if not repeat_demo or paused: return
	repeat_remaining -= delta
	if repeat_remaining <= 0:
		repeat_remaining = 0.5
		demonstrate("Fire" if selected < 5 else "Armor")


func _refresh_status() -> void:
	status.text = "%s  /  %s" % ["Overview" if selected < 0 else TITLES[selected], "Presentation paused" if paused else "Presentation running"]


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_0:
		select_view(-1)
	elif key.physical_keycode >= KEY_1 and key.physical_keycode <= KEY_6:
		select_view(key.physical_keycode - KEY_1)
	elif key.physical_keycode == KEY_SPACE:
		paused = not paused
		for preview in previews:
			preview.set_process(not paused)
		_refresh_status()
	elif selected >= 0 and key.physical_keycode in [KEY_LEFT, KEY_RIGHT]:
		previews[selected].rotate_y(deg_to_rad(15.0 if key.physical_keycode == KEY_LEFT else -15.0))
