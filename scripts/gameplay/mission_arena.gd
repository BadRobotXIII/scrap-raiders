extends "res://scripts/gameplay/raider_arena.gd"
## Owns scheduled entry and scenario selection; Raiders retain their shared FSM.

const CONFIGS: Array[MissionConfig] = [preload("res://resources/missions/intercept.tres"), preload("res://resources/missions/swarm.tres"), preload("res://resources/missions/recovery.tres"), preload("res://resources/missions/survival.tres"), preload("res://resources/missions/loot_pressure.tres"), preload("res://resources/missions/extraction.tres"), preload("res://resources/missions/ecosystem.tres"), preload("res://resources/missions/traversal.tres"), preload("res://resources/missions/social_rivalry.tres"), preload("res://resources/missions/social_cooperation.tres"), preload("res://resources/missions/social_pressure.tres"), preload("res://resources/missions/social_betrayal.tres"), preload("res://resources/missions/integrated_extraction.tres"), preload("res://resources/missions/emergent_encounters.tres"), preload("res://resources/missions/personality_encounters.tres"), preload("res://resources/missions/refined_extraction.tres"), preload("res://resources/missions/asset_recovery.tres")]
@export_range(0, 16) var scenario_index: int = 0
@export var capture_metrics: bool = false
@export var mission_config_override: MissionConfig
var metrics: DeploymentMetrics
var mission_objectives: MissionObjectives
var objective_view: MissionObjectivesView
var config: MissionConfig
var pending_ids: Array[int] = []
var spawn_order: Array[Node3D] = []
var entry_log: Array[StringName] = []
var entry_retry: float = 0.0
var entry_status: String = "Waiting for navigation"
var encounter: EncounterSetup
var seed_override: int = -1


func _ready() -> void:
	config = mission_config_override if mission_config_override != null else CONFIGS[clampi(scenario_index, 0, CONFIGS.size() - 1)]
	hybrid_inventory = config.hybrid_inventory
	loot_table = config.loot_table
	deployment_started = not config.briefing_required
	if not deployment_started:
		process_mode = Node.PROCESS_MODE_DISABLED
		$Overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	raider_count = config.raider_count
	salvage_point_count = config.salvage_point_count
	materials_per_point = config.materials_per_point
	mission_duration = config.duration
	debug_seed = config.seed
	max_active_raiders = config.max_active_raiders
	fallback_profiles = config.fallback_profiles
	if not config.encounter_layouts.is_empty():
		if seed_override >= 0:
			debug_seed = seed_override
		encounter = EncounterSetup.new()
		encounter.arena = self
		add_child(encounter)
		setup_error = encounter.resolve(config, debug_seed)
	dynamic_ai = true
	combat_profile = preload("res://resources/enemies/armed_scavenger.tres") if config.armed else null
	flare_rules = preload("res://resources/missions/death_flare_rules.tres") if config.death_flares else null
	recall_enabled = config.player_extraction
	ecosystem_enabled = config.machine_ecosystem
	social_rules = config.social_rules
	mission.post_death_spectating = config.post_death_spectating
	if social_rules != null:
		$Robot.position = $SocialRobotStart.position
	if not config.player_start_marker.is_empty():
		var marker := get_node_or_null(NodePath(config.player_start_marker)) as Node3D
		if marker != null:
			$Robot.position = marker.position
	$Robot.traversal_enabled = config.experimental_traversal
	super._ready()
	$Overlay/FoundationStatus.text = "SCRAP RAIDERS | %s\nWASD: move | Mouse: orbit | RMB: aim | LMB: fire | E: recover\nF2: Traversal | F4: Machines | F5: Extraction | F6-8: Unarmed | F9: Survival | F10: Loot | F12: Recall | F3: debug" % config.display_name
	if OS.is_debug_build():
		$Overlay/FoundationStatus.text += "\nF1: Spectator | F11: Rivalry | Shift+F11: Cooperation | Ctrl+F11: Pressure | Alt+F11: Betrayal"
	if encounter != null:
		$Overlay/FoundationStatus.text = "EMERGENT ENCOUNTERS | WASD move | Mouse orbit | LMB fire | E recover\nSpace jump | Shift boost | F1 spectator | F3 diagnostics\nShift+F5: encounter preset | Ctrl+Shift+F5: next seed | Hold E at dock: recall"
		if scenario_index == 14:
			$Overlay/FoundationStatus.text = $Overlay/FoundationStatus.text.replace("EMERGENT ENCOUNTERS", "PERSONALITY ENCOUNTERS")
		$Overlay/FoundationStatus.text += "\nAlt+Shift+F5: personality comparison"
	if not mission.is_finished():
		for index in range(config.ground_stacks):
			present_drop(index + 1, $GroundCargo.get_child(index).global_position)
		status.text = "%s: %d Raiders scheduled. Intercept and recover cargo." % [config.display_name, raider_count]
		if config.player_extraction:
			status.text = "%s: recover loot and hold E at the Recall Dock to extract before the deadline." % config.display_name
		refresh_hud()
	if objective_view != null:
		if not deployment_started:
			robot.input_adapter.gameplay_enabled = false
			robot.input_adapter.clear_intent()
			robot.get_node("Weapon").enabled = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		objective_view.prepare()


