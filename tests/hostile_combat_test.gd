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


func create_arena() -> Node3D:
	var arena := load("res://scenes/levels/mission_arena.tscn").instantiate() as Node3D
	arena.scenario_index = 3
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	return arena


func deploy(arena: Node3D) -> void:
	await frames(8)
	arena.elapsed = 10
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.combat.weapon.set_physics_process(false)
		actor.combat.profile = actor.combat.profile.duplicate()
		actor.combat.profile.spread_degrees = 0


func run() -> void:
	var arena := create_arena()
	await deploy(arena)
	var robot := arena.robot as RobotController
	var hull := robot.get_node("Health") as Health
	var actor := arena.raiders[1] as Raider
	var second := arena.raiders[2] as Raider
	var third := arena.raiders[3] as Raider
	var initial_aim_state: int = actor.combat.random.state
	check(arena.raiders.size() == 3 and actor.combat != null and hull.current == 100, "Survival deploys three armed instances with a healthy player")
	robot.position = Vector3(0, 0.1, 16)
	actor.position = Vector3(0, 0.1, 8)
	second.position = Vector3(-14, 0.1, 10)
	third.position = Vector3(18, 0.1, -18)
	await frames(3)
	actor.decide()
	check(actor.state == Raider.State.ENGAGING, "Visible in-range robot triggers the common FSM engagement state")
	actor.combat.tick(0.6)
	check(hull.current == 100, "Reaction warning prevents immediate damage")
	actor.combat.tick(0.06)
	check(hull.current == 90 and hull.last_damage_origin.is_finite(), "Shared executor applies exactly ten hostile damage with impact origin")
	check(robot.get_node("SurvivalHUD/DamageFeedback").flash > 0, "Player health event drives incoming damage feedback")
	actor.combat.tick(0.2)
	check(hull.current == 90, "Hostile shot cooldown blocks repeated same-window damage")
	actor.combat.weapon._physics_process(0.8)
	actor.combat.tick(0.8)
	check(hull.current == 80, "Hostile cadence permits the next shot after 0.8 seconds")
	robot.position = Vector3(0, 0.1, 40)
	await frames(3)
	actor.combat.weapon.cooldown = 0
	actor.combat.tick(1)
	check(hull.current == 80 and actor.combat.aim_elapsed == 0, "Out-of-range target cancels aiming without firing")
	robot.position = Vector3(-9, 0.1, -5)
	actor.position = Vector3(-5, 0.1, -5)
	await frames(3)
	actor.combat.weapon.try_fire_at(robot.global_position + Vector3.UP)
	check(hull.current == 80, "Physical cover blocks hostile muzzle damage")
	actor.combat.tick(1)
	check(actor.combat.aim_elapsed == 0, "Lost visibility interrupts the firing warning")
	# Protective cover is selected from authored reachable slots with valid peek routes.
	robot.position = Vector3(-15, 0.1, 3)
	actor.position = Vector3(-5, 0.1, 3)
	second.position = Vector3(-5, 0.1, 5)
	await frames(3)
	for raider in [actor, second]:
		raider.last_threat_position = robot.global_position
		raider.threat_remaining = 10
	var cover := arena.reserve_cover(1) as Node3D
	var other_cover := arena.reserve_cover(2) as Node3D
	check(cover != null and other_cover != null and other_cover != cover, "Basic squad coordination assigns distinct validated cover slots")
	arena.release_cover(1)
	arena.release_cover(2)
	actor.health.apply_damage(25)
	check(actor.state == Raider.State.TAKING_COVER and actor.combat.aim_elapsed == 0, "Nonlethal damage interrupts engagement and requests validated cover")
	if actor.combat.cover != null:
		actor.position = actor.combat.cover.position
		actor.task_elapsed = actor.combat.profile.cover_hold
		actor.combat.on_arrived(0)
		check(actor.state == Raider.State.REPOSITIONING, "Cover dwell advances explicitly to the authored peek position")
		actor.position = actor.combat.destination.global_position
		actor.combat.on_arrived(0)
		check(actor.state == Raider.State.ENGAGING and actor.combat.aim_elapsed == 0, "Reposition arrival requires a fresh firing warning")
	else:
		check(false, "Cover fixture must provide a valid protective slot")
	actor.health.apply_damage(50)
	check(actor.state == Raider.State.FLEEING and not arena.cover_reservations.has(1), "Overwhelmed Raider retreats and releases its squad cover slot")
	actor.position = actor.extraction.global_position
	actor.decide()
	check(actor.state == Raider.State.EXTRACTING, "Low-health retreat can enter extraction rather than looping forever")
	# A healthy, empty fighter disengages once an unseen threat memory expires.
	second.transition(Raider.State.ENGAGING)
	second.threat_remaining = 0
	robot.position = Vector3(100, 0, 100)
	await frames(3)
	second.decide()
	check(second.state == Raider.State.SCAVENGING, "Lost threat returns a healthy empty fighter to scavenging")
	# Independent actors share shot execution but retain cooldowns and health.
	robot.position = Vector3(0, 0.1, 16)
	second.position = Vector3(-2, 0.1, 8)
	third.position = Vector3(-4, 0.1, 8)
	await frames(3)
	second.decide()
	third.decide()
	second.combat.tick(0.66)
	third.combat.tick(0.66)
	check(hull.current == 60 and second.health.current == 100 and third.health.current == 100, "Two attackers damage the player independently without sharing cooldowns or health")
	# Mixed material categories survive player destruction without reclassification.
	arena.ledger.collect(2, &"Salvage", 3)
	second.health.apply_damage(100)
	arena.ledger.collect(3, &"Salvage2", 3)
	var protected_before: int = arena.ledger.protected_materials
	var ground_before: int = arena.ledger.dropped_materials
	var carried_before: int = arena.ledger.carried_materials
	var deaths := [0]
	hull.died.connect(func() -> void: deaths[0] += 1)
	await frames(3)
	hull.apply_damage(50, third.global_position)
	third.combat.weapon.cooldown = 0
	check(third.combat.weapon.try_fire_at(robot.global_position + Vector3.UP), "A lethal hostile shot uses the shared physical damage path")
	await frames(3)
	check(deaths[0] == 1 and not hull.apply_damage(10) and hull.current == 0, "Player destruction is emitted once and rejects further damage")
	check(arena.mission.player_destroyed and arena.mission.is_finished() and arena.summary.visible, "Player death produces an explicit failed-deployment outcome")
	check(not robot.is_physics_processing() and not robot.get_node("Weapon").enabled and not third.combat.weapon.enabled, "Death stops player controls and every hostile weapon")
	check(not robot.visuals.visible and get_nodes_in_group("death_tumbles").size() > 0, "Player destruction retains a separate cosmetic tumble")
	check(arena.ledger.protected_materials == protected_before and arena.ledger.dropped_materials == ground_before and arena.ledger.carried_materials == carried_before and arena.ledger.lost_materials == 0 and arena.ledger.is_conserved(), "Player death seals exact material categories without inventing extracted losses")
	check(not third.combat.weapon.try_fire_at(robot.global_position + Vector3.UP) and not robot.get_node("Weapon").try_fire(), "Direct late firing requests are rejected after terminal shutdown")
	check(arena.ledger.collect(1, &"Salvage3", 3) == 0, "Destroyed deployment rejects late material transfers")
	arena.restart_mission()
	await frames(8)
	arena = current_scene
	arena.set_physics_process(false)
	check(arena.scenario_index == 3 and arena.robot.get_node("Health").current == 100 and not arena.mission.player_destroyed and arena.ledger.is_conserved(), "Restart preserves Survival selection and resets health, outcomes, and ledger")
	check(arena.raiders[1].combat.random.state == initial_aim_state, "Restart restores the actual per-actor seeded aim stream")
	arena.queue_free()
	await frames(3)
	# Exercise firing through real physics scheduling and AI decisions.
	arena = create_arena()
	await deploy(arena)
	actor = arena.raiders[1]
	arena.robot.position = Vector3(0, 0.1, 16)
	actor.position = Vector3(0, 0.1, 8)
	for id in [2, 3]:
		arena.raiders[id].position = Vector3(20, 0.1, -18 + id)
	actor.set_physics_process(true)
	actor.combat.weapon.set_physics_process(true)
	await frames(90)
	check(arena.robot.get_node("Health").current < 100 and arena.robot.get_node("Health").current > 0 and arena.ledger.is_conserved(), "Natural armed physics run warns, shoots, and damages the player with conserved accounting")
	actor.health.apply_damage(25)
	var moved_from := actor.global_position
	await frames(90)
	check(actor.global_position.distance_to(moved_from) > 0.5 and actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING, Raider.State.ENGAGING], "Threatened fighter physically follows a cover/reposition route")
	var reached_peek := [false]
	actor.state_changed.connect(func(_previous: Raider.State, next: Raider.State) -> void:
		if next == Raider.State.REPOSITIONING:
			reached_peek[0] = true)
	for index in range(600):
		if reached_peek[0] and actor.state == Raider.State.ENGAGING:
			break
		await frames(1)
	if not (reached_peek[0] and actor.state == Raider.State.ENGAGING):
		print("Cover diagnostic: ", actor.position, " target ", actor.combat.destination.global_position if actor.combat.destination != null else Vector3.INF, " memory ", actor.threat_remaining, " nav ", actor.navigation_status)
	check(reached_peek[0] and actor.state == Raider.State.ENGAGING, "Natural cover route completes its dwell and physical peek before re-engaging")
	arena.queue_free()
	await frames(3)
	print("Stage E checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
