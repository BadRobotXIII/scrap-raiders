extends Node
## Reads simulation state only. Never modifies movement, tasks, or material records.

@onready var actor: Raider = get_parent()
@onready var alert: Label3D = $"../Alert"
var cargo_material := StandardMaterial3D.new()


func _ready() -> void:
	cargo_material.emission_enabled = true
	actor.get_node("Visuals/Backpack").material_override = cargo_material
	refresh()


func _process(_delta: float) -> void:
	refresh()


func stop() -> void:
	set_process(false)
	alert.hide()


func refresh() -> void:
	var loaded := actor.carried_materials > 0
	cargo_material.albedo_color = Color(1, 0.75, 0.15) if loaded else Color(0.22, 0.25, 0.3)
	cargo_material.emission = Color(0.25, 0.12, 0.01) if loaded else Color.BLACK
	alert.visible = actor.dynamic_ai and actor.ledger.is_active(actor.raider_id) and actor.threat_remaining > 0
	if not alert.visible:
		return
	var investigating := actor.state == Raider.State.INVESTIGATING
	alert.text = "?" if investigating else "!"
	if actor.threat_source == "gunfire":
		alert.text += " GUNFIRE"
	alert.modulate = Color(1, 0.8, 0.3) if investigating else Color(1, 0.45, 0.25)
