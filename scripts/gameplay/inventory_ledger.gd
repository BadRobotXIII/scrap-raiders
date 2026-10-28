class_name InventoryLedger
extends RefCounted
## One owner of all live stacks, equipment, containers and terminal locations.
## Callers receive copies. No physics, UI, input, disk access or gameplay RNG.

signal changed(event: Dictionary)
const MAX_RECORDS := 10000
var catalog: ItemCatalog
var hybrid: bool = false
var sealed: bool = false
var player_settled: bool = false
var serial: int = 0
var identity_prefix: String = "local"
var actor_outcomes: Dictionary = {}
var equipment_assigned: Dictionary = {}
var equipment_resolved: Dictionary = {}
var drop_sources: Dictionary = {}
var actor_drops: Dictionary = {}
var next_drop_id: int = 1
var next_equipment_id: int = 1
var material_notified: bool = false
var equipment_notified: bool = false
var settled_player_summary: Dictionary = {}
var _records: Dictionary = {}
var _containers: Dictionary = {}
var _issued: Dictionary = {}
var _initial: Dictionary = {}
var _commands: Dictionary = {}
var _transformations: Dictionary = {}
var _next_id: int = 1
var _busy: bool = false

func _init(definitions: ItemCatalog = null) -> void:
	catalog = definitions if definitions != null else load("res://resources/items/catalog.tres") as ItemCatalog
	assert(catalog != null and catalog.validation_error().is_empty())
	ensure_container("player", "player")
	ensure_container("banked", "banked")
	ensure_container("forfeited", "forfeited")

func ensure_container(id: String, kind: String, rules: InventoryRules = null) -> void:
	if _containers.has(id): return
	_containers[id] = {"kind": kind, "slots": rules.cargo_slots if rules != null else -1, "weight": rules.weight_limit_g if rules != null else -1, "actor_kind": str(rules.actor_kind) if rules != null else "", "mounts": Array(rules.equipment_slots) if rules != null else [], "revision": 0, "closed": false}

func configure_container(id: String, rules: InventoryRules) -> bool:
	if not _containers.has(id) or rules == null or not rules.validation_error().is_empty(): return false
	var prior: Dictionary = _containers[id].duplicate(true)
	_containers[id].slots = rules.cargo_slots
	_containers[id].weight = rules.weight_limit_g
	_containers[id].actor_kind = str(rules.actor_kind)
	_containers[id].mounts = Array(rules.equipment_slots)
	if not _capacity_valid(id):
		_containers[id] = prior
		return false
	return true

func container(id: String) -> Dictionary:
	return _containers.get(id, {}).duplicate(true)

func records(id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in _records.values():
		if id.is_empty() or record.container == id: result.append(record.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id))
	return result

func record(id: String) -> Dictionary:
	return _records.get(id, {}).duplicate(true)

func weight(id: String) -> int:
	var total := 0
	for item in _records.values():
		if item.container == id:
			var definition := catalog.find(StringName(item.definition))
			if definition != null: total += definition.unit_weight_g * int(item.quantity)
	return total

func occupied(id: String) -> int:
	var total := 0
	for item in _records.values():
		if item.container == id and str(item.slot).begins_with("c"): total += 1
	return total

func quantity(id: String, materials_only: bool = false, cohort: String = "") -> int:
	var total := 0
	for item in _records.values():
		if item.container != id or (not cohort.is_empty() and item.cohort != cohort): continue
		var definition := catalog.find(StringName(item.definition))
		if definition != null: total += int(item.quantity) * (definition.material_units if materials_only else 1)
	return total

func loot_value(id: String) -> int:
	var total := 0
	for item in _records.values():
		if item.container != id or (item.cohort != "world" and not id.begins_with("actor:")): continue
		if item.cohort == "world" and item.metadata.get("loadout", false) and id == "actor:%d" % int(item.metadata.get("origin_actor", 0)): continue
		var definition := catalog.find(StringName(item.definition))
		if definition != null: total += int(item.quantity) * definition.base_value
	return total

func material_total() -> int:
	var total := 0
	for key in _initial:
		var parts := str(key).split("|")
		var definition := catalog.find(StringName(parts[0]))
		if parts[1] == "world" and definition != null: total += int(_initial[key]) * definition.material_units
	return total

func material_at(kind: String) -> int:
	var total := 0
	for item in _records.values():
		if item.cohort == "world" and _containers[item.container].kind == kind:
			total += int(item.quantity) * catalog.find(StringName(item.definition)).material_units
	return total

func equipment_summary(location: int, owner: int = 0) -> Vector2i:
	var result := Vector2i.ZERO
	for item in _records.values():
		if item.cohort != "world" or not item.metadata.has("equipment_id") or (owner > 0 and int(item.metadata.get("origin_actor", 0)) != owner) or equipment_location(item) != location: continue
		result.x += 1
		result.y += catalog.find(StringName(item.definition)).base_value
	return result

