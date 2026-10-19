class_name MaterialLedger
extends RefCounted
## Sole writer of material quantities/locations. No mission success/failure policy.

enum Outcome { ACTIVE, DEFEATED, EXTRACTED }

var _stock: Dictionary[StringName, int] = {}
var _cargo: Dictionary[int, int] = {}
var _outcomes: Dictionary[int, Outcome] = {}
var _ground: Dictionary[int, int] = {}
var _drop_sources: Dictionary[int, int] = {}
var _next_drop_id: int = 1
var _recovered: int = 0
var _banked: int = 0
var _forfeited: int = 0
var _player_settled: bool = false
var _lost: int = 0
var _total: int = 0
var _sealed: bool = false
var accepted_transfers: int = 0

var total_materials: int:
	get: return _total
var protected_materials: int:
	get: return _sum(_stock)
var carried_materials: int:
	get: return _sum(_cargo)
var dropped_materials: int:
	get: return _sum(_ground)
var recovered_materials: int:
	get: return _recovered
var lost_materials: int:
	get: return _lost
var banked_materials: int:
	get: return _banked
var forfeited_materials: int:
	get: return _forfeited
var active_raiders: int:
	get:
		var count := 0
		for id in _outcomes:
			if _outcomes[id] == Outcome.ACTIVE:
				count += 1
		return count


func _init(stock: Dictionary = {}, raider_ids: Array[int] = [], initial_ground: Dictionary = {}) -> void:
	for point_id in stock:
		assert(int(stock[point_id]) >= 0)
		_stock[StringName(point_id)] = int(stock[point_id])
		_total += int(stock[point_id])
	for drop_id in initial_ground:
		assert(int(drop_id) > 0 and int(initial_ground[drop_id]) > 0)
		_ground[int(drop_id)] = int(initial_ground[drop_id])
		_drop_sources[int(drop_id)] = 0 # Mission stock, not Raider cargo.
		_total += int(initial_ground[drop_id])
		_next_drop_id = maxi(_next_drop_id, int(drop_id) + 1)
	for id in raider_ids:
		assert(not _cargo.has(id) and id > 0)
		_cargo[id] = 0
		_outcomes[id] = Outcome.ACTIVE
	assert(is_conserved())


func available(point_id: StringName) -> int:
	return _stock.get(point_id, 0)


func register_raider(id: int) -> bool:
	if _sealed or id <= 0 or _cargo.has(id):
		return false
	_cargo[id] = 0
	_outcomes[id] = Outcome.ACTIVE
	_verify_transfer()
	return true


func cargo_for(raider_id: int) -> int:
	return _cargo.get(raider_id, 0)


func release_source(point_id: StringName) -> int:
	if _sealed or available(point_id) <= 0:
		return 0
	var id := _next_drop_id
	_next_drop_id += 1
	_ground[id] = _stock[point_id]
	_stock[point_id] = 0
	_drop_sources[id] = 0
	_verify_transfer()
	return id


func collect_ground(raider_id: int, drop_id: int, capacity: int) -> int:
	if _sealed or not is_active(raider_id) or capacity <= cargo_for(raider_id):
		return 0
	var amount := mini(capacity - cargo_for(raider_id), ground_for(drop_id))
	if amount <= 0:
		return 0
	_ground[drop_id] -= amount
	_cargo[raider_id] += amount
	_verify_transfer()
	return amount


func ground_for(drop_id: int) -> int:
	return _ground.get(drop_id, 0)


func drop_source(drop_id: int) -> int:
	return _drop_sources.get(drop_id, 0)


func is_active(raider_id: int) -> bool:
	return _outcomes.has(raider_id) and _outcomes[raider_id] == Outcome.ACTIVE


func collect(raider_id: int, point_id: StringName, capacity: int) -> int:
	if _sealed or not is_active(raider_id) or capacity <= cargo_for(raider_id):
		return 0
	var amount := mini(capacity - cargo_for(raider_id), available(point_id))
	if amount <= 0:
		return 0
	_stock[point_id] -= amount
	_cargo[raider_id] += amount
	_verify_transfer()
	return amount


func defeat(raider_id: int) -> int:
	# -1 rejected, 0 empty death, positive value = unique new ground stack ID.
	if _sealed or not is_active(raider_id):
		return -1
	var amount := cargo_for(raider_id)
	_cargo[raider_id] = 0
	_outcomes[raider_id] = Outcome.DEFEATED
	var drop_id := 0
	if amount > 0:
		drop_id = _next_drop_id
		_next_drop_id += 1
		_ground[drop_id] = amount
		_drop_sources[drop_id] = raider_id
	_verify_transfer()
	return drop_id


func extract(raider_id: int) -> bool:
	if _sealed or not is_active(raider_id):
		return false
	_lost += cargo_for(raider_id)
	_cargo[raider_id] = 0
	_outcomes[raider_id] = Outcome.EXTRACTED
	_verify_transfer()
	return true


func recover(drop_id: int) -> int:
	if _sealed or _player_settled or ground_for(drop_id) <= 0:
		return 0
	var amount := _ground[drop_id]
	_ground[drop_id] = 0
	_recovered += amount
	_verify_transfer()
	return amount


func seal() -> void:
	_sealed = true


func settle_player(extracted: bool) -> bool:
	if _sealed or _player_settled:
		return false
	_player_settled = true
	if extracted:
		_banked += _recovered
	else:
		_forfeited += _recovered
	_recovered = 0
	_verify_transfer()
	return true


func can_settle_player() -> bool:
	return not _sealed and not _player_settled


func is_conserved() -> bool:
	if protected_materials + carried_materials + dropped_materials + _recovered + _lost + _banked + _forfeited != _total:
		return false
	for records in [_stock, _cargo, _ground]:
		for amount in records.values():
			if amount < 0:
				return false
	for id in _outcomes:
		if not is_active(id) and cargo_for(id) != 0:
			return false
	return _recovered >= 0 and _lost >= 0 and _banked >= 0 and _forfeited >= 0


func _verify_transfer() -> void:
	accepted_transfers += 1
	# Execute validation in release builds too; assert adds debug diagnostics.
	var valid := is_conserved()
	if not valid:
		push_error("Material conservation invariant violated")
	assert(valid, "Material conservation invariant violated")


func _sum(records: Dictionary) -> int:
	var result := 0
	for id in records:
		result += int(records[id])
	return result
