extends Node3D
## Coordinates scene objects and presentation. Ledger owns materials; rules own outcomes.

const DEPLOYMENT_EFFECT := preload("res://scenes/effects/deployment_effect.tscn")
const RAIDER_SCENE := preload("res://scenes/raiders/raider.tscn")
const DROP_SCENE := preload("res://scenes/loot/material_drop.tscn")
const PROFILES: Array[RaiderProfile] = [preload("res://resources/enemies/greedy.tres"), preload("res://resources/enemies/cowardly.tres"), preload("res://resources/enemies/aggressive.tres")]

@export_range(1, 5) var raider_count: int = 3
@export_range(1, 3) var salvage_point_count: int = 3
@export_range(1, 99) var materials_per_point: int = 3
@export var mission_duration: float = 180.0
@export var pickup_distance: float = 1.8
@export var dynamic_ai: bool = true
@export var debug_seed: int = 4711
@export var combat_profile: RaiderCombatProfile
var cover_reservations: Dictionary[int, Node3D] = {}
var ledger: MaterialLedger
var mission := MissionRules.new()
var elapsed: float = 0.0
var raiders: Dictionary[int, Raider] = {}
var drops: Dictionary[int, MaterialDrop] = {}
var salvage_points: Array[Node3D] = []
var extraction_points: Array[Node3D] = []
var debug_visible: bool = false
@onready var robot: RobotController = $Robot
@onready var status: Label = $Overlay/RaiderStatus
@onready var objectives: Label = $Overlay/MissionStatus
@onready var summary: PanelContainer = $Overlay/Summary


func _ready() -> void:
	process_physics_priority = 20
	var stock := {}
	var candidates: Array[Node3D] = [$Salvage, $Salvage2, $Salvage3]
	for index in range(candidates.size()):
		candidates[index].visible = index < salvage_point_count
		if index < salvage_point_count:
			salvage_points.append(candidates[index])
			stock[candidates[index].name] = materials_per_point
	var ids: Array[int] = []
	for index in range(raider_count):
		ids.append(index + 1)
	ledger = MaterialLedger.new(stock, ids, initial_ground_stock())
	setup_extractions()
	$NavigationRegion3D.bake_navigation_mesh(false)
	$Overlay/Summary/Content/Restart.pressed.connect(restart_mission)
	$Robot/Weapon.fired.connect(_on_weapon_fired)
	$Robot/Health.died.connect(_on_player_destroyed)
	deploy_raiders()
	if mission.is_finished():
		return
	status.text = "Intercept %d Raiders. Prevent theft or recover dropped cargo. F3: diagnostics." % raider_count
	refresh_hud()
	var arrival := DEPLOYMENT_EFFECT.instantiate() as Node3D
	arrival.position = robot.position
	add_child(arrival)


func initial_ground_stock() -> Dictionary:
	return {}


func _on_player_destroyed() -> void:
	mission.fail_player_destroyed()
	finish_mission()


func _on_weapon_fired(origin: Vector3, _endpoint: Vector3, _damaged_target: bool) -> void:
	if mission.is_finished():
		return
	for actor in raiders.values():
		if is_instance_valid(actor):
			actor.hear_gunfire(origin)


func setup_extractions() -> void:
	extraction_points.append($Extraction)
	$Extraction2.visible = dynamic_ai
	if dynamic_ai:
		extraction_points.append($Extraction2)


func deploy_raiders() -> void:
	var spawns := $RaiderSpawns.get_children()
	var positions: Array[Vector3] = []
	for index in range(raider_count):
		var position: Vector3 = spawns[index].global_position
		if not spawn_is_clear(position, positions):
			mission.fail_setup("Invalid Raider spawn %d; deployment aborted." % (index + 1))
			push_error(mission.reason)
			finish_mission()
			return
		positions.append(position)
	for index in range(raider_count):
		spawn_raider(index + 1, positions[index])


