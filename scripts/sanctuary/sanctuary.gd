class_name Sanctuary
extends Node3D
enum Mode { WALKING, STATION, NAVIGATION, PLACEMENT }
var session: Node
var mode: Mode = Mode.WALKING
var registry := StationRegistry.new()
var robot: RobotController
var message: Label
var navigation: Control
var ui_layer: CanvasLayer
var placed: Node3D

func _ready() -> void:
	registry.sanctuary = self
	box("Floor", Vector3(20, 0.5, 16), Vector3(0, -0.25, 0), load("res://resources/materials/environment/concrete.tres"))
	var steel := load("res://resources/materials/environment/painted_steel_bluegray.tres")
	box("NorthWall", Vector3(20, 3.6, 0.3), Vector3(0, 1.8, -8), steel)
	box("SouthWall", Vector3(20, 3.6, 0.3), Vector3(0, 1.8, 8), steel)
	box("WestWall", Vector3(0.3, 3.6, 16), Vector3(-10, 1.8, 0), steel)
	box("EastWall", Vector3(0.3, 3.6, 16), Vector3(10, 1.8, 0), steel)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.09, 0.14, 0.18)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.68, 0.77, 0.85)
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -25, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	robot = preload("res://scenes/sanctuary/sanctuary_robot.tscn").instantiate() as RobotController
	robot.position = Vector3(0, 0.1, 2)
	add_child(robot)
	for child in robot.visuals.get_children():
		if child is MeshInstance3D: child.hide()
	robot.get_node("Visuals/ActorVisual").configure(robot)
	robot.get_node("CombatHUD").hide()
	robot.get_node("SurvivalHUD").hide()
	var ids := ["storage", "maintenance", "fabrication", "disassembly", "contracts", "deployment"]
	var names := ["Storage", "Robot maintenance", "Fabrication", "Disassembly", "Operations / Contracts", "Deployment"]
	for index in 6:
		var station := preload("res://scenes/sanctuary/workshop_station.tscn").instantiate() as WorkshopStation
		station.station_id = StringName(ids[index])
		station.context = station.station_id
		station.display_name = names[index]
		station.position = Vector3(-7 + (index % 3) * 7, 0, -6.5 if index < 3 else 6.5)
		if index < 3: station.rotation.y = PI
		station.available = session.stash.home_snapshot().station_unlocks.has(ids[index])
		add_child(station)
		registry.register(station)
		var mat := MeshInstance3D.new()
		var surface := BoxMesh.new()
		surface.size = Vector3(2.3, 0.015, 1.3)
		surface.material = load("res://resources/materials/environment/painted_steel_bluegray.tres")
		mat.mesh = surface
		mat.position = station.anchor() + Vector3(0, 0.012, 0)
		add_child(mat)
	# Existing visual-only utility runs connect stations; the protected aisle stays clear.
	for x in [-7.0, 0.0, 7.0]:
		var utility := preload("res://scenes/environment/props/utility_run_2m.tscn").instantiate() as Node3D
		utility.position = Vector3(x, 2.5, -7.4)
		add_child(utility)
	var sign := Label3D.new()
	sign.text = "THE SANCTUARY\nSAFE WORKSHOP"
	sign.position = Vector3(0, 3, -7.7)
	sign.font_size = 62
	add_child(sign)
	# Visual-only boundary for the later customization milestone, off the main aisle.
	for edge in [[Vector3(6, 0.02, 0.04), Vector3(4.5, 0.015, -2)], [Vector3(6, 0.02, 0.04), Vector3(4.5, 0.015, 2)], [Vector3(0.04, 0.02, 4), Vector3(1.5, 0.015, 0)], [Vector3(0.04, 0.02, 4), Vector3(7.5, 0.015, 0)]]:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = edge[0]
		mesh.material = load("res://resources/materials/environment/safety_yellow.tres")
		marker.mesh = mesh
		marker.position = edge[1]
		add_child(marker)
	placed = Node3D.new()
	placed.name = "PlacedObjects"
	add_child(placed)
	rebuild_layout()
	var display := preload("res://scenes/sanctuary/item_display.tscn").instantiate() as ItemDisplay
	display.preparation = session.preparation
	display.position = Vector3(-3.5, 0, -6.5)
	add_child(display)
	add_child(preload("res://scenes/presentation/sanctuary_atmosphere.tscn").instantiate())
	var overlay := CanvasLayer.new()
	add_child(overlay)
	ui_layer = overlay
	message = Label.new()
	message.position = Vector2(24, 20)
	message.custom_minimum_size.x = 1050
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 19)
	message.text = "THE SANCTUARY · Always safe\nWASD: walk · Mouse: orbit · Wheel: zoom · E: station · Tab: quick navigation · I: storage"
	overlay.add_child(message)
	if not session.last_error.is_empty(): message.text += "\n" + session.last_error
	transition(Mode.WALKING)

