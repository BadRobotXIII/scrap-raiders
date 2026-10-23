class_name EquipmentLedger
extends RefCounted
## Sole writer of equipment ownership. Items are not mission material units.

signal transfer_accepted(kind: StringName, details: Dictionary)

enum Location { CARRIED, GROUND, RECOVERED, EXTRACTED, BANKED, FORFEITED }
var _items: Dictionary[int, Dictionary] = {}
var _owners: Dictionary[int, Array] = {}
var _resolved: Dictionary[int, bool] = {}
var _next_id: int = 1
var accepted_transfers: int = 0
var _sealed: bool = false
var _player_settled: bool = false


func assign_loadout(owner_id: int, responder: bool) -> bool:
	if _sealed or _owners.has(owner_id) or owner_id <= 0:
		return false
	_owners[owner_id] = []
	# A responder's worn weapon is worth one; regular loadouts total six.
	var definitions: Array = [["Worn response rifle", 1]] if responder else [["Raider rifle", 4], ["Electronics kit", 2]]
	for definition in definitions:
		_items[_next_id] = {"owner": owner_id, "name": definition[0], "value": definition[1], "location": Location.CARRIED}
		_owners[owner_id].append(_next_id)
		_next_id += 1
	_verify()
	_notify(&"assign_loadout", {"actor": owner_id, "count": definitions.size(), "value": 1 if responder else 6})
	return true


func resolve(owner_id: int, extracted: bool = false) -> bool:
	if _sealed or not _owners.has(owner_id) or _resolved.has(owner_id):
		return false
	_resolved[owner_id] = true
	for id in _owners[owner_id]:
		_items[id].location = Location.EXTRACTED if extracted else Location.GROUND
	_verify()
	_notify(&"resolve", {"actor": owner_id, "count": _owners[owner_id].size(), "extracted": extracted})
	return true


func recover(owner_id: int) -> bool:
	if _sealed or _player_settled or ground_count(owner_id) == 0:
		return false
	var count := ground_count(owner_id)
	var value := value_at(Location.GROUND, owner_id)
	for id in _owners[owner_id]:
		if _items[id].location == Location.GROUND:
			_items[id].location = Location.RECOVERED
	_verify()
	_notify(&"recover", {"actor": owner_id, "count": count, "value": value})
	return true


func ground_count(owner_id: int = 0) -> int:
	return count_at(Location.GROUND, owner_id)


func description_for(owner_id: int) -> String:
	var names := PackedStringArray()
	for id in _owners.get(owner_id, []):
		names.append(_items[id].name)
	return " + ".join(names)


func count_at(location: Location, owner_id: int = 0) -> int:
	var count := 0
	for item in _items.values():
		if item.location == location and (owner_id == 0 or item.owner == owner_id):
			count += 1
	return count


func value_at(location: Location, owner_id: int = 0) -> int:
	var value := 0
	for item in _items.values():
		if item.location == location and (owner_id == 0 or item.owner == owner_id):
			value += item.value
	return value


func seal() -> void:
	_sealed = true


func recovered_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for id in _items:
		if _items[id].location == Location.RECOVERED:
			items.append({"id": id, "name": _items[id].name, "value": _items[id].value})
	return items


func settle_player(extracted: bool) -> bool:
	if _sealed or _player_settled:
		return false
	var count := count_at(Location.RECOVERED)
	var value := value_at(Location.RECOVERED)
	_player_settled = true
	for item in _items.values():
		if item.location == Location.RECOVERED:
			item.location = Location.BANKED if extracted else Location.FORFEITED
	_verify()
	_notify(&"settle_player", {"count": count, "value": value, "extracted": extracted})
	return true


func can_settle_player() -> bool:
	return not _sealed and not _player_settled


func is_valid() -> bool:
	var seen := {}
	for owner_id in _owners:
		for id in _owners[owner_id]:
			if seen.has(id) or not _items.has(id) or _items[id].owner != owner_id:
				return false
			seen[id] = true
			if _items[id].location not in Location.values() or _items[id].value < 0:
				return false
			if _resolved.has(owner_id) == (_items[id].location == Location.CARRIED):
				return false
	return seen.size() == _items.size()


func _verify() -> void:
	accepted_transfers += 1
	var valid := is_valid()
	if not valid:
		push_error("Equipment ownership invariant violated")
	assert(valid)


func _notify(kind: StringName, details: Dictionary) -> void:
	details["serial"] = accepted_transfers
	transfer_accepted.emit(kind, details)
