class_name Raider
extends CharacterBody3D
## Owns this actor's FSM and physics. Quantities remain read-only ledger views.

signal navigation_recovered(details: Dictionary)
signal state_changed(previous: State, next: State)
signal extracted(materials: int)
signal cargo_collected(materials: int)
signal collection_requested
signal defeated(dropped_materials: int)

enum State { SCAVENGING, FLEEING, EXTRACTING, DEAD, EXTRACTED, SELECTING, INVESTIGATING, STRANDED, ENGAGING, TAKING_COVER, REPOSITIONING, ASSESSING_BETRAYAL }

@export var robot: Node3D
@export var salvage: Node3D
@export var extraction: Node3D
@export var scavenge_seconds: float = 3.0
@export var extraction_seconds: float = 3.0
@export var detection_range: float = 8.0
@export var walk_speed: float = 3.0
@export var flee_speed: float = 4.5
@export var navigation_stall_seconds: float = 1.5
var dynamic_ai: bool = false
var profile: RaiderProfile
var combat: RaiderCombat
var threat_monitor := RaiderThreatMonitor.new()
var social: RaiderSocial
var betrayal: RaiderBetrayal
var combat_target: Node3D
var select_combat_target: Callable
var combat_target_allowed: Callable
var squad_id: StringName = &""
var target_reason: String = "player baseline"
var available_stock: Callable
var is_flare_responder: bool = false
var ledger: MaterialLedger
var raider_id: int = 0
var select_salvage: Callable
var select_extraction: Callable
var state: State = State.SCAVENGING
var carried_materials: int:
	get: return ledger.cargo_for(raider_id) if ledger != null else 0
var task_elapsed: float = 0.0
var decision_remaining: float = 0.0
var threat_visible: bool = false
var threat_remaining: float = 0.0
var threat_source: String = "none"
var last_threat_position: Vector3
var investigation_position: Vector3
var _investigated_threat_position: Vector3 = Vector3.INF
var navigation_status: String = "READY"
var navigation_failures: int = 0
var blocked_salvage: Dictionary[StringName, bool] = {}
var blocked_exits: Dictionary[StringName, bool] = {}
var _progress_elapsed: float = 0.0
var _progress_origin: Vector3
var _progress_best_remaining: float = INF
var _progress_checkpoint_remaining: float = INF
var _retry_remaining: float = 0.0
var _bypass_actor: CharacterBody3D
var _bypass_direction: Vector3
var _bypass_remaining: float = 0.0
var _bypass_goal: Vector3
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var label: Label3D = $Label3D
@onready var visuals: Node3D = $Visuals


func _ready() -> void:
	assert(robot != null and extraction != null and ledger != null and select_salvage.is_valid())
	if dynamic_ai:
		assert(profile != null and select_extraction.is_valid())
		detection_range = profile.detection_radius
		var material := StandardMaterial3D.new()
		material.albedo_color = profile.color
		$Visuals/Body.material_override = material
		transition(State.SELECTING)
	elif salvage == null:
		transition(State.EXTRACTING)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	_progress_origin = global_position
	update_label()


func transition(next: State) -> void:
	if state == next or state in [State.DEAD, State.EXTRACTED]:
		return
	var previous := state
	state = next
	if next == State.INVESTIGATING:
		_investigated_threat_position = last_threat_position
		# This accepted route has its own deadline. Later knowledge cannot
		# extend it indefinitely or reset the navigation watchdog.
		threat_monitor.investigation_remaining = minf(threat_remaining, profile.threat_memory)
		threat_monitor.reported_investigation = threat_source in ["ally report", "flare"]
	task_elapsed = 0.0
	_progress_elapsed = 0.0
	_progress_origin = global_position
	_progress_best_remaining = INF
	_progress_checkpoint_remaining = INF
	navigation_failures = 0
	print("R%02d: %s -> %s" % [raider_id, State.keys()[previous], State.keys()[next]])
	state_changed.emit(previous, next)
	update_label()


func current_target() -> Node3D:
	return combat_target if is_instance_valid(combat_target) else robot


func target_point(target: Node3D) -> Vector3:
	return target.get_aim_position() if target.has_method("get_aim_position") else target.global_position + Vector3.UP