func spawn_raider(id: int, world_position: Vector3) -> Raider:
	var actor := RAIDER_SCENE.instantiate() as Raider
	actor.name = "Raider" if id == 1 else "Raider%d" % id
	actor.raider_id = id
	actor.ledger = ledger
	actor.dynamic_ai = dynamic_ai
	actor.profile = PROFILES[(id - 1) % PROFILES.size()]
	actor.select_extraction = choose_extraction
	actor.robot = robot
	actor.select_salvage = choose_salvage
	actor.salvage = choose_salvage(id)
	actor.extraction = extraction_points[0]
	actor.position = to_local(world_position)
	raiders[id] = actor
	actor.collection_requested.connect(_on_collection_requested.bind(actor))
	actor.defeated.connect(_on_defeated.bind(actor))
	actor.extracted.connect(_on_extracted.bind(actor))
	add_child(actor)
	if combat_profile != null:
		actor.combat = RaiderCombat.new()
		actor.add_child(actor.combat)
		actor.combat.reserve_cover = reserve_cover
		actor.combat.release_cover = release_cover
		actor.combat.setup(actor, combat_profile, debug_seed)
		actor.detection_range = combat_profile.engagement_range
	return actor


func release_cover(id: int) -> void:
	cover_reservations.erase(id)


func reserve_cover(id: int) -> Node3D:
	release_cover(id)
	var actor := raiders.get(id) as Raider
	var group := get_node_or_null("CoverPoints")
	if not is_instance_valid(actor) or group == null:
		return null
	var selected: Node3D
	var best := INF
	for point: Node3D in group.get_children():
		if cover_reservations.values().has(point) or point.global_position.distance_to(actor.global_position) > 18:
			continue
		var peek := point.get_node("Peek") as Node3D
		var query := PhysicsRayQueryParameters3D.create(point.global_position + Vector3.UP, actor.last_threat_position + Vector3.UP, 1, [actor.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not hit.collider is StaticBody3D:
			continue
		query.from = peek.global_position + Vector3.UP
		query.collision_mask = 3
		hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider != robot:
			continue
		var cost := route_cost(actor, point) + route_cost(actor, peek)
		if cost < best:
			best = cost
			selected = point
	if selected != null:
		cover_reservations[id] = selected
	return selected


func spawn_is_clear(position: Vector3, other_positions: Array[Vector3] = []) -> bool:
	for other in other_positions:
		if other.distance_to(position) < 0.9:
			return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, position + Vector3(0, 0.9, 0))
	query.collision_mask = 3
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func choose_salvage(id: int) -> Node3D:
	var actor := raiders.get(id) as Raider
	if dynamic_ai and is_instance_valid(actor):
		var selected: Node3D
		var best := INF
		for index in range(salvage_points.size()):
			var point := salvage_points[index]
			if not is_instance_valid(point) or ledger.available(point.name) <= 0 or actor.blocked_salvage.has(point.name):
				continue
			var cost := route_cost(actor, point)
			if is_inf(cost):
				continue
			for other in raiders.values():
				if is_instance_valid(other) and other != actor and other.state == Raider.State.SCAVENGING and other.salvage == point:
					cost += 4.0
			cost -= minf(ledger.available(point.name), actor.profile.cargo_target - actor.carried_materials) * 0.25
			cost += selection_jitter(id, index)
			if cost < best:
				best = cost
				selected = point
		return selected
	for offset in range(salvage_points.size()):
		var point := salvage_points[(id - 1 + offset) % salvage_points.size()]
		if is_instance_valid(point) and ledger.available(point.name) > 0:
			return point
	return null


func selection_jitter(id: int, candidate_index: int) -> float:
	var random := RandomNumberGenerator.new()
	random.seed = debug_seed + id * 997 + candidate_index * 101
	return random.randf_range(-0.1, 0.1)


func choose_extraction(id: int) -> Node3D:
	if not dynamic_ai:
		return $Extraction
	var actor := raiders.get(id) as Raider
	if not is_instance_valid(actor):
		return $Extraction
	var selected: Node3D
	var best := INF
	for index in range(extraction_points.size()):
		var point := extraction_points[index]
		if not is_instance_valid(point) or actor.blocked_exits.has(point.name):
			continue
		var cost := route_cost(actor, point) + selection_jitter(id, index)
		if cost < best:
			best = cost
			selected = point
	return selected


func route_cost(actor: Raider, point: Node3D) -> float:
	var map: RID = $NavigationRegion3D.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return INF
	var closest := NavigationServer3D.map_get_closest_point(map, point.global_position)
	if closest.distance_to(point.global_position) > 1.0:
		return INF
	var path := NavigationServer3D.map_get_path(map, actor.global_position, closest, true)
	if path.is_empty() or path[path.size() - 1].distance_to(closest) > 0.8:
		return INF
	var cost := 0.0
	var risk := 0.0
	var previous := actor.global_position
	for position in path:
		cost += previous.distance_to(position)
		if actor.threat_visible or actor.threat_remaining > 0:
			var near := Geometry3D.get_closest_point_to_segment(actor.last_threat_position, previous, position)
			risk = maxf(risk, 8.0 - near.distance_to(actor.last_threat_position))
		previous = position
	return cost + risk * actor.profile.route_risk_weight


func _physics_process(delta: float) -> void:
	if mission.is_finished():
		return
	elapsed += delta
	if elapsed >= mission_duration:
		mission.evaluate(ledger, true)
		finish_mission()
		return
	if robot.input_adapter.pickup_intent:
		try_recover()
	refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_hud"):
		debug_visible = not debug_visible
		refresh_hud()
		get_viewport().set_input_as_handled()
	elif mission.is_finished() and event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		restart_mission()


func _on_collection_requested(actor: Raider) -> void:
	if mission.is_finished() or raiders.get(actor.raider_id) != actor or not ledger.is_active(actor.raider_id):
		return
	if actor.state != Raider.State.SCAVENGING or actor.health.current <= 0 or not is_instance_valid(actor.salvage):
		return
	if actor.task_elapsed < actor.scavenge_seconds or actor.global_position.distance_to(actor.salvage.global_position) >= 0.8:
		return
	var target := actor.profile.cargo_target if actor.dynamic_ai else materials_per_point
	var amount := ledger.collect(actor.raider_id, actor.salvage.name, target)
	if amount > 0:
		status.text = "R%02d carrying %d materials. Stop it before extraction." % [actor.raider_id, amount]
	after_event()


func _on_defeated(_reported_amount: int, actor: Raider) -> void:
	if raiders.get(actor.raider_id) != actor or actor.state != Raider.State.DEAD or actor.health.current > 0:
		return
	var drop_id := ledger.defeat(actor.raider_id)
	if drop_id < 0:
		return
	if drop_id > 0:
		var drop := present_drop(drop_id, actor.global_position)
		status.text = "%d materials dropped by R%02d. Approach the cyan cube and press E." % [drop.materials, actor.raider_id]
	else:
		status.text = "R%02d stopped empty; other Raiders and cargo remain active." % actor.raider_id
	after_event()


func present_drop(id: int, world_position: Vector3) -> MaterialDrop:
	var drop := DROP_SCENE.instantiate() as MaterialDrop
	drop.ledger = ledger
	drop.drop_id = id
	drop.position = to_local(world_position)
	drops[id] = drop
	add_child(drop)
	return drop


func _on_extracted(_reported_amount: int, actor: Raider) -> void:
	if raiders.get(actor.raider_id) != actor or actor.state != Raider.State.EXTRACTED or not ledger.is_active(actor.raider_id):
		return
	var amount := ledger.cargo_for(actor.raider_id)
	if ledger.extract(actor.raider_id):
		status.text = "R%02d extracted with %d materials. Continue intercepting/recovering." % [actor.raider_id, amount]
		after_event()


func after_event() -> void:
	mission.evaluate(ledger)
	refresh_hud()
	if mission.is_finished():
		finish_mission()


func eligible_drop(drop: MaterialDrop) -> bool:
	if mission.is_finished() or not is_instance_valid(drop):
		return false
	if drop.is_queued_for_deletion() or drop.ledger != ledger or drops.get(drop.drop_id) != drop or drop.materials <= 0:
		return false
	if robot.global_position.distance_to(drop.global_position) > pickup_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		robot.global_position + Vector3.UP, drop.global_position + Vector3(0, 0.3, 0), 1)
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func selected_drop() -> MaterialDrop:
	var selected: MaterialDrop
	var distance := INF
	for id in drops:
		var drop := drops[id]
		if not eligible_drop(drop):
			continue
		var candidate := robot.global_position.distance_squared_to(drop.global_position)
		if candidate < distance - 0.000001 or (absf(candidate - distance) <= 0.000001 and (selected == null or id < selected.drop_id)):
			distance = candidate
			selected = drop
	return selected