func setup_mission_objectives() -> void:
	if not config.objective_definitions.is_empty():
		mission_objectives = MissionObjectives.new(config, ledger, flare_director.equipment, robot.get_instance_id(), recall.deployment_id)
		raider_defeat_accepted.connect(mission_objectives.accepted_defeat)
		objective_view = MissionObjectivesView.new()
		objective_view.arena = self
		$Overlay.add_child(objective_view)


func setup_observer() -> void:
	if OS.is_debug_build() and (capture_metrics or "--capture-metrics" in OS.get_cmdline_user_args()):
		metrics = DeploymentMetrics.new()
		add_child(metrics)
		metrics.attach(self)


func initial_ground_stock() -> Dictionary:
	var stock := {}
	for index in range(config.ground_stacks):
		stock[index + 1] = config.materials_per_stack
	return stock


func actor_entered(actor: Raider) -> void:
	if metrics != null:
		metrics.register_actor(actor)
	if encounter != null:
		encounter.register_actor(actor)


func setup_extractions() -> void:
	for point in [$Extraction, $Extraction2]:
		point.visible = config.exits.has(str(point.name))
		if point.visible:
			extraction_points.append(point)


func deploy_raiders() -> void:
	var error := config.validation_error()
	if not config.player_start_marker.is_empty() and not get_node_or_null(NodePath(config.player_start_marker)) is Marker3D:
		error = "Unknown player start marker."
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
	if not deployment_started or mission.is_world_finished():
		return
	if encounter != null and not encounter.navigation_checked:
		if NavigationServer3D.map_get_iteration_id($NavigationRegion3D.get_navigation_map()) == 0:
			return
		var error := encounter.validate_navigation()
		if not error.is_empty():
			mission.fail_setup(error)
			finish_mission()
			return
	for id in pending_ids.duplicate():
		if not population_has_room():
			break
		if elapsed < config.entry_times[id - 1]:
			continue
		var entered := false
		var choices: Array[Node3D] = spawn_order
		if not config.preferred_entries.is_empty():
			choices = [$RaiderSpawns.get_node(NodePath(config.preferred_entries[id - 1]))]
		if encounter != null:
			choices = [$RaiderSpawns.get_node(NodePath(encounter.layout.entry_markers[id - 1]))]
		for offset in range(choices.size()):
			var marker := choices[(id - 1 + offset) % choices.size()]
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
	if mission.is_world_finished():
		return
	entry_retry -= delta
	if entry_retry <= 0 and not pending_ids.is_empty():
		entry_retry = 0.5
		process_entries()
		refresh_hud()