func detects_actor(target: Node3D) -> bool:
	if not is_instance_valid(target) or target.get_node("Health").current <= 0 or global_position.distance_to(target.global_position) > detection_range:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP, target_point(target), 3, [get_rid()])
	query.hit_from_inside = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == target


func detects_robot() -> bool:
	return detects_current_target()


func detects_machine(target: Node3D) -> bool:
	return detects_actor(target)


func detects_current_target() -> bool:
	var target := current_target()
	return (not combat_target_allowed.is_valid() or combat_target_allowed.call(target)) and detects_actor(target)


func loot_progress() -> int:
	return ledger.inventory.loot_value("actor:%d" % raider_id) if ledger != null and ledger.inventory.hybrid else carried_materials

func salvage_available() -> int:
	if not is_instance_valid(salvage):
		return 0
	if social != null and salvage is MaterialDrop and not social.knows_drop(salvage):
		if ledger.inventory.hybrid and salvage is WorldLoot and salvage.drop_id < 0 and not social.searched_empty_cache(salvage): return 1 # Known authored route; inspect contents only on arrival/sight.
		return 0
	return available_stock.call(salvage) if available_stock.is_valid() else ledger.available(salvage.name)


func _choose_exit(preserve_activity_on_failure: bool = false) -> bool:
	extraction = select_extraction.call(raider_id)
	if extraction == null:
		navigation_status = "NO REACHABLE EXIT; retry in 2s"
		_retry_remaining = 2.0
		if not preserve_activity_on_failure:
			transition(State.STRANDED)
		return false
	return true


func decide() -> void:
	if state in [State.DEAD, State.EXTRACTED]:
		return
	if state == State.INVESTIGATING and threat_monitor.reported_investigation and threat_monitor.investigation_remaining <= 0:
		transition(State.SELECTING)
	if select_combat_target.is_valid():
		var selected: Node3D = select_combat_target.call(self)
		if is_instance_valid(selected) and selected != combat_target:
			combat_target = selected
			target_reason = "nearest visible hostile Raider" if selected is Raider else "nearest visible machine threat"
			if combat != null:
				combat.aim_elapsed = 0
		elif is_instance_valid(combat_target) and (combat_target.get_node("Health").current <= 0 or (combat_target_allowed.is_valid() and not combat_target_allowed.call(combat_target))):
			combat_target = null
			threat_remaining = 0
			target_reason = "target no longer eligible"
			if combat != null and combat.owns_state():
				transition(State.SELECTING)
	threat_visible = detects_robot()
	if not dynamic_ai:
		if state == State.SCAVENGING and salvage_available() == 0:
			salvage = select_salvage.call(raider_id)
			task_elapsed = 0.0
			if salvage == null:
				transition(State.EXTRACTING)
		if state == State.SCAVENGING and threat_visible:
			transition(State.FLEEING)
		elif state == State.FLEEING and global_position.distance_to(extraction.global_position) < 1.0:
			transition(State.EXTRACTING)
		return
	if threat_visible:
		threat_remaining = profile.threat_memory
		last_threat_position = current_target().global_position
		threat_source = "sight"
	elif threat_remaining <= 0.0:
		if threat_source not in ["ally report", "flare"]:
			_investigated_threat_position = Vector3.INF
		if threat_source != "ally report":
			threat_source = "none"
	if social != null:
		social.sense()
	if betrayal != null and betrayal.decide():
		return
	if combat != null and combat.decide():
		return
	if state == State.STRANDED:
		if _retry_remaining <= 0.0:
			blocked_exits.clear()
			blocked_salvage.clear()
			if loot_progress() < profile.cargo_target and select_salvage.call(raider_id) != null:
				transition(State.SELECTING)
			elif _choose_exit():
				transition(State.EXTRACTING)
		return
	if threat_visible and global_position.distance_to(current_target().global_position) <= profile.flee_distance:
		if state != State.FLEEING and _choose_exit():
			transition(State.FLEEING)
	elif state == State.FLEEING and threat_remaining <= 0 and loot_progress() < profile.cargo_target:
		transition(State.SELECTING)
	elif threat_visible and profile.investigates and state == State.SCAVENGING and last_threat_position.distance_to(_investigated_threat_position) >= profile.investigation_rearm_distance:
		begin_investigation()
	if state == State.SELECTING:
		salvage = select_salvage.call(raider_id) if loot_progress() < profile.cargo_target else null
		if salvage != null:
			transition(State.SCAVENGING)
		elif _choose_exit():
			transition(State.EXTRACTING)
	elif state == State.SCAVENGING and salvage_available() == 0:
		transition(State.SELECTING)
	elif state == State.FLEEING and is_instance_valid(extraction) and global_position.distance_to(extraction.global_position) < 0.8:
		transition(State.EXTRACTING)


