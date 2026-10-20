class_name PostDeathSpectator
extends Node
## Player permissions/selection only; shared rig owns camera motion. No actor writes.

var arena: Node3D
var active: bool = false
var selected: Node3D
var preferred_id: int = 0
var yaw: float = 0
var pitch: float = -0.25
var choice: PanelContainer
var indicator: Label
var return_button: Button
var view: SpectatorCamera


func _ready() -> void:
	view = arena.spectator_view
	choice = PanelContainer.new()
	choice.name = "PostDeathChoice"
	arena.get_node("Overlay").add_child(choice)
	choice.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	choice.offset_left = -260
	choice.offset_right = 260
	choice.offset_top = -130
	choice.offset_bottom = 130
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	choice.add_child(content)
	var title := Label.new()
	title.text = "ROBOT DESTROYED\nDeployment failed. Carried loot forfeited.\nThe world continues; spectating cannot earn rewards."
	content.add_child(title)
	var watch := Button.new()
	watch.text = "Spectate"
	watch.pressed.connect(enter)
	content.add_child(watch)
	var back := Button.new()
	back.text = "Return"
	back.pressed.connect(return_to_summary)
	content.add_child(back)
	choice.hide()
	indicator = Label.new()
	indicator.position = Vector2(24, 24)
	indicator.add_theme_color_override("font_outline_color", Color.BLACK)
	indicator.add_theme_constant_override("outline_size", 4)
	indicator.add_theme_font_size_override("font_size", 20)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.get_node("Overlay").add_child(indicator)
	indicator.hide()
	return_button = Button.new()
	return_button.position = Vector2(24, 92)
	return_button.text = "Return (Esc)"
	return_button.pressed.connect(return_to_summary)
	arena.get_node("Overlay").add_child(return_button)
	return_button.hide()
	set_physics_process(false)


func eligible(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion():
		return false
	if actor is Raider:
		return arena.raiders.get(actor.raider_id) == actor and actor.health.current > 0 and arena.ledger.is_active(actor.raider_id) and actor.state not in [Raider.State.DEAD, Raider.State.EXTRACTED]
	return actor is SupportMachine and arena.ecosystem != null and arena.ecosystem.machines.has(actor) and actor.health.current > 0 and actor.active


func candidates() -> Array[Node3D]:
	var result: Array[Node3D] = []
	var ids: Array = arena.raiders.keys()
	ids.sort()
	for id in ids:
		var actor = arena.raiders[id]
		if is_instance_valid(actor) and eligible(actor):
			result.append(actor)
	if arena.ecosystem != null:
		var machines: Array = arena.ecosystem.machines.duplicate()
		machines.sort_custom(func(a: SupportMachine, b: SupportMachine) -> bool: return a.source_id < b.source_id)
		for actor in machines:
			if eligible(actor):
				result.append(actor)
	return result


func offer() -> void:
	preferred_id = arena.robot.get_node("Health").last_damage_instigator_id
	choice.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func enter() -> bool:
	if active or not arena.mission.player_destroyed or arena.mission.is_world_finished():
		return false
	choice.hide()
	arena.summary.hide()
	arena.robot.get_node("SurvivalHUD").hide()
	if arena.recall != null:
		arena.recall.stash_label.hide()
	view.follow_mode()
	selected = null
	var killer: Object = instance_from_id(preferred_id) if preferred_id > 0 else null
	if killer is Raider and eligible(killer):
		selected = killer
	else:
		cycle(1)
	active = true
	view.camera.make_current()
	indicator.show()
	return_button.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	step()
	set_physics_process(true)
	return true


func cycle(direction: int) -> void:
	var options := candidates()
	if options.is_empty():
		selected = null
		return
	var index := options.find(selected) if is_instance_valid(selected) else -1
	selected = options[posmod(index + direction, options.size())] if index >= 0 else options[0 if direction > 0 else options.size() - 1]


func step() -> void:
	if arena.mission.is_world_finished():
		arena.finish_mission()
		return
	if not is_instance_valid(selected) or not eligible(selected):
		cycle(1)
	if is_instance_valid(selected):
		view.follow_actor(selected)
		view.look(yaw, pitch, true)
		var title := "Raider R%02d" % selected.raider_id if selected is Raider else ("Scout" if selected.flying else "Guard")
		indicator.text = "SPECTATING %s | Deployment failed\nTab / Shift+Tab: cycle | Hold RMB + mouse: orbit | Esc: Return" % title
	else:
		indicator.text = "SPECTATING | Waiting for surviving actors or pending arrivals\nDeployment failed | Esc: Return"


func stop() -> void:
	active = false
	selected = null
	set_physics_process(false)
	choice.hide()
	indicator.hide()
	return_button.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	arena.robot.camera_rig.camera.make_current()


func return_to_summary() -> void:
	if not arena.mission.player_destroyed:
		return
	arena.mission.stop_world("Observation ended by player.")
	arena.finish_mission()


func _physics_process(_delta: float) -> void:
	step()


func _input(event: InputEvent) -> void:
	if not arena.mission.player_destroyed or arena.mission.is_world_finished():
		return
	if event.is_action_pressed("pause"):
		return_to_summary()
		get_viewport().set_input_as_handled()
	elif active and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		cycle(-1 if event.shift_pressed else 1)
		step()
		get_viewport().set_input_as_handled()
	elif active and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw = wrapf(yaw - event.screen_relative.x * 0.0025, -PI, PI)
		pitch = clampf(pitch - event.screen_relative.y * 0.0025, deg_to_rad(-65), deg_to_rad(35))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	if active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
