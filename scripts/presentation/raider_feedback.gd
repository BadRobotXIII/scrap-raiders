extends Node
## Reads simulation state only. Never modifies movement, tasks, or material records.

@onready var actor: Raider = get_parent()
@onready var alert: Label3D = $"../Alert"
var cargo_material := StandardMaterial3D.new()


func setup_weapon(weapon: ShotExecutor) -> void:
	# Shared WeaponFeedback is registered once by the arena after combat setup.
	assert(weapon != null)


func _on_enemy_fired(origin: Vector3, endpoint: Vector3, _damaged: bool) -> void:
	pass # Retained compatibility method; not a second discharge subscriber.


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
	var adapter := actor.get_node_or_null("Visuals/ActorVisual") as ActorVisual
	if adapter != null:
		adapter.set_cargo(actor.carried_materials)
	cargo_material.albedo_color = Color(1, 0.75, 0.15) if loaded else Color(0.22, 0.25, 0.3)
	cargo_material.emission = Color(0.25, 0.12, 0.01) if loaded else Color.BLACK
	if actor.state == Raider.State.ASSESSING_BETRAYAL and actor.betrayal != null and is_instance_valid(actor.betrayal.candidate):
		alert.show()
		alert.text = "?! EYEING R%02d CARGO %.1fs" % [actor.betrayal.candidate.raider_id, maxf(0, actor.betrayal.profile.assessment_seconds - actor.betrayal.elapsed)]
		alert.modulate = Color(1, 0.55, 0.1)
		return
	alert.visible = actor.dynamic_ai and actor.ledger.is_active(actor.raider_id) and actor.threat_remaining > 0
	if not alert.visible:
		return
	var investigating := actor.state == Raider.State.INVESTIGATING
	alert.text = "?" if investigating else "!"
	if actor.state == Raider.State.ENGAGING:
		alert.text = "! AIMING" if actor.combat.aim_elapsed < actor.combat.profile.warning_time else "! FIRING"
	if actor.threat_source == "gunfire":
		alert.text += " GUNFIRE"
	elif actor.threat_source == "flare":
		alert.text += " FLARE"
	alert.modulate = Color(1, 0.8, 0.3) if investigating else Color(1, 0.45, 0.25)