func _fresh_id() -> String:
	var id := "%s/%d" % [identity_prefix, _next_id]
	_next_id += 1
	return id

func _free_slot(id: String) -> String:
	var used := {}
	for item in _records.values():
		if item.container == id: used[item.slot] = true
	var limit: int = _containers[id].slots
	for index in range(MAX_RECORDS if limit < 0 else limit):
		var slot := "c%d" % index
		if not used.has(slot): return slot
	return ""

func _snapshot() -> Dictionary:
	return {"records": _records.duplicate(true), "containers": _containers.duplicate(true), "issued": _issued.duplicate(true), "initial": _initial.duplicate(true), "next_id": _next_id, "actors": actor_outcomes.duplicate(true), "assigned": equipment_assigned.duplicate(true), "resolved": equipment_resolved.duplicate(true), "sources": drop_sources.duplicate(true), "drops": actor_drops.duplicate(true), "next_drop": next_drop_id, "next_equipment": next_equipment_id, "player_settled": player_settled, "identity_prefix": identity_prefix, "commands": _commands.duplicate(true), "serial": serial, "hybrid": hybrid, "player_summary": settled_player_summary.duplicate(true), "transformations": _transformations.duplicate(true)}

func _restore(state: Dictionary) -> void:
	_records = state.records
	_containers = state.containers
	_issued = state.issued
	_initial = state.initial
	_next_id = state.next_id
	actor_outcomes = state.actors
	equipment_assigned = state.assigned
	equipment_resolved = state.resolved
	drop_sources = state.sources
	actor_drops = state.drops
	next_drop_id = state.next_drop
	next_equipment_id = state.next_equipment
	player_settled = state.player_settled
	identity_prefix = state.get("identity_prefix", "local")
	_commands = state.get("commands", {})
	_transformations = state.get("transformations", {})
	serial = int(state.get("serial", 0))
	hybrid = state.get("hybrid", false)
	settled_player_summary = state.get("player_summary", {}).duplicate(true)

func _reject(reason: String) -> Dictionary:
	return {"ok": false, "amount": 0, "remainder": 0, "reason": reason}

func _transaction(operation: String, payload: Dictionary, action: Callable, command: String = "") -> Dictionary:
	if _busy or sealed: return _reject("Inventory is closed or busy.")
	if not command.is_empty() and _commands.has(command):
		return _commands[command].result.duplicate(true) if _commands[command].payload == payload else _reject("Command identity was reused with different contents.")
	var before := _snapshot()
	_busy = true
	var result: Dictionary = action.call()
	if not result.get("ok", false) or not is_valid():
		_restore(before)
		_busy = false
		return result if not result.get("ok", false) else _reject("Inventory invariant rejected this operation.")
	serial += 1
	for id in _containers:
		if _containers[id] != before.containers.get(id): continue
		# Revisions are updated only for containers whose contents changed.
		var old: Array = []
		var now: Array = []
		for item in before.records.values():
			if item.container == id: old.append(item)
		for item in _records.values():
			if item.container == id: now.append(item)
		if old != now: _containers[id].revision += 1
	result["serial"] = serial
	if not command.is_empty(): _commands[command] = {"payload": payload.duplicate(true), "result": result.duplicate(true)}
	changed.emit({"kind": operation, "serial": serial, "result": result.duplicate(true)})
	_busy = false
	return result

func issue(permit: String, definition_id: StringName, amount: int, destination: String, cohort: String = "world", metadata: Dictionary = {}, identity: String = "") -> Dictionary:
	return _transaction("issue", {"permit": permit}, _issue_records.bind(permit, definition_id, amount, destination, cohort, metadata, identity))

func _issue_records(permit: String, definition_id: StringName, amount: int, destination: String, cohort: String, metadata: Dictionary, identity: String = "") -> Dictionary:
		var definition := catalog.find(definition_id)
		if permit.is_empty() or _issued.has(permit) or definition == null or amount <= 0 or amount > 1000000 or not _containers.has(destination): return _reject("Invalid or spent supply permit.")
		if not serializable_metadata(metadata) or JSON.stringify(metadata).length() > 4096: return _reject("Invalid item metadata.")
		if _records.size() + ceili(float(amount) / definition.max_stack) > MAX_RECORDS: return _reject("Item record safety limit exceeded.")
		_issued[permit] = true
		var key := "%s|%s" % [definition_id, cohort]
		_initial[key] = int(_initial.get(key, 0)) + amount
		var remaining := amount
		var ids: Array[String] = []
		while remaining > 0:
			var id := identity if not identity.is_empty() else _fresh_id()
			if _records.has(id): return _reject("Duplicate item identity.")
			var slot := _free_slot(destination)
			if slot.is_empty(): return _reject("No cargo slot available.")
			var count := mini(remaining, definition.max_stack)
			var facts := metadata.duplicate(true)
			if definition.material_units == 0 and not facts.has("equipment_id"):
				facts["equipment_id"] = next_equipment_id
				facts["origin_actor"] = 0
				next_equipment_id += 1
			_records[id] = {"id": id, "definition": str(definition_id), "quantity": count, "container": destination, "slot": slot, "cohort": cohort, "metadata": facts}
			ids.append(id)
			remaining -= count
		if not _capacity_valid(destination): return _reject("Weight capacity exceeded.")
		return {"ok": true, "amount": amount, "ids": ids, "remainder": 0, "reason": ""}

