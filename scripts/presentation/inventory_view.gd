class_name InventoryView
extends PanelContainer
## Event-driven Controls only. IDs/revisions are requests, never trusted ownership.
const PAGE_SIZE := 24
var mode: PlayerInteractionMode
var context: InventoryContext
var source: WorldLoot
var selected_id: String = ""
var source_revision: int = -1
var player_revision: int = -1
var page: int = 0
var inspect_quarantine: bool = false
var rows: HBoxContainer
var equipment_box: VBoxContainer
var cargo_grid: GridContainer
var other_list: VBoxContainer
var source_scroll: ScrollContainer
var source_items: VBoxContainer
var source_caption: Label
var list_context: String = ""
var title: Label
var weight_label: Label
var details: Label
var notice: RichTextLabel
var quantity: SpinBox
var pending: bool = false
var ledger: InventoryLedger
var action_buttons: Dictionary = {}
var weight_bar: ProgressBar
var weapon_status: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if context == null: context = InventoryContext.for_arena(mode)
	ledger = context.inventory()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -580
	offset_right = 580
	offset_top = -365
	offset_bottom = 365
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.08, 1.0)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	rows = HBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	content.add_child(rows)
	equipment_box = VBoxContainer.new()
	equipment_box.custom_minimum_size.x = 220
	_section(rows, "ROBOT EQUIPMENT", equipment_box)
	cargo_grid = GridContainer.new()
	cargo_grid.columns = 4
	_section(rows, "CARGO", cargo_grid)
	other_list = VBoxContainer.new()
	other_list.custom_minimum_size = Vector2(355, 305)
	_section(rows, "STORAGE / SEARCHED SOURCE", other_list)
	source_scroll = ScrollContainer.new()
	source_scroll.custom_minimum_size = Vector2(355, 305)
	other_list.add_child(source_scroll)
	source_items = VBoxContainer.new()
	source_scroll.add_child(source_items)
	source_caption = Label.new()
	other_list.add_child(source_caption)
	weight_label = Label.new()
	content.add_child(weight_label)
	weight_bar = ProgressBar.new()
	weight_bar.custom_minimum_size.y = 8
	weight_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.17, 0.19)
	track.set_corner_radius_all(4)
	weight_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.7, 0.76)
	fill.set_corner_radius_all(4)
	weight_bar.add_theme_stylebox_override("fill", fill)
	content.add_child(weight_bar)
	weapon_status = Label.new()
	weapon_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(weapon_status)
	details = Label.new()
	details.custom_minimum_size = Vector2(1100, 60)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(details)
	var actions := HFlowContainer.new()
	content.add_child(actions)
	var amount_label := Label.new()
	amount_label.text = "Quantity"
	actions.add_child(amount_label)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 1000
	quantity.value = 1
	actions.add_child(quantity)
	for action in ["Take", "Take fitting", "Take All", "Transfer", "Split", "Equip / Unequip", "Drop", "Previous", "Next", "Quarantine / Stash", "Cancel loadout", "Close"]:
		var button := Button.new()
		button.text = action
		button.add_theme_font_size_override("font_size", 14)
		var action_style := StyleBoxFlat.new()
		action_style.bg_color = Color(0.12, 0.21, 0.24) if action in ["Equip / Unequip", "Take All", "Transfer"] else Color(0.1, 0.13, 0.15)
		action_style.border_color = Color(0.29, 0.43, 0.46)
		action_style.set_border_width_all(1)
		action_style.set_corner_radius_all(4)
		action_style.content_margin_left = 8
		action_style.content_margin_right = 8
		action_style.content_margin_top = 7
		action_style.content_margin_bottom = 7
		button.add_theme_stylebox_override("normal", action_style)
		action_buttons[action] = button
		button.pressed.connect(perform.bind(action))
		actions.add_child(button)
	notice = RichTextLabel.new()
	notice.custom_minimum_size.y = 72
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(notice)
	var shortcuts := Label.new()
	shortcuts.text = "Shift+click: move stack   |   Double-click: equip / move   |   F: equip   |   T: move selected   |   A: take fitting loot   |   X: drop   |   I / Esc: close"
	shortcuts.add_theme_font_size_override("font_size", 14)
	content.add_child(shortcuts)
	get_viewport().size_changed.connect(_fit_viewport)
	resized.connect(_fit_viewport)
	ledger.changed.connect(_changed)
	hide()

func _fit_viewport() -> void:
	if not is_inside_tree(): return
	pivot_offset = size * 0.5
	var available := get_viewport_rect().size - Vector2(24, 24)
	var factor := minf(1.0, minf(available.x / maxf(size.x, 1), available.y / maxf(size.y, 1)))
	scale = Vector2.ONE * factor

func open(loot: WorldLoot = null) -> void:
	source = loot
	selected_id = ""
	page = 0
	inspect_quarantine = false
	list_context = ""
	notice.text = "World simulation continues. Damage closes inventory." if context.active() else "Safe preparation. Equipped and carried items become at risk only when you Deploy. [I] closes."
	show()
	refresh()

