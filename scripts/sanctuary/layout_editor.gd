class_name LayoutEditor
extends Control
## Preview poses are presentation only. Confirmation saves one validated intent.
var sanctuary: Sanctuary
var rows: Array = []
var selected: String = ""
var definition: String = "cabinet"
var point := Vector2(4.5, 0)
var turn: int = 0
var ghost: Node3D
var feedback: Label
var camera_transform: Transform3D

func _ready() -> void:
	rows = sanctuary.session.stash.home_snapshot().layout.duplicate(true)
	# Inspect the marked area independently of the robot's last station position.
	camera_transform = sanctuary.robot.camera_rig.transform
	sanctuary.robot.camera_rig.top_level = true
	sanctuary.robot.camera_rig.global_transform = Transform3D(Basis.IDENTITY, Vector3(4.5, 1.6, 0))
	theme = ApplicationTheme.theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 110)
	panel.custom_minimum_size = Vector2(490, 0)
	add_child(panel)
	var body := VBoxContainer.new()
	panel.add_child(body)
	ApplicationTheme.label(body, "WORKSHOP LAYOUT · 0.5 m grid · Maximum 8 objects")
	var picker := OptionButton.new()
	for id in ["cabinet", "scrap_bin", "pallet_load"]:
		picker.add_item(PlaceableDefinition.find(id).display_name)
		picker.set_item_metadata(picker.item_count - 1, id)
	body.add_child(picker)
	picker.item_selected.connect(func(index: int) -> void:
		selected = ""
		definition = picker.get_item_metadata(index)
		refresh_ghost())
	var existing := OptionButton.new()
	existing.add_item("New object")
	existing.set_item_metadata(0, "")
	for row in rows:
		existing.add_item(PlaceableDefinition.find(row.definition).display_name + " · " + str(row.id).left(6))
		existing.set_item_metadata(existing.item_count - 1, row.id)
	body.add_child(existing)
	existing.item_selected.connect(func(index: int) -> void:
		selected = existing.get_item_metadata(index)
		for row in rows:
			if row.id == selected:
				definition = row.definition
				point = Vector2(row.x, row.z)
				turn = row.rotation
		refresh_ghost())
	ApplicationTheme.label(body, "Point at floor or use arrows · R rotates · Enter confirms\nEscape cancels. Routes and station anchors remain protected.")
	ApplicationTheme.button(body, "Rotate 90°", rotate_preview)
	ApplicationTheme.button(body, "Confirm and save", commit)
	ApplicationTheme.button(body, "Remove selected and save", remove_selected)
	ApplicationTheme.button(body, "Cancel", cancel)
	feedback = ApplicationTheme.label(body, "")
	refresh_ghost()

func proposed() -> Array:
	var result: Array = []
	for row in rows:
		if row.id != selected: result.append(row.duplicate(true))
	result.append({"id": selected if not selected.is_empty() else "preview", "definition": definition, "x": point.x, "z": point.y, "rotation": turn})
	return result

func refresh_ghost() -> void:
	if is_instance_valid(ghost):
		ghost.get_parent().remove_child(ghost)
		ghost.queue_free()
	ghost = load(PlaceableDefinition.find(definition).scene_path).instantiate()
	sanctuary.add_child(ghost)
	ghost.position = Vector3(point.x, 0, point.y)
	ghost.rotation.y = turn * PI / 2
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.9, 0.65, 0.55) if SanctuaryLayout.valid(proposed()) else Color(1, 0.25, 0.2, 0.55)
	for mesh in ghost.find_children("*", "MeshInstance3D", true, false): mesh.material_override = material
	if feedback != null: feedback.text = "Preview %.1f, %.1f · %d°" % [point.x, point.y, turn * 90]

func rotate_preview() -> void:
	turn = (turn + 1) % 4
	refresh_ghost()

func commit() -> void:
	var candidate := proposed()
	if selected.is_empty(): candidate[-1].id = Crypto.new().generate_random_bytes(16).hex_encode()
	if not sanctuary.placement_clear(candidate[-1], selected):
		feedback.text = "Placement intersects the robot or physical geometry."
		return
	finish_save(candidate)

func remove_selected() -> void:
	if selected.is_empty(): return
	var candidate: Array = []
	for row in rows:
		if row.id != selected: candidate.append(row)
	finish_save(candidate)

func finish_save(candidate: Array) -> void:
	var result := SanctuaryLayout.save(sanctuary.session.preparation, candidate)
	if not result.ok:
		feedback.text = result.get("reason", "Layout was not saved.")
		return
	sanctuary.rebuild_layout()
	cancel()

func cancel() -> void:
	if is_instance_valid(ghost): ghost.queue_free()
	sanctuary.transition(Sanctuary.Mode.WALKING)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera := get_viewport().get_camera_3d()
		var ray := camera.project_ray_origin(event.position)
		var direction := camera.project_ray_normal(event.position)
		var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(ray, direction)
		if hit != null:
			point = Vector2(snappedf(hit.x, 0.5), snappedf(hit.z, 0.5))
			refresh_ghost()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_ESCAPE: cancel()
		KEY_ENTER: commit()
		KEY_R: rotate_preview()
		KEY_LEFT: point.x -= 0.5
		KEY_RIGHT: point.x += 0.5
		KEY_UP: point.y -= 0.5
		KEY_DOWN: point.y += 0.5
		_: return
	get_viewport().set_input_as_handled()
	if is_inside_tree() and not is_queued_for_deletion(): refresh_ghost()

func _exit_tree() -> void:
	if is_instance_valid(ghost): ghost.queue_free()
	if is_instance_valid(sanctuary) and is_instance_valid(sanctuary.robot):
		sanctuary.robot.camera_rig.top_level = false
		sanctuary.robot.camera_rig.transform = camera_transform
