class_name PlaceableDefinition
extends Resource
@export var definition_id: String = ""
@export var display_name: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var dimensions: Vector3 = Vector3.ONE

static func find(id: String) -> PlaceableDefinition:
	if id not in ["cabinet", "scrap_bin", "pallet_load"]: return null
	return load("res://resources/sanctuary/" + id + ".tres") as PlaceableDefinition
