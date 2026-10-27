class_name EquipmentLedger
extends RefCounted
## Compatibility projection over the same InventoryLedger used for materials.

signal transfer_accepted(kind: StringName, details: Dictionary)
enum Location { CARRIED, GROUND, RECOVERED, EXTRACTED, BANKED, FORFEITED }
var inventory: InventoryLedger
var accepted_transfers: int = 0
var _items: Dictionary:
	get:
		var result := {}
		for item in inventory.equipment_records():
			var definition := inventory.catalog.find(StringName(item.definition))
			result[int(item.metadata.equipment_id)] = {"owner": int(item.metadata.origin_actor), "name": definition.display_name, "value": definition.base_value, "location": inventory.equipment_location(item)}
		return result

func _init(authority: InventoryLedger = null) -> void:
	inventory = authority if authority != null else InventoryLedger.new()

func assign_loadout(owner_id: int, responder: bool) -> bool:
	if not inventory.assign_equipment(owner_id, responder): return false
	_notify(&"assign_loadout", {"actor": owner_id, "count": 1 if responder else 2, "value": 1 if responder else 6})
	return true

func resolve(owner_id: int, extracted: bool = false) -> bool:
	if not inventory.resolve_equipment(owner_id, extracted): return false
	_notify(&"resolve", {"actor": owner_id, "count": inventory.equipment_records(-1, owner_id).size(), "extracted": extracted})
	return true

func recover(owner_id: int) -> bool:
	var count := ground_count(owner_id)
	var value := value_at(Location.GROUND, owner_id)
	if not inventory.recover_equipment(owner_id): return false
	_notify(&"recover", {"actor": owner_id, "count": count, "value": value})
	return true

func ground_count(owner_id: int = 0) -> int:
	return count_at(Location.GROUND, owner_id)

func description_for(owner_id: int) -> String:
	var names := PackedStringArray()
	for item in inventory.equipment_records(-1, owner_id):
		names.append(inventory.catalog.find(StringName(item.definition)).display_name)
	return " + ".join(names)

func count_at(location: Location, owner_id: int = 0) -> int:
	return inventory.equipment_summary(location, owner_id).x

func value_at(location: Location, owner_id: int = 0) -> int:
	return inventory.equipment_summary(location, owner_id).y

func seal() -> void:
	inventory.sealed = true

func recovered_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in inventory.equipment_records(Location.RECOVERED):
		if item.cohort != "world": continue
		var definition := inventory.catalog.find(StringName(item.definition))
		result.append({"id": int(item.metadata.equipment_id), "name": definition.display_name, "value": definition.base_value})
	return result

func settle_player(extracted: bool) -> bool:
	if inventory.sealed or inventory.equipment_notified: return false
	var count := count_at(Location.RECOVERED)
	var value := value_at(Location.RECOVERED)
	if not inventory.player_settled and not inventory.settle_player(extracted): return false
	count = int(inventory.settled_player_summary.get("equipment", count))
	value = int(inventory.settled_player_summary.get("value", value))
	inventory.equipment_notified = true
	_notify(&"settle_player", {"count": count, "value": value, "extracted": extracted})
	return true

func can_settle_player() -> bool:
	return not inventory.sealed and not inventory.player_settled and not inventory.equipment_notified

func is_valid() -> bool:
	return inventory.is_valid()

func _notify(kind: StringName, details: Dictionary) -> void:
	accepted_transfers += 1
	assert(is_valid())
	details["serial"] = accepted_transfers
	transfer_accepted.emit(kind, details)
