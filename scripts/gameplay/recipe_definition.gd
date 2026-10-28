class_name RecipeDefinition
extends Resource
## Approved deterministic transformations. Definitions contain no owned items.
@export var recipe_id: String = ""
@export var display_name: String = ""
@export var inputs: Dictionary = {}
@export var outputs: Dictionary = {}
@export var disassembly: bool = true

static func approved(id: String) -> RecipeDefinition:
	if id not in ["strip_raider_rifle", "strip_response_rifle", "recover_servo", "fabricate_blaster", "cargo_rack_1"]: return null
	return load("res://resources/workshop/recipes/" + id + ".tres") as RecipeDefinition

func valid(catalog: ItemCatalog) -> bool:
	if recipe_id.is_empty() or inputs.is_empty(): return false
	for group in [inputs, outputs]:
		for id in group:
			if catalog.find(StringName(id)) == null or not group[id] is int or group[id] <= 0 or group[id] > 1000: return false
	return true
