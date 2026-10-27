extends Control
## Player-only reticle and authoritative-damage hit confirmation.

@export var weapon: HitscanWeapon
var hit_remaining: float = 0.0


func _ready() -> void:
	weapon.fired.connect(_on_fired)

func _process(delta: float) -> void:
	hit_remaining = maxf(0.0, hit_remaining - delta)
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


func _on_fired(_origin: Vector3, _endpoint: Vector3, damaged_target: bool) -> void:
	if damaged_target:
		hit_remaining = 0.12
		var world := MissionPresentation.find_world(self)
		if world != null: world.play_interface("hit_confirm")
