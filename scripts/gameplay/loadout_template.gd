class_name LoadoutTemplate
extends RefCounted
## Desired definitions only. A template never owns item instances.
const MOUNTS := ["primary", "armor", "power", "mobility", "utility"]

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("name") is String or value.name.strip_edges().is_empty() or value.name.length() > 64: return false
	if not value.get("mounts") is Dictionary or value.mounts.size() > 5 or not value.get("cargo") is Array or value.cargo.size() > 32: return false
	for mount in value.mounts:
		if mount not in MOUNTS or not definition_id_valid(value.mounts[mount]): return false
	for row in value.cargo:
		if not row is Dictionary or not definition_id_valid(row.get("definition")) or not row.get("quantity") is int or row.quantity < 1 or row.quantity > 1000: return false
	return true

static func definition_id_valid(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 80 and value.is_valid_identifier()

static func from_inventory(authority: InventoryLedger, name: String) -> Dictionary:
	var value := {"name": name.strip_edges(), "mounts": {}, "cargo": []}
	var cargo := {}
	for item in authority.records("prepared"):
		if str(item.slot).begins_with("e:"): value.mounts[str(item.slot).trim_prefix("e:")] = str(item.definition)
		else: cargo[item.definition] = int(cargo.get(item.definition, 0)) + int(item.quantity)
	for definition in cargo: value.cargo.append({"definition": str(definition), "quantity": cargo[definition]})
	return value
