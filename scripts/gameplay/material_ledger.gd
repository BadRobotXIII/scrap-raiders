class_name MaterialLedger
extends RefCounted
## Compatibility projection. InventoryLedger is the sole quantity writer.

signal transfer_accepted(kind: StringName, details: Dictionary)
enum Outcome { ACTIVE, DEFEATED, EXTRACTED }
var inventory: InventoryLedger
var accepted_transfers: int = 0
var total_materials: int:
	get: return inventory.material_total()
var protected_materials: int:
	get: return _at("stock")
var carried_materials: int:
	get: return _at("actor")
var dropped_materials: int:
	get: return _at("ground")
var recovered_materials: int:
	get: return inventory.quantity("player", true, "world")
var lost_materials: int:
	get: return _at("extracted")
var banked_materials: int:
	get: return inventory.quantity("banked", true, "world") + inventory.quantity("stash", true, "world")
var forfeited_materials: int:
	get: return inventory.quantity("forfeited", true, "world")
var active_raiders: int:
	get:
		var count := 0
		for state in inventory.actor_outcomes.values():
			if state == Outcome.ACTIVE: count += 1
		return count

func _init(stock: Dictionary = {}, raider_ids: Array[int] = [], initial_ground: Dictionary = {}, authority: InventoryLedger = null) -> void:
	inventory = authority if authority != null else InventoryLedger.new()
	for point in stock:
		inventory.ensure_container("stock:" + str(point), "stock")
		if int(stock[point]) > 0:
			var issued := inventory.issue("stock:" + str(point), &"scrap_steel", int(stock[point]), "stock:" + str(point))
			assert(issued.ok)
	for drop in initial_ground:
		inventory.ensure_container("ground:%d" % int(drop), "ground")
		var issued := inventory.issue("initial_ground:%d" % int(drop), &"scrap_steel", int(initial_ground[drop]), "ground:%d" % int(drop))
		assert(issued.ok)
		inventory.drop_sources[int(drop)] = 0
		inventory.next_drop_id = maxi(inventory.next_drop_id, int(drop) + 1)
	for id in raider_ids:
		var registered := inventory.register_actor(id)
		assert(registered)
	assert(is_conserved())

func _at(kind: String) -> int:
	return inventory.material_at(kind)

func available(point_id: StringName) -> int:
	return inventory.quantity("stock:" + str(point_id), true, "world")

func register_raider(id: int) -> bool:
	if not inventory.register_actor(id): return false
	_notify(&"register_raider", {"actor": id, "amount": 0})
	return true

func cargo_for(id: int) -> int:
	return inventory.quantity("actor:%d" % id, true, "world")

func release_source(point_id: StringName) -> int:
	var id := inventory.release_material_source(point_id)
	if id > 0: _notify(&"release_source", {"source": point_id, "drop": id, "amount": ground_for(id)})
	return id

func collect_ground(id: int, drop: int, capacity: int) -> int:
	if not is_active(id) or capacity <= cargo_for(id): return 0
	var amount := inventory.move_contents("ground:%d" % drop, "actor:%d" % id, true, false, capacity - cargo_for(id))
	if amount > 0: _notify(&"collect_ground", {"actor": id, "drop": drop, "amount": amount})
	return amount

func ground_for(id: int) -> int:
	return inventory.quantity("ground:%d" % id, true, "world")

func drop_source(id: int) -> int:
	return int(inventory.drop_sources.get(id, 0))

func is_active(id: int) -> bool:
	return inventory.actor_outcomes.get(id, -1) == Outcome.ACTIVE

func collect(id: int, point_id: StringName, capacity: int) -> int:
	if not is_active(id) or capacity <= cargo_for(id): return 0
	var amount := inventory.move_contents("stock:" + str(point_id), "actor:%d" % id, true, false, capacity - cargo_for(id))
	if amount > 0: _notify(&"collect", {"actor": id, "source": point_id, "amount": amount})
	return amount

func defeat(id: int) -> int:
	var amount := cargo_for(id)
	var result := inventory.resolve_actor(id, false)
	if not result.ok: return -1
	var drop: int = result.drop if amount > 0 or inventory.hybrid else 0
	_notify(&"defeat", {"actor": id, "drop": drop, "amount": amount})
	return drop

func extract(id: int) -> bool:
	var amount := cargo_for(id)
	if not inventory.resolve_actor(id, true).ok: return false
	_notify(&"extract", {"actor": id, "amount": amount})
	return true

func recover(drop: int) -> int:
	if inventory.player_settled: return 0
	var amount := inventory.move_contents("ground:%d" % drop, "player", true)
	if amount > 0: _notify(&"recover", {"drop": drop, "amount": amount})
	return amount

func seal() -> void:
	inventory.sealed = true

func settle_player(extracted: bool) -> bool:
	if inventory.sealed or inventory.material_notified: return false
	var amount := recovered_materials
	if not inventory.player_settled and not inventory.settle_player(extracted): return false
	inventory.material_notified = true
	_notify(&"settle_player", {"extracted": extracted, "amount": amount if amount > 0 else (banked_materials if extracted else forfeited_materials)})
	return true

func can_settle_player() -> bool:
	return not inventory.sealed and not inventory.player_settled and not inventory.material_notified

func is_conserved() -> bool:
	return inventory.is_valid() and protected_materials + carried_materials + dropped_materials + recovered_materials + lost_materials + banked_materials + forfeited_materials == total_materials

func _notify(kind: StringName, details: Dictionary) -> void:
	accepted_transfers += 1
	assert(is_conserved())
	details["serial"] = accepted_transfers
	transfer_accepted.emit(kind, details)
