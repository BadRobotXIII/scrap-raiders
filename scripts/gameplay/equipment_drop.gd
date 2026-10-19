class_name EquipmentDrop
extends Node3D
## Read-only world view of one defeated actor's identified equipment allocation.

var ledger: EquipmentLedger
var owner_id: int
var label: Label3D
var material := StandardMaterial3D.new()


func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.6, 0.3, 0.45)
	material.albedo_color = Color(0.75, 0.45, 1)
	material.emission_enabled = true
	mesh.material = material
	body.mesh = mesh
	body.position.y = 0.18
	add_child(body)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 0.75
	label.font_size = 30
	label.pixel_size = 0.005
	add_child(label)
	set_available(false)


func set_available(available: bool, remaining: float = 1.5) -> void:
	material.emission = Color(0.35, 0.15, 0.5) if available else Color.BLACK
	label.text = "HOLD [E] EQUIPMENT %.1fs" % remaining if available else "%s\nVALUE %d" % [ledger.description_for(owner_id), ledger.value_at(EquipmentLedger.Location.GROUND, owner_id)]
