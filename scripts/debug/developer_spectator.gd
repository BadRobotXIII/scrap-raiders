class_name DeveloperSpectator
extends Node3D
## Debug-only view/input routing. Never supplies a world position to gameplay.

@export var move_speed: float = 10.0
@export var fast_multiplier: float = 4.0
@export var mouse_sensitivity: float = 0.0025
var arena: Node3D
var active: bool = false
var camera: Camera3D
var indicator: Label
var yaw: float = 0
var pitch: float = 0
var selected: Raider
var following: bool = false
var follow_position: Vector3
var previous_mouse_mode: Input.MouseMode
var previous_gameplay_enabled: bool
var previous_weapon_enabled: bool
var previous_camera_processing: bool
var previous_combat_hud: bool


func _ready() -> void:
	name = "DeveloperSpectator"
	if not OS.is_debug_build():
		set_process(false)
		set_process_input(false)
		return
	camera = arena.spectator_view.camera
	indicator = Label.new()
	indicator.name = "SpectatorIndicator"
	indicator.position = Vector2(760, 300)
	indicator.add_theme_font_size_override("font_size", 16)
	indicator.add_theme_color_override("font_outline_color", Color.BLACK)
	indicator.add_theme_constant_override("outline_size", 4)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.hide()
	arena.get_node("Overlay").add_child(indicator)
	set_process(false)


func enter() -> bool:
	if not OS.is_debug_build() or active or arena.mission.is_finished() or arena.robot.get_node("Health").current <= 0:
		return false
	var robot: RobotController = arena.robot
	previous_mouse_mode = Input.mouse_mode
	previous_gameplay_enabled = robot.input_adapter.gameplay_enabled
	previous_weapon_enabled = robot.get_node("Weapon").enabled
	previous_camera_processing = robot.camera_rig.is_physics_processing()
	previous_combat_hud = robot.get_node("CombatHUD").visible
	robot.input_adapter.gameplay_enabled = false
	robot.input_adapter.clear_intent()
	robot.debug_movement_locked = true
	robot.get_node("Weapon").enabled = false
	robot.get_node("CombatHUD").hide()
	robot.camera_rig.set_physics_process(false)
	arena.spectator_view.free_mode()
	camera.global_transform = robot.camera_rig.camera.global_transform
	camera.fov = robot.camera_rig.camera.fov
	camera.near = robot.camera_rig.camera.near
	yaw = camera.global_rotation.y
	pitch = camera.global_rotation.x
	camera.make_current()
	active = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	indicator.show()
	refresh_indicator()
	set_process(true)
	return true


func leave(restore_controls: bool = true) -> void:
	if not active:
		return
	active = false
	following = false
	selected = null
	set_process(false)
	indicator.hide()
	var robot: RobotController = arena.robot
	robot.camera_rig.camera.make_current()
	robot.debug_movement_locked = false
	robot.input_adapter.clear_intent()
	robot.camera_rig.set_physics_process(previous_camera_processing)
	if restore_controls and not arena.mission.is_finished() and robot.get_node("Health").current > 0:
		robot.input_adapter.gameplay_enabled = previous_gameplay_enabled
		robot.get_node("Weapon").enabled = previous_weapon_enabled
		robot.get_node("CombatHUD").visible = previous_combat_hud
		Input.mouse_mode = previous_mouse_mode
	else:
		robot.input_adapter.gameplay_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func apply_look(relative: Vector2) -> void:
	yaw = wrapf(yaw - relative.x * mouse_sensitivity, -PI, PI)
	pitch = wrapf(pitch - relative.y * mouse_sensitivity, -PI, PI)
	arena.spectator_view.look(yaw, pitch, false)


func fly(intent: Vector2, vertical: float, fast: bool, delta: float) -> void:
	# Yaw-relative horizontal translation remains usable when looking vertically.
	var direction := Basis(Vector3.UP, yaw) * Vector3(intent.x, 0, intent.y) + Vector3.UP * vertical
	arena.spectator_view.translate_view(direction.limit_length() * move_speed * (fast_multiplier if fast else 1.0) * delta)


func select_next() -> void:
	var candidates: Array[Raider] = []
	for actor in arena.raiders.values():
		if is_instance_valid(actor) and actor.health.current > 0 and actor.state != Raider.State.EXTRACTED:
			candidates.append(actor)
	if candidates.is_empty():
		selected = null
		following = false
		return
	var index := candidates.find(selected) if is_instance_valid(selected) else -1
	selected = candidates[(index + 1) % candidates.size()]
	follow_position = selected.global_position


func follow_step() -> void:
	if not is_instance_valid(selected) or selected.health.current <= 0 or selected.state == Raider.State.EXTRACTED:
		selected = null
		following = false
		return
	if following:
		arena.spectator_view.translate_view(selected.global_position - follow_position)
	follow_position = selected.global_position


func _process(delta: float) -> void:
	follow_step()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var horizontal := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var vertical := float(Input.is_physical_key_pressed(KEY_SPACE)) - float(Input.is_physical_key_pressed(KEY_CTRL))
		fly(horizontal, vertical, Input.is_physical_key_pressed(KEY_SHIFT), delta)
	refresh_indicator()


func refresh_indicator() -> void:
	if not arena.debug_visible:
		indicator.text = "DEV SPECTATOR | F1 exit | F3 show debug HUD | Robot vulnerable"
		return
	indicator.text = "DEV SPECTATOR [F1] exit | Robot remains vulnerable\nWASD fly | Space/Ctrl up/down | Shift fast\nMouse look | Esc release | Click capture\nTab inspect next Raider | F follow: %s | F3 debug" % ("ON" if following else "OFF")
	if is_instance_valid(selected):
		var objective := str(selected.salvage.name) if is_instance_valid(selected.salvage) else "none"
		var target := str(selected.current_target().name) if is_instance_valid(selected.current_target()) else "none"
		var exit_name := str(selected.extraction.name) if is_instance_valid(selected.extraction) else "none"
		indicator.text += "\nR%02d %s | %s | cargo %d\nTarget: %s | Salvage: %s\nExit: %s | Navigation: %s\nRelationships: not implemented" % [selected.raider_id, selected.profile.display_name if selected.profile != null else "Legacy", Raider.State.keys()[selected.state], selected.carried_materials, target, objective, exit_name, selected.navigation_status]
		if arena.social != null:
			indicator.text = indicator.text.replace("Relationships: not implemented", arena.social.describe(selected))
			indicator.text += "\nTarget reason: %s" % selected.target_reason


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		if active:
			leave()
		else:
			enter()
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.screen_relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			select_next()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F:
			if not is_instance_valid(selected):
				select_next()
			following = not following and is_instance_valid(selected)
			if following:
				follow_position = selected.global_position
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	if active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