func _changed(_event: Dictionary) -> void:
	if not visible or pending: return
	pending = true
	refresh.call_deferred()

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _section(parent: Node, caption: String, body: Control) -> void:
	var section := VBoxContainer.new()
	parent.add_child(section)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(0.5, 0.8, 0.85)
	section.add_child(label)
	section.add_child(body)

func compatibility(definition: ItemDefinition) -> String:
	if definition.mount.is_empty(): return "Salvage cargo"
	if not definition.compatible_actors.has("robot"): return "RAIDER ONLY — cargo for the robot"
	return "Robot · " + str(definition.mount).capitalize()

func item_button(item: Dictionary, empty_text: String, parent: Node, size: Vector2) -> void:
	var button := Button.new()
	button.custom_minimum_size = size
	button.text = empty_text
	button.add_theme_font_size_override("font_size", 13)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 30)
	if not item.is_empty():
		var definition := ledger.catalog.find(StringName(item.definition))
		var mount_label := str(item.slot).trim_prefix("e:").capitalize() + " · " if str(item.slot).begins_with("e:") else ""
		button.text = "%s%s\nx%d · %.1f kg%s" % [mount_label, definition.display_name, item.quantity, definition.unit_weight_g * int(item.quantity) / 1000.0, " · Raider" if not definition.mount.is_empty() and not definition.compatible_actors.has("robot") else ""]
		button.icon = definition.icon
		button.tooltip_text = "%s\n%s\n%s\nShift+click: move stack. Double-click: equip compatible gear or move cargo." % [definition.display_name, compatibility(definition), definition.description]
		button.gui_input.connect(_item_input.bind(str(item.id)))
		button.pressed.connect(select.bind(item.id))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.2, 0.23) if definition.compatible_actors.has("robot") else Color(0.13, 0.15, 0.17)
		style.border_color = Color(0.4, 0.85, 0.95) if selected_id == item.id else Color(0.28, 0.34, 0.36)
		style.set_border_width_all(2 if selected_id == item.id else 1)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", style)
	else:
		button.disabled = true
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.07, 0.09, 0.1)
		empty_style.border_color = Color(0.23, 0.3, 0.32)
		empty_style.set_border_width_all(1)
		empty_style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("disabled", empty_style)
	parent.add_child(button)

func _item_input(event: InputEvent, id: String) -> void:
	if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	if event.shift_pressed or event.double_click:
		select(id)
		perform(quick_action() if event.shift_pressed else primary_action())
		get_viewport().set_input_as_handled()

func primary_action() -> String:
	var item := ledger.record(selected_id)
	var definition := ledger.catalog.find(StringName(item.get("definition", "")))
	var owner := "player" if context.active() else "prepared"
	if definition != null and not definition.mount.is_empty() and definition.compatible_actors.has("robot") and (item.get("container") == owner or (not context.active() and item.get("container") == "stash")):
		return "Equip / Unequip"
	return quick_action()

func quick_action() -> String:
	var item := ledger.record(selected_id)
	if context.active() and is_instance_valid(source) and item.get("container") == source.container_id: return "Take fitting"
	return "Transfer"

func shortcut(event: InputEventKey) -> bool:
	if not visible or not event.pressed or event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return false
	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit: return false
	var action: String = {KEY_F: "Equip / Unequip", KEY_T: quick_action(), KEY_A: "Take All", KEY_X: "Drop"}.get(event.physical_keycode, "")
	if action.is_empty(): return false
	if action_buttons[action].visible and not action_buttons[action].disabled: perform(action)
	return true

func _update_actions(active: bool, owner: String, other: String, item: Dictionary) -> void:
	var own: bool = item.get("container") == owner
	var external: bool = not other.is_empty() and item.get("container") == other and other != "quarantine"
	var definition := ledger.catalog.find(StringName(item.get("definition", "")))
	for action in action_buttons:
		var button: Button = action_buttons[action]
		button.visible = true
		button.disabled = false
		match action:
			"Take", "Take fitting":
				button.visible = active and is_instance_valid(source)
				button.disabled = not external
			"Take All":
				button.visible = active and is_instance_valid(source)
				button.text = "Take all that fits [A]"
			"Transfer":
				button.text = ("Store [T]" if own else "Prepare cargo [T]") if not active else "Put in source [T]"
				button.visible = not active or is_instance_valid(source)
				button.disabled = not (own or (external and not active))
			"Split": button.disabled = not (own or (external and not active)) or int(item.get("quantity", 0)) < 2
			"Equip / Unequip":
				button.text = "Unequip [F]" if str(item.get("slot", "")).begins_with("e:") and own else "Equip [F]"
				button.disabled = not (own or (external and not active)) or definition == null or definition.mount.is_empty() or not definition.compatible_actors.has("robot")
				button.tooltip_text = "Select robot-compatible equipment in your cargo or base storage." if definition == null else (compatibility(definition) + ". Take searched equipment into cargo before equipping.")
			"Drop":
				button.visible = active
				button.text = "Drop [X]"
				button.disabled = not own
			"Previous", "Next": button.visible = not other.is_empty() and ledger.records(other).size() > PAGE_SIZE
			"Quarantine / Stash":
				button.visible = not active and ledger.quantity("quarantine") > 0
				button.text = "Back to storage" if inspect_quarantine else "Inspect unsupported legacy items"
			"Cancel loadout":
				button.visible = not active
				button.text = "Store entire loadout"
			"Close": button.text = "Close [I / Esc]"

