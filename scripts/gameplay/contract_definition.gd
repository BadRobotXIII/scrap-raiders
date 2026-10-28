class_name ContractDefinition
extends Resource
@export var contract_id: StringName
@export var display_name: String
@export_file("*.tscn") var scene_path: String
@export var mission: MissionConfig

func validation_error() -> String:
	if contract_id.is_empty() or display_name.is_empty() or not ResourceLoader.exists(scene_path) or mission == null: return "Contract is incomplete."
	return mission.validation_error()
