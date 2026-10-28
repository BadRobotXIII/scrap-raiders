extends "res://tests/inventory_world_test.gd"
## Actual workshop collision, station entry, shared paths and save failures.

func run() -> void:
	root.size = Vector2i(1600, 900)
	var app: Node = load("res://scenes/application/application.tscn").instantiate()
	var session: GameSession = app.get_node("GameSession")
	session.profile_path = test_directory + "/sanctuary.json"
	root.add_child(app)
	current_scene = app
	session.enter_sanctuary()
	await frames(8)
	var home := session.active_scene as Sanctuary
	check(home.registry.stations.size() == 6 and home.robot.camera_rig.sanctuary_preset, "Home provides six stable station identities and an opt-in elevated camera")
	home.robot.input_adapter.set_physics_process(false)
	home.robot.input_adapter.move_intent = Vector2(1, 0)
	var origin := home.robot.position
	await frames(20)
	check(home.robot.position.distance_to(origin) > 0.5 and home.robot.is_on_floor(), "Existing physical controller walks on the workshop floor")
	home.robot.input_adapter.clear_intent()
	for id in home.registry.stations:
		var station: WorkshopStation = home.registry.stations[id]
		check(home.registry.anchor_valid(station), "Station anchor has a clear standing capsule and protected route: " + str(id))
	var storage: WorkshopStation = home.registry.stations[&"storage"]
	home.robot.position = storage.anchor() + Vector3.UP * 0.05
	await frames(4)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode = KEY_E
	key.pressed = true
	root.push_input(key)
	await frames(3)
	check(home.mode == Sanctuary.Mode.STATION and session.panel.inventory_view != null, "Real physical E opens the same inventory view at a registered station")
	var prepared_id: String = session.stash.inventory.records("prepared")[0].id
	session.panel.inventory_view.select(prepared_id)
	session.panel.inventory_view.perform("Transfer")
	var physically_stored := semantic(session.stash.inventory)
	home.close_station()
	check(home.mode == Sanctuary.Mode.WALKING and home.robot.input_adapter.gameplay_enabled, "Closing a station returns control at its safe anchor")
	home.navigate(&"maintenance")
	await frames(3)
	var loadouts: LoadoutView
	for child in session.panel.body.get_children():
		if child is LoadoutView: loadouts = child
	loadouts.name_field.text = "Scout "
	loadouts.name_field.caret_column = loadouts.name_field.text.length()
	loadouts.name_field.grab_focus()
	var typed := InputEventKey.new()
	typed.physical_keycode = KEY_I
	typed.keycode = KEY_I
	typed.unicode = 105
	typed.pressed = true
	root.push_input(typed)
	await frames(2)
	check(is_instance_valid(session.panel) and loadouts.name_field.text == "Scout i", "Typing a template name cannot activate the inventory-close hotkey")
	home.close_station()
	session.show_title()
	session.quick_prepare()
	await frames(4)
	session.open_preparation("storage", session.show_title)
	session.panel.inventory_view.select(prepared_id)
	session.panel.inventory_view.perform("Equip / Unequip")
	session.panel.inventory_view.perform("Transfer")
	check(semantic(session.stash.inventory) == physically_stored, "Equivalent physical-home and Quick Deploy operations produce identical item/slot outcomes")
	session.show_title()
	session.enter_sanctuary()
	await frames(5)
	home = session.active_scene as Sanctuary
	storage = home.registry.stations[&"storage"]
	var obstacle := StaticBody3D.new()
	obstacle.position = storage.anchor() + Vector3.UP
	home.add_child(obstacle)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 2)
	collision.shape = shape
	obstacle.add_child(collision)
	await frames(3)
	var before := home.robot.position
	check(not home.navigate(&"storage") and home.robot.position == before, "Blocked quick anchors reject without teleporting or changing ownership")
	check(not home.robot.get_node("Health").apply_damage(50) and home.robot.get_node("Health").current == 100 and not home.robot.get_node("Weapon").enabled, "Home refuses authoritative damage and fire even with equipped weapons")
	check(session.stash.inventory.is_valid(), "Station navigation and both preparation paths conserve inventory")
	app.queue_free()
	await frames(20)
	print("Sanctuary failures: ", failures)
	quit(1 if failures else 0)

func semantic(authority: InventoryLedger) -> Array:
	var rows: Array = []
	for item in authority.records():
		if item.container in ["stash", "prepared"]: rows.append([item.id, item.definition, item.quantity, item.container, item.slot])
	return rows
