class_name MissionObjectiveDefinition
extends Resource
## Immutable mission data. Banked kinds deliberately exclude temporary possession.

enum Kind { BANK_MATERIALS, BANK_EQUIPMENT, EXTRACT, DEFEAT_HOSTILE_RAIDERS }
@export var objective_id: StringName
@export var description: String
@export var kind: Kind = Kind.BANK_MATERIALS
@export_range(1, 999) var target: int = 1
@export var required: bool = false


func validation_error() -> String:
	if objective_id.is_empty() or description.strip_edges().is_empty():
		return "Objectives need an ID and description."
	if kind not in Kind.values() or target <= 0 or (kind == Kind.EXTRACT and target != 1):
		return "Invalid objective kind or target."
	return ""
