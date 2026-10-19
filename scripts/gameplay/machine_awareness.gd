class_name MachineAwareness
extends RefCounted
## Mission-local observations only: sources publish snapshots, recipients choose actions.

var _reports: Dictionary[StringName, Dictionary] = {}
var lifetime: float = 3.0


func observe(source: StringName, target_id: int, position: Vector3, now: float) -> void:
	_reports[source] = {"source": source, "target_id": target_id, "position": position, "expires": now + lifetime}


func forget_source(source: StringName) -> void:
	_reports.erase(source)


func observations(now: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in _reports.keys():
		if _reports[source].expires <= now:
			_reports.erase(source)
		else:
			result.append(_reports[source].duplicate(true))
	return result
