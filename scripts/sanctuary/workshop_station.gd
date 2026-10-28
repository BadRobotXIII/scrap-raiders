class_name WorkshopStation
extends Node3D
@export var station_id: StringName
@export var display_name: String
@export var context: StringName
@export var anchor_offset: Vector3 = Vector3(0, 0, -1.8)
var available: bool = true
var requirement: String = ""

func anchor() -> Vector3:
	return global_transform * anchor_offset

func _ready() -> void:
	var cabinet := preload("res://scenes/environment/props/control_cabinet.tscn").instantiate()
	add_child(cabinet)
	var label := Label3D.new()
	label.text = display_name.to_upper()
	label.position = Vector3(0, 2.2, 0)
	label.font_size = 40
	label.modulate = Color(0.55, 0.9, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.6, 0.42)
	shape.shape = box
	shape.position.y = 0.8
	body.add_child(shape)
