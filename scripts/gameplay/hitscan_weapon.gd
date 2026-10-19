class_name HitscanWeapon
extends Node
## Owns cadence and shot resolution. Camera selects aim; muzzle ray prevents cover bypass.

signal fired(origin: Vector3, endpoint: Vector3, damaged_target: bool)

@export var definition: WeaponDefinition
@export var input_adapter: RobotInput
@export var camera: Camera3D
@export var muzzle: Marker3D
@export var shooter: CharacterBody3D
var cooldown: float = 0.0


func _ready() -> void:
	process_physics_priority = 10
	assert(definition != null and input_adapter != null and camera != null)
	assert(muzzle != null and shooter != null)


func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if input_adapter.fire_intent:
		try_fire()


func cast_ray(origin: Vector3, endpoint: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, 1, [shooter.get_rid()])
	query.hit_from_inside = true
	return shooter.get_world_3d().direct_space_state.intersect_ray(query)


func try_fire() -> bool:
	if cooldown > 0.00001:
		return false
	cooldown = definition.shot_interval
	var center := camera.get_viewport().get_visible_rect().size * 0.5
	var view_origin := camera.project_ray_origin(center)
	var view_end := view_origin + camera.project_ray_normal(center) * definition.maximum_range
	var aim_hit := cast_ray(view_origin, view_end)
	var aim_point: Vector3 = aim_hit.get("position", view_end)
	var origin := muzzle.global_position
	# Cast slightly beyond the camera hit surface. Ending exactly on a curved
	# collider can miss through floating-point rounding in the muzzle query.
	var to_aim := aim_point - origin
	var endpoint := origin + to_aim.normalized() * minf(to_aim.length() + 0.05, definition.maximum_range)
	var hit := cast_ray(origin, endpoint)
	var damaged_target := false
	if not hit.is_empty():
		endpoint = hit.position
		var collider := hit.collider as Node
		var health := collider.get_node_or_null("Health") as Health
		if health != null:
			damaged_target = health.apply_damage(definition.damage)
	fired.emit(origin, endpoint, damaged_target)
	return true
