class_name ActorDamageFeedback
extends Node
## Health observer; owns mesh overlays and bounded machine sound/smoke only.

var actor: Node3D
var world: MissionPresentation
var kind: StringName
var health: Health
var loop: AudioStreamPlayer3D
var flash_remaining: float = 0
var dead: bool = false
var meshes: Array[MeshInstance3D] = []
var overlays: Array[Material] = []
var flash := StandardMaterial3D.new()
var smoke: CPUParticles3D

func configure(source: Node3D, owner_world: MissionPresentation, actor_kind: StringName) -> void:
	actor = source
	world = owner_world
	kind = actor_kind
	health = actor.get_node("Health") as Health
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.albedo_color = Color(0.9, 0.72, 0.4)
	if kind != &"raider":
		for node in actor.get_node("Visuals").find_children("*", "MeshInstance3D", true, false):
			meshes.append(node)
			overlays.append(node.material_overlay)
		loop = AudioStreamPlayer3D.new()
		loop.bus = &"Machines"
		loop.volume_db = -30
		loop.max_distance = 26
		loop.unit_size = 3
		add_child(loop)
		if world.add_loop(loop):
			loop.stream = FeedbackProfile.sound("machines/" + ({&"player": "player_servo_loop", &"ground_machine": "guard_drive_loop", &"flying_scout": "scout_rotor_loop"}[kind]))
		smoke = preload("res://scenes/effects/industrial_ambient.tscn").instantiate() as CPUParticles3D
		smoke.amount = 8
		smoke.position.y = 1
		smoke.emitting = false
		actor.add_child(smoke)

func _on_damaged(_amount: float) -> void:
	if not world.enabled: return
	flash_remaining = 0.12
	for mesh in meshes: mesh.material_overlay = flash
	world.play_spatial("actors/" + ("raider_hurt" if kind == &"raider" else ("player_hurt" if kind == &"player" else "machine_hurt")), actor.global_position, &"Impacts", -20)

func _on_died() -> void:
	if dead: return
	dead = true
	if loop != null:
		loop.stop()
		loop.stream = null
	if is_instance_valid(smoke): smoke.emitting = false
	world.destruction(actor.global_position, kind)

func _process(delta: float) -> void:
	flash_remaining = maxf(0, flash_remaining - delta)
	if flash_remaining <= 0:
		for index in range(meshes.size()): meshes[index].material_overlay = overlays[index]
	if loop == null: return
	var live: bool = not dead and world.enabled and world.accepting and (world.arena == null or world.arena.deployment_started)
	var body := actor as CharacterBody3D
	var speed := body.get_real_velocity().length() if body != null else 0.0
	if live and loop.stream != null:
		loop.volume_db = -32 + minf(speed, 5) * 0.7
		loop.pitch_scale = 0.85 + minf(speed, 5) * 0.07
		if not loop.playing: loop.play()
	elif loop.playing: loop.stop()
	if smoke != null: smoke.emitting = live and health.current > 0 and health.current <= health.maximum * 0.3

func _exit_tree() -> void:
	if loop != null:
		loop.stop()
		loop.stream = null
