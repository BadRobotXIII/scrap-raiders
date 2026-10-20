class_name ShotExecutor
extends Node
## Shared authority for cooldown, physical shot obstruction, and weapon damage.

signal fired(origin: Vector3, endpoint: Vector3, damaged_target: bool)
@export var definition: WeaponDefinition
@export var muzzle: Marker3D
@export var shooter: CharacterBody3D
@export_flags_3d_physics var shot_mask: int = 1
@export_flags_3d_physics var damage_mask: int = 3
var cooldown: float = 0.0
var enabled: bool = true
var can_damage_target: Callable


func _ready() -> void:
	process_physics_priority = 10
	assert(definition != null and muzzle != null and shooter != null)


func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)


func cast_ray(origin: Vector3, endpoint: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, shot_mask, [shooter.get_rid()])
	query.hit_from_inside = true
	return shooter.get_world_3d().direct_space_state.intersect_ray(query)


func try_fire_at(aim_point: Vector3) -> bool:
	var health := shooter.get_node_or_null("Health") as Health
	if not enabled or cooldown > 0.00001 or (health != null and health.current <= 0):
		return false
	cooldown = definition.shot_interval
	var origin := muzzle.global_position
	var to_aim := aim_point - origin
	# Extend past the selected surface to avoid curved-collider rounding misses.
	var endpoint := origin + to_aim.normalized() * minf(to_aim.length() + 0.05, definition.maximum_range)
	var hit := cast_ray(origin, endpoint)
	var damaged_target := false
	if not hit.is_empty():
		endpoint = hit.position
		var target_health := (hit.collider as Node).get_node_or_null("Health") as Health
		if target_health != null and (hit.collider as CollisionObject3D).collision_layer & damage_mask and (not can_damage_target.is_valid() or can_damage_target.call(hit.collider)):
			damaged_target = target_health.apply_damage(definition.damage, origin, shooter.get_instance_id())
	fired.emit(origin, endpoint, damaged_target)
	return true