func refresh() -> void:
	pending = false
	if not visible: return
	var active: bool = context.active()
	var owner := "player" if active else "prepared"
	var policy := ledger.container(owner)
	var other := source.container_id if is_instance_valid(source) else ("" if active else "stash")
	if not active and inspect_quarantine: other = "quarantine"
	title.text = "INVENTORY | %s" % (source.title if is_instance_valid(source) else ("Deployment cargo" if active else "Stash / Prepared loadout"))
	# Keep the scroller alive so selection and ownership refreshes retain its offset.
	for parent in [equipment_box, cargo_grid, source_items]: clear_children(parent)
	source_scroll.visible = not other.is_empty()
	source_caption.visible = not other.is_empty()
	var items := ledger.records(owner)
	for mount in policy.mounts:
		var found := {}
		for item in items:
			if item.slot == "e:" + mount: found = item
		item_button(found, mount.capitalize() + " | empty", equipment_box, Vector2(220, 53))
	for index in int(policy.slots):
		var found := {}
		for item in items:
			if item.slot == "c%d" % index: found = item
		item_button(found, "Empty", cargo_grid, Vector2(120, 88))
	if not other.is_empty():
		var all := ledger.records(other)
		page = clampi(page, 0, maxi(0, (all.size() - 1) / PAGE_SIZE))
		var context := "%s:%d" % [other, page]
		if context != list_context:
			source_scroll.scroll_vertical = 0
			list_context = context
		for index in range(page * PAGE_SIZE, mini(all.size(), (page + 1) * PAGE_SIZE)):
			item_button(all[index], "", source_items, Vector2(330, 48))
		if all.is_empty():
			var empty := Label.new()
			empty.text = "No items in this source." if active else "Base storage is empty.\nStore prepared items here, or\nextract recovered equipment."
			source_items.add_child(empty)
		source_caption.text = "%s | page %d | %d items" % ["Unsupported legacy items" if other == "quarantine" else (source.title if is_instance_valid(source) else "Base storage"), page + 1, all.size()]
	weight_label.text = "Cargo %d / %d slots   |   Total weight %.1f / %.1f kg   |   New salvage value %d   |   Quarantined %d" % [ledger.occupied(owner), int(policy.slots), ledger.weight(owner) / 1000.0, int(policy.weight) / 1000.0, ledger.loot_value(owner), ledger.quantity("quarantine")]
	weight_bar.max_value = maxi(1, int(policy.weight))
	weight_bar.value = ledger.weight(owner)
	var mounted := false
	for entry in items:
		if entry.slot == "e:primary": mounted = true
	weapon_status.text = "PRIMARY READY · Industrial blaster mounted" if mounted else "UNARMED · Equip a robot-compatible blaster. You may deploy unarmed and recover the finite blaster from a tool cabinet."
	weapon_status.modulate = Color(0.5, 0.9, 0.8) if mounted else Color(1, 0.77, 0.4)
	source_revision = int(ledger.container(other).get("revision", -1))
	player_revision = int(ledger.container(owner).get("revision", -1))
	var selected := ledger.record(selected_id)
	details.text = "Select an item to see its actions. Equipment mass counts toward capacity. Armor, power, mobility and utility currently have no stat effect."
	if not selected.is_empty():
		var definition := ledger.catalog.find(StringName(selected.definition))
		details.text = "%s · %s · value %d each\n%s" % [definition.display_name, compatibility(definition), definition.base_value, definition.description]
		if selected.definition == "unsupported_legacy": details.text += "\nPreserved legacy item: " + str(selected.metadata.get("legacy_name", "Unknown"))
	_update_actions(active, owner, other, selected)
	_fit_viewport.call_deferred()

func select(id: String) -> void:
	selected_id = id
	quantity.value = mini(int(ledger.record(id).get("quantity", 1)), 1000)
	refresh()

func perform(action: String) -> void:
	if not visible or not context.permitted(): return
	if action == "Close": context.close(); return
	if action in ["Previous", "Next"]:
		page += -1 if action == "Previous" else 1
		refresh()
		return
	if action == "Quarantine / Stash":
		inspect_quarantine = not inspect_quarantine
		page = 0
		refresh()
		return
	var result := context.execute(action, selected_id, int(quantity.value), source, source_revision, player_revision)
	notice.text = str(result.get("reason", ""))
	if result.ok and notice.text.is_empty(): notice.text = "Accepted %d. Inventory updated." % int(result.get("amount", 0))
	refresh()

func _equip(authority: InventoryLedger, item: Dictionary, owner: String) -> Dictionary:
	return PreparationService.equip(authority, item, owner)
