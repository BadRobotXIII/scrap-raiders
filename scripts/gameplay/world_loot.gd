class_name WorldLoot
extends MaterialDrop
## A registered, read-only cue. Existing geometry remains the physical authority.
var container_id: String
@export var title: String = "Salvage cache"
@export var cue_color: Color = Color(0.3, 0.8, 0.85)
var access_seconds: float = 1.5
var voluntary: bool = false
var label: Label3D

func inventory_container() -> String:
	return container_id

func _ready() -> void:
	var cue := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.rings = 16
	mesh.ring_segments = 6
	mesh.inner_radius = 0.28
	mesh.outer_radius = 0.34
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.albedo_color = cue_color
	mesh.material = surface
	cue.mesh = mesh
	cue.position.y = 0.08
	add_child(cue)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 26
	label.pixel_size = 0.005
	label.position.y = 0.75
	add_child(label)
	set_pickup_available(false)

func set_pickup_available(available: bool) -> void:
	if label == null: return
	label.visible = available
	label.text = "Hold [E] Search %s" % title