func begin_investigation() -> void:
	var target := Vector3(last_threat_position.x, global_position.y, last_threat_position.z)
	var away := (global_position - target).normalized()
	# Arrival allows 0.8 m tolerance; stay clear of the close-threat threshold.
	investigation_position = target + away * (profile.flee_distance + 1.25)
	transition(State.INVESTIGATING)


func consider_allied_report(position: Vector3, remaining: float) -> bool:
	if threat_visible or remaining <= 0 or state in [State.DEAD, State.EXTRACTED, State.FLEEING, State.STRANDED] or loot_progress() >= profile.cargo_target or health.current <= health.maximum * 0.3:
		return false
	if (combat != null and (combat.owns_state() or combat.pursuing or combat.escaping)) or (threat_source in ["damage", "gunfire"] and threat_remaining > 0):
		return false
	last_threat_position = position
	threat_remaining = maxf(threat_remaining, remaining)
	threat_source = "ally report"
	if not threat_monitor.allows_interruption(RaiderThreatMonitor.Level.REPORTED, minimum_interrupt()):
		return false
	if position.distance_to(_investigated_threat_position) < profile.investigation_rearm_distance:
		return false
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var closest := NavigationServer3D.map_get_closest_point(map, position)
	var path := NavigationServer3D.map_get_path(map, global_position, closest, true)
	if closest.distance_to(position) > 1 or path.is_empty() or path[path.size() - 1].distance_to(closest) > 0.8:
		return false
	last_threat_position = position
	investigation_position = position
	transition(State.INVESTIGATING)
	return true


func investigate_flare(position: Vector3) -> bool:
	if state in [State.DEAD, State.EXTRACTED, State.FLEEING, State.STRANDED] or health.current <= health.maximum * 0.3:
		return false
	if detects_robot() or (combat != null and (combat.owns_state() or combat.pursuing or combat.escaping)):
		return false
	if state == State.EXTRACTING and loot_progress() >= profile.cargo_target:
		return false
	if not threat_monitor.allows_interruption(RaiderThreatMonitor.Level.REPORTED, minimum_interrupt()) or position.distance_to(_investigated_threat_position) < profile.investigation_rearm_distance:
		return false
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var closest := NavigationServer3D.map_get_closest_point(map, position)
	var path := NavigationServer3D.map_get_path(map, global_position, closest, true)
	if closest.distance_to(position) > 1 or path.is_empty() or path[path.size() - 1].distance_to(closest) > 0.8:
		return false
	if investigation_position.distance_to(position) > 0.5:
		task_elapsed = 0.0
	investigation_position = position
	last_threat_position = position
	threat_source = "flare"
	threat_remaining = maxf(threat_remaining, profile.threat_memory)
	transition(State.INVESTIGATING)
	return true


func minimum_interrupt() -> RaiderThreatMonitor.Level:
	# Rank unsolicited observations against the accepted action. Combat's
	# existing attacker and survival policies still decide urgent responses.
	match state:
		State.DEAD, State.EXTRACTED, State.FLEEING, State.STRANDED:
			return RaiderThreatMonitor.Level.CRITICAL
		State.ENGAGING, State.TAKING_COVER, State.REPOSITIONING, State.ASSESSING_BETRAYAL:
			return RaiderThreatMonitor.Level.DIRECT_ATTACK
		State.INVESTIGATING:
			return RaiderThreatMonitor.Level.VISIBLE
	return RaiderThreatMonitor.Level.REPORTED


