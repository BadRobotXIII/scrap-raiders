class_name EncounterLayout
extends Resource
## Initial conditions only. Never commands actors or owns live quantities.

@export var layout_id: StringName
@export var salvage_markers: PackedStringArray
@export var salvage_quantities: PackedInt32Array
@export var entry_markers: PackedStringArray
@export var profiles: Array[RaiderProfile] = []
@export var machine_routes: PackedStringArray = PackedStringArray(["ScoutRoute", "GuardRoute"])


func validation_error(config: MissionConfig) -> String:
	if layout_id.is_empty() or salvage_markers.size() != config.salvage_point_count or salvage_quantities.size() != salvage_markers.size() or entry_markers.size() != config.raider_count:
		return "Incomplete encounter layout."
	var seen := {}
	for index in range(salvage_markers.size()):
		if salvage_markers[index].is_empty() or seen.has(salvage_markers[index]) or salvage_quantities[index] <= 0:
			return "Invalid or duplicate encounter salvage."
		seen[salvage_markers[index]] = true
	for marker in entry_markers:
		if not config.spawn_markers.has(marker):
			return "Unknown encounter entry."
	if profiles.size() != config.raider_count or profiles.has(null) or machine_routes.size() != 2:
		return "Invalid encounter profiles or patrols."
	return ""
