class_name HitscanWeapon
extends ShotExecutor
## Player aiming adapter. Shared ShotExecutor owns cadence and physical shot resolution.

@export var input_adapter: RobotInput
@export var camera: Camera3D


func _ready() -> void:
	super._ready()
	assert(input_adapter != null and camera != null)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if input_adapter.fire_intent:
		try_fire()


func try_fire() -> bool:
	var center := camera.get_viewport().get_visible_rect().size * 0.5
	var view_origin := camera.project_ray_origin(center)
	var view_end := view_origin + camera.project_ray_normal(center) * definition.maximum_range
	var aim_hit := cast_ray(view_origin, view_end)
	var aim_point: Vector3 = aim_hit.get("position", view_end)
	return try_fire_at(aim_point)
