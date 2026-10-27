class_name LootTable
extends Resource
## Resolves a bounded manifest once; never called by opening a source.
@export var table_version: int = 1
@export var salvage_definitions: Array[StringName] = [&"scrap_steel", &"copper_winding", &"servo_motor", &"industrial_sensor", &"control_pcb"]

func manifest(mission_id: StringName, seed_value: int, layout: String, source: String, units: int) -> Array[StringName]:
	var random := RandomNumberGenerator.new()
	var digest := ("loot/%d/%s/%d/%s/%s" % [table_version, mission_id, seed_value, layout, source]).sha256_text()
	random.seed = digest.substr(0, 15).hex_to_int()
	var candidates := salvage_definitions.duplicate()
	candidates.sort()
	var result: Array[StringName] = []
	for index in units: result.append(candidates[random.randi_range(0, candidates.size() - 1)])
	return result
