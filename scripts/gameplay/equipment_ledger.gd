class_name EquipmentLedger
extends RefCounted
## Sole writer of equipment ownership. Items are not mission material units.

enum Location { CARRIED, GROUND, RECOVERED, EXTRACTED }
var _items: Dictionary[int, Dictionary] = {}
var _owners: Dictionary[int, Array] = {}
var _resolved: Dictionary[int, bool] = {}
var _next_id: int = 1
var _sealed: bool = false


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
	return true


func resolve(owner_id: int, extracted: bool = false) -> bool:
	if _sealed or not _owners.has(owner_id) or _resolved.has(owner_id):
		return false
	_resolved[owner_id] = true
	for id in _owners[owner_id]:
		_items[id].location = Location.EXTRACTED if extracted else Location.GROUND
	_verify()
	return true


func recover(owner_id: int) -> bool:
	if _sealed or ground_count(owner_id) == 0:
		return false
	for id in _owners[owner_id]:
		if _items[id].location == Location.GROUND:
			_items[id].location = Location.RECOVERED
	_verify()
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
	var valid := is_valid()
	if not valid:
		push_error("Equipment ownership invariant violated")
	assert(valid)
