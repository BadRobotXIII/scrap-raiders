class_name RaiderSocialConfig
extends Resource
## Authored encounter attitudes, independent from personality or squad assignment.

@export var allied_pairs: Array[Vector2i] = []
@export var hostile_pairs: Array[Vector2i] = []
@export var cooperation_enabled: bool = false
@export var loot_enabled: bool = false
@export var communication_radius: float = 15.0
@export var memory_seconds: float = 3.0
@export var loot_radius: float = 12.0
@export var responder_allied_to: PackedInt32Array = []
@export var responder_hostile_to: PackedInt32Array = []
@export var responders_allied: bool = true
@export var opportunist_ids: PackedInt32Array = []
@export var betrayal_profile: RaiderBetrayalProfile


func validation_error(count: int) -> String:
	if betrayal_profile != null and not betrayal_profile.validation_error().is_empty():
		return betrayal_profile.validation_error()
	var opportunists := {}
	for id in opportunist_ids:
		if id < 1 or id > count or opportunists.has(id) or betrayal_profile == null:
			return "Invalid opportunist registration."
		opportunists[id] = true
	if not is_finite(communication_radius) or communication_radius <= 0 or not is_finite(memory_seconds) or memory_seconds <= 0 or not is_finite(loot_radius) or loot_radius <= 0:
		return "Invalid social perception tuning."
	var responder_ids := {}
	for id in Array(responder_allied_to) + Array(responder_hostile_to):
		if id < 1 or id > count or responder_ids.has(id):
			return "Invalid or conflicting responder relation."
		responder_ids[id] = true
	var seen := {}
	for pair in allied_pairs + hostile_pairs:
		var key := Vector2i(mini(pair.x, pair.y), maxi(pair.x, pair.y))
		if key.x <= 0 or key.y > count or key.x == key.y or seen.has(key):
			return "Invalid or duplicate social relation pair."
		seen[key] = true
	return ""
