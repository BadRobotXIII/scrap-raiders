extends Node3D
## Scene wiring and presentation. MissionRules owns outcomes and accounting.

const DEPLOYMENT_EFFECT := preload("res://scenes/effects/deployment_effect.tscn")

@export var mission_duration: float = 180.0
@export var pickup_distance: float = 1.8
var mission := MissionRules.new()
var elapsed: float = 0.0
var cargo_drop: MaterialDrop
@onready var robot: RobotController = $Robot
@onready var status: Label = $Overlay/RaiderStatus
@onready var objectives: Label = $Overlay/MissionStatus
@onready var summary: PanelContainer = $Overlay/Summary


func _ready() -> void:
	process_physics_priority = 20
	$NavigationRegion3D.bake_navigation_mesh(false)
	$Raider.cargo_collected.connect(_on_cargo_collected)
	$Raider.defeated.connect(_on_defeated)
	$Raider.extracted.connect(_on_extracted)
	$Overlay/Summary/Content/Restart.pressed.connect(restart_mission)
	status.text = "Intercept the Raider. Stop theft, or recover its cargo before time expires."
	refresh_hud()
	var arrival := DEPLOYMENT_EFFECT.instantiate() as Node3D
	arrival.position = robot.position
	add_child(arrival)


func _physics_process(delta: float) -> void:
	if mission.is_finished():
		return
	elapsed += delta
	if elapsed >= mission_duration:
		mission.expire()
		finish_mission()
		return
	if robot.input_adapter.pickup_intent:
		try_recover()
	refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if mission.is_finished() and event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		restart_mission()


func _on_cargo_collected(amount: int) -> void:
	if not mission.scavenge(amount):
		push_error("Rejected inconsistent scavenging event")
		return
	status.text = "Raider carrying %d materials. Stop it before extraction to drop cargo." % amount
	refresh_hud()


func _on_defeated(amount: int) -> void:
	if not mission.defeat(amount):
		push_error("Rejected inconsistent Raider defeat event")
		return
	if amount > 0:
		for drop in get_tree().get_nodes_in_group("material_drops"):
			if drop.get_parent() == self and drop is MaterialDrop and drop.materials == amount:
				cargo_drop = drop
				break
		status.text = "%d materials dropped. Approach the cyan cube and press E to recover." % amount
	else:
		status.text = "Raider stopped before scavenging. No materials were stolen."
	refresh_hud()
	if mission.is_finished():
		finish_mission()


func _on_extracted(amount: int) -> void:
	if not mission.extract(amount):
		push_error("Rejected inconsistent Raider extraction event")
		return
	finish_mission()


func can_recover() -> bool:
	if mission.phase != MissionRules.Phase.RECOVERING or not is_instance_valid(cargo_drop):
		return false
	if cargo_drop.materials != mission.dropped_materials or cargo_drop.materials <= 0:
		return false
	if robot.global_position.distance_to(cargo_drop.global_position) > pickup_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		robot.global_position + Vector3.UP, cargo_drop.global_position + Vector3(0, 0.3, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func try_recover() -> bool:
	if not can_recover():
		return false
	var amount := cargo_drop.consume()
	# Perform the state change outside assert (assertions are omitted in release).
	var accepted := mission.recover(amount)
	assert(accepted, "World cargo and mission ledger must agree")
	finish_mission()
	return accepted


func refresh_hud() -> void:
	# Presentation uses the same range/cover rule as actual pickup.
	var pickup_available := can_recover() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	$Overlay/PickupPrompt.visible = pickup_available
	if pickup_available:
		$Overlay/PickupPrompt.text = "[E] Recover %d materials" % cargo_drop.materials
	if is_instance_valid(cargo_drop):
		cargo_drop.set_pickup_available(pickup_available)
	var objective := "Prevent theft or intercept stolen cargo."
	if mission.is_finished():
		objective = "Deployment complete. See mission summary."
	elif mission.phase == MissionRules.Phase.RECOVERING:
		objective = "Press E to recover cargo." if can_recover() else "Reach the cyan cargo drop."
	objectives.text = "%s\nProtected %d | Carried %d | Ground %d | Recovered %d | Lost %d | Time %ds" % [
		objective, mission.protected_materials, mission.carried_materials,
		mission.dropped_materials, mission.recovered_materials, mission.lost_materials,
		ceili(maxf(0.0, mission_duration - elapsed))]


func finish_mission() -> void:
	if not mission.is_finished() or summary.visible:
		return
	robot.input_adapter.clear_intent()
	robot.input_adapter.set_physics_process(false)
	robot.input_adapter.set_process_input(false)
	robot.set_physics_process(false)
	robot.get_node("Weapon").set_physics_process(false)
	robot.get_node("CombatHUD").hide()
	var raider := get_node_or_null("Raider")
	if raider != null:
		raider.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var title := "MISSION SUCCESS" if mission.phase == MissionRules.Phase.SUCCEEDED else "MISSION FAILED"
	$Overlay/Summary/Content/Report.text = "%s\n\n%s\n\nProtected: %d   Recovered: %d   Lost: %d\nUnrecovered: %d   Raider cargo: %d\nElapsed: %.1f seconds\n\nPress R or click Restart to deploy again." % [
		title, mission.reason, mission.protected_materials, mission.recovered_materials,
		mission.lost_materials, mission.dropped_materials, mission.carried_materials, elapsed]
	summary.show()
	refresh_hud()


func restart_mission() -> void:
	var result := get_tree().reload_current_scene()
	if result != OK:
		push_error("Unable to restart mission: %s" % error_string(result))
