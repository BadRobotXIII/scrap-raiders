class_name SupportMachine
extends CharacterBody3D
## Independent allied actor. Reports observations; owns only its movement/FSM/health.

signal destroyed(machine: SupportMachine)
enum State { PATROLLING, INVESTIGATING, ENGAGING, DEAD }

var arena: Node3D
var awareness: MachineAwareness
var source_id: StringName
var flying: bool = false
var route: PackedVector3Array
var state: State = State.PATROLLING
var route_index: int = 0
var health: Health
var agent: NavigationAgent3D
var weapon: ShotExecutor
var visuals: Node3D
var label: Label3D
var target: Raider
var observed_position: Vector3
var scan_remaining: float = 0
var aim_elapsed: float = 0
var progress_elapsed: float = 0
var progress_origin: Vector3
var active: bool = true


func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.25
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.2
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 0.6
	add_child(collision)
	visuals = Node3D.new()
	visuals.name = "Visuals"
	add_child(visuals)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 0.35, 0.8) if flying else Vector3(0.8, 0.8, 1)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.8, 1) if flying else Color(0.4, 0.8, 0.5)
	mesh.material = material
	body.mesh = mesh
	body.position.y = 0.6
	visuals.add_child(body)
	var visual_scene := load("res://scenes/characters/visuals/flying_scout_visual.tscn" if flying else "res://scenes/characters/visuals/ground_machine_visual.tscn") as PackedScene
	var adapter := visual_scene.instantiate() as ActorVisual
	adapter.name = "ActorVisual"
	visuals.add_child(adapter)
	health = Health.new()
	health.name = "Health"
	health.maximum = 50 if flying else 80
	add_child(health)
	var tumble := preload("res://scripts/components/death_tumble.gd").new()
	tumble.health = health
	tumble.visuals = visuals
	tumble.body_collision = collision
	add_child(tumble)
	health.died.connect(_on_died)
	agent = NavigationAgent3D.new()
	agent.path_height_offset = 0.5
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.5
	add_child(agent)
	label = Label3D.new()
	label.position.y = 1.5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.pixel_size = 0.005
	add_child(label)
	if not flying:
		var muzzle := Marker3D.new()
		muzzle.position = Vector3(0, 0.7, -0.65)
		visuals.add_child(muzzle)
		weapon = ShotExecutor.new()
		weapon.definition = preload("res://resources/weapons/guard_pulse.tres")
		weapon.muzzle = muzzle
		weapon.shooter = self
		weapon.shot_mask = 3
		weapon.damage_mask = 1
		add_child(weapon)
	arena.setup_actor_visual(self, &"flying_scout" if flying else &"ground_machine", weapon, source_id)
	body.visible = not adapter.production_enabled
	progress_origin = global_position


func get_aim_position() -> Vector3:
	return global_position + Vector3.UP * 0.6


func transition(next: State) -> void:
	if state == State.DEAD or state == next:
		return
	state = next
	aim_elapsed = 0


func sees(actor: Raider) -> bool:
	if not is_instance_valid(actor) or actor.health.current <= 0:
		return false
	var range_limit := 20.0 if flying else 12.0
	if global_position.distance_to(actor.global_position) > range_limit:
		return false
	var query := PhysicsRayQueryParameters3D.create(get_aim_position(), actor.global_position + Vector3.UP, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == actor


func scan() -> void:
	var selected: Raider
	var nearest := INF
	for actor in arena.raiders.values():
		if not is_instance_valid(actor) or not sees(actor):
			continue
		var distance := global_position.distance_squared_to(actor.global_position)
		if distance < nearest:
			nearest = distance
			selected = actor
	if selected != null:
		awareness.observe(source_id, selected.raider_id, selected.global_position, arena.elapsed)
	if flying:
		return
	if selected != null and global_position.distance_to(selected.global_position) <= 10:
		if target != selected:
			aim_elapsed = 0
		target = selected
		transition(State.ENGAGING)
	else:
		target = null
		var reports := awareness.observations(arena.elapsed)
		if reports.is_empty():
			transition(State.PATROLLING)
		else:
			var best := INF
			for report in reports:
				var distance := global_position.distance_squared_to(report.position)
				if distance < best:
					best = distance
					observed_position = report.position
			transition(State.INVESTIGATING)


func _physics_process(delta: float) -> void:
	if not active or state == State.DEAD or route.is_empty():
		return
	scan_remaining -= delta
	if scan_remaining <= 0:
		scan_remaining = 0.25
		scan()
	var destination := observed_position if state == State.INVESTIGATING else route[route_index]
	var direction := Vector3.ZERO
	if state == State.ENGAGING:
		if not is_instance_valid(target) or not sees(target) or global_position.distance_to(target.global_position) > 10:
			aim_elapsed = 0
		else:
			var facing := target.global_position - global_position
			visuals.rotation.y = atan2(-facing.x, -facing.z)
			aim_elapsed += delta
			if aim_elapsed >= 0.5:
				weapon.try_fire_at(target.global_position + Vector3.UP)
	else:
		var arrived := global_position.distance_to(destination) < 0.8
		if arrived and state == State.PATROLLING:
			route_index = (route_index + 1) % route.size()
		elif not arrived:
			if flying:
				direction = (destination - global_position).normalized()
			elif NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0 and NavigationServer3D.map_get_closest_point_owner(agent.get_navigation_map(), global_position).is_valid():
				if agent.target_position != destination:
					agent.target_position = destination
				if not agent.is_navigation_finished():
					direction = agent.get_next_path_position() - global_position
					direction.y = 0
					direction = direction.normalized()
			progress_elapsed += delta
			if progress_elapsed >= 1.5:
				if global_position.distance_to(progress_origin) < 0.2:
					transition(State.PATROLLING)
					route_index = (route_index + 1) % route.size()
					agent.target_position = route[route_index]
				progress_elapsed = 0
				progress_origin = global_position
	velocity.x = direction.x * 2.5
	velocity.z = direction.z * 2.5
	if flying:
		velocity.y = direction.y * 2.5
	elif not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	move_and_slide()
	if state != State.ENGAGING and direction.length_squared() > 0.01:
		visuals.rotation.y = atan2(-direction.x, -direction.z)
	label.text = "%s | %s\nHULL %d" % ["SCOUT" if flying else "GUARD", State.keys()[state], health.current]


func stop() -> void:
	active = false
	set_physics_process(false)
	if weapon != null:
		weapon.enabled = false
		weapon.set_physics_process(false)


func _on_died() -> void:
	transition(State.DEAD)
	stop()
	awareness.forget_source(source_id)
	destroyed.emit(self)
	queue_free()