func can_recover() -> bool:
	return selected_drop() != null


func try_recover() -> bool:
	var drop := selected_drop()
	if drop == null:
		return false
	var amount := ledger.recover(drop.drop_id)
	if amount <= 0:
		return false
	drops.erase(drop.drop_id)
	drop.queue_free()
	status.text = "Recovered %d materials." % amount
	after_event()
	return true


func refresh_hud() -> void:
	var selected := selected_drop()
	$Overlay/PickupPrompt.visible = selected != null
	if selected != null:
		$Overlay/PickupPrompt.text = "[E] Recover %d materials" % selected.materials
	for drop in drops.values():
		if is_instance_valid(drop):
			drop.set_pickup_available(drop == selected)
	var objective := "Intercept Raiders and recover dropped cargo."
	if mission.is_finished():
		objective = "Deployment complete. See mission summary."
	elif mission.phase == MissionRules.Phase.RECOVERING:
		objective = "All Raiders resolved. Recover remaining ground cargo."
	objectives.text = "%s\nActive %d | Protected %d | Carried %d | Ground %d | Recovered %d | Lost %d | Time %ds" % [
		objective, ledger.active_raiders, ledger.protected_materials, ledger.carried_materials,
		ledger.dropped_materials, ledger.recovered_materials, ledger.lost_materials,
		ceili(maxf(0.0, mission_duration - elapsed))]
	for point in salvage_points:
		if is_instance_valid(point):
			point.get_node("Label3D").text = "%s\n%d materials" % [point.name, ledger.available(point.name)]
			var available := ledger.available(point.name) > 0
			point.get_node("Crate").visible = available
			point.get_node("Label3D").modulate = Color(1, 0.85, 0.35) if available else Color(0.6, 0.65, 0.7)
			if not available:
				point.get_node("Label3D").text = "%s\nDEPLETED" % point.name
	$Overlay/DebugStatus.visible = debug_visible
	if debug_visible:
		var lines := PackedStringArray(["STAGE B | seed %d | conservation %s | transfers %d" % [debug_seed, ledger.is_conserved(), ledger.accepted_transfers]])
		for id in raiders:
			var actor := raiders[id]
			if is_instance_valid(actor):
				var target := str(actor.salvage.name) if is_instance_valid(actor.salvage) else "none"
				var destination := target if actor.state == Raider.State.SCAVENGING else (str(actor.extraction.name) if is_instance_valid(actor.extraction) else "none")
				if actor.state == Raider.State.INVESTIGATING:
					destination = str(actor.investigation_position)
				if actor.combat != null and is_instance_valid(actor.combat.destination):
					destination = str(actor.combat.destination.global_position)
				lines.append("R%02d %s %s | target %s | dest %s | cargo %d | threat %s/%s/%.1fs | %s" % [id, actor.profile.display_name, Raider.State.keys()[actor.state], target, destination, actor.carried_materials, actor.threat_source, actor.threat_visible, actor.threat_remaining, actor.navigation_status])
		$Overlay/DebugStatus.text = "\n".join(lines)


