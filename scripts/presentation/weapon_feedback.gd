class_name WeaponFeedback
extends Node
## Exactly one discharge adapter per executor. ActorVisual alone owns recoil.

var weapon: ShotExecutor
var world: MissionPresentation
var profile: FeedbackProfile
var flash: Node3D
var light: OmniLight3D
var audio: AudioStreamPlayer3D
var remaining: float = 0
var random := RandomNumberGenerator.new()
var presented: int = 0

func configure(source: ShotExecutor, owner_world: MissionPresentation, kind: StringName, seed_value: int) -> void:
	stop()
	if is_instance_valid(weapon):
		if weapon.fired.is_connected(_on_fired): weapon.fired.disconnect(_on_fired)
		if weapon.impact_resolved.is_connected(_on_impact): weapon.impact_resolved.disconnect(_on_impact)
	if is_instance_valid(flash): flash.queue_free()
	if is_instance_valid(audio): audio.queue_free()
	weapon = source
	world = owner_world
	_prepare(weapon.muzzle, kind, seed_value)
	weapon.fired.connect(_on_fired)
	weapon.impact_resolved.connect(_on_impact)

func configure_preview(muzzle: Node3D, owner_world: MissionPresentation, kind: StringName, seed_value: int) -> void:
	world = owner_world
	_prepare(muzzle, kind, seed_value)

func _prepare(muzzle: Node3D, kind: StringName, seed_value: int) -> void:
	profile = load("res://resources/presentation/" + ("guard" if kind == &"ground_machine" else String(kind)) + "_discharge.tres") as FeedbackProfile
	random.seed = seed_value
	flash = preload("res://scenes/effects/weapon_discharge.tscn").instantiate() as Node3D
	muzzle.add_child(flash)
	flash.hide()
	for node in flash.get_children():
		if node is MeshInstance3D:
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = profile.color
			node.material_override = material
	light = flash.get_node("Light") as OmniLight3D
	light.light_color = profile.color
	light.light_energy = profile.light_energy
	audio = AudioStreamPlayer3D.new()
	audio.bus = &"Weapons"
	audio.max_polyphony = 1
	audio.volume_db = profile.volume_db
	audio.max_distance = 42
	audio.unit_size = 5
	muzzle.add_child(audio)

func _on_fired(origin: Vector3, endpoint: Vector3, _damaged: bool) -> void:
	if not world.enabled or not world.accepting: return
	presented += 1
	world.shots_presented += 1
	remaining = 0.045
	flash.scale = Vector3.ONE * random.randf_range(0.85, 1.1)
	flash.show()
	light.visible = world.acquire_light(light)
	audio.stop()
	audio.stream = FeedbackProfile.sound("weapons/%s_0%d" % [profile.sound_stem, random.randi_range(1, 2)])
	audio.pitch_scale = random.randf_range(0.97, 1.03)
	audio.play()
	# A thin, bounded triangle ribbon reads consistently at oblique angles.
	var tracer := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = profile.color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var side := (endpoint - origin).cross(Vector3.UP).normalized() * 0.013
	if side.is_zero_approx(): side = Vector3.RIGHT * 0.013
	for vertex in [origin + side, origin - side, endpoint - side, origin + side, endpoint - side, endpoint + side]: mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	tracer.mesh = mesh
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.admit_trace(tracer)
	tracer.add_to_group("presentation_tracers")
	world.get_tree().create_timer(profile.trace_seconds).timeout.connect(tracer.queue_free)

func _on_impact(position: Vector3, normal: Vector3, incoming: Vector3, surface: StringName, _damaged: bool) -> void:
	world.impact(position, normal, surface, incoming)

func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	if is_instance_valid(flash) and remaining <= 0:
		flash.hide()
		light.hide()
	if is_instance_valid(audio) and not audio.playing and audio.stream != null: audio.stream = null

func stop() -> void:
	remaining = 0
	if is_instance_valid(flash): flash.hide()
	if is_instance_valid(light): light.hide()
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null

func _exit_tree() -> void:
	stop()
