@tool
extends Node3D
## Presentation-only selection. Structural nodes/collision never change.

@export var art_enabled: bool = true:
	set(value):
		art_enabled = value
		if is_node_ready():
			apply_visibility()
@export var graybox_visuals: Array[NodePath] = []
@export var production_visuals: Array[NodePath] = []


func _ready() -> void:
	apply_visibility()


func apply_visibility() -> void:
	for path in graybox_visuals:
		var visual := get_node_or_null(path) as Node3D
		if visual != null:
			visual.visible = not art_enabled
	for path in production_visuals:
		var visual := get_node_or_null(path) as Node3D
		if visual != null:
			visual.visible = art_enabled