func hear_gunfire(origin: Vector3) -> bool:
	if not dynamic_ai or state in [State.DEAD, State.EXTRACTED] or is_queued_for_deletion() or not ledger.is_active(raider_id):
		return false
	if global_position.distance_to(origin) > profile.hearing_radius:
		return false
	var already_alerted := threat_remaining > 0.0
	# Sound gives a last-known source, never continuous tracking through cover.
	if threat_remaining <= 0.0 and not threat_visible:
		_investigated_threat_position = Vector3.INF
	if not threat_visible:
		last_threat_position = Vector3(origin.x, global_position.y, origin.z)
		threat_source = "gunfire"
	threat_remaining = maxf(threat_remaining, profile.threat_memory)
	if combat != null:
		return true # Combat decides its response on the normal perception interval.
	# Damage/flight retain priority; repeated shots must not restart task clocks.
	if state in [State.FLEEING, State.STRANDED]:
		return true
	if state == State.EXTRACTING and already_alerted:
		return true
	if profile.flees_from_gunfire or global_position.distance_to(origin) <= profile.flee_distance:
		if _choose_exit():
			transition(State.FLEEING)
	elif profile.investigates and state in [State.SCAVENGING, State.SELECTING] and loot_progress() < profile.cargo_target and last_threat_position.distance_to(_investigated_threat_position) >= profile.investigation_rearm_distance:
		begin_investigation()
	update_label()
	return true


func _physics_process(delta: float) -> void:
	if state in [State.DEAD, State.EXTRACTED]:
		return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	if dynamic_ai and not NavigationServer3D.map_get_closest_point_owner(agent.get_navigation_map(), global_position).is_valid():
		return
	threat_remaining = maxf(0, threat_remaining - delta)
	_retry_remaining = maxf(0, _retry_remaining - delta)
	_bypass_remaining = maxf(0, _bypass_remaining - delta)
	if betrayal != null:
		betrayal.tick(delta)
	if combat != null:
		combat.tick(delta)
		if not combat.weapon.enabled:
			return
	else:
		threat_monitor.tick(delta)
	decision_remaining -= delta
	if decision_remaining <= 0:
		decision_remaining = 0.15
		decide()
	var destination: Node3D = salvage if state == State.SCAVENGING else extraction
	var position_target := global_position
	if state == State.INVESTIGATING:
		position_target = investigation_position
	elif state == State.ENGAGING and combat != null:
		position_target = combat.spacing_position()
	elif state == State.ASSESSING_BETRAYAL:
		position_target = global_position
	elif state in [State.TAKING_COVER, State.REPOSITIONING] and combat != null and is_instance_valid(combat.destination):
		position_target = combat.destination.global_position
	elif state not in [State.SELECTING, State.STRANDED] and is_instance_valid(destination):
		position_target = destination.global_position
	elif state not in [State.SELECTING, State.STRANDED]:
		if dynamic_ai:
			transition(State.SELECTING)
	var arrived := global_position.distance_to(position_target) < 0.8
	if arrived:
		task_elapsed += delta
		if combat != null and combat.owns_state():
			combat.on_arrived(delta)
		if state == State.SCAVENGING and task_elapsed >= scavenge_seconds:
			collection_requested.emit()
			if loot_progress() > 0:
				cargo_collected.emit(carried_materials)
				if dynamic_ai and loot_progress() < profile.cargo_target:
					transition(State.SELECTING)
				elif not dynamic_ai or _choose_exit():
					transition(State.EXTRACTING)
			else:
				salvage = select_salvage.call(raider_id)
				task_elapsed = 0
				if salvage == null and (not dynamic_ai or _choose_exit()):
					transition(State.EXTRACTING)
			return
		elif state == State.EXTRACTING and task_elapsed >= extraction_seconds:
			var amount := carried_materials
			transition(State.EXTRACTED)
			extracted.emit(amount)
			queue_free()
			return
		elif state == State.INVESTIGATING and task_elapsed >= 2.0:
			if combat != null and combat.pursuing:
				combat.release_interest("last observed position searched; resume objectives")
			else:
				transition(State.SELECTING)
	else:
		task_elapsed = 0
	var direction := Vector3.ZERO
	if not arrived and state not in [State.SELECTING, State.STRANDED]:
		if agent.target_position != position_target:
			agent.target_position = position_target
			_progress_elapsed = 0
			_progress_origin = global_position
			_progress_best_remaining = INF
			_progress_checkpoint_remaining = INF
		var next_position := agent.get_next_path_position()
		if not agent.is_navigation_finished():
			direction = next_position - global_position
			direction.y = 0
			direction = direction.normalized()
		if dynamic_ai:
			var cover_route := state in [State.TAKING_COVER, State.REPOSITIONING]
			var remaining := remaining_path_distance(next_position) if cover_route else INF
			if cover_route:
				if not is_finite(_progress_checkpoint_remaining):
					_progress_checkpoint_remaining = remaining
				_progress_best_remaining = minf(_progress_best_remaining, remaining)
			_progress_elapsed += delta
			if _progress_elapsed >= navigation_stall_seconds:
				# Circling a body can produce full-speed displacement without
				# advancing the accepted route. Preserve its best remaining
				# length across repaths instead of treating each loop as progress.
				# Other activities retain their accepted displacement watchdog;
				# cover work is the route vulnerable to blocked-waypoint circles.
				var stalled := global_position.distance_to(_progress_origin) < 0.2
				if cover_route:
					stalled = _progress_checkpoint_remaining - _progress_best_remaining < 0.2 or not is_finite(remaining)
				if stalled:
					recover_navigation(position_target)
				else:
					navigation_failures = 0
					navigation_status = "FOLLOWING PATH"
				_progress_elapsed = 0
				_progress_origin = global_position
				_progress_checkpoint_remaining = _progress_best_remaining
	else:
		_progress_elapsed = 0
	var speed := flee_speed if state == State.FLEEING else walk_speed
	direction = steer_around_actor(direction, position_target)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	move_and_slide()
	if direction.length_squared() > 0.01 and state != State.ENGAGING:
		visuals.rotation.y = atan2(-direction.x, -direction.z)
	update_label()