func _capacity_valid(id: String) -> bool:
	if not _containers.has(id): return false
	var policy: Dictionary = _containers[id]
	if policy.slots >= 0 and occupied(id) > policy.slots: return false
	if policy.weight >= 0 and weight(id) > policy.weight: return false
	var slots := {}
	for item in _records.values():
		if item.container != id: continue
		if slots.has(item.slot): return false
		slots[item.slot] = true
		if str(item.slot).begins_with("c"):
			var number := str(item.slot).trim_prefix("c")
			if not number.is_valid_int() or int(number) < 0 or (policy.slots >= 0 and int(number) >= policy.slots): return false
		elif not str(item.slot).begins_with("e:"): return false
		if str(item.slot).begins_with("e:"):
			var mount := str(item.slot).trim_prefix("e:")
			var definition := catalog.find(StringName(item.definition))
			if definition == null or not policy.mounts.has(mount) or str(definition.mount) != mount or not definition.compatible_actors.has(policy.actor_kind): return false
	return true

func _move(id: String, requested: int, destination: String, partial: bool, mount: String = "", preserve_identity: bool = false) -> Dictionary:
	if not _records.has(id) or not _containers.has(destination) or requested <= 0: return _reject("Item or destination unavailable.")
	var source: Dictionary = _records[id]
	if requested > int(source.quantity): return _reject("Requested quantity is no longer available.")
	if _containers[source.container].closed or _containers[destination].closed: return _reject("Inventory access has ended.")
	var definition := catalog.find(StringName(source.definition))
	if definition == null: return _reject("Unknown item definition; item preserved.")
	if source.definition == "unsupported_legacy": return _reject("Unsupported item is preserved in quarantine and cannot deploy.")
	if not mount.is_empty():
		if requested != 1 or definition.max_stack != 1: return _reject("Only unique equipment can be mounted.")
		var policy: Dictionary = _containers[destination]
		if not policy.mounts.has(mount) or str(definition.mount) != mount or not definition.compatible_actors.has(policy.actor_kind): return _reject("Item is incompatible with this equipment mount.")
		for other in _records.values():
			if other.container == destination and other.slot == "e:" + mount:
				if source.container != destination or not str(source.slot).begins_with("c"): return _reject("Unequip the existing item first.")
				other.slot = source.slot
		source.container = destination
		source.slot = "e:" + mount
		return {"ok": true, "amount": 1, "remainder": 0, "reason": ""} if _capacity_valid(destination) else _reject("Equipment exceeds capacity.")
	var amount := requested
	var weight_limit: int = _containers[destination].weight
	if destination != source.container and weight_limit >= 0 and definition.unit_weight_g > 0:
		amount = mini(amount, maxi(0, (weight_limit - weight(destination)) / definition.unit_weight_g))
	var room := 0
	var merge_ids: Array[String] = []
	for other in records(destination):
		if not preserve_identity and other.id != id and str(other.slot).begins_with("c") and other.definition == source.definition and other.cohort == source.cohort and other.metadata == source.metadata:
			room += definition.max_stack - int(other.quantity)
			merge_ids.append(other.id)
	var available_slots: int = _containers[destination].slots
	if available_slots < 0: available_slots = MAX_RECORDS
	available_slots -= occupied(destination)
	if source.container == destination and str(source.slot).begins_with("c"): available_slots += 1
	amount = mini(amount, room + maxi(0, available_slots) * definition.max_stack)
	if amount <= 0: return _reject("Cargo is full: no slot or weight capacity.")
	if amount < requested and not partial: return _reject("Requested amount exceeds slot or weight capacity; use Take fitting.")
	var remaining := amount
	for merge_id in merge_ids:
		var count := mini(remaining, definition.max_stack - int(_records[merge_id].quantity))
		_records[merge_id].quantity += count
		source.quantity -= count
		remaining -= count
	if remaining > 0:
		var target_id: String = id if int(source.quantity) == remaining else _fresh_id()
		var moved := source.duplicate(true)
		source.quantity -= remaining
		moved.id = target_id
		moved.quantity = remaining
		moved.container = destination
		if target_id == id: _records.erase(id)
		var slot := _free_slot(destination)
		if slot.is_empty(): return _reject("No free cargo slot.")
		moved.slot = slot
		_records[target_id] = moved
	if _records.has(id) and int(_records[id].quantity) == 0: _records.erase(id)
	return {"ok": true, "amount": amount, "remainder": requested - amount, "reason": ""}

