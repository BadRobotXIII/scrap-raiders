class_name InventoryRules
extends Resource
## Shared capacity policy; different actors supply configuration, not algorithms.

@export var cargo_slots: int = -1
@export var weight_limit_g: int = -1
@export var actor_kind: StringName = &"robot"
@export var equipment_slots: PackedStringArray = []
@export var world_drop_limit: int = 64

func validation_error() -> String:
	if cargo_slots < -1 or cargo_slots > 1024 or weight_limit_g < -1 or weight_limit_g > 1000000000:
		return "Invalid inventory capacity."
	return ""
