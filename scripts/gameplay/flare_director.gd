class_name FlareDirector
extends Node
## Mission-local bounded responses and recovery. Does not own AI or material quantities.

const FLARE := preload("res://scripts/presentation/death_flare.gd")
var arena: Node3D
var rules: FlareConfig
var equipment := EquipmentLedger.new()
var equipment_drops: Dictionary[int, EquipmentDrop] = {}
var responder_ids: Dictionary[int, bool] = {}
var handled_deaths: Dictionary[int, bool] = {}
var local_jobs: Array[Dictionary] = []
var tickets: Array[Dictionary] = []
var committed: int = 0
var next_id: int
var recovering_id: int = 0
var recovery_elapsed: float = 0
var recovery_origin: Vector3
var retry: float = 0
var damage_serial: int = 0
var recovery_serial: int = 0


func setup() -> void:
	process_physics_priority = 30
	next_id = arena.raider_count + 1
	arena.robot.get_node("Health").damaged.connect(func(_amount: float) -> void:
		damage_serial += 1
		cancel_recovery())


func register_actor(actor: Raider) -> void:
	equipment.assign_loadout(actor.raider_id, responder_ids.has(actor.raider_id))


func accepted_death(actor: Raider) -> void:
	if arena.mission.is_world_finished() or handled_deaths.has(actor.raider_id) or not equipment.resolve(actor.raider_id):
		return
	handled_deaths[actor.raider_id] = true
	var position := actor.global_position
	var drop := EquipmentDrop.new()
	drop.ledger = equipment
	drop.owner_id = actor.raider_id
	drop.position = arena.to_local(position)
	equipment_drops[actor.raider_id] = drop
	arena.add_child(drop)
	var flare := FLARE.new() as Node3D
	flare.position = arena.to_local(position)
	arena.add_child(flare)
	for other in arena.raiders.values():
		if is_instance_valid(other) and other != actor and arena.ledger.is_active(other.raider_id) and other.global_position.distance_to(position) <= rules.alert_radius:
			local_jobs.append({"id": other.raider_id, "position": position, "due": arena.elapsed + rules.local_delay})
	if committed < rules.reinforcement_budget:
		committed += 1
		tickets.append({"id": next_id, "position": position, "due": arena.elapsed + maxf(rules.local_delay + 0.1, rules.reinforcement_delay), "relations": arena.social.responder_relations() if arena.social != null else []})
		next_id += 1
	arena.status.text = "Death flare! Hold E to loot equipment; reinforcements may follow."


func process_responses() -> void:
	if arena.mission.is_world_finished():
		return
	for job in local_jobs.duplicate():
		if arena.elapsed < job.due:
			continue
		var actor = arena.raiders.get(int(job.id))
		if is_instance_valid(actor) and arena.ledger.is_active(actor.raider_id):
			actor.investigate_flare(job.position)
		local_jobs.erase(job)
	for ticket in tickets.duplicate():
		if arena.elapsed < ticket.due or living_count() >= rules.active_cap:
			continue
		for offset in range(arena.spawn_order.size()):
			var marker: Node3D = arena.spawn_order[(int(ticket.id) - 1 + offset) % arena.spawn_order.size()]
			if not arena.entry_is_valid(marker.global_position):
				continue
			if not reaches_flare(marker.global_position, ticket.position):
				continue
			if not arena.ledger.register_raider(ticket.id):
				break
			responder_ids[ticket.id] = true
			var actor: Raider = arena.spawn_raider(ticket.id, marker.global_position)
			if arena.social != null:
				arena.social.initialize_responder(ticket.id, ticket.relations)
			actor.investigate_flare(ticket.position)
			tickets.erase(ticket)
			break


func reaches_flare(origin: Vector3, position: Vector3) -> bool:
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	var closest := NavigationServer3D.map_get_closest_point(map, position)
	var path := NavigationServer3D.map_get_path(map, origin, closest, true)
	return closest.distance_to(position) <= 1 and not path.is_empty() and path[path.size() - 1].distance_to(closest) <= 0.8


func living_count() -> int:
	var count := 0
	for actor in arena.raiders.values():
		if is_instance_valid(actor) and arena.ledger.is_active(actor.raider_id):
			count += 1
	return count


func eligible(drop: EquipmentDrop) -> bool:
	if arena.mission.is_finished() or not is_instance_valid(drop) or drop.is_queued_for_deletion():
		return false
	if equipment_drops.get(drop.owner_id) != drop or equipment.ground_count(drop.owner_id) <= 0:
		return false
	if arena.robot.global_position.distance_to(drop.global_position) > arena.pickup_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(arena.robot.global_position + Vector3.UP, drop.global_position + Vector3.UP * 0.3, 1)
	query.hit_from_inside = true
	return arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func selected_drop() -> EquipmentDrop:
	var selected: EquipmentDrop
	var distance := INF
	for drop in equipment_drops.values():
		if not eligible(drop):
			continue
		var candidate: float = arena.robot.global_position.distance_squared_to(drop.global_position)
		if candidate < distance - 0.000001 or (absf(candidate - distance) <= 0.000001 and (selected == null or drop.owner_id < selected.owner_id)):
			selected = drop
			distance = candidate
	return selected


func cancel_recovery() -> void:
	recovering_id = 0
	recovery_elapsed = 0


func update_recovery(delta: float) -> void:
	var selected := selected_drop()
	var input: RobotInput = arena.robot.input_adapter
	if selected == null or arena.selected_drop() != null or not input.recover_held or input.fire_intent or not input.move_intent.is_zero_approx():
		cancel_recovery()
	elif recovering_id != selected.owner_id:
		recovering_id = selected.owner_id
		recovery_origin = arena.robot.global_position
		recovery_serial = damage_serial
		recovery_elapsed = 0
	elif arena.robot.global_position.distance_to(recovery_origin) > 0.25 or recovery_serial != damage_serial:
		cancel_recovery()
	else:
		recovery_elapsed += delta
		if recovery_elapsed >= rules.recovery_time and eligible(selected) and equipment.recover(selected.owner_id):
			equipment_drops.erase(selected.owner_id)
			selected.queue_free()
			cancel_recovery()
			arena.after_event()
			selected = null
	for drop in equipment_drops.values():
		drop.set_available(drop == selected and arena.selected_drop() == null, maxf(0, rules.recovery_time - recovery_elapsed))
	if selected != null and arena.selected_drop() == null:
		arena.get_node("Overlay/PickupPrompt").show()
		arena.get_node("Overlay/PickupPrompt").text = "Hold [E] recover equipment %.1fs" % maxf(0, rules.recovery_time - recovery_elapsed)


func _physics_process(delta: float) -> void:
	if arena.mission.is_world_finished():
		return
	retry -= delta
	if retry <= 0:
		retry = 0.5
		process_responses()
	update_recovery(delta)


func stop() -> void:
	set_physics_process(false)
	cancel_recovery()
	equipment.seal()
	for drop in equipment_drops.values():
		drop.set_available(false)