func pending_world_entries() -> int:
	return pending_ids.size()


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
		if not reports.is_empty() and not mission.is_finished() and not action_notice_active():
			$Overlay/RaiderStatus.text = "Machine report: R%02d last seen near (%.0f, %.0f)" % [reports[0].target_id, reports[0].position.x, reports[0].position.z]
		elif not action_notice_active() and $Overlay/RaiderStatus.text.begins_with("Machine report:"):
			$Overlay/RaiderStatus.text = ""
	if action_notice_active():
		status.text = action_notice
	elif status.text == action_notice:
		status.text = ""
	if debug_visible:
		$Overlay/DebugStatus.text = $Overlay/DebugStatus.text.replace("STAGE B", "STAGE C")
		$Overlay/DebugStatus.text += "\nSTAGE C | %s | pending %s | %s" % [config.display_name, pending_ids, entry_status]
		if social != null:
			for actor in raiders.values():
				if is_instance_valid(actor):
					$Overlay/DebugStatus.text += "\nR%02d target %s (%s) | %s" % [actor.raider_id, actor.current_target().name, actor.target_reason, social.describe(actor)]
		if flare_director != null:
			$Overlay/DebugStatus.text += "\nFLARES %d | local jobs %d | reinforcement tickets %d | equipment invariant %s" % [flare_director.handled_deaths.size(), flare_director.local_jobs.size(), flare_director.tickets.size(), flare_director.equipment.is_valid()]
		if ecosystem != null:
			for actor in raiders.values():
				if is_instance_valid(actor):
					$Overlay/DebugStatus.text += "\nR%02d target %s" % [actor.raider_id, actor.current_target().name]
		if encounter != null and not encounter.snapshot.is_empty():
			$Overlay/DebugStatus.text = encounter.describe()

	if uses_concise_hud():
		refresh_refined_hud()
	if objective_view != null:
		objective_view.refresh()


func uses_concise_hud() -> bool:
	return scenario_index == 15 or (config != null and config.concise_hud)


func refresh_refined_hud() -> void:
	objectives.position.y = 160 if debug_visible else 24
	var global_totals := objectives.text
	var routine_report := status.text if status.text.begins_with("Machine report:") else ""
	var equipment_count := flare_director.equipment.count_at(EquipmentLedger.Location.RECOVERED) if flare_director != null else 0
	objectives.text = "Recover loot and return to the Recall Dock.\nCargo: %d materials | %d equipment | Time: %ds" % [ledger.recovered_materials, equipment_count, ceili(maxf(0, mission_duration - elapsed))]
	if mission.is_finished():
		objectives.text = "Deployment ended. See the report."
	if not action_notice_active():
		status.text = ""
	if debug_visible:
		$Overlay/DebugStatus.text += "\n" + global_totals + "\n" + routine_report
		if metrics != null:
			$Overlay/DebugStatus.text += "\nMETRICS ON | Ctrl+F3: export local snapshot | events %d/%d" % [metrics.events.size(), DeploymentMetrics.EVENT_LIMIT]
	for actor in raiders.values():
		if is_instance_valid(actor):
			actor.label.visible = debug_visible
	if ecosystem != null:
		for machine in ecosystem.machines:
			machine.label.visible = debug_visible
	for target in ["TargetA", "TargetB", "TargetC"]:
		var target_label := get_node_or_null(target + "/Label3D")
		if target_label != null:
			target_label.visible = debug_visible
	if recall != null:
		recall.stash_label.visible = debug_visible or not recall.save_error.is_empty()


func start_deployment() -> bool:
	if deployment_started or mission.is_finished():
		return false
	if hybrid_inventory and (not recall.save_error.is_empty() or not recall.stash.begin_inventory_deployment(recall.deployment_id)):
		recall.save_error = recall.stash.last_error if recall.save_error.is_empty() else recall.save_error
		recall.refresh_stash()
		return false
	deployment_started = true
	robot.input_adapter.clear_intent()
	robot.input_adapter.gameplay_enabled = true
	robot.get_node("Weapon").enabled = true
	if interaction_mode != null:
		interaction_mode.close_inventory()
		interaction_mode.refresh()
	process_mode = Node.PROCESS_MODE_INHERIT
	if hybrid_inventory:
		# Briefing disabled the region too. Publish its re-enabled map before any
		# scheduled entry validates reachability against a previously empty map.
		NavigationServer3D.map_force_update($NavigationRegion3D.get_navigation_map())
		# Static collision participation also resumes at the next server step.
		# Do not classify its activation interval as invalid authored geometry.
		entry_retry = 0.1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if objective_view != null:
		objective_view.begin()
	present_arrival()
	refresh_hud()
	return true


