class_name WorkshopService
extends RefCounted
## Non-mutating previews and one shared persistent execution path.
var preparation: PreparationService

func _init(service: PreparationService) -> void:
	preparation = service

func preview(id: String) -> Dictionary:
	var recipe := RecipeDefinition.approved(id)
	if recipe == null: return {"ok": false, "reason": "Unknown recipe.", "rows": []}
	var rows: Array = []
	var ready := true
	for definition in recipe.inputs:
		var owned := 0
		for item in preparation.stash.inventory.records("stash"):
			if item.definition == definition: owned += int(item.quantity)
		rows.append({"definition": definition, "required": recipe.inputs[definition], "available": owned, "missing": maxi(0, int(recipe.inputs[definition]) - owned)})
		ready = ready and owned >= int(recipe.inputs[definition])
	if id == "cargo_rack_1" and preparation.stash.home_snapshot().upgrades.get(id, false):
		return {"ok": false, "rows": rows, "reason": "Cargo Rack I is already installed."}
	return {"ok": ready, "rows": rows, "reason": "Ready. Uses available stash items only." if ready else "Missing ingredients in available stash."}

func execute(id: String, operation: String, revision: int) -> Dictionary:
	if not preparation.available() or not preparation.stash.home_snapshot().station_unlocks.has("disassembly" if id.begins_with("strip_") or id == "recover_servo" else "fabrication"):
		return {"ok": false, "reason": "Workshop is unavailable."}
	return preparation.stash.persistent_command(operation, {"recipe": id, "revision": revision}, func(candidate: InventoryLedger) -> Dictionary:
		if candidate.container("stash").revision != revision: return {"ok": false, "reason": "Stash changed; review the recipe again."}
		if id == "cargo_rack_1" and preparation.stash.home_snapshot().upgrades.get(id, false): return {"ok": false, "reason": "Upgrade already installed."}
		var result := candidate.transform_recipe(id, operation)
		if result.ok and id == "cargo_rack_1":
			var upgraded := preparation.stash.home_snapshot()
			upgraded.upgrades[id] = true
			for box in ["prepared", "escrow", "player"]:
				if not candidate.configure_container(box, UpgradeDefinition.player_rules(upgraded)): return {"ok": false, "reason": "Upgrade capacity could not be applied."}
		return result,
		func(home: Dictionary) -> Dictionary:
			if id == "cargo_rack_1": home.upgrades[id] = true
			return {"ok": true})

func fabrication_preview(missing: Dictionary, reserved_stash: Dictionary = {}) -> Dictionary:
	# One level only: aggregate shared ingredients before calculating shortages.
	var ingredients := {}
	var unsupported: Array = []
	for definition in missing:
		if int(missing[definition]) <= 0: continue
		if definition != "industrial_blaster": unsupported.append(definition); continue
		var recipe := RecipeDefinition.approved("fabricate_blaster")
		for input in recipe.inputs: ingredients[input] = int(ingredients.get(input, 0)) + int(recipe.inputs[input]) * int(missing[definition])
	var rows: Array = []
	var ready := unsupported.is_empty() and not ingredients.is_empty()
	for definition in ingredients:
		var owned := 0
		for item in preparation.stash.inventory.records("stash"):
			if item.definition == definition: owned += int(item.quantity)
		owned = maxi(0, owned - int(reserved_stash.get(definition, 0)))
		rows.append({"definition": definition, "required": ingredients[definition], "available": owned, "missing": maxi(0, int(ingredients[definition]) - owned)})
		ready = ready and owned >= int(ingredients[definition])
	return {"ok": ready, "rows": rows, "unsupported": unsupported, "reason": "Fabricate each missing blaster explicitly, then prepare the kit."}

func display_item(identity: String) -> Dictionary:
	if not preparation.available(): return {"ok": false, "reason": "Display is unavailable during deployment."}
	var assignment := {}
	return preparation.stash.persistent_command(preparation.next_command(), {"display": identity}, func(candidate: InventoryLedger) -> Dictionary:
		var rules := InventoryRules.new()
		rules.cargo_slots = 1
		rules.weight_limit_g = -1
		candidate.ensure_container("display:workshop", "display", rules)
		for displayed in candidate.records("display:workshop"):
			if not candidate.transfer_display(displayed.id, "stash").ok: return {"ok": false, "reason": "Could not return the displayed item."}
		if not identity.is_empty():
			var item := candidate.record(identity)
			if item.get("container") != "stash": return {"ok": false, "reason": "Select an available stash item."}
			var moved := candidate.transfer_display(identity, "display:workshop")
			if not moved.ok: return moved
			assignment["workshop"] = identity
		return {"ok": true, "reason": "Display updated. Ownership and identity preserved."},
		func(home: Dictionary) -> Dictionary:
			home.display_assignments = assignment.duplicate(true)
			return {"ok": true})
