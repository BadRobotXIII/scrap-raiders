class_name Raider
extends CharacterBody3D
## Owns this actor's FSM and physics. Quantities remain read-only ledger views.

signal state_changed(previous: State, next: State)
signal extracted(materials: int)
signal cargo_collected(materials: int)
signal collection_requested
signal defeated(dropped_materials: int)

enum State { SCAVENGING, FLEEING, EXTRACTING, DEAD, EXTRACTED, SELECTING, INVESTIGATING, STRANDED }

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
var last_threat_position: Vector3
var investigation_position: Vector3
var navigation_status: String = "READY"
var navigation_failures: int = 0
var blocked_salvage: Dictionary[StringName, bool] = {}
var blocked_exits: Dictionary[StringName, bool] = {}
var _progress_elapsed: float = 0.0
var _progress_origin: Vector3
var _retry_remaining: float = 0.0
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
	task_elapsed = 0.0
	_progress_elapsed = 0.0
	_progress_origin = global_position
	navigation_failures = 0
	print("R%02d: %s -> %s" % [raider_id, State.keys()[previous], State.keys()[next]])
	state_changed.emit(previous, next)
	update_label()


func detects_robot() -> bool:
	if global_position.distance_to(robot.global_position) > detection_range:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP, robot.global_position + Vector3.UP, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == robot


func _choose_exit() -> bool:
	extraction = select_extraction.call(raider_id)
	if extraction == null:
		navigation_status = "NO REACHABLE EXIT; retry in 2s"
		_retry_remaining = 2.0
		transition(State.STRANDED)
		return false
	return true


func decide() -> void:
	threat_visible = detects_robot()
	if not dynamic_ai:
		if state == State.SCAVENGING and (not is_instance_valid(salvage) or ledger.available(salvage.name) == 0):
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
		last_threat_position = robot.global_position
	if state == State.STRANDED:
		if _retry_remaining <= 0.0:
			blocked_exits.clear()
			blocked_salvage.clear()
			if carried_materials < profile.cargo_target and select_salvage.call(raider_id) != null:
				transition(State.SELECTING)
			elif _choose_exit():
				transition(State.EXTRACTING)
		return
	if threat_visible and global_position.distance_to(robot.global_position) <= profile.flee_distance:
		if state != State.FLEEING and _choose_exit():
			transition(State.FLEEING)
	elif state == State.FLEEING and threat_remaining <= 0 and carried_materials < profile.cargo_target:
		transition(State.SELECTING)
	elif threat_visible and profile.investigates and state == State.SCAVENGING:
		var away := (global_position - last_threat_position).normalized()
		investigation_position = last_threat_position + away * 3.5
		transition(State.INVESTIGATING)
	if state == State.SELECTING:
		salvage = select_salvage.call(raider_id) if carried_materials < profile.cargo_target else null
		if salvage != null:
			transition(State.SCAVENGING)
		elif _choose_exit():
			transition(State.EXTRACTING)
	elif state == State.SCAVENGING and (not is_instance_valid(salvage) or ledger.available(salvage.name) == 0):
		transition(State.SELECTING)
	elif state == State.FLEEING and is_instance_valid(extraction) and global_position.distance_to(extraction.global_position) < 0.8:
		transition(State.EXTRACTING)


func _physics_process(delta: float) -> void:
	if state in [State.DEAD, State.EXTRACTED]:
		return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	if dynamic_ai and not NavigationServer3D.map_get_closest_point_owner(agent.get_navigation_map(), global_position).is_valid():
		return
	threat_remaining = maxf(0, threat_remaining - delta)
	_retry_remaining = maxf(0, _retry_remaining - delta)
	decision_remaining -= delta
	if decision_remaining <= 0:
		decision_remaining = 0.15
		decide()
	var destination: Node3D = salvage if state == State.SCAVENGING else extraction
	var position_target := global_position
	if state == State.INVESTIGATING:
		position_target = investigation_position
	elif state not in [State.SELECTING, State.STRANDED] and is_instance_valid(destination):
		position_target = destination.global_position
	elif state not in [State.SELECTING, State.STRANDED]:
		if dynamic_ai:
			transition(State.SELECTING)
	var arrived := global_position.distance_to(position_target) < 0.8
	if arrived:
		task_elapsed += delta
		if state == State.SCAVENGING and task_elapsed >= scavenge_seconds:
			collection_requested.emit()
			if carried_materials > 0:
				cargo_collected.emit(carried_materials)
				if dynamic_ai and carried_materials < profile.cargo_target:
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
			transition(State.SELECTING)
	else:
		task_elapsed = 0
	var direction := Vector3.ZERO
	if not arrived and state not in [State.SELECTING, State.STRANDED]:
		if agent.target_position != position_target:
			agent.target_position = position_target
			_progress_elapsed = 0
			_progress_origin = global_position
		var next_position := agent.get_next_path_position()
		if not agent.is_navigation_finished():
			direction = next_position - global_position
			direction.y = 0
			direction = direction.normalized()
		if dynamic_ai:
			_progress_elapsed += delta
			if _progress_elapsed >= navigation_stall_seconds:
				if global_position.distance_to(_progress_origin) < 0.2:
					recover_navigation(position_target)
				else:
					navigation_failures = 0
					navigation_status = "FOLLOWING PATH"
				_progress_elapsed = 0
				_progress_origin = global_position
	else:
		_progress_elapsed = 0
	var speed := flee_speed if state == State.FLEEING else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	move_and_slide()
	if direction.length_squared() > 0.01:
		visuals.rotation.y = atan2(-direction.x, -direction.z)
	update_label()


func recover_navigation(destination: Vector3) -> void:
	navigation_failures += 1
	if navigation_failures == 1:
		navigation_status = "REPATH REQUESTED"
		agent.target_position = destination
		return
	navigation_failures = 0
	if state == State.SCAVENGING:
		if is_instance_valid(salvage):
			blocked_salvage[salvage.name] = true
		navigation_status = "ALTERNATE SALVAGE"
		transition(State.SELECTING)
	elif state == State.INVESTIGATING:
		transition(State.SELECTING)
	else:
		if is_instance_valid(extraction):
			blocked_exits[extraction.name] = true
		navigation_status = "ALTERNATE EXIT"
		if _choose_exit():
			task_elapsed = 0


func _on_damaged(_amount: float) -> void:
	if health.current > 0:
		task_elapsed = 0
		if dynamic_ai:
			threat_remaining = profile.threat_memory + 2.0
			last_threat_position = robot.global_position
			if not _choose_exit():
				return
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
	label.modulate = color
	var identity := "R%02d %s" % [raider_id, profile.display_name] if dynamic_ai else "R%02d" % raider_id
	label.text = "%s %s\nHP %d | CARGO %d" % [identity, activity, health.current, carried_materials]
