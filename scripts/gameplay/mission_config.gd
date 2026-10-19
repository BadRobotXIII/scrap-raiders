class_name MissionConfig
extends Resource
## Mission definitions only. Runtime state belongs to the arena and ledger.

@export var display_name: String = "Intercept"
@export_range(1, 5) var raider_count: int = 3
@export_range(1, 3) var salvage_point_count: int = 3
@export_range(1, 99) var materials_per_point: int = 3
@export_range(10.0, 600.0) var duration: float = 180.0
@export var entry_times: PackedFloat32Array = PackedFloat32Array([0, 0, 0])
@export var spawn_markers: PackedStringArray = PackedStringArray(["Spawn1", "Spawn2", "Spawn3", "Spawn4", "Spawn5"])
@export var exits: PackedStringArray = PackedStringArray(["Extraction", "Extraction2"])
@export var seed: int = 4711
@export_range(0, 3) var ground_stacks: int = 0
@export_range(1, 99) var materials_per_stack: int = 3


func validation_error() -> String:
	if raider_count < 1 or raider_count > 5 or salvage_point_count < 1 or salvage_point_count > 3 or materials_per_point < 1:
		return "Invalid Raider or salvage quantities."
	if not is_finite(duration) or duration <= 0 or entry_times.size() != raider_count or spawn_markers.is_empty() or exits.is_empty():
		return "Missing entry schedule, spawn markers, exits, or duration."
	var previous := -1.0
	for time in entry_times:
		if not is_finite(time) or time < 0 or time < previous or time >= duration:
			return "Entry times must be ordered and precede the deadline."
		previous = time
	if ground_stacks < 0 or ground_stacks > 3 or materials_per_stack < 1:
		return "Invalid initial ground stock."
	return ""
