extends Control
## Presentation only: reticle, tracers, muzzle flash, and synthesized shot/hit audio.

@export var weapon: HitscanWeapon
@export_range(-40.0, 0.0) var shot_volume_db: float = -18.0
@export_range(-40.0, 0.0) var hit_volume_db: float = -22.0
var hit_remaining: float = 0.0
var flash_remaining: float = 0.0
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D
var shot_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer


func _ready() -> void:
	weapon.fired.connect(_on_fired)
	shot_audio = AudioStreamPlayer.new()
	shot_audio.stream = synthesize_sound(false)
	shot_audio.volume_db = shot_volume_db
	shot_audio.max_polyphony = 3
	add_child(shot_audio)
	hit_audio = AudioStreamPlayer.new()
	hit_audio.stream = synthesize_sound(true)
	hit_audio.volume_db = hit_volume_db
	hit_audio.max_polyphony = 3
	add_child(hit_audio)

	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.12
	flash_mesh.height = 0.24
	var flash_material := StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1, 0.85, 0.3)
	flash_mesh.material = flash_material
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.scale = Vector3(1, 0.8, 1.7)
	muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_flash.visible = false
	weapon.muzzle.add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1, 0.7, 0.25)
	muzzle_light.light_energy = 2.0
	muzzle_light.omni_range = 2.5
	muzzle_light.visible = false
	weapon.muzzle.add_child(muzzle_light)


func _process(delta: float) -> void:
	hit_remaining = maxf(0.0, hit_remaining - delta)
	flash_remaining = maxf(0.0, flash_remaining - delta)
	muzzle_flash.visible = flash_remaining > 0.0
	muzzle_light.visible = flash_remaining > 0.0
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 2.0, Color.WHITE)
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		draw_line(center + axis * 5, center + axis * 10, Color.WHITE, 2)
		draw_line(center - axis * 5, center - axis * 10, Color.WHITE, 2)
	if hit_remaining > 0.0:
		for direction in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(center + direction * 12, center + direction * 18, Color(1, 0.7, 0.15), 3)


func _on_fired(origin: Vector3, endpoint: Vector3, damaged_target: bool) -> void:
	shot_audio.play()
	flash_remaining = 0.045
	muzzle_flash.show()
	muzzle_light.show()
	if damaged_target:
		hit_remaining = 0.12
		hit_audio.play()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 0.8, 0.2)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(origin)
	mesh.surface_add_vertex(endpoint)
	mesh.surface_end()
	var tracer := MeshInstance3D.new()
	tracer.mesh = mesh
	get_tree().current_scene.add_child(tracer)
	get_tree().create_timer(0.06).timeout.connect(tracer.queue_free)


func synthesize_sound(is_hit: bool) -> AudioStreamWAV:
	# Original PCM generated once on startup; local RNG cannot affect simulation.
	const SAMPLE_RATE := 22050
	var duration := 0.065 if is_hit else 0.14
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 17
	for index in range(count):
		var time := float(index) / SAMPLE_RATE
		var envelope := pow(1.0 - time / duration, 2.0) * minf(time / 0.002, 1.0)
		var sample: float
		if is_hit:
			sample = sin(TAU * 1100 * time) * 0.7 + sin(TAU * 2200 * time) * 0.2
		else:
			sample = sin(TAU * (240 * time - 600 * time * time)) * 0.6 + noise.randf_range(-0.3, 0.3)
		data.encode_s16(index * 2, int(clampf(sample * envelope, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
