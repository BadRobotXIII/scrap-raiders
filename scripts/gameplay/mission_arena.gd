extends "res://scripts/gameplay/raider_arena.gd"
## Owns scheduled entry and scenario selection; Raiders retain their shared FSM.

const CONFIGS: Array[MissionConfig] = [preload("res://resources/missions/intercept.tres"), preload("res://resources/missions/swarm.tres"), preload("res://resources/missions/recovery.tres"), preload("res://resources/missions/survival.tres"), preload("res://resources/missions/loot_pressure.tres"), preload("res://resources/missions/extraction.tres"), preload("res://resources/missions/ecosystem.tres"), preload("res://resources/missions/traversal.tres")]
@export_range(0, 7) var scenario_index: int = 0
var config: MissionConfig
var pending_ids: Array[int] = []
var spawn_order: Array[Node3D] = []
var entry_log: Array[StringName] = []
var entry_retry: float = 0.0
var entry_status: String = "Waiting for navigation"


func _ready() -> void:
	config = CONFIGS[clampi(scenario_index, 0, CONFIGS.size() - 1)]
	raider_count = config.raider_count
	salvage_point_count = config.salvage_point_count
	materials_per_point = config.materials_per_point
	mission_duration = config.duration
	debug_seed = config.seed
	dynamic_ai = true
	combat_profile = preload("res://resources/enemies/armed_scavenger.tres") if config.armed else null
	flare_rules = preload("res://resources/missions/death_flare_rules.tres") if config.death_flares else null
	recall_enabled = config.player_extraction
	ecosystem_enabled = config.machine_ecosystem
	$Robot.traversal_enabled = config.experimental_traversal
	super._ready()
	if config.experimental_traversal:
		var feedback := preload("res://scripts/presentation/traversal_feedback.gd").new()
		feedback.robot = robot
		$Overlay.add_child(feedback)
	$Overlay/FoundationStatus.text = "SCRAP RAIDERS | %s\nWASD: move | Mouse: orbit | RMB: aim | LMB: fire | E: recover\nF2: Traversal | F4: Machines | F6-8: Unarmed | F9: Survival | F10: Loot | F12: Recall | F3: debug" % config.display_name
	if not mission.is_finished():
		for index in range(config.ground_stacks):
			present_drop(index + 1, $GroundCargo.get_child(index).global_position)
		status.text = "%s: %d Raiders scheduled. Intercept and recover cargo." % [config.display_name, raider_count]
		refresh_hud()


func initial_ground_stock() -> Dictionary:
	var stock := {}
	for index in range(config.ground_stacks):
		stock[index + 1] = config.materials_per_stack
	return stock


func setup_extractions() -> void:
	for point in [$Extraction, $Extraction2]:
		point.visible = config.exits.has(str(point.name))
		if point.visible:
			extraction_points.append(point)


func deploy_raiders() -> void:
	var error := config.validation_error()
	for marker_name in config.spawn_markers:
		var marker := $RaiderSpawns.get_node_or_null(NodePath(marker_name)) as Node3D
		if marker == null:
			error = "Unknown spawn marker: %s" % marker_name
		elif not spawn_order.has(marker):
			spawn_order.append(marker)
	for exit_name in config.exits:
		if get_node_or_null(NodePath(exit_name)) not in extraction_points:
			error = "Unknown extraction: %s" % exit_name
	if not error.is_empty():
		mission.fail_setup(error)
		finish_mission()
		return
	var random := RandomNumberGenerator.new()
	random.seed = debug_seed
	for index in range(spawn_order.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var marker := spawn_order[index]
		spawn_order[index] = spawn_order[other]
		spawn_order[other] = marker
	for id in range(1, raider_count + 1):
		pending_ids.append(id)


func entry_is_valid(position: Vector3) -> bool:
	for actor in raiders.values():
		if is_instance_valid(actor) and actor.global_position.distance_to(position) < 0.9:
			return false
	if not spawn_is_clear(position):
		return false
	var floor_query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.2, position + Vector3.DOWN * 0.5, 1)
	var floor_hit := get_world_3d().direct_space_state.intersect_ray(floor_query)
	if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP) < 0.7:
		return false
	var map: RID = $NavigationRegion3D.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var closest := NavigationServer3D.map_get_closest_point(map, position)
	if not NavigationServer3D.map_get_closest_point_owner(map, position).is_valid() or closest.distance_to(position) > 0.6:
		return false
	# An entry must reach both an enabled salvage point and an enabled exit.
	return reaches_any(map, closest, salvage_points) and reaches_any(map, closest, extraction_points)


