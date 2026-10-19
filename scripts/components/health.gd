class_name Health
extends Node
## The only writer of current health. Death is emitted once.

signal damaged(amount: float)
signal died

@export_range(1.0, 10000.0) var maximum: float = 100.0
var current: float = 0.0
var last_damage_origin: Vector3 = Vector3.INF


func _ready() -> void:
	current = maximum


func apply_damage(amount: float, origin: Vector3 = Vector3.INF) -> bool:
	if not is_finite(amount) or amount <= 0.0 or current <= 0.0:
		return false
	var applied := minf(amount, current)
	last_damage_origin = origin
	current -= applied
	damaged.emit(applied)
	if current <= 0.0:
		died.emit()
	return true