func remaining_path_distance(next_position: Vector3) -> float:
	var path := agent.get_current_navigation_path()
	if path.is_empty():
		return INF
	var index := agent.get_current_navigation_path_index()
	# get_next_path_position() already includes the actor's bake-height offset;
	# the remaining path segments retain their original relative elevations.
	var remaining := global_position.distance_to(next_position)
	for step in range(index + 1, path.size()):
		remaining += path[step - 1].distance_to(path[step])
	return remaining


func steer_around_actor(direction: Vector3, destination: Vector3) -> Vector3:
	if direction.is_zero_approx():
		_bypass_remaining = 0
		return direction
	# Navigation paths describe static geometry. Sweep the actual body for a
	# nearby actor before walking into it; geometry still blocks every move.
	if _bypass_remaining > 0 and is_instance_valid(_bypass_actor) and destination.distance_to(_bypass_goal) < 1:
		var offset := _bypass_actor.global_position - global_position
		offset.y = 0
		# The blocker occupies this navigation segment. A corner can place it
		# outside the final-goal corridor while it still obstructs our path.
		var forward := direction.normalized()
		var lateral := offset - forward * offset.dot(forward)
		var goal_forward := (destination - global_position).normalized()
		if offset.length() < 2.5 and lateral.length() < 1.0 and offset.dot(goal_forward) > 0 and not test_move(global_transform, _bypass_direction * 0.6):
			return _bypass_direction
	_bypass_remaining = 0
	var collision := KinematicCollision3D.new()
	var blocker: CharacterBody3D
	if test_move(global_transform, direction, collision) and collision.get_collider() is CharacterBody3D:
		blocker = collision.get_collider() as CharacterBody3D
	if blocker == null:
		return direction
	var away := global_position - blocker.global_position
	away.y = 0
	if away.is_zero_approx():
		away = -direction
	away = away.normalized()
	var tangent := Vector3(-away.z, 0, away.x)
	var preferred := tangent if tangent.dot(destination - global_position) >= 0 else -tangent
	for side in [preferred, -preferred]:
		var detour: Vector3 = (side + away * 0.5 + direction * 0.5).normalized()
		if not test_move(global_transform, detour * 0.6):
			# Commit to this physical direction briefly, not a recomputed tangent
			# around a moving blocker. Expiry/changed goals/geometry release it.
			_bypass_actor = blocker
			_bypass_direction = detour
			_bypass_goal = destination
			_bypass_remaining = 0.35
			return detour
	return Vector3.ZERO