func box(caption: String, size_value: Vector3, at: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = caption
	body.position = at
	add_child(body)
	var shape := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = size_value
	shape.shape = volume
	body.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh.material = material
	visual.mesh = mesh
	body.add_child(visual)

func transition(next: Mode) -> void:
	mode = next
	robot.input_adapter.gameplay_enabled = mode == Mode.WALKING
	robot.input_adapter.clear_intent()
	robot.stop_traversal()
	robot.get_node("Weapon").enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == Mode.WALKING else Input.MOUSE_MODE_VISIBLE

func enter_station(station: WorkshopStation) -> void:
	transition(Mode.STATION)
	session.open_preparation(str(station.context), close_station)

func close_station() -> void:
	session.clear_panel()
	transition(Mode.WALKING)

func navigate(id: StringName) -> bool:
	if is_instance_valid(navigation):
		navigation.queue_free()
		navigation = null
	transition(Mode.WALKING)
	var opened := registry.open_station(id, true)
	if not opened: message.text = registry.last_error
	return opened

func open_navigation() -> void:
	if mode != Mode.WALKING: return
	transition(Mode.NAVIGATION)
	navigation = Control.new()
	ui_layer.add_child(navigation)
	navigation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := ApplicationTheme.panel(navigation, "Workshop navigation", 620)
	for id in registry.stations:
		var station: WorkshopStation = registry.stations[id]
		var button := ApplicationTheme.button(body, station.display_name, navigate.bind(id))
		button.disabled = not station.available
	ApplicationTheme.button(body, "Title screen", session.show_title)
	ApplicationTheme.button(body, "Item display", func() -> void:
		navigation.queue_free()
		navigation = null
		transition(Mode.WALKING)
		open_display(true))
	ApplicationTheme.button(body, "Arrange workshop", func() -> void:
		navigation.queue_free()
		navigation = null
		transition(Mode.PLACEMENT)
		var editor := LayoutEditor.new()
		editor.sanctuary = self
		ui_layer.add_child(editor))
	ApplicationTheme.button(body, "Close", func() -> void:
		navigation.queue_free()
		navigation = null
		transition(Mode.WALKING))

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if mode == Mode.WALKING:
		if event.physical_keycode == KEY_TAB: open_navigation()
		elif event.physical_keycode == KEY_I: navigate(&"storage")
		elif event.is_action_pressed("recover"):
			if robot.position.distance_to(Vector3(-3.5, 0, -6.5)) < 2.6:
				open_display(false)
				get_viewport().set_input_as_handled()
				return
			var station := registry.nearest()
			if station != null and not registry.open_station(station.station_id, false): message.text = registry.last_error
		else: return
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if robot != null and (robot.position.y < -2 or absf(robot.position.x) > 10 or absf(robot.position.z) > 8):
		robot.position = Vector3(0, 0.1, 2)
		robot.stop_traversal()

func rebuild_layout() -> void:
	for child in placed.get_children():
		placed.remove_child(child)
		child.queue_free()
	for row in session.stash.home_snapshot().layout:
		var definition := PlaceableDefinition.find(row.definition)
		var body := StaticBody3D.new()
		body.set_meta("layout_id", row.id)
		body.position = Vector3(row.x, 0, row.z)
		body.rotation.y = row.rotation * PI / 2
		placed.add_child(body)
		body.add_child(load(definition.scene_path).instantiate())
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = definition.dimensions
		collision.shape = shape
		collision.position.y = definition.dimensions.y / 2
		body.add_child(collision)

func placement_clear(row: Dictionary, replacing: String) -> bool:
	var definition := PlaceableDefinition.find(row.definition)
	if definition == null: return false
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = definition.dimensions + Vector3(0.05, -0.04, 0.05)
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.UP, row.rotation * PI / 2), Vector3(row.x, definition.dimensions.y / 2 + 0.03, row.z))
	query.collision_mask = 1 | 2 | 4
	var excluded: Array[RID] = []
	for child in placed.get_children():
		if child.get_meta("layout_id") == replacing: excluded.append(child.get_rid())
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func open_display(quick: bool) -> bool:
	if mode != Mode.WALKING: return false
	var anchor := Vector3(-3.5, 0.05, -4.7)
	var query := PhysicsRayQueryParameters3D.create(robot.position + Vector3.UP, anchor + Vector3.UP, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		message.text = "Display access is obstructed."
		return false
	if quick: robot.position = anchor
	elif robot.position.distance_to(Vector3(-3.5, 0, -6.5)) > 2.6: return false
	transition(Mode.STATION)
	session.open_preparation("display", close_station)
	return true