func complete_player_extraction() -> void:
	var required_met := mission_objectives.required_satisfied(true) if mission_objectives != null else true
	mission.complete_extraction(required_met)
	finish_mission()


func finalize_player_result() -> void:
	if mission_objectives != null:
		mission_objectives.close(mission, elapsed)


func finish_mission() -> void:
	var was_visible := summary.visible
	super.finish_mission()
	if metrics != null and mission.is_world_finished():
		# Finish after the terminal signal has reached all observers (e.g. last machine death).
		metrics.finish.call_deferred(mission.world_reason)
	if not was_visible and summary.visible and mission_objectives == null:
		$Overlay/Summary/Content/Report.text += "\nRaiders never entered: %d" % pending_ids.size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3 and event.ctrl_pressed and metrics != null:
			var output := "user://deployment_%d_%d.json" % [debug_seed, Time.get_ticks_msec()]
			var error := metrics.export_json(output)
			show_action_notice("Metrics saved: " + ProjectSettings.globalize_path(output) if error == OK else "Metrics export failed: " + error_string(error))
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F5:
			get_viewport().set_input_as_handled()
			if event.shift_pressed and OS.is_debug_build():
				if event.ctrl_pressed and scenario_index == 16:
					select_scenario.call_deferred(16, debug_seed + 1, true)
					return
				var encounter_index := 14 if event.alt_pressed or (event.ctrl_pressed and scenario_index == 14) else 13
				var encounter_seed := -1
				if encounter != null:
					if event.ctrl_pressed:
						encounter_seed = debug_seed + 1
					elif event.alt_pressed or scenario_index == 14:
						encounter_seed = debug_seed
				select_scenario.call_deferred(encounter_index, encounter_seed)
			else:
				select_scenario.call_deferred(12)
			return
		if event.physical_keycode == KEY_F11 and OS.is_debug_build():
			get_viewport().set_input_as_handled()
			select_scenario.call_deferred(11 if event.alt_pressed else (10 if event.ctrl_pressed else (9 if event.shift_pressed else 8)))
			return
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


func select_scenario(index: int, new_seed: int = -1, preserve_level: bool = false) -> void:
	# Replace the scene with an explicit configuration; no persistent singleton state.
	if mission_objectives != null and not mission.is_finished():
		mission.fail_abandoned()
		finish_mission()
	if mission.player_destroyed and not mission.is_world_finished():
		mission.stop_world("Deployment replaced.")
		finish_mission()
	var scene_path := "res://scenes/levels/emergent_encounters_arena.tscn" if index == 13 else "res://scenes/levels/mission_arena.tscn"
	if index == 14:
		scene_path = "res://scenes/levels/personality_encounters_arena.tscn"
	if index == 15:
		scene_path = "res://scenes/levels/refined_extraction_arena.tscn"
	if index == 16:
		scene_path = "res://scenes/levels/asset_recovery_arena.tscn"
	if preserve_level and not scene_file_path.is_empty():
		scene_path = scene_file_path
	if metrics != null:
		metrics.finish("Deployment replaced.")
	var replacement := load(scene_path).instantiate() as Node3D
	replacement.scenario_index = clampi(index, 0, CONFIGS.size() - 1)
	replacement.mission_config_override = mission_config_override if preserve_level else null
	replacement.seed_override = new_seed
	replacement.capture_metrics = capture_metrics
	replacement.stash_path = stash_path
	var tree := get_tree()
	tree.root.remove_child(self)
	tree.root.add_child(replacement)
	tree.current_scene = replacement
	queue_free()


func restart_mission() -> void:
	select_scenario.call_deferred(scenario_index, debug_seed if encounter != null else -1, true)


func _exit_tree() -> void:
	if mission_objectives != null:
		mission_objectives.dispose()
	if is_instance_valid(metrics) and not metrics.stopped:
		metrics.finish("Scene closed.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and mission_objectives != null and not mission.is_finished():
		mission.fail_abandoned()
		finish_mission()