func transfer(id: String, amount: int, destination: String, partial: bool = false, command: String = "", source_revision: int = -1, destination_revision: int = -1, mount: String = "") -> Dictionary:
	var payload := {"id": id, "amount": amount, "destination": destination, "partial": partial, "source_revision": source_revision, "destination_revision": destination_revision, "mount": mount}
	return _transaction("transfer", payload, func() -> Dictionary:
		if not _records.has(id): return _reject("Item is no longer available.")
		var source: String = _records[id].container
		if source_revision >= 0 and source_revision != int(_containers[source].revision): return _reject("Source changed; refresh the selection.")
		if not _containers.has(destination): return _reject("Unknown destination.")
		if destination_revision >= 0 and destination_revision != int(_containers[destination].revision): return _reject("Destination changed; refresh the selection.")
		return _move(id, amount, destination, partial, mount), command)

func transfer_display(id: String, destination: String) -> Dictionary:
	return _transaction("display_transfer", {"id": id, "destination": destination}, func() -> Dictionary:
		var item := record(id)
		if item.is_empty() or item.container not in ["stash", "display:workshop"] or destination not in ["stash", "display:workshop"] or item.container == destination: return _reject("Display item is unavailable.")
		# A displayed stack remains inspectable by its original identity, including
		# after return beside another merge-compatible stack in available storage.
		return _move(id, item.quantity, destination, false, "", true))

func split(id: String, amount: int, command: String = "") -> Dictionary:
	return _transaction("split", {"id": id, "amount": amount}, func() -> Dictionary:
		if not _records.has(id) or amount <= 0 or amount >= int(_records[id].quantity): return _reject("Choose a quantity smaller than the stack.")
		var item: Dictionary = _records[id]
		if _containers[item.container].closed or not str(item.slot).begins_with("c"): return _reject("Cannot split this item.")
		var slot := _free_slot(item.container)
		if slot.is_empty(): return _reject("Splitting needs a free cargo slot.")
		var copy := item.duplicate(true)
		copy.id = _fresh_id()
		copy.quantity = amount
		copy.slot = slot
		item.quantity -= amount
		_records[copy.id] = copy
		return {"ok": true, "amount": amount, "id": copy.id, "reason": ""}, command)

func move_contents(source: String, destination: String, materials_only: bool = false, equipment_only: bool = false, maximum: int = 1000000) -> int:
	var result := _transaction("move_contents", {"source": source, "destination": destination}, func() -> Dictionary:
		var moved := 0
		for item in records(source):
			var definition := catalog.find(StringName(item.definition))
			if definition == null or (materials_only and definition.material_units == 0) or (equipment_only and definition.material_units != 0): continue
			var amount := mini(int(item.quantity), maximum - moved)
			if amount <= 0: break
			var one := _move(item.id, amount, destination, true)
			if one.ok: moved += int(one.amount)
		return {"ok": moved > 0, "amount": moved, "reason": ""})
	return int(result.get("amount", 0)) if result.ok else 0

func fit_value(source: String, destination: String) -> int:
	if _busy or sealed or source == destination or not _containers.has(source) or not _containers.has(destination): return 0
	# Only these two containers participate in a hypothetical transfer. Avoid
	# copying an unrelated large safe stash for every Raider route comparison.
	# No await, callbacks, events, supply changes or externally visible mutation.
	var original_records := _records
	var original_next_id := _next_id
	_records = {}
	for item in original_records.values():
		if item.container in [source, destination]: _records[item.id] = item.duplicate(true)
	var value := 0
	for item in records(source):
		var result := _move(item.id, item.quantity, destination, true)
		if result.ok: value += int(result.amount) * catalog.find(StringName(item.definition)).base_value
	_records = original_records
	_next_id = original_next_id
	return value

func register_actor(id: int) -> bool:
	if sealed or id <= 0 or actor_outcomes.has(id): return false
	actor_outcomes[id] = 0
	ensure_container("actor:%d" % id, "actor")
	return true

