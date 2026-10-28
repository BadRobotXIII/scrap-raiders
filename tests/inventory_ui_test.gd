extends "res://tests/inventory_world_test.gd"
## Controls and permission transitions with a live physical world.

func run() -> void:
	root.size = Vector2i(1600, 900)
	var arena := create_arena("ui")
	await frames(10)
	var mode: PlayerInteractionMode = arena.interaction_mode
	check(mode.open_inventory() and mode.view.visible and mode.view.cargo_grid.get_child_count() == 12 and mode.view.equipment_box.get_child_count() == 5, "Preparation presents five mounts and a four-column twelve-slot cargo grid")
	var starter: Dictionary = arena.ledger.inventory.records("prepared")[0]
	var view: InventoryView = mode.view
	view.select(starter.id)
	check(not view.action_buttons["Drop"].visible and view.weight_bar.value == 4000, "Preparation shows storage actions and includes mounted mass")
	view.perform("Drop")
	check(arena.ledger.inventory.record(starter.id).container == "prepared", "Unavailable preparation Drop cannot silently transfer an item")
	await inventory_key(KEY_T)
	check(arena.ledger.inventory.record(starter.id).container == "stash", "Real T input stores selected mounted equipment safely")
	await inventory_key(KEY_F)
	check(arena.ledger.inventory.record(starter.id).slot == "e:primary" and arena.ledger.inventory.record(starter.id).container == "prepared", "Real F input equips directly from base storage in one persistent operation")
	await frames(3)
	await inventory_click(view.equipment_box.get_child(0), true, false)
	check(arena.ledger.inventory.record(starter.id).container == "stash", "Shift-click moves the full selected stack through durable preparation")
	await frames(3)
	await inventory_click(view.other_list.get_child(0).get_child(0).get_child(0), false, true)
	check(arena.ledger.inventory.record(starter.id).slot == "e:primary", "Double-click equips a compatible stored weapon directly")
	view.select(starter.id)
	view.quantity.get_line_edit().grab_focus()
	await inventory_key(KEY_T)
	check(arena.ledger.inventory.record(starter.id).container == "prepared", "Typing in the quantity field cannot activate transfer shortcuts")
	view.quantity.get_line_edit().release_focus()
	var isolated := InventoryLedger.new()
	isolated.configure_container("prepared", load("res://resources/inventory/player.tres"))
	isolated.ensure_container("stash", "stash")
	isolated.issue("ui_rifle", &"raider_rifle", 1, "stash")
	var rifle: Dictionary = isolated.records("stash")[0]
	var before := isolated.export_state()
	check(not view._equip(isolated, rifle, "prepared").ok and isolated.export_state() == before and view.compatibility(isolated.catalog.find(&"raider_rifle")).contains("RAIDER ONLY"), "Human rifle restriction is explained without changing cargo ownership")
	for definition in arena.ledger.inventory.catalog.definitions:
		check(definition.icon != null, "Catalog supplies a distinct original item icon: " + definition.display_name)
	mode.view.select(starter.id)
	mode.view.perform("Equip / Unequip")
	check(arena.ledger.inventory.record(starter.id).slot.begins_with("c"), "Unequipping preparation is a durable ownership operation")
	mode.close_inventory()
	check(arena.start_deployment(), "An unarmed prepared loadout can deploy")
	await frames(15)
	freeze(arena)
	check(not arena.robot.get_node("Weapon").enabled, "Cargo weapon presence does not grant firing without a mount")
	check(arena.spectator.enter(), "Developer camera enters through its existing permission path")
	arena.spectator.leave()
	check(not arena.robot.get_node("Weapon").enabled and mode.current == PlayerInteractionMode.Mode.GAMEPLAY, "Leaving spectator resolves ownership instead of restoring stale weapon flags")
	check(mode.open_inventory(), "Inventory opens during active play")
	check(not arena.robot.input_adapter.gameplay_enabled and not arena.robot.get_node("Weapon").enabled and arena.robot.is_physics_processing(), "Overlay suppresses intents while robot physics remains active")
	var elapsed_before: float = arena.elapsed
	arena.set_physics_process(true)
	await frames(10)
	arena.set_physics_process(false)
	check(arena.elapsed > elapsed_before, "Inventory does not pause deployment time")
	mode.view.select(starter.id)
	mode.view.perform("Equip / Unequip")
	check(not arena.robot.get_node("Weapon").enabled, "Equipping inside inventory does not enable firing through the overlay")
	mode.close_inventory()
	check(arena.robot.get_node("Weapon").enabled and arena.robot.input_adapter.suppress_fire_until_release, "Closing inventory resolves the mounted weapon and suppresses a held click")
	var source: WorldLoot = arena.drops[-1]
	arena.robot.position = source.position + Vector3(0, 0.1, 1)
	await frames(3)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.recover_held = true
	for index in 95:
		arena.inventory_interaction._physics_process(1.0 / 60)
		if mode.current == PlayerInteractionMode.Mode.INVENTORY: break
	check(mode.current == PlayerInteractionMode.Mode.INVENTORY and arena.inventory_interaction.opened == source, "Stationary held E completes searchable-source access before opening")
	var loot: Dictionary = arena.ledger.inventory.records(source.container_id)[0]
	var before_take: int = arena.ledger.inventory.quantity("player")
	mode.view.select(loot.id)
	await inventory_key(KEY_T)
	check(arena.ledger.inventory.quantity("player") > before_take, "Real T input takes fitting source loot through physical access validation")
	arena.robot.get_node("Health").apply_damage(1)
	check(mode.current == PlayerInteractionMode.Mode.GAMEPLAY and not mode.view.visible and arena.inventory_interaction.opened == null, "Nonlethal damage revokes loot access and closes the overlay")
	mode.open_inventory()
	arena.robot.get_node("Health").apply_damage(1000)
	check(mode.current == PlayerInteractionMode.Mode.POST_DEATH and not mode.view.visible and not mode.open_inventory(), "Death wins over inventory and normal post-death spectators cannot transfer")
	check(arena.ledger.is_conserved(), "UI and spectator transitions preserve authoritative inventory totals")
	arena.queue_free()
	await frames(20)
	await scroll_retention()
	print("Inventory UI failures: ", failures)
	quit(1 if failures else 0)