func finish_mission() -> void:
	if not mission.is_finished() or summary.visible:
		return
	ledger.seal()
	robot.input_adapter.clear_intent()
	robot.input_adapter.set_physics_process(false)
	robot.input_adapter.set_process_input(false)
	robot.set_physics_process(false)
	robot.get_node("Weapon").set_physics_process(false)
	robot.get_node("Weapon").enabled = false
	robot.get_node("CombatHUD").hide()
	for actor in raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			if actor.combat != null:
				actor.combat.stop()
			actor.get_node("RaiderFeedback").stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var title := "MISSION SUCCESS" if mission.phase == MissionRules.Phase.SUCCEEDED else "MISSION FAILED"
	$Overlay/Summary/Content/Report.text = "%s\n\n%s\n\nProtected: %d   Recovered: %d   Lost: %d\nUnrecovered ground: %d   Raider cargo: %d\nTotal: %d   Elapsed: %.1f seconds\n\nPress R or click Restart to deploy again." % [
		title, mission.reason, ledger.protected_materials, ledger.recovered_materials,
		ledger.lost_materials, ledger.dropped_materials, ledger.carried_materials, ledger.total_materials, elapsed]
	summary.show()
	refresh_hud()


func restart_mission() -> void:
	var result := get_tree().reload_current_scene()
	if result != OK:
		push_error("Unable to restart mission: %s" % error_string(result))