func resolve_actor(id: int, extracted: bool) -> Dictionary:
	return _transaction("resolve_actor", {"actor": id, "extracted": extracted}, func() -> Dictionary:
		if actor_outcomes.get(id, -1) != 0: return _reject("Actor inventory is already resolved.")
		var source := "actor:%d" % id
		var drop_id := 0
		var destination := "extracted:%d" % id
		if not extracted and not records(source).is_empty() and (hybrid or quantity(source, true) > 0):
			drop_id = next_drop_id
			next_drop_id += 1
			destination = "ground:%d" % drop_id
			drop_sources[drop_id] = id
			actor_drops[id] = drop_id
		elif not extracted:
			destination = "equipment_ground:%d" % id
		ensure_container(destination, "extracted" if extracted else "ground")
		for item in _records.values():
			if item.container == source:
				item.container = destination
				item.slot = _free_slot(destination)
		_containers[source].closed = true
		actor_outcomes[id] = 2 if extracted else 1
		return {"ok": true, "drop": drop_id, "amount": quantity(destination, true, "world"), "reason": ""})

func release_material_source(point: StringName) -> int:
	var source := "stock:" + str(point)
	var result := _transaction("release_source", {"source": source}, func() -> Dictionary:
		if quantity(source, true) <= 0: return _reject("Source is depleted.")
		var id := next_drop_id
		next_drop_id += 1
		var destination := "ground:%d" % id
		ensure_container(destination, "ground")
		drop_sources[id] = 0
		for item in _records.values():
			if item.container == source:
				item.container = destination
				item.slot = _free_slot(destination)
		return {"ok": true, "amount": quantity(destination, true), "drop": id, "reason": ""})
	return int(result.drop) if result.ok else 0

func assign_equipment(owner: int, responder: bool) -> bool:
	if sealed or owner <= 0 or equipment_assigned.has(owner): return false
	if not actor_outcomes.has(owner): register_actor(owner)
	var result := _transaction("assign_equipment", {"actor": owner}, func() -> Dictionary:
		var definitions: Array = [&"worn_response_rifle"] if responder else [&"raider_rifle", &"electronics_kit"]
		for definition in definitions:
			var metadata := {"equipment_id": next_equipment_id, "origin_actor": owner, "loadout": true}
			next_equipment_id += 1
			var issued := _issue_records("loadout:%d:%s" % [owner, definition], definition, 1, "actor:%d" % owner, "world", metadata)
			if not issued.ok: return issued
			if hybrid:
				var mounted := _move(issued.ids[0], 1, "actor:%d" % owner, false, str(catalog.find(definition).mount))
				if not mounted.ok: return mounted
		equipment_assigned[owner] = true
		return {"ok": true, "amount": definitions.size(), "reason": ""})
	return result.ok

func resolve_equipment(owner: int, extracted: bool) -> bool:
	if sealed or not equipment_assigned.has(owner) or equipment_resolved.has(owner): return false
	if actor_outcomes.get(owner, -1) == 0:
		if not resolve_actor(owner, extracted).ok: return false
	equipment_resolved[owner] = true
	return true

func equipment_location(item: Dictionary) -> int:
	var kind: String = _containers.get(item.container, {}).get("kind", "")
	return {"actor": 0, "ground": 1, "player": 2, "extracted": 3, "banked": 4, "stash": 4, "forfeited": 5}.get(kind, -1)

