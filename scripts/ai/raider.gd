class_name Raider
extends CharacterBody3D
## Single authoritative state machine; navigation supplies paths, this body owns motion.

signal state_changed(previous: State, next: State)
signal extracted(materials: int)
signal cargo_collected(materials: int)
signal collection_requested
signal defeated(dropped_materials: int)

enum State { SCAVENGING, FLEEING, EXTRACTING, DEAD, EXTRACTED }

@export var robot: Node3D
@export var salvage: Node3D
@export var extraction: Node3D
var ledger: MaterialLedger
var raider_id: int = 0
var select_salvage: Callable
@export var scavenge_seconds: float = 3.0
@export var extraction_seconds: float = 3.0
@export var detection_range: float = 8.0
@export var walk_speed: float = 3.0
@export var flee_speed: float = 4.5
var state: State = State.SCAVENGING
var carried_materials: int:
	get:
		return ledger.cargo_for(raider_id) if ledger != null else 0
var task_elapsed: float = 0.0
var decision_remaining: float = 0.0
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: Health = $Health
@onready var label: Label3D = $Label3D
@onready var visuals: Node3D = $Visuals


func _ready() -> void:
	assert(robot != null and extraction != null and ledger != null and select_salvage.is_valid())
	if salvage == null:
		transition(State.EXTRACTING)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	update_label()


func transition(next: State) -> void:
	if state == next or state in [State.DEAD, State.EXTRACTED]:
		return
	var previous := state
	state = next
	task_elapsed = 0.0
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


func _physics_process(delta: float) -> void:
	if state in [State.DEAD, State.EXTRACTED]:
		return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	decision_remaining -= delta
	if decision_remaining <= 0.0:
		decision_remaining = 0.15
		if state == State.SCAVENGING and (not is_instance_valid(salvage) or ledger.available(salvage.name) == 0):
			salvage = select_salvage.call(raider_id)
			task_elapsed = 0.0
			if salvage == null:
				transition(State.EXTRACTING)
		if state == State.SCAVENGING and detects_robot():
			transition(State.FLEEING)
		elif state == State.FLEEING and global_position.distance_to(extraction.global_position) < 1.0:
			transition(State.EXTRACTING)

	var destination := salvage if state == State.SCAVENGING else extraction
	var arrived := global_position.distance_to(destination.global_position) < 0.8
	if arrived:
		task_elapsed += delta
		if state == State.SCAVENGING and task_elapsed >= scavenge_seconds:
			collection_requested.emit()
			if carried_materials > 0:
				cargo_collected.emit(carried_materials)
				transition(State.EXTRACTING)
			else:
				salvage = select_salvage.call(raider_id)
				task_elapsed = 0.0
				if salvage == null:
					transition(State.EXTRACTING)
			return
		elif state == State.EXTRACTING and task_elapsed >= extraction_seconds:
			var amount := carried_materials
			transition(State.EXTRACTED)
			extracted.emit(amount)
			queue_free()
			return
	else:
		task_elapsed = 0.0

	if agent.target_position != destination.global_position:
		agent.target_position = destination.global_position
	var direction := Vector3.ZERO
	if not arrived:
		var next_position := agent.get_next_path_position()
		if not agent.is_navigation_finished():
			direction = next_position - global_position
			direction.y = 0
			direction = direction.normalized()
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


func _on_damaged(_amount: float) -> void:
	if health.current > 0:
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
	label.modulate = color
	label.text = "R%02d %s\nHP %d | CARGO %d" % [raider_id, activity, health.current, carried_materials]
