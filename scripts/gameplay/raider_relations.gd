class_name RaiderRelations
extends RefCounted
## Pair attitudes only. Neither salvage entitlement nor squad membership is implied.

enum Attitude { ALLIED, NEUTRAL, HOSTILE }
var ledger: MaterialLedger
var _pairs: Dictionary[Vector2i, Attitude] = {}
var _sealed: bool = false
var _events: Array[Dictionary] = []


func _init(materials: MaterialLedger) -> void:
	ledger = materials


func attitude(a: int, b: int) -> Attitude:
	return _pairs.get(Vector2i(mini(a, b), maxi(a, b)), Attitude.NEUTRAL)


func set_attitude(a: int, b: int, next: Attitude, reason: String, now: float) -> bool:
	if _sealed or a == b or not ledger.is_active(a) or not ledger.is_active(b) or reason.is_empty() or not is_finite(now):
		return false
	if next < Attitude.ALLIED or next > Attitude.HOSTILE or attitude(a, b) == next:
		return false
	_pairs[Vector2i(mini(a, b), maxi(a, b))] = next
	_events.append({"a": a, "b": b, "attitude": next, "reason": reason, "time": now})
	return true


func events() -> Array[Dictionary]:
	return _events.duplicate(true)


func last_reason(a: int, b: int) -> String:
	for index in range(_events.size() - 1, -1, -1):
		var event := _events[index]
		if (event.a == a and event.b == b) or (event.a == b and event.b == a):
			return event.reason
	return "default neutral"


func seal() -> void:
	_sealed = true
