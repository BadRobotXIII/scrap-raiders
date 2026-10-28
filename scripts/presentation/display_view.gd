class_name DisplayView
extends VBoxContainer
var preparation: PreparationService
var feedback: Label

func _ready() -> void:
	render()

func render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	ApplicationTheme.label(self, "Display one owned item or stack. It stays reserved from loadouts and recipes until returned to storage.")
	var displayed := preparation.stash.inventory.records("display:workshop")
	if not displayed.is_empty():
		var item: Dictionary = displayed[0]
		var definition := preparation.stash.inventory.catalog.find(StringName(item.definition))
		ApplicationTheme.label(self, "%s × %d\n%s" % [definition.display_name, item.quantity, definition.description])
	var picker := OptionButton.new()
	picker.add_item("Select an available stash item")
	picker.set_item_metadata(0, "")
	for item in preparation.stash.inventory.records("stash"):
		var definition := preparation.stash.inventory.catalog.find(StringName(item.definition))
		picker.add_icon_item(definition.icon, "%s × %d" % [definition.display_name, item.quantity])
		picker.set_item_metadata(picker.item_count - 1, item.id)
	add_child(picker)
	ApplicationTheme.button(self, "Assign selected item", func() -> void:
		var id: String = picker.get_selected_metadata()
		if id.is_empty(): return
		show_result(WorkshopService.new(preparation).display_item(id)))
	ApplicationTheme.button(self, "Return displayed item to storage", func() -> void: show_result(WorkshopService.new(preparation).display_item("")))
	feedback = ApplicationTheme.label(self, "")

func show_result(result: Dictionary) -> void:
	render()
	feedback.text = result.get("reason", "Display updated.")