func reaches_any(map: RID, origin: Vector3, points: Array[Node3D]) -> bool:
	for point in points:
		var destination := NavigationServer3D.map_get_closest_point(map, point.global_position)
		if destination.distance_to(point.global_position) > 0.6:
			continue
		var path := NavigationServer3D.map_get_path(map, origin, destination, true)
		if not path.is_empty() and path[path.size() - 1].distance_to(destination) < 0.6:
			return true
	return false


func process_entries() -> void:
	if mission.is_finished():
		return
	for id in pending_ids.duplicate():
		if flare_director != null and flare_director.living_count() >= flare_rules.active_cap:
			break
		if elapsed < config.entry_times[id - 1]:
			continue
		var entered := false
		for offset in range(spawn_order.size()):
			var marker := spawn_order[(id - 1 + offset) % spawn_order.size()]
			if entry_is_valid(marker.global_position):
				spawn_raider(id, marker.global_position)
				pending_ids.erase(id)
				entry_log.append(marker.name)
				entry_status = "R%02d entered at %s" % [id, marker.name]
				entered = true
				break
		if not entered:
			entry_status = "R%02d entry blocked; retrying until deadline" % id


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if mission.is_finished():
		return
	entry_retry -= delta
	if entry_retry <= 0 and not pending_ids.is_empty():
		entry_retry = 0.5
		process_entries()
		refresh_hud()


func refresh_hud() -> void:
	super.refresh_hud()
	if config == null:
		return
	objectives.text = objectives.text.replace("Active ", "Unresolved ")
	objectives.text += " | Pending entry %d" % pending_ids.size()
	if recall != null and not mission.is_finished():
		objectives.text = objectives.text.replace("All Raiders resolved. Recover remaining ground cargo.", "Raiders resolved. Recover loot or return to Recall Dock.")
		objectives.text = objectives.text.replace("Intercept Raiders and recover dropped cargo.", "Recover loot, survive, and extract at the Recall Dock.")
	if flare_director != null:
		objectives.text += "\nEquipment ground %d | Recovered %d | Response budget %d/%d" % [flare_director.equipment.ground_count(), flare_director.equipment.count_at(EquipmentLedger.Location.RECOVERED), flare_director.committed, flare_rules.reinforcement_budget]
	if ecosystem != null:
		var reports := ecosystem.awareness.observations(elapsed)
		if not reports.is_empty() and not mission.is_finished():
			$Overlay/RaiderStatus.text = "Machine report: R%02d last seen near (%.0f, %.0f)" % [reports[0].target_id, reports[0].position.x, reports[0].position.z]
		elif $Overlay/RaiderStatus.text.begins_with("Machine report:"):
			$Overlay/RaiderStatus.text = ""
	if debug_visible:
		$Overlay/DebugStatus.text = $Overlay/DebugStatus.text.replace("STAGE B", "STAGE C")
		$Overlay/DebugStatus.text += "\nSTAGE C | %s | pending %s | %s" % [config.display_name, pending_ids, entry_status]
		if flare_director != null:
			$Overlay/DebugStatus.text += "\nFLARES %d | local jobs %d | reinforcement tickets %d | equipment invariant %s" % [flare_director.handled_deaths.size(), flare_director.local_jobs.size(), flare_director.tickets.size(), flare_director.equipment.is_valid()]
		if ecosystem != null:
			for actor in raiders.values():
				if is_instance_valid(actor):
					$Overlay/DebugStatus.text += "\nR%02d target %s" % [actor.raider_id, actor.current_target().name]


func finish_mission() -> void:
	var was_visible := summary.visible
	super.finish_mission()
	if not was_visible and summary.visible:
		$Overlay/Summary/Content/Report.text += "\nRaiders never entered: %d" % pending_ids.size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F2:
			get_viewport().set_input_as_handled()
			select_scenario.call_deferred(7)
			return
		if event.physical_keycode == KEY_F4:
			get_viewport().set_input_as_handled()
			select_scenario.call_deferred(6)
			return
		var index := [KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F12].find(event.physical_keycode)
		if index >= 0:
			get_viewport().set_input_as_handled()
			select_scenario.call_deferred(index)
			return
	super._unhandled_input(event)


func select_scenario(index: int) -> void:
	# Replace the scene with an explicit configuration; no persistent singleton state.
	var replacement := load("res://scenes/levels/mission_arena.tscn").instantiate() as Node3D
	replacement.scenario_index = clampi(index, 0, CONFIGS.size() - 1)
	replacement.stash_path = stash_path
	var tree := get_tree()
	tree.root.remove_child(self)
	tree.root.add_child(replacement)
	tree.current_scene = replacement
	queue_free()


func restart_mission() -> void:
	select_scenario.call_deferred(scenario_index)