func scroll_retention() -> void:
	var arena := create_arena("scroll")
	await frames(10)
	var stocked: Dictionary = arena.recall.stash.persistent_command("scroll_fixture", {}, func(candidate: InventoryLedger) -> Dictionary:
		for index in 31:
			var issued := candidate.issue("scroll_blaster_%d" % index, &"industrial_blaster", 1, "stash", "imported")
			if not issued.ok: return issued
		return {"ok": true})
	check(stocked.ok and arena.interaction_mode.open_inventory(), "Isolated scroll fixture opens a multi-page equipment list")
	var view: InventoryView = arena.interaction_mode.view
	await frames(4)
	var scroll: ScrollContainer = view.other_list.get_child(0)
	scroll.scroll_vertical = 400
	await frames(2)
	var offset := scroll.scroll_vertical
	check(offset > 0, "Equipment list has a real nonzero scroll offset")
	var button: Button = scroll.get_child(0).get_child(10)
	await inventory_click(button, false, false)
	await frames(3)
	check(not view.selected_id.is_empty() and view.other_list.get_child(0).scroll_vertical == offset, "Clicking equipment below the fold retains the list scroll position")
	var selected := view.selected_id
	await inventory_key(KEY_F)
	await frames(3)
	check(arena.ledger.inventory.record(selected).slot == "e:primary" and view.other_list.get_child(0).scroll_vertical == offset, "Equipping and deferred ledger refresh retain the scrolled list")
	view.refresh()
	view.refresh()
	await frames(3)
	check(view.other_list.get_child(0).scroll_vertical == offset, "Repeated refreshes retain the same scroll position")
	view.perform("Next")
	await frames(3)
	check(view.page == 1 and view.other_list.get_child(0).scroll_vertical == 0, "Changing list pages deliberately starts at the top")
	view.perform("Previous")
	await frames(3)
	view.other_list.get_child(0).scroll_vertical = 400
	arena.interaction_mode.close_inventory()
	arena.interaction_mode.open_inventory()
	await frames(3)
	check(view.other_list.get_child(0).scroll_vertical == 0, "A newly opened inventory starts at the top")
	check(arena.ledger.inventory.is_valid(), "Scroll and equip interactions preserve inventory invariants")
	arena.queue_free()
	await frames(20)

func inventory_key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		root.push_input(event)
		await frames(1)

func inventory_click(control: Control, shift: bool, double: bool) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		event.shift_pressed = shift
		event.double_click = double and pressed
		root.push_input(event)
		await frames(1)
