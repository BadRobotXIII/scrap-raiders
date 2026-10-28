class_name LoadoutView
extends VBoxContainer
var preparation: PreparationService
var selected_id: String = ""
var editing: Dictionary = {}
var name_field: LineEdit
var mount_fields: Dictionary = {}
var cargo_rows: Array = []
var feedback: RichTextLabel
var confirmation: ConfirmationDialog

func _ready() -> void:
	editing = LoadoutTemplate.from_inventory(preparation.stash.inventory, "New loadout")
	render()

func render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	mount_fields.clear()
	var templates := OptionButton.new()
	templates.add_item("New / unsaved template")
	templates.set_item_metadata(0, "")
	var all: Dictionary = preparation.stash.home_snapshot().templates
	for id in all:
		templates.add_item(all[id].name)
		templates.set_item_metadata(templates.item_count - 1, id)
		if id == selected_id: templates.select(templates.item_count - 1)
	templates.item_selected.connect(func(index: int) -> void:
		selected_id = str(templates.get_item_metadata(index))
		editing = all.get(selected_id, LoadoutTemplate.from_inventory(preparation.stash.inventory, "New loadout")).duplicate(true)
		render())
	add_child(templates)
	name_field = LineEdit.new()
	name_field.placeholder_text = "Name this template"
	name_field.max_length = 64
	name_field.text = editing.name
	add_child(name_field)
	var mounts := GridContainer.new()
	mounts.columns = 2
	add_child(mounts)
	for mount in LoadoutTemplate.MOUNTS:
		var mount_label := ApplicationTheme.label(mounts, str(mount).capitalize())
		mount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		mount_label.custom_minimum_size.x = 140
		var picker := OptionButton.new()
		picker.custom_minimum_size.x = 350
		picker.add_item("Empty")
		picker.set_item_metadata(0, "")
		for definition in preparation.stash.inventory.catalog.definitions:
			if str(definition.mount) != mount or not definition.compatible_actors.has("robot"): continue
			picker.add_item(definition.display_name)
			picker.set_item_metadata(picker.item_count - 1, str(definition.definition_id))
		var desired: String = editing.mounts.get(mount, "")
		var found := desired.is_empty()
		for index in picker.item_count:
			if picker.get_item_metadata(index) == desired:
				picker.select(index)
				found = true
		if not found:
			picker.add_item("Missing / incompatible: " + desired)
			picker.set_item_metadata(picker.item_count - 1, desired)
			picker.select(picker.item_count - 1)
		mounts.add_child(picker)
		mount_fields[mount] = picker
	cargo_rows = editing.cargo.duplicate(true)
	var cargo_line := HBoxContainer.new()
	add_child(cargo_line)
	var cargo_picker := OptionButton.new()
	for definition in preparation.stash.inventory.catalog.definitions:
		cargo_picker.add_item(definition.display_name)
		cargo_picker.set_item_metadata(cargo_picker.item_count - 1, str(definition.definition_id))
	cargo_line.add_child(cargo_picker)
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = 1000
	cargo_line.add_child(amount)
	ApplicationTheme.button(cargo_line, "Add cargo request", func() -> void:
		editing = current_value()
		editing.cargo.append({"definition": str(cargo_picker.get_selected_metadata()), "quantity": int(amount.value)})
		render())
	var cargo_scroll := ScrollContainer.new()
	cargo_scroll.custom_minimum_size.y = 70
	add_child(cargo_scroll)
	var rows := VBoxContainer.new()
	cargo_scroll.add_child(rows)
	for index in cargo_rows.size():
		var row: Dictionary = cargo_rows[index]
		var line := HBoxContainer.new()
		rows.add_child(line)
		var definition := preparation.stash.inventory.catalog.find(StringName(row.definition))
		ApplicationTheme.label(line, "%s × %d" % [definition.display_name if definition != null else "Missing: " + str(row.definition), row.quantity])
		ApplicationTheme.button(line, "Remove", func() -> void:
			editing = current_value()
			editing.cargo.remove_at(index)
			render())
	var actions := HFlowContainer.new()
	add_child(actions)
	ApplicationTheme.button(actions, "Preview availability", preview)
	ApplicationTheme.button(actions, "Save / Rename", func() -> void: save(false))
	ApplicationTheme.button(actions, "Duplicate", func() -> void: save(true))
	ApplicationTheme.button(actions, "Delete", delete_selected)
	ApplicationTheme.button(actions, "Capture prepared kit", func() -> void:
		editing = LoadoutTemplate.from_inventory(preparation.stash.inventory, name_field.text if not name_field.text.is_empty() else "New loadout")
		render())
	ApplicationTheme.button(actions, "Prepare saved template", func() -> void: apply(false))
	ApplicationTheme.button(actions, "Prepare available items…", confirm_partial)
	feedback = RichTextLabel.new()
	feedback.custom_minimum_size.y = 180
	add_child(feedback)
	confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Replace the current prepared kit using only available requested items? Missing requests will remain empty. No substitutions or fabrication."
	confirmation.confirmed.connect(func() -> void: apply(true))
	add_child(confirmation)
	preview()

func current_value() -> Dictionary:
	var value := {"name": name_field.text.strip_edges(), "mounts": {}, "cargo": cargo_rows.duplicate(true)}
	for mount in mount_fields:
		var id: String = mount_fields[mount].get_selected_metadata()
		if not id.is_empty(): value.mounts[mount] = id
	return value

func preview() -> void:
	var result := preparation.evaluate(current_value())
	feedback.text = str(result.status) + "\n" + str(result.get("reason", "")) + "\n"
	for row in result.rows:
		var definition := preparation.stash.inventory.catalog.find(StringName(row.definition))
		feedback.text += "%s: need %d, own %d, missing %d\n" % [definition.display_name if definition != null else "Unknown: " + str(row.definition), row.required, row.available, row.missing]
	feedback.text += "Templates describe a desired kit and reserve nothing. One prepared kit is available."
	var fabrication: Dictionary = result.get("fabrication", {})
	for row in fabrication.get("rows", []):
		feedback.text += "Fabrication ingredient %s: need %d, available %d, missing %d\n" % [row.definition, row.required, row.available, row.missing]
	if not fabrication.get("unsupported", []).is_empty(): feedback.text += "No recipe for: " + str(fabrication.unsupported) + "\n"
	feedback.text += "Fabrication is explicit at the Fabrication station; template selection never crafts."

func save(duplicate_template: bool) -> void:
	var value := current_value()
	var id := Crypto.new().generate_random_bytes(16).hex_encode() if duplicate_template or selected_id.is_empty() else selected_id
	var result := preparation.save_template(id, value)
	if not result.ok:
		feedback.text = result.get("reason", "Could not save template.")
		return
	selected_id = id
	editing = value
	render()

func delete_selected() -> void:
	var result := preparation.delete_template(selected_id)
	if result.ok:
		selected_id = ""
		editing = LoadoutTemplate.from_inventory(preparation.stash.inventory, "New loadout")
		render()
	else: feedback.text = result.get("reason", "Select a saved template.")

func apply(partial: bool) -> void:
	var result := preparation.apply_template(selected_id, partial)
	preview()
	feedback.text = str(result.get("reason", "Preparation updated.")) + "\n" + feedback.text

func confirm_partial() -> void:
	if selected_id.is_empty():
		feedback.text = "Save or select a template first."
		return
	confirmation.popup_centered(Vector2i(620, 200))
