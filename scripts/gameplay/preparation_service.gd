class_name PreparationService
extends RefCounted
## Shared command boundary for workshop and Quick Deploy. Owns no item balance.
var stash: PersistentStash
var enabled: bool = true
var serial: int = 0
var command_prefix: String = Crypto.new().generate_random_bytes(16).hex_encode()

func _init(profile: PersistentStash) -> void:
	stash = profile

func next_command() -> String:
	serial += 1
	return command_prefix + "/prepare/" + str(serial)

func available() -> bool:
	return enabled and stash.inventory != null and not stash.inventory.sealed

func execute(action: String, id: String, amount: int, revision: int = -1) -> Dictionary:
	if not available(): return {"ok": false, "reason": "Preparation is closed during a transition or deployment."}
	return stash.persistent_command(next_command(), {"action": action, "id": id, "amount": amount, "revision": revision}, func(candidate: InventoryLedger) -> Dictionary:
		if action == "Cancel loadout": return candidate.transfer_group("prepared", "stash")
		var item := candidate.record(id)
		if item.is_empty() or item.container not in ["stash", "prepared"]: return {"ok": false, "reason": "Select an available stash or prepared item."}
		if revision >= 0 and candidate.container(item.container).revision != revision: return {"ok": false, "reason": "Inventory changed; select the item again."}
		if action == "Equip / Unequip": return equip(candidate, item, "prepared")
		if action == "Split": return candidate.split(id, amount)
		if action in ["Transfer", "Take fitting"]: return candidate.transfer(id, amount, "prepared" if item.container == "stash" else "stash", action == "Take fitting")
		return {"ok": false, "reason": "This action is unavailable in preparation."})

static func equip(authority: InventoryLedger, item: Dictionary, owner: String) -> Dictionary:
	if item.is_empty(): return {"ok": false, "reason": "Select equipment first."}
	var definition := authority.catalog.find(StringName(item.definition))
	if definition == null or definition.mount.is_empty(): return {"ok": false, "reason": "This item is salvage cargo."}
	if not definition.compatible_actors.has("robot"): return {"ok": false, "reason": "Raider-only equipment. Carry and extract it as cargo; the robot cannot equip it."}
	if item.container != owner:
		if item.container != "stash" or owner != "prepared": return {"ok": false, "reason": "Take this equipment into cargo first."}
		for equipped in authority.records(owner):
			if equipped.slot == "e:" + str(definition.mount):
				var stored := authority.transfer(equipped.id, 1, "stash")
				if not stored.ok: return stored
		return authority.transfer(item.id, 1, owner, false, "", -1, -1, str(definition.mount))
	return authority.transfer(item.id, 1, owner, false, "", -1, -1, "" if str(item.slot).begins_with("e:") else str(definition.mount))

func metadata(payload: Dictionary, action: Callable) -> Dictionary:
	if not available(): return {"ok": false, "reason": "Preparation is unavailable."}
	return stash.persistent_command(next_command(), payload, func(_candidate: InventoryLedger) -> Dictionary: return {"ok": true}, action)

func save_template(id: String, value: Dictionary) -> Dictionary:
	if not LoadoutTemplate.valid(value): return {"ok": false, "reason": "Give the template a name and valid definition/quantity rows."}
	var target := id if not id.is_empty() else Crypto.new().generate_random_bytes(16).hex_encode()
	return metadata({"template": target, "value": value}, func(home: Dictionary) -> Dictionary:
		if not home.templates.has(target) and home.templates.size() >= 32: return {"ok": false, "reason": "Template limit reached (32)."}
		home.templates[target] = value.duplicate(true)
		return {"ok": true})

func delete_template(id: String) -> Dictionary:
	return metadata({"delete_template": id}, func(home: Dictionary) -> Dictionary:
		if not home.templates.has(id): return {"ok": false, "reason": "Template no longer exists."}
		home.templates.erase(id)
		return {"ok": true})

func select_contract(id: String, seed_value: int) -> Dictionary:
	if id not in ["asset_recovery", "salvage_complex"] or seed_value < 0 or seed_value > 2147483647: return {"ok": false, "reason": "Invalid contract or seed."}
	return metadata({"contract": id, "seed": seed_value}, func(home: Dictionary) -> Dictionary:
		home.contract = id
		home.seed = seed_value
		return {"ok": true})

