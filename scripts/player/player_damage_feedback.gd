extends Control
## Health presentation only; simulation/deployment shutdown is owned elsewhere.

@onready var robot: RobotController = get_parent().get_parent()
@onready var health: Health = robot.get_node("Health")
var flash: float = 0.0
var audio: AudioStreamPlayer


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(func() -> void: robot.visuals.hide())
	audio = AudioStreamPlayer.new()
	var sound := AudioStreamWAV.new()
	sound.mix_rate = 22050
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	var samples := PackedByteArray()
	for index in range(2646):
		var envelope := 1.0 - float(index) / 2646.0
		samples.append(int(sin(index * TAU * 160.0 / 22050.0) * 65.0 * envelope) & 255)
	sound.data = samples
	audio.stream = sound
	audio.volume_db = -16
	add_child(audio)


func _on_damaged(_amount: float) -> void:
	flash = 0.45
	audio.play()


func _process(delta: float) -> void:
	flash = maxf(0, flash - delta)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := "ROBOT DESTROYED" if health.current <= 0 else "HULL %d / %d" % [health.current, health.maximum]
	draw_string(font, Vector2(24, size.y - 25), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.4, 0.3) if health.current <= 30 else Color.WHITE)
	if flash <= 0:
		return
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(1, 0.1, 0.05, flash), false, 8)
	if health.last_damage_origin.is_finite():
		var relative := robot.camera_rig.global_basis.inverse() * (health.last_damage_origin - robot.global_position)
		var direction := Vector2(relative.x, relative.z).normalized()
		var center := size * 0.5
		draw_line(center + direction * 65, center + direction * 90, Color(1, 0.15, 0.05, minf(1, flash * 3)), 8)
