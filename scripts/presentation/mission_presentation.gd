class_name MissionPresentation
extends Node3D
## Mission-local presentation lifetime. Reads events; cannot command simulation.

const MAX_BURSTS := 16
const MAX_PARTICLES := 256
const MAX_LIGHTS := 4
const AUDIO_SLOTS := 12
var enabled: bool = true
var arena: Node3D
var actors: Dictionary[int, WeakRef] = {}
var bursts: Array[EffectBurst] = []
var tracers: Array[MeshInstance3D] = []
var lights: Array[OmniLight3D] = []
var spatial: Array[AudioStreamPlayer3D] = []
var interface_players: Array[AudioStreamPlayer] = []
var listener: AudioListener3D
var serial: int = 0
var shots_presented: int = 0
var impacts_presented: int = 0
var deaths_presented: int = 0
var accepting: bool = true
var audio_cursor: int = 0
var ui_cursor: int = 0
var recovery_serial: int = 0
var equipment_serial: int = 0
var result_presented: bool = false
var objective_states: Dictionary = {}
var loop_players: Array[AudioStreamPlayer3D] = []
var observed_objectives: MissionObjectives

static func find_world(node: Node) -> MissionPresentation:
	var cursor := node
	while cursor != null:
		var candidate := cursor.get_node_or_null("Presentation") as MissionPresentation
		if candidate != null: return candidate
		cursor = cursor.get_parent()
	return null

func _ready() -> void:
	name = "Presentation"
	add_to_group("mission_presentations")
	listener = AudioListener3D.new()
	add_child(listener)
	listener.make_current()
	for index in range(AUDIO_SLOTS):
		var player := AudioStreamPlayer3D.new()
		player.max_polyphony = 1
		player.max_distance = 42
		player.unit_size = 5
		add_child(player)
		spatial.append(player)
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = &"Interface"
		player.max_polyphony = 1
		add_child(player)
		interface_players.append(player)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if is_instance_valid(camera): listener.global_transform = camera.global_transform
	bursts = bursts.filter(func(item) -> bool: return is_instance_valid(item) and not item.is_queued_for_deletion())
	lights = lights.filter(func(item) -> bool: return is_instance_valid(item) and item.visible)
	if arena != null and arena.mission.is_world_finished() and accepting: shutdown()
	for player in spatial:
		if not player.playing and player.stream != null: player.stream = null
	for player in interface_players:
		if not player.playing and player.stream != null: player.stream = null
	if arena != null and not result_presented and arena.mission.is_finished():
		result_presented = true
		play_interface("recall_complete" if arena.mission.player_extracted else "deployment_failed")

func register_actor(actor: Node3D, kind: StringName, weapon: ShotExecutor) -> void:
	var id := actor.get_instance_id()
	if actors.has(id): return
	actors[id] = weakref(actor)
	actor.tree_exiting.connect(func() -> void: actors.erase(id))
	actor.set_meta("feedback_surface", &"raider_gear" if kind == &"raider" else &"machine_armor")
	if weapon != null:
		var feedback := WeaponFeedback.new()
		actor.add_child(feedback)
		feedback.configure(weapon, self, kind, String(actor.get_path()).hash())
	var damage := ActorDamageFeedback.new()
	actor.add_child(damage)
	damage.configure(actor, self, kind)

func bind_accounting(materials: MaterialLedger, equipment: EquipmentLedger = null, objectives: MissionObjectives = null) -> void:
	if not materials.transfer_accepted.is_connected(_on_material): materials.transfer_accepted.connect(_on_material)
	if equipment != null and not equipment.transfer_accepted.is_connected(_on_equipment): equipment.transfer_accepted.connect(_on_equipment)
	if objectives != null and objectives != observed_objectives:
		if is_instance_valid(observed_objectives): observed_objectives.changed.disconnect(_on_objectives.bind(observed_objectives))
		observed_objectives = objectives
		objectives.changed.connect(_on_objectives.bind(objectives))

func _on_material(kind: StringName, details: Dictionary) -> void:
	if int(details.serial) <= recovery_serial: return
	recovery_serial = int(details.serial)
	if kind == &"recover": play_interface("recovered")

func _on_equipment(kind: StringName, details: Dictionary) -> void:
	if int(details.serial) <= equipment_serial: return
	equipment_serial = int(details.serial)
	if kind == &"recover": play_interface("recovered")

func _on_objectives(owner: MissionObjectives) -> void:
	for row in owner.snapshot():
		var key: String = row.description
		if row.status == "completed" and objective_states.get(key, "") != "completed": play_interface("objective_complete")
		objective_states[key] = row.status

func add_loop(player: AudioStreamPlayer3D) -> bool:
	loop_players = loop_players.filter(func(item) -> bool: return is_instance_valid(item))
	if loop_players.size() >= 6: return false
	loop_players.append(player)
	return true

func play_spatial(cue: String, position: Vector3, bus: StringName = &"Impacts", volume: float = -20) -> void:
	if not enabled or not accepting or not position.is_finite(): return
	var player := spatial[audio_cursor % spatial.size()]
	audio_cursor += 1
	player.stop()
	player.stream = FeedbackProfile.sound(cue)
	player.bus = bus
	player.volume_db = volume
	player.global_position = position
	player.play()

