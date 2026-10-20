extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func create_arena(scene: String = "social_cooperation_arena") -> Node3D:
	var arena := load("res://scenes/levels/" + scene + ".tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.position = Vector3(100, 0.1, 100)
	if arena.flare_director != null:
		arena.flare_director.set_physics_process(false)
	await frames(10)
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.combat.weapon.set_physics_process(false)
	return arena


func wall(arena: Node3D, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = position
	arena.add_child(body)
	return body


func ready_collection(actor: Raider, drop: MaterialDrop) -> void:
	actor.salvage = drop
	actor.transition(Raider.State.SCAVENGING)
	actor.task_elapsed = actor.scavenge_seconds


func run() -> void:
	var arena: Node3D = await create_arena()
	var a := arena.raiders[1] as Raider
	var b := arena.raiders[2] as Raider
	var c := arena.raiders[3] as Raider
	check(a.social != null and b.social != null and arena.flare_director == null, "Cooperation is opt-in and owns separate per-Raider observations")
	a.position = Vector3(0, 0.1, 14)
	b.position = Vector3(4, 0.1, 8)
	c.position = Vector3(0, 0.1, 6)
	var blocker := wall(arena, Vector3(0, 1.5, 10), Vector3(3, 3, 0.4))
	await frames(3)
	b.decide()
	check(b.threat_visible and b.current_target() == c and not a.detects_actor(c), "Source sees rival while physical cover hides it from ally")
	a.decide()
	check(a.state == Raider.State.INVESTIGATING and not a.threat_visible and a.threat_source == "ally report", "Ally independently investigates report without gaining visual targeting")
	a.task_elapsed = 0.7
	b.decide()
	a.decide()
	check(a.state == Raider.State.INVESTIGATING and is_equal_approx(a.task_elapsed, 0.7), "Repeated stationary reports preserve the active investigation timer")
	var observation := a.social.best_report()
	check(not observation.is_empty() and observation.position.is_equal_approx(c.position), "Report carries the actual last-known snapshot")
	check(c.social.reports.is_empty() and b.social.reports.is_empty(), "Reports do not leak to hostile actors or relay through an unseen ally")
	check(not a.social.receive(b, c, Vector3.INF, 3), "Non-finite observations cannot enter memory")
	var copied: Vector3 = observation.position
	observation.position = Vector3.ZERO
	c.position = Vector3(-1, 0.1, 6)
	await frames(3)
	check(a.social.best_report().position == copied, "Unseen target movement and detached diagnostic mutation cannot change snapshot")
	a.position = Vector3(-20, 0.1, 14)
	a.social.reports.clear()
	b.decide()
	check(a.social.reports.is_empty(), "Communication radius rejects out-of-range ally")
	a.position = Vector3(0, 0.1, 14)
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.NEUTRAL, "neutral receiver", 0)
	b.decide()
	check(a.social.reports.is_empty(), "Neutral competitor receives no allied report")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.ALLIED, "alliance restored", 0)
	b.decide()
	a.transition(Raider.State.FLEEING)
	a.decide()
	check(a.state in [Raider.State.FLEEING, Raider.State.EXTRACTING], "Report cannot override an active retreat")
	a.transition(Raider.State.SELECTING)
	a.threat_remaining = 0
	a.decide()
	arena.elapsed += 3.1
	a.threat_remaining = 0
	a.decide()
	check(a.social.best_report().is_empty() and a.state != Raider.State.INVESTIGATING, "Expiry clears observations and releases reported investigation")
	blocker.queue_free()
	await frames(3)
	c.position = Vector3(0, 0.1, 8)
	check(arena.ledger.collect(3, &"Salvage", 3) == 3, "Finite original stock is loaded before ordinary rival death")
	c.health.apply_damage(1000)
	await frames(3)
	var drop := arena.drops.values()[0] as MaterialDrop
	a.position = Vector3(0, 0.1, 12)
	b.position = Vector3(3, 0.1, 12)
	a.transition(Raider.State.SELECTING)
	a.threat_remaining = 0
	a.social.reports.clear()
	a.combat.retreat_remaining = 0
	a.profile = a.profile.duplicate()
	a.profile.cargo_target = 2
	await frames(3)
	a.decide()
	b.social.sense()
	check(a.social.knows_drop(drop) and a.salvage == drop and a.state == Raider.State.SCAVENGING, "Visible death cargo becomes a scored salvage objective")
	blocker = wall(arena, Vector3(0, 1.5, 10), Vector3(3, 3, 0.4))
	await frames(3)
	arena.elapsed += 3.1
	a.social.sense()
	check(not a.social.knows_drop(drop), "Unseen loot memory expires rather than exposing global drop locations")
	blocker.queue_free()
	await frames(3)
	a.social.sense()
	check(a.social.knows_drop(drop), "Fresh visible observation rediscovers the same finite drop")
	ready_collection(a, drop)
	var transfers: int = arena.ledger.accepted_transfers
	arena._on_collection_requested(a)
	check(arena.ledger.accepted_transfers == transfers, "Distant cargo collection is rejected despite remembered identity")
	var forged := load("res://scenes/loot/material_drop.tscn").instantiate() as MaterialDrop
	forged.ledger = arena.ledger
	forged.drop_id = drop.drop_id
	forged.position = a.position
	arena.add_child(forged)
	ready_collection(a, forged)
	arena._on_collection_requested(a)
	check(arena.ledger.accepted_transfers == transfers, "Unregistered lookalike view cannot transfer a real drop allocation")
	forged.queue_free()
	ready_collection(a, drop)
	blocker = wall(arena, Vector3(0, 1, 8.4), Vector3(2, 2, 0.06))
	a.position = Vector3(0, 0.1, 8.78)
	await frames(3)
	arena._on_collection_requested(a)
	check(arena.ledger.accepted_transfers == transfers and not a.social.sees_drop(drop), "Close scavenging cannot reach through cover")
	blocker.queue_free()
	await frames(3)
	a.social.sense()
	ready_collection(a, drop)
	arena._on_collection_requested(a)
	check(arena.ledger.cargo_for(1) == 2 and drop.materials == 1 and arena.ledger.is_conserved(), "Capacity-limited recovery transfers two units and leaves one real unit")
	arena._on_collection_requested(a)
	check(drop.materials == 1 and arena.ledger.cargo_for(1) == 2, "Duplicate completed collection cannot exceed capacity")
	a.position = Vector3(-5, 0.1, 12)
	b.position = Vector3(3, 0.1, 8)
	arena.robot.position = Vector3(0, 0.1, 9)
	await frames(3)
	check(arena.try_recover(), "Player can recover the remaining contested unit normally")
	b.position = Vector3(0.6, 0.1, 8)
	ready_collection(b, drop)
	arena._on_collection_requested(b)
	check(arena.ledger.cargo_for(2) == 0 and arena.ledger.recovered_materials == 1, "Late Raider request cannot duplicate the player-consumed stack")
	await frames(3)
	check(a.social.known_drops().is_empty(), "Consumed drop identity clears from local loot memory")
	a.health.apply_damage(1000)
	await frames(3)
	drop = arena.drops.values()[0]
	b.position = drop.position + Vector3(0.6, 0.1, 0)
	arena.robot.position = Vector3(100, 0.1, 100)
	await frames(3)
	b.social.sense()
	ready_collection(b, drop)
	arena._on_collection_requested(b)
	check(arena.ledger.cargo_for(2) == 2 and arena.ledger.lost_materials == 0, "Re-looted cargo remains carried and is not yet extraction loss")
	b._choose_exit()
	b.position = b.extraction.position + Vector3.UP * 0.1
	b.transition(Raider.State.EXTRACTING)
	b.extraction_seconds = 0.1
	b.threat_remaining = 0
	b.combat.retreat_remaining = 0
	b.set_physics_process(true)
	await frames(20)
	check(arena.ledger.lost_materials == 2 and arena.ledger.recovered_materials == 1 and arena.ledger.is_conserved(), "Only completed physical extraction records the re-looted two units as lost")
	arena.queue_free()
	await frames(5)
	# Natural travel, full scavenging dwell and travel to exit, with no forced state.
	arena = await create_arena()
	a = arena.raiders[1]
	b = arena.raiders[2]
	c = arena.raiders[3]
	a.position = Vector3(0, 0.1, 14)
	b.position = Vector3(18, 0.1, -18)
	c.position = Vector3(0, 0.1, 8)
	arena.ledger.collect(3, &"Salvage", 3)
	c.health.apply_damage(1000)
	a.profile = a.profile.duplicate()
	a.profile.cargo_target = 3
	await frames(3)
	# Hide all other sources from this fixture without changing their quantities.
	a.select_salvage = func(_id: int) -> Node3D:
		var options: Array[Node3D] = a.social.known_drops()
		return options[0] if not options.is_empty() else null
	a.set_physics_process(true)
	var collected := false
	for index in range(1500):
		await frames(1)
		if arena.ledger.cargo_for(1) == 3:
			collected = true
		if not arena.ledger.is_active(1):
			break
	check(collected and arena.ledger.lost_materials == 3 and arena.ledger.is_conserved(), "Natural Raider physically approaches, scavenges and extracts defeated rival cargo")
	arena.queue_free()
	await frames(5)
	arena = await create_arena("social_pressure_arena")
	a = arena.raiders[1]
	b = arena.raiders[2]
	c = arena.raiders[3]
	a.health.apply_damage(1000)
	check(arena.flare_director.tickets.size() == 1 and not arena.flare_director.tickets[0].relations.is_empty(), "Social flare captures explicit responder attitude policy")
	await frames(3)
	arena.elapsed = 8
	arena.flare_director.process_responses()
	var responder := arena.raiders.get(4) as Raider
	check(is_instance_valid(responder) and responder.social != null and responder.squad_id.is_empty(), "Bounded responder has independent perception without a squad requirement")
	if is_instance_valid(responder):
		responder.set_physics_process(false)
		responder.combat.weapon.set_physics_process(false)
	check(arena.social.relations.attitude(4, 2) == RaiderRelations.Attitude.ALLIED and arena.social.relations.attitude(4, 3) == RaiderRelations.Attitude.HOSTILE, "Responder uses authored ally/rival attitudes rather than inferred membership")
	b.health.apply_damage(1000)
	await frames(3)
	arena.elapsed = 16
	arena.flare_director.process_responses()
	check(arena.raiders.has(5) and arena.social.relations.attitude(4, 5) == RaiderRelations.Attitude.ALLIED, "Second finite responder is explicitly allied to existing responders")
	if is_instance_valid(responder):
		responder.health.apply_damage(1000)
	check(arena.flare_director.committed == 2 and arena.flare_director.tickets.is_empty() and arena.ledger.total_materials == 9 and arena.ledger.is_conserved(), "Responder death cannot replenish the budget or create material stock")
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(arena.mission.is_finished() and arena.flare_director.equipment.is_valid(), "Deadline seals social pressure with equipment ownership intact")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	check(arena.social.rules.cooperation_enabled and arena.ledger.total_materials == 9 and arena.flare_director.committed == 0, "Restart rebuilds cooperation, finite materials and response budget")
	arena.queue_free()
	await frames(30)
	print("Stage L social cooperation checks complete; failures: ", failures)
	quit(1 if failures else 0)