func equipment_records(location: int = -1, owner: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in records():
		if not item.metadata.has("equipment_id") or (owner > 0 and int(item.metadata.get("origin_actor", 0)) != owner): continue
		if location < 0 or equipment_location(item) == location: result.append(item)
	return result

func recover_equipment(owner: int) -> bool:
	if player_settled: return false
	var result := _transaction("recover_equipment", {"actor": owner}, func() -> Dictionary:
		var count := 0
		for item in equipment_records(1, owner):
			var moved := _move(item.id, 1, "player", false)
			if not moved.ok: return moved
			count += 1
		return {"ok": count > 0, "amount": count, "reason": ""})
	return result.ok

func settle_player(extracted: bool, safe_destination: String = "banked") -> bool:
	if player_settled: return false
	var result := _transaction("settle_player", {"extracted": extracted}, func() -> Dictionary:
		settled_player_summary = {"materials": quantity("player", true, "world"), "equipment": 0, "value": 0}
		for item in equipment_records(2):
			if item.cohort == "world":
				settled_player_summary.equipment += 1
				settled_player_summary.value += catalog.find(StringName(item.definition)).base_value
		var destination := safe_destination if extracted else "forfeited"
		if not _containers.has(destination): return _reject("Settlement destination unavailable.")
		for item in _records.values():
			if item.container == "player":
				item.container = destination
				item.slot = _free_slot(destination)
		_containers.player.closed = true
		player_settled = true
		return {"ok": true, "amount": quantity(destination, true, "world"), "reason": ""})
	return result.ok

func is_valid() -> bool:
	if _records.size() > MAX_RECORDS: return false
	for outcome in actor_outcomes.values():
		if outcome not in [0, 1, 2]: return false
	var totals := {}
	var weights := {}
	var cargo_counts := {}
	var used_slots := {}
	var equipment_ids := {}
	for id in _records:
		var item: Dictionary = _records[id]
		var definition := catalog.find(StringName(item.definition))
		if item.id != id or id.is_empty() or definition == null or item.cohort not in ["world", "imported"] or not _containers.has(item.container) or not item.quantity is int or item.quantity <= 0 or item.quantity > definition.max_stack: return false
		if id.length() > 256 or not serializable_metadata(item.metadata) or JSON.stringify(item.metadata).length() > 4096: return false
		if item.metadata.has("equipment_id"):
			var identity: Variant = item.metadata.equipment_id
			if not identity is int or identity <= 0 or equipment_ids.has(identity) or definition.material_units != 0: return false
			if not item.metadata.get("origin_actor") is int or item.metadata.origin_actor < 0: return false
			equipment_ids[identity] = true
		var key := "%s|%s" % [item.definition, item.cohort]
		totals[key] = int(totals.get(key, 0)) + int(item.quantity)
		var policy: Dictionary = _containers[item.container]
		var slot_key := "%s/%s" % [item.container, item.slot]
		if used_slots.has(slot_key): return false
		used_slots[slot_key] = true
		weights[item.container] = int(weights.get(item.container, 0)) + int(item.quantity) * definition.unit_weight_g
		if str(item.slot).begins_with("c"):
			var number := str(item.slot).trim_prefix("c")
			if not number.is_valid_int() or int(number) < 0 or (policy.slots >= 0 and int(number) >= policy.slots): return false
			cargo_counts[item.container] = int(cargo_counts.get(item.container, 0)) + 1
		elif str(item.slot).begins_with("e:"):
			var mount := str(item.slot).trim_prefix("e:")
			if item.quantity != 1 or not policy.mounts.has(mount) or str(definition.mount) != mount or not definition.compatible_actors.has(policy.actor_kind): return false
		else: return false
	var expected := _initial.duplicate(true)
	if not _transformations is Dictionary or _transformations.size() > MAX_RECORDS: return false
	for receipt in _transformations.values():
		if not receipt is Dictionary or not receipt.get("recipe") is String or not receipt.get("debits") is Dictionary or not receipt.get("credits") is Dictionary: return false
		var recipe := RecipeDefinition.approved(receipt.recipe)
		if recipe == null: return false
		var consumed := {}
		for key in receipt.debits:
			var parts: PackedStringArray = str(key).split("|")
			if parts.size() != 2 or parts[1] not in ["world", "imported"] or not receipt.debits[key] is int or receipt.debits[key] <= 0: return false
			consumed[parts[0]] = int(consumed.get(parts[0], 0)) + int(receipt.debits[key])
			expected[key] = int(expected.get(key, 0)) - int(receipt.debits[key])
		if consumed != recipe.inputs: return false
		var credits := {}
		for id in recipe.outputs: credits[str(id) + "|imported"] = int(recipe.outputs[id])
		if credits != receipt.credits: return false
		for key in credits: expected[key] = int(expected.get(key, 0)) + int(credits[key])
	for key in expected.keys():
		if expected[key] == 0: expected.erase(key)
	if totals != expected: return false
	for id in _containers:
		var policy: Dictionary = _containers[id]
		if policy.slots >= 0 and int(cargo_counts.get(id, 0)) > policy.slots: return false
		if policy.weight >= 0 and int(weights.get(id, 0)) > policy.weight: return false
	return true

func export_state() -> Dictionary:
	return _snapshot().duplicate(true)

func import_state(data: Dictionary) -> bool:
	if _busy: return false
	var before := _snapshot()
	var required := ["records", "containers", "issued", "initial", "next_id", "actors", "assigned", "resolved", "sources", "drops", "next_drop", "next_equipment", "player_settled"]
	for key in required:
		if not data.has(key): return false
	for key in ["records", "containers", "issued", "initial", "actors", "assigned", "resolved", "sources", "drops"]:
		if not data[key] is Dictionary: return false
	var decoded: Dictionary = normalize_json(data)
	if decoded.has("transformations") and not decoded.transformations is Dictionary: return false
	if decoded.records.size() > MAX_RECORDS or not decoded.player_settled is bool: return false
	for key in ["next_id", "next_drop", "next_equipment"]:
		if not decoded[key] is int or decoded[key] < 1 or decoded[key] > 1000000000: return false
	for id in decoded.containers:
		var box: Variant = decoded.containers[id]
		if not id is String or not box is Dictionary: return false
		for key in ["kind", "actor_kind"]:
			if not box.get(key) is String: return false
		for key in ["slots", "weight", "revision"]:
			if not box.get(key) is int: return false
		if box.slots < -1 or box.weight < -1 or not box.get("mounts") is Array or not box.get("closed") is bool: return false
		if box.slots > MAX_RECORDS or box.weight > 1000000000 or box.revision < 0: return false
	for id in decoded.records:
		var item: Variant = decoded.records[id]
		if not id is String or not item is Dictionary: return false
		for key in ["id", "definition", "container", "slot", "cohort"]:
			if not item.get(key) is String: return false
		if not item.get("quantity") is int or not item.get("metadata") is Dictionary: return false
	for key in ["actors", "assigned", "resolved", "sources", "drops"]:
		var numbered := {}
		for id in decoded[key]:
			if not str(id).is_valid_int(): return false
			numbered[int(id)] = decoded[key][id]
		decoded[key] = numbered
	_restore(decoded)
	if not is_valid():
		_restore(before)
		return false
	return true

func install_state(data: Dictionary, kind: String) -> bool:
	if not import_state(data): return false
	serial += 1
	changed.emit({"kind": kind, "serial": serial, "result": {"ok": true}})
	return true

static func normalize_json(value: Variant) -> Variant:
	if value is float and is_finite(value) and floor(value) == value: return int(value)
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = normalize_json(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(normalize_json(item))
		return result
	return value

func transfer_group(source: String, destination: String, command: String = "", preserve_mounts: bool = false) -> Dictionary:
	return _transaction("transfer_group", {"source": source, "destination": destination}, func() -> Dictionary:
		var count := 0
		for item in records(source):
			var mount := str(item.slot).trim_prefix("e:") if preserve_mounts and str(item.slot).begins_with("e:") else ""
			var result := _move(item.id, item.quantity, destination, false, mount)
			if not result.ok: return result
			count += int(result.amount)
		return {"ok": true, "amount": count, "reason": ""}, command)

func persistent_state() -> Dictionary:
	# A serialized checkpoint, not a second spendable set of items.
	var state := _snapshot()
	state.records = {}
	state.containers = {}
	state.initial = {}
	state.actors = {}
	state.assigned = {}
	state.resolved = {}
	state.sources = {}
	state.drops = {}
	state.player_settled = false
	# Persistent projection is a new admission baseline; durable profile operation
	# receipts retain transformation provenance while world-only cohorts are retired.
	state.transformations = {}
	for id in ["stash", "prepared", "escrow", "quarantine", "display:workshop"]:
		if _containers.has(id): state.containers[id] = _containers[id].duplicate(true)
	for item in _records.values():
		if not state.containers.has(item.container): continue
		state.records[item.id] = item.duplicate(true)
		var key := "%s|%s" % [item.definition, item.cohort]
		state.initial[key] = int(state.initial.get(key, 0)) + int(item.quantity)
	return state

func admit_persistent(data: Dictionary) -> bool:
	var decoded: Dictionary = normalize_json(data)
	var candidate := InventoryLedger.new(catalog)
	if not candidate.import_state(decoded): return false
	var result := _transaction("admit_persistent", {}, func() -> Dictionary:
		for id in decoded.containers:
			if id not in ["stash", "prepared", "escrow", "quarantine", "display:workshop"]: return _reject("Invalid persistent location.")
			if not _containers.has(id): _containers[id] = decoded.containers[id].duplicate(true)
		for item in decoded.records.values():
			if _records.has(item.id): return _reject("Duplicate persistent identity.")
			var copy: Dictionary = item.duplicate(true)
			copy.cohort = "imported"
			if copy.metadata.has("equipment_id"):
				copy.metadata.equipment_id = next_equipment_id
				next_equipment_id += 1
			_records[copy.id] = copy
			var key := "%s|imported" % copy.definition
			_initial[key] = int(_initial.get(key, 0)) + int(copy.quantity)
		return {"ok": true, "amount": decoded.records.size(), "reason": ""})
	return result.ok

func seal_world() -> void:
	sealed = true

func transform_recipe(recipe_id: String, command: String) -> Dictionary:
	return _transaction("workshop", {"recipe": recipe_id}, func() -> Dictionary:
		var recipe := RecipeDefinition.approved(recipe_id)
		if recipe == null or not recipe.valid(catalog) or command.is_empty(): return _reject("Unapproved recipe.")
		if not _containers.has("stash") or _containers.stash.closed: return _reject("Stash is closed.")
		var debits := {}
		var inputs: Array = []
		for definition in recipe.inputs:
			var remaining: int = recipe.inputs[definition]
			for item in records("stash"):
				if item.definition != definition or not str(item.slot).begins_with("c"): continue
				var count := mini(remaining, int(item.quantity))
				var key := "%s|%s" % [item.definition, item.cohort]
				debits[key] = int(debits.get(key, 0)) + count
				inputs.append({"id": item.id, "definition": item.definition, "quantity": count})
				_records[item.id].quantity -= count
				if _records[item.id].quantity == 0: _records.erase(item.id)
				remaining -= count
				if remaining == 0: break
			if remaining > 0: return _reject("Missing available stash ingredients: " + str(definition))
		var outputs: Array = []
		var credits := {}
		for definition in recipe.outputs:
			var amount: int = recipe.outputs[definition]
			var baseline := _initial.duplicate(true)
			var issued := _issue_records("workshop:" + command + ":" + str(definition), StringName(definition), amount, "stash", "imported", {"recipe": recipe_id, "operation": command})
			_initial = baseline
			if not issued.ok: return issued
			outputs.append_array(issued.ids)
			credits[str(definition) + "|imported"] = amount
		var receipt := {"recipe": recipe_id, "inputs": inputs, "outputs": outputs, "debits": debits, "credits": credits}
		_transformations[command] = receipt
		return {"ok": true, "reason": "Workshop operation completed.", "transformation": receipt}, command)

static func quarantine_missing(data: Dictionary, definitions: ItemCatalog) -> Dictionary:
	var state: Dictionary = normalize_json(data).duplicate(true)
	if not state.get("records") is Dictionary or not state.get("containers") is Dictionary: return state
	var totals := {}
	for item in state.records.values():
		if not item is Dictionary or not item.get("definition") is String or not item.get("cohort") is String or not item.get("quantity") is int: return data
		var key := "%s|%s" % [item.definition, item.cohort]
		totals[key] = int(totals.get(key, 0)) + int(item.quantity)
	if totals != state.get("initial"): return data
	var ordinal := 0
	var changed_any := false
	for item in state.records.values():
		if not item is Dictionary or not item.get("definition") is String or definitions.find(StringName(item.definition)) != null: continue
		if not item.get("quantity") is int or item.quantity <= 0 or item.quantity > 1000 or not item.get("metadata") is Dictionary: return data
		item.metadata["missing_definition"] = item.definition
		item.definition = "unsupported_legacy"
		item.container = "quarantine"
		item.slot = "c%d" % ordinal
		ordinal += 1
		changed_any = true
	if not changed_any: return state
	# Preserve existing quarantine entries too, with disjoint addresses.
	for item in state.records.values():
		if item.container == "quarantine":
			item.slot = "c%d" % ordinal
			ordinal += 1
	state.containers["quarantine"] = {"kind": "quarantine", "slots": -1, "weight": -1, "actor_kind": "", "mounts": [], "revision": 0, "closed": false}
	state.initial = {}
	for item in state.records.values():
		var key := "%s|%s" % [item.definition, item.cohort]
		state.initial[key] = int(state.initial.get(key, 0)) + int(item.quantity)
	return state

static func serializable_metadata(value: Variant, depth: int = 0) -> bool:
	if depth > 4: return false
	if value is String: return value.length() <= 1024
	if value is bool or value is int or value == null: return true
	if value is float: return is_finite(value)
	if value is Array:
		if value.size() > 64: return false
		for child in value:
			if not serializable_metadata(child, depth + 1): return false
		return true
	if value is Dictionary:
		if value.size() > 64: return false
		for key in value:
			if not key is String or not serializable_metadata(key, depth + 1) or not serializable_metadata(value[key], depth + 1): return false
		return true
	return false

func retype_source(source: String, definitions: Array[StringName]) -> bool:
	# Bootstrap-only substitution, preserving the declared material supply exactly.
	var result := _transaction("source_manifest", {"source": source}, func() -> Dictionary:
		if _issued.has("manifest:" + source) or quantity(source, true) != definitions.size(): return _reject("Invalid or already resolved source manifest.")
		for definition_id in definitions:
			var definition := catalog.find(definition_id)
			if definition == null or definition.material_units != 1: return _reject("Invalid material substitution.")
		for item in records(source):
			var key := "%s|%s" % [item.definition, item.cohort]
			_initial[key] -= int(item.quantity)
			if _initial[key] == 0: _initial.erase(key)
			_records.erase(item.id)
		for index in definitions.size():
			var issued := _issue_records("manifest:%s:%d" % [source, index], definitions[index], 1, source, "world", {})
			if not issued.ok: return issued
		_issued["manifest:" + source] = true
		return {"ok": true, "amount": definitions.size(), "reason": ""})
	return result.ok

func drop_player(id: String, amount: int, command: String) -> Dictionary:
	return _transaction("drop", {"id": id, "amount": amount}, func() -> Dictionary:
		if player_settled or not _records.has(id) or _records[id].container != "player": return _reject("Player item unavailable.")
		var drop_id := next_drop_id
		var destination := "ground:%d" % drop_id
		ensure_container(destination, "ground")
		var moved := _move(id, amount, destination, false)
		if not moved.ok: return moved
		next_drop_id += 1
		drop_sources[drop_id] = 0
		moved["drop"] = drop_id
		return moved, command)
