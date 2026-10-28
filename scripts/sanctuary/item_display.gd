class_name ItemDisplay
extends Node3D
## Read-only view of one real reserved item identity.
var preparation: PreparationService
var sprite: Sprite3D
var label: Label3D

func _ready() -> void:
	var plinth := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.65
	mesh.bottom_radius = 0.7
	mesh.height = 0.75
	plinth.mesh = mesh
	plinth.position.y = 0.375
	add_child(plinth)
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = 0.75
	collision.shape = shape
	collision.position.y = 0.375
	body.add_child(collision)
	add_child(body)
	sprite = Sprite3D.new()
	sprite.position.y = 1.4
	sprite.pixel_size = 0.016
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sprite)
	label = Label3D.new()
	label.position.y = 2.1
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	preparation.stash.inventory.changed.connect(refresh.unbind(1))
	refresh()

func refresh() -> void:
	if not is_instance_valid(sprite): return
	var items := preparation.stash.inventory.records("display:workshop")
	sprite.texture = null
	label.text = "ITEM DISPLAY · E"
	if items.is_empty(): return
	var definition := preparation.stash.inventory.catalog.find(StringName(items[0].definition))
	sprite.texture = definition.icon
	label.text = "%s × %d\nReserved · E to inspect" % [definition.display_name, items[0].quantity]
