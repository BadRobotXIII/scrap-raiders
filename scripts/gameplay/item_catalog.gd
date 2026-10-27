class_name ItemCatalog
extends Resource

@export var definitions: Array[ItemDefinition] = []

func find(id: StringName) -> ItemDefinition:
	if id == &"unsupported_legacy":
		var preserved := ItemDefinition.new()
		preserved.definition_id = id
		preserved.display_name = "Unsupported item (preserved)"
		preserved.description = "Original data is preserved in quarantine; restore its definition before deployment."
		preserved.max_stack = 1000
		return preserved
	for definition in definitions:
		if definition.definition_id == id:
			return definition
	return null

func validation_error() -> String:
	var seen := {}
	for definition in definitions:
		if definition == null or not definition.validation_error().is_empty() or seen.has(definition.definition_id):
			return "Invalid or duplicate catalog definition."
		seen[definition.definition_id] = true
	return ""