func play_interface(cue: String) -> void:
	if not enabled: return
	var player := interface_players[ui_cursor % interface_players.size()]
	ui_cursor += 1
	player.stop()
	player.stream = FeedbackProfile.sound("interface/" + cue)
	player.volume_db = -21
	player.play()

func acquire_light(light: OmniLight3D) -> bool:
	lights = lights.filter(func(item) -> bool: return is_instance_valid(item) and item.visible)
	if lights.has(light): return true
	if lights.size() >= MAX_LIGHTS: return false
	lights.append(light)
	return true

func admit_trace(tracer: MeshInstance3D) -> void:
	tracers = tracers.filter(func(item) -> bool: return is_instance_valid(item) and not item.is_queued_for_deletion())
	if tracers.size() >= 16:
		var oldest: MeshInstance3D = tracers.pop_front()
		oldest.queue_free()
	add_child(tracer)
	tracers.append(tracer)

func impact(position: Vector3, normal: Vector3, surface: StringName, _incoming: Vector3) -> void:
	if not enabled or not accepting or not position.is_finite() or not normal.is_finite() or normal.is_zero_approx(): return
	impacts_presented += 1
	spawn_burst(position + normal * 0.012, normal, FeedbackSurface.color_for(surface), 12, 0.36)
	play_spatial(FeedbackSurface.sound_for(surface), position)

func destruction(position: Vector3, kind: StringName) -> void:
	if not enabled or not accepting: return
	deaths_presented += 1
	spawn_burst(position + Vector3.UP * 0.7, Vector3.UP, Color(0.45, 0.5, 0.54), 12 if kind == &"raider" else 24, 1.6)
	spawn_burst(position + Vector3.UP * 0.7, Vector3.UP, Color(0.7, 0.65, 0.48) if kind == &"raider" else Color(0.7, 0.85, 1.0), 4 if kind == &"raider" else 8, 0.32)
	if kind != &"raider":
		var light := OmniLight3D.new()
		light.omni_range = 3
		light.light_color = Color(1, 0.65, 0.22)
		light.light_energy = 1.8
		light.shadow_enabled = false
		add_child(light)
		light.global_position = position + Vector3.UP
		light.visible = acquire_light(light)
		get_tree().create_timer(0.12).timeout.connect(light.queue_free)
	play_spatial("actors/raider_death" if kind == &"raider" else "actors/machine_destroy", position, &"Impacts", -14)

func spawn_burst(position: Vector3, normal: Vector3, color: Color, count: int, lifetime: float) -> EffectBurst:
	if not enabled or not accepting: return null
	bursts = bursts.filter(func(item) -> bool: return is_instance_valid(item) and not item.is_queued_for_deletion())
	var particles := 0
	for item in bursts: particles += item.count
	while not bursts.is_empty() and (bursts.size() >= MAX_BURSTS or particles + count > MAX_PARTICLES):
		# Prefer expiring optional contact bursts before a terminal smoke cue.
		var expendable := 0
		for index in range(bursts.size()):
			if bursts[index].lifetime < 0.5:
				expendable = index
				break
		var oldest: EffectBurst = bursts[expendable]
		bursts.remove_at(expendable)
		particles -= oldest.count
		oldest.queue_free()
	var burst := (preload("res://scenes/effects/machine_destruction.tscn") if lifetime > 1 else preload("res://scenes/effects/surface_impact.tscn")).instantiate() as EffectBurst
	burst.count = mini(count, MAX_PARTICLES)
	burst.normal = normal
	burst.color = color
	burst.lifetime = lifetime
	serial += 1
	burst.seed_value = serial * 7919 + 87017
	add_child(burst)
	burst.global_position = position
	bursts.append(burst)
	return burst

func snapshot() -> Dictionary:
	var particles := 0
	var count := 0
	for item in bursts:
		if is_instance_valid(item) and not item.is_queued_for_deletion():
			particles += item.count
			count += 1
	var voices := 0
	for player in spatial + interface_players:
		if player.playing: voices += 1
	for player in loop_players:
		if is_instance_valid(player) and player.playing: voices += 1
	for item in actors.values():
		var actor: Node = item.get_ref()
		if is_instance_valid(actor):
			for feedback in actor.get_children():
				if feedback is WeaponFeedback and feedback.audio.playing: voices += 1
	return {"shots": shots_presented, "impacts": impacts_presented, "deaths": deaths_presented, "bursts": count, "particles": particles, "voices": voices, "lights": lights.filter(func(light) -> bool: return is_instance_valid(light) and light.visible).size()}

func shutdown() -> void:
	accepting = false
	for item in bursts:
		if is_instance_valid(item): item.queue_free()
	bursts.clear()
	for tracer in tracers:
		if is_instance_valid(tracer): tracer.queue_free()
	tracers.clear()
	for player in spatial + interface_players + loop_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for item in actors.values():
		var actor: Node = item.get_ref()
		if is_instance_valid(actor):
			for feedback in actor.get_children():
				if feedback is WeaponFeedback: feedback.stop()
	for light in lights:
		if is_instance_valid(light): light.hide()
	lights.clear()

func _exit_tree() -> void:
	shutdown()
	if is_instance_valid(listener): listener.clear_current()
