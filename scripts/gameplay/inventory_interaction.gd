class_name InventoryInteraction
extends Node
## Shared physical access boundary for player and Raider requests. Never owns items.
var arena: Node3D
var ledger: InventoryLedger
var searching: WorldLoot
var search_elapsed: float = 0
var search_origin: Vector3
var opened: WorldLoot
var command_serial: int = 0

func setup() -> void:
	ledger = arena.ledger.inventory
	process_physics_priority = 25
	arena.robot.get_node("Health").damaged.connect(func(_amount: float) -> void:
		cancel()
		if arena.interaction_mode != null: arena.interaction_mode.close_inventory())

func next_command() -> String:
	command_serial += 1
	return "%s/ui/%d" % [ledger.identity_prefix, command_serial]

func registered(source: MaterialDrop) -> bool:
	return is_instance_valid(source) and not source.is_queued_for_deletion() and arena.drops.get(source.drop_id) == source and source.ledger == arena.ledger and source.content_count() > 0

func physical_access(actor: Node3D, source: MaterialDrop, distance: float) -> bool:
	if not registered(source) or not is_instance_valid(actor) or actor.get_node("Health").current <= 0 or actor.global_position.distance_to(source.global_position) >= distance: return false
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, source.global_position + Vector3.UP * 0.3, 1, [actor.get_rid()] if actor is CollisionObject3D else [])
	query.hit_from_inside = true
	return arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func player_access(source: MaterialDrop) -> bool:
	return arena.deployment_started and not arena.mission.is_finished() and not ledger.player_settled and not (arena.spectator != null and arena.spectator.active) and physical_access(arena.robot, source, arena.pickup_distance)

func selected() -> WorldLoot:
	var best: WorldLoot
	var nearest := INF
	for source in arena.drops.values():
		if not source is WorldLoot or not player_access(source): continue
		var distance: float = arena.robot.global_position.distance_squared_to(source.global_position)
		if distance < nearest or (is_equal_approx(distance, nearest) and (best == null or source.drop_id < best.drop_id)):
			best = source
			nearest = distance
	return best

func cancel() -> void:
	searching = null
	search_elapsed = 0
	opened = null

func take(source: WorldLoot, id: String, amount: int, fitting: bool, command: String, expected_source: int, expected_player: int) -> Dictionary:
	var item := ledger.record(id)
	if opened != source or not player_access(source) or item.get("container") != source.container_id:
		return {"ok": false, "reason": "Source access ended; approach and search again."}
	var before: int = arena.ledger.recovered_materials
	var result := ledger.transfer(id, amount, "player", fitting, command, expected_source, expected_player)
	if result.ok:
		var definition := ledger.catalog.find(StringName(item.definition))
		if definition.material_units > 0:
			arena.ledger._notify(&"recover", {"drop": source.drop_id, "amount": arena.ledger.recovered_materials - before})
		else:
			arena.flare_director.equipment._notify(&"recover", {"count": int(result.amount) if item.cohort == "world" else 0, "value": int(result.amount) * definition.base_value if item.cohort == "world" else 0})
		arena.after_event()
	return result

func collect(actor: Raider, source: MaterialDrop) -> int:
	if arena.mission.is_world_finished() or arena.raiders.get(actor.raider_id) != actor or not arena.ledger.is_active(actor.raider_id) or actor.state != Raider.State.SCAVENGING or actor.task_elapsed < actor.scavenge_seconds or not physical_access(actor, source, 0.8): return 0
	if actor.social != null and (not actor.social.knows_drop(source) or not actor.social.sees_drop(source)): return 0
	var destination := "actor:%d" % actor.raider_id
	var materials_before := ledger.quantity(destination, true, "world")
	var count := ledger.move_contents(source.inventory_container(), destination)
	if count > 0:
		arena.ledger._notify(&"collect_ground", {"actor": actor.raider_id, "drop": source.drop_id, "amount": ledger.quantity(destination, true, "world") - materials_before, "items": count})
	return count

func put(source: WorldLoot, id: String, amount: int, command: String, expected_source: int, expected_player: int) -> Dictionary:
	if opened != source or not player_access(source) or ledger.record(id).get("container") != "player": return {"ok": false, "reason": "Source access ended or selected cargo changed."}
	return ledger.transfer(id, amount, source.container_id, false, command, expected_player, expected_source)

func drop(id: String, amount: int, command: String) -> Dictionary:
	if arena.mission.is_finished() or not arena.deployment_started or arena.robot.get_node("Health").current <= 0 or (arena.spectator != null and arena.spectator.active): return {"ok": false, "reason": "Drop is unavailable."}
	var count := 0
	for source in arena.drops.values():
		if source is WorldLoot and source.voluntary: count += 1
	if count >= 52: return {"ok": false, "reason": "Too many loose bundles nearby; recover one before dropping more."}
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	var point := NavigationServer3D.map_get_closest_point(map, arena.robot.global_position)
	if point.distance_to(arena.robot.global_position) > 1.2: return {"ok": false, "reason": "Move onto an accessible floor before dropping."}
	var query := PhysicsRayQueryParameters3D.create(arena.robot.global_position + Vector3.UP, point + Vector3.UP * 0.3, 1)
	query.hit_from_inside = true
	if not arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return {"ok": false, "reason": "Drop location is obstructed."}
	var result := ledger.drop_player(id, amount, command)
	if result.ok:
		var view: WorldLoot = arena.present_drop(result.drop, point)
		view.voluntary = true
		view.title = "Dropped cargo"
		view.access_seconds = 0 if ledger.quantity(view.container_id, true) == ledger.quantity(view.container_id) else 1.5
	return result

func _physics_process(delta: float) -> void:
	if not arena.deployment_started or arena.mission.is_finished(): return
	if opened != null and not player_access(opened):
		arena.interaction_mode.close_inventory()
		cancel()
	if arena.interaction_mode != null and arena.interaction_mode.current == PlayerInteractionMode.Mode.INVENTORY: return
	var source := selected()
	var input: RobotInput = arena.robot.input_adapter
	if source == null or not input.recover_held or input.fire_intent or not input.move_intent.is_zero_approx() or Vector2(arena.robot.velocity.x, arena.robot.velocity.z).length() > 0.1:
		searching = null
		search_elapsed = 0
	elif searching != source:
		searching = source
		search_elapsed = 0
		search_origin = arena.robot.global_position
	elif arena.robot.global_position.distance_to(search_origin) > 0.25:
		cancel()
	else:
		search_elapsed += delta
		if search_elapsed >= source.access_seconds:
			arena.interaction_mode.open_inventory(source)
			opened = source
			searching = null
			search_elapsed = 0
	if source != null:
		arena.get_node("Overlay/PickupPrompt").show()
		arena.get_node("Overlay/PickupPrompt").text = "Hold [E] Search %s %.1fs | [I] Inventory" % [source.title, maxf(0, source.access_seconds - search_elapsed)]
	# Empty views have no authority; deleting one cannot discard contents.
	for source_view in arena.drops.values():
		if source_view is WorldLoot and source_view.content_count() == 0 and source_view.drop_id > 0:
			arena.drops.erase(source_view.drop_id)
			source_view.queue_free()
