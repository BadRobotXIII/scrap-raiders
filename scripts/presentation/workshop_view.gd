class_name WorkshopView
extends VBoxContainer
var preparation: PreparationService
var context: String = "fabrication"
var feedback: Label

func _ready() -> void:
	render()

func render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	ApplicationTheme.label(self, "Available stash only. Prepared and displayed items stay reserved. Every operation requires confirmation.")
	var service := WorkshopService.new(preparation)
	for id in ["strip_raider_rifle", "strip_response_rifle", "recover_servo", "fabricate_blaster", "cargo_rack_1"]:
		var recipe := RecipeDefinition.approved(id)
		if (context == "disassembly") != recipe.disassembly: continue
		var preview := service.preview(id)
		ApplicationTheme.label(self, recipe.display_name)
		ApplicationTheme.label(self, preview.reason)
		for row in preview.rows:
			ApplicationTheme.label(self, "%s: need %d / available %d / missing %d" % [preparation.stash.inventory.catalog.find(StringName(row.definition)).display_name, row.required, row.available, row.missing])
		var outputs := PackedStringArray()
		for definition in recipe.outputs: outputs.append("%d × %s" % [recipe.outputs[definition], preparation.stash.inventory.catalog.find(StringName(definition)).display_name])
		ApplicationTheme.label(self, "Output: " + (", ".join(outputs) if not outputs.is_empty() else "Permanent Cargo Rack I: 16 slots / 45 kg"))
		var revision: int = preparation.stash.inventory.container("stash").revision
		var confirm := ConfirmationDialog.new()
		confirm.dialog_text = recipe.display_name + "? Listed stash ingredients will be consumed permanently."
		add_child(confirm)
		confirm.confirmed.connect(func() -> void:
			var result := service.execute(id, preparation.next_command(), revision)
			render()
			feedback.text = result.get("reason", "Completed.") if result.ok else "Refused: " + str(result.get("reason", "No change.")))
		var button := ApplicationTheme.button(self, "Confirm: " + recipe.display_name, func() -> void: confirm.popup_centered(Vector2i(640, 220)))
		button.disabled = not preview.ok
		button.tooltip_text = preview.reason
	feedback = ApplicationTheme.label(self, "")
