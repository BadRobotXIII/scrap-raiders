extends StaticBody3D
## Health drives target presentation and lifetime; no duplicate health state.

@onready var health: Health = $Health
@onready var body_mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label3D
var flash_remaining: float = 0.0
var material: StandardMaterial3D


func _ready() -> void:
	material = body_mesh.get_active_material(0).duplicate() as StandardMaterial3D
	body_mesh.material_override = material
	health.damaged.connect(_on_damaged)
	health.died.connect(queue_free)
	update_label()


func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	material.albedo_color = Color.WHITE if flash_remaining > 0.0 else Color(0.8, 0.22, 0.25)


func _on_damaged(_amount: float) -> void:
	flash_remaining = 0.10
	update_label()


func update_label() -> void:
	label.text = "TEST TARGET\n%d / %d" % [health.current, health.maximum]