func recover_navigation(destination: Vector3) -> void:
	var previous := state
	navigation_failures += 1
	if navigation_failures == 1:
		navigation_status = "REPATH REQUESTED"
		agent.target_position = destination
		navigation_recovered.emit({"goal": destination, "reason": "low progress", "result": navigation_status, "before": previous, "after": state})
		return
	navigation_failures = 0
	if state == State.SCAVENGING:
		if is_instance_valid(salvage):
			blocked_salvage[salvage.name] = true
		navigation_status = "ALTERNATE SALVAGE"
		transition(State.SELECTING)
	elif state == State.INVESTIGATING:
		transition(State.SELECTING)
	elif combat != null and combat.owns_state():
		combat.release()
		if detects_current_target():
			transition(State.ENGAGING)
		else:
			begin_investigation()
	else:
		if is_instance_valid(extraction):
			blocked_exits[extraction.name] = true
		navigation_status = "ALTERNATE EXIT"
		if _choose_exit():
			task_elapsed = 0

	navigation_recovered.emit({"goal": destination, "reason": "repeated low progress", "result": navigation_status, "before": previous, "after": state})


func _on_damaged(_amount: float) -> void:
	if health.current > 0:
		if dynamic_ai:
			threat_remaining = profile.threat_memory + 2.0
			last_threat_position = health.last_damage_origin if select_combat_target.is_valid() and health.last_damage_origin.is_finite() else robot.global_position
			threat_source = "damage"
			if combat != null:
				var instigator := instance_from_id(health.last_damage_instigator_id) if health.last_damage_instigator_id > 0 else null
				# React to an observed, eligible attacker. Damage alone does not
				# grant vision through walls or turn neutral actors hostile.
				if instigator is Node3D and combat_target_allowed.is_valid() and combat_target_allowed.call(instigator) and detects_actor(instigator):
					if combat_target != instigator and combat.can_redirect_to_attacker():
						combat_target = instigator
						combat.aim_elapsed = 0
						target_reason = "visible attacker"
				combat.on_damaged()
				return
			task_elapsed = 0
			if not _choose_exit():
				return
		task_elapsed = 0
		transition(State.FLEEING)


func _on_died() -> void:
	transition(State.DEAD)
	velocity = Vector3.ZERO
	defeated.emit(carried_materials)
	queue_free()


func update_label() -> void:
	# Presentation reads the actual task clock; it never advances AI progress.
	var activity: String = State.keys()[state]
	var color := Color.WHITE
	match state:
		State.SCAVENGING:
			color = Color(1, 0.85, 0.35)
			if task_elapsed > 0.0:
				var progress := clampf(task_elapsed / maxf(scavenge_seconds, 0.001), 0.0, 1.0)
				activity = "SCAVENGING %d%%" % int(progress * 100)
			else:
				activity = "SEEKING SALVAGE"
		State.FLEEING:
			color = Color(1, 0.6, 0.3)
			activity = "FLEEING WITH CARGO" if carried_materials > 0 else "FLEEING EMPTY"
		State.EXTRACTING:
			color = Color(1, 0.6, 0.3) if carried_materials > 0 else Color(0.6, 1, 0.7)
			if task_elapsed > 0.0:
				activity = "EXTRACTING IN %.1fs" % maxf(0.0, extraction_seconds - task_elapsed)
			else:
				activity = "ESCAPING WITH CARGO" if carried_materials > 0 else "RETREATING EMPTY"
		State.SELECTING:
			activity = "CHOOSING OBJECTIVE"
		State.INVESTIGATING:
			activity = "INVESTIGATING THREAT"
			color = Color(1, 0.5, 0.3)
		State.STRANDED:
			activity = "NO ROUTE - RETRYING"
			color = Color(1, 0.4, 0.4)
		State.ENGAGING:
			activity = "AIMING %.1fs" % maxf(0, combat.profile.warning_time - combat.aim_elapsed) if combat != null else "ENGAGING"
			if combat != null and combat.aim_elapsed >= combat.profile.warning_time:
				activity = "FIRING"
			color = Color(1, 0.35, 0.25)
		State.TAKING_COVER:
			activity = "SEEKING COVER" if task_elapsed <= 0 else "IN COVER"
		State.REPOSITIONING:
			activity = "REPOSITIONING"
		State.ASSESSING_BETRAYAL:
			activity = "HESITATING"
			color = Color(1, 0.55, 0.1)
	label.modulate = color
	var identity := "R%02d %s" % [raider_id, profile.display_name] if dynamic_ai else "R%02d" % raider_id
	if is_flare_responder:
		identity = "R%02d RESPONDER" % raider_id
	label.text = "%s %s\nHP %d | CARGO %d" % [identity, activity, health.current, carried_materials]