func evaluate(value: Dictionary) -> Dictionary:
	if not LoadoutTemplate.valid(value): return {"status": "Unavailable", "rows": [], "reason": "Invalid template."}
	var needed := {}
	for definition in value.mounts.values(): needed[definition] = int(needed.get(definition, 0)) + 1
	for row in value.cargo: needed[row.definition] = int(needed.get(row.definition, 0)) + int(row.quantity)
	var rows: Array = []
	var missing := false
	var any := false
	for id in needed:
		var owned := 0
		for item in stash.inventory.records():
			if item.container in ["stash", "prepared"] and str(item.definition) == id: owned += int(item.quantity)
		var known := stash.inventory.catalog.find(StringName(id)) != null
		rows.append({"definition": id, "required": needed[id], "available": owned, "missing": maxi(0, int(needed[id]) - owned), "known": known})
		missing = missing or owned < int(needed[id]) or not known
		any = any or owned > 0
	var candidate := InventoryLedger.new()
	if not candidate.import_state(stash.inventory.export_state()): return {"status": "Unavailable", "rows": rows, "reason": "Inventory checkpoint is invalid."}
	var applied := _apply(candidate, value, false)
	var shortages := {}
	var reserved := {}
	for row in rows:
		if row.missing > 0: shortages[row.definition] = row.missing
		var prepared_count := 0
		for item in stash.inventory.records("prepared"):
			if item.definition == row.definition: prepared_count += int(item.quantity)
		reserved[row.definition] = maxi(0, mini(int(row.available), int(row.required)) - prepared_count)
	var fabrication := WorkshopService.new(self).fabrication_preview(shortages, reserved)
	var status: String = ("Partially available" if any else "Unavailable") if missing else ("Ready" if applied.ok else "Unavailable")
	if missing and fabrication.ok:
		var desired_weight := 0
		for id in needed:
			var definition := stash.inventory.catalog.find(StringName(id))
			if definition != null: desired_weight += definition.unit_weight_g * int(needed[id])
		if desired_weight > int(stash.inventory.container("prepared").weight):
			fabrication.ok = false
			fabrication.reason = "Desired kit exceeds its weight limit, even after fabrication."
		else:
			var projected := InventoryLedger.new()
			fabrication.ok = projected.import_state(stash.inventory.export_state())
			for index in int(shortages.get("industrial_blaster", 0)):
				if not fabrication.ok: break
				fabrication.ok = projected.transform_recipe("fabricate_blaster", "preview/" + str(index)).ok
			if fabrication.ok: fabrication.ok = _apply(projected, value, false).ok
			if not fabrication.ok: fabrication.reason = "Fabricated kit cannot fit its validated equipment and cargo limits."
		if fabrication.ok: status = "Craftable"
	return {"status": status, "rows": rows, "reason": str(applied.get("reason", "")), "fabrication": fabrication}

func apply_template(id: String, partial: bool = false) -> Dictionary:
	if not available(): return {"ok": false, "reason": "Preparation is unavailable."}
	var value: Dictionary = stash.home_snapshot().get("templates", {}).get(id, {})
	if not LoadoutTemplate.valid(value): return {"ok": false, "reason": "Template no longer exists."}
	return stash.persistent_command(next_command(), {"apply": id, "template": value, "partial": partial}, func(candidate: InventoryLedger) -> Dictionary: return _apply(candidate, value, partial))

func _apply(candidate: InventoryLedger, value: Dictionary, partial: bool) -> Dictionary:
	var cleared := candidate.transfer_group("prepared", "stash")
	if not cleared.ok: return cleared
	for mount in value.mounts:
		var moved := _allocate(candidate, str(value.mounts[mount]), 1, str(mount), partial)
		if not moved.ok: return moved
	for row in value.cargo:
		var moved := _allocate(candidate, str(row.definition), int(row.quantity), "", partial)
		if not moved.ok: return moved
	return {"ok": true, "reason": "Available items prepared; missing requests were left empty." if partial else "Prepared kit matches the template."}

func _allocate(candidate: InventoryLedger, definition: String, quantity: int, mount: String, partial: bool) -> Dictionary:
	var data := candidate.catalog.find(StringName(definition))
	if data != null and not mount.is_empty() and (str(data.mount) != mount or not data.compatible_actors.has("robot")): return {"ok": false, "reason": definition + " is incompatible with " + mount}
	var remaining := quantity
	for item in candidate.records("stash"):
		if str(item.definition) != definition: continue
		var count := mini(remaining, int(item.quantity))
		var moved := candidate.transfer(item.id, count, "prepared", false, "", -1, -1, mount)
		if not moved.ok: return moved
		remaining -= count
		if remaining == 0: break
	if remaining > 0 and not partial: return {"ok": false, "reason": "Missing %d × %s. No items were changed." % [remaining, definition]}
	return {"ok": true}

