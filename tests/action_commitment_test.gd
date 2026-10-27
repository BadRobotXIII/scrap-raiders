extends "res://tests/gameplay_integration_test.gd"
## Real LOS, actor movement and finite ownership across competing observations.


func perception_commitment() -> void:
	var arena := await isolated_s("visibility", 87018)
	await all_entries(arena)
	var actor: Raider = arena.raiders[4]
	var target: Raider = arena.raiders[1]
	var alternative: Raider = arena.raiders[2]
	actor.position = Vector3(0, 0.1, 8)
	target.position = Vector3(0, 0.1, 14)
	alternative.position = Vector3(-5, 0.1, 14)
	target.health.maximum = 1000
	target.health.current = 1000
	actor.combat.reserve_cover = func(_id: int) -> Node3D: return null
	var wall := barrier(arena)
	var collider := wall.get_child(0) as CollisionShape3D
	collider.disabled = true
	await frames(3)
	actor.decide()
	check(actor.state == Raider.State.ENGAGING and actor.combat_target == target, "First visible enemy engages immediately without an artificial think delay")
	var transitions := {"count": 0}
	actor.state_changed.connect(func(previous: Raider.State, next: Raider.State) -> void:
		if previous in [Raider.State.ENGAGING, Raider.State.INVESTIGATING] and next in [Raider.State.ENGAGING, Raider.State.INVESTIGATING]:
			transitions.count += 1)
	var shots := {"count": 0, "hidden": 0}
	actor.combat.weapon.fired.connect(func(_origin: Vector3, _endpoint: Vector3, _hit: bool) -> void:
		shots.count += 1
		if not actor.detects_current_target():
			shots.hidden += 1)
	actor.set_physics_process(true)
	actor.combat.weapon.set_physics_process(true)
	var retained := true
	# Every occlusion is real physics geometry. The old immediate transition
	# alternated ENGAGING/INVESTIGATING here before any action could complete.
	for cycle in range(8):
		collider.disabled = false
		await frames(9)
		retained = retained and actor.state == Raider.State.ENGAGING and actor.combat_target == target
		collider.disabled = true
		await frames(9)
		retained = retained and actor.state == Raider.State.ENGAGING and actor.combat_target == target
	check(retained and transitions.count == 0, "Repeated brief LOS interruptions retain the committed action and target rather than animate every alternative")
	check(shots.hidden == 0, "Visibility grace never permits firing through actual occluding geometry")
	await frames(65)
	check(shots.count > 0 and target.health.current < 1000, "A stable visible opportunity produces physical return fire after intermittent occlusion")
	collider.disabled = false
	await frames(45)
	actor.set_physics_process(false)
	actor.combat.weapon.set_physics_process(false)
	check(actor.state == Raider.State.INVESTIGATING and actor.combat.pursuing and actor.combat_target == target, "Sustained LOS loss releases engagement into bounded pursuit of the same observed opponent")
	var snapshot := actor.investigation_position
	target.position = Vector3(100, 0.1, 100)
	await frames(3)
	actor.decide()
	check(actor.combat_target == target and actor.investigation_position == snapshot, "Another visible enemy and unseen target movement cannot rewrite accepted pursuit")
	target.position = Vector3(0, 0.1, 14)
	collider.disabled = true
	await frames(3)
	actor.combat.tick(0.15)
	actor.decide()
	check(actor.state == Raider.State.INVESTIGATING, "A brief same-target sighting does not immediately abandon a pursuit action")
	actor.combat.tick(0.15)
	actor.decide()
	check(actor.state == Raider.State.ENGAGING and actor.combat_target == target, "Sustained same-target reacquisition returns to engagement without losing eligibility")
	alternative.position = actor.position + Vector3(-4, 0, 0)
	await frames(3)
	actor.health.apply_damage(1, alternative.position, alternative.get_instance_id())
	check(actor.combat_target == alternative, "A genuinely observed immediate attacker can interrupt an existing action")
	actor.health.apply_damage(75, alternative.position, alternative.get_instance_id())
	check(actor.state == Raider.State.FLEEING and actor.combat.escaping, "Critical survival overrides perception commitment immediately")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Action commitment cannot allocate or transfer materials or equipment")
	print("LOS commitment transitions: ", transitions.count, " | physical shots: ", shots.count, " | hidden shots: ", shots.hidden)
	arena.queue_free()
	await frames(30)


func reported_objective_commitment() -> void:
	var arena := await isolated_s("reports", 87018)
	var actor: Raider = arena.raiders[1]
	var ally: Raider = arena.raiders[2]
	actor.position = Vector3(0, 0.1, 8)
	ally.position = Vector3(-7, 0.1, 8)
	var initial := Vector3(0, 0.1, 18)
	await frames(3)
	check(actor.social.receive(ally, arena.robot, initial, arena.elapsed + 4), "A live allied report records an eligible distant hostile observation")
	actor.decide()
	check(actor.state == Raider.State.INVESTIGATING and actor.threat_source == "ally report", "The accepted report starts one independent investigation")
	var snapshot := actor.investigation_position
	var transfers: int = arena.ledger.accepted_transfers
	var origin := actor.position
	actor.set_physics_process(true)
	var stable := true
	for index in range(12):
		var alternative := Vector3(-9 if index % 2 == 0 else 9, 0.1, 17)
		actor.social.receive(ally, arena.robot, alternative, arena.elapsed + 4)
		# A flare is also knowledge, rather than permission to replace every
		# unfinished lower-priority investigation with a new physical action.
		actor.investigate_flare(alternative)
		await frames(4)
		stable = stable and actor.state == Raider.State.INVESTIGATING and actor.investigation_position == snapshot
	actor.set_physics_process(false)
	check(stable, "Competing reports and flares update knowledge without rewriting the accepted investigation route")
	check(actor.position.distance_to(origin) > 1.0, "A retained reported objective executes real navigation instead of reconsidering in place")
	check(actor.investigation_position == snapshot, "The original reported route is still accepted immediately before its deadline test")
	# Knowledge keeps arriving, but the accepted action must remain bounded.
	actor.hear_gunfire(actor.position + Vector3(0, 0, 6))
	check(actor.threat_source == "gunfire" and actor.investigation_position == snapshot, "New audible knowledge changes the report without changing the accepted route or its deadline")
	actor.combat.tick(actor.profile.threat_memory + 0.1)
	actor.threat_remaining = 0
	actor.decide()
	check(actor.state != Raider.State.INVESTIGATING or actor.investigation_position != snapshot, "An expired reported action is released rather than extended indefinitely by unrelated new reports")
	check(arena.ledger.accepted_transfers == transfers and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Observation, movement and expiry leave authoritative ownership unchanged")
	arena.queue_free()
	await frames(30)


func occupied_corner_recovery() -> void:
	# This exact U corner was observed in the ordinary west deployment. The
	# guard overlaps a navigation waypoint while the final cover slot is free.
	var arena := load("res://scenes/levels/expanded_salvage_complex.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/occupied_corner.json"
	root.add_child(arena)
	current_scene = arena
	await start_frozen(arena)
	arena.ledger.transfer_accepted.connect(audit_transfer.bind(arena))
	arena.flare_director.equipment.transfer_accepted.connect(audit_transfer.bind(arena))
	park_actors(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(100, 4, 100)
	var guard: SupportMachine = arena.ecosystem.machines[1]
	guard.position = Vector3(8.28985, 0.00094, 0.72117)
	guard.health.maximum = 1000
	guard.health.current = 1000
	var actor: Raider = arena.raiders[1]
	actor.profile = actor.profile.duplicate()
	actor.profile.combat_policy = RaiderProfile.CombatPolicy.BASELINE
	actor.position = Vector3(4.49, 0.1, -0.10)
	actor.combat_target = guard
	actor.combat.cover = arena.get_node("CoverPoints/YardEast")
	actor.combat.destination = actor.combat.cover
	actor.combat.profile = actor.combat.profile.duplicate()
	actor.combat.profile.cover_hold = 100
	actor.threat_remaining = 100
	actor.transition(Raider.State.TAKING_COVER)
	if actor.betrayal != null:
		actor.betrayal.spent = true
	await frames(3)
	var evidence := {"recoveries": 0, "shots": 0}
	actor.navigation_recovered.connect(func(_details: Dictionary) -> void: evidence.recoveries += 1)
	actor.combat.weapon.fired.connect(func(_origin: Vector3, _endpoint: Vector3, _hit: bool) -> void: evidence.shots += 1)
	actor.set_physics_process(true)
	actor.combat.weapon.set_physics_process(true)
	var previous := actor.visuals.rotation.y
	var snaps := 0
	for index in range(480):
		await frames(1)
		if absf(angle_difference(previous, actor.visuals.rotation.y)) > 0.65:
			snaps += 1
		previous = actor.visuals.rotation.y
	freeze(arena)
	check(evidence.recoveries >= 2 and actor.state == Raider.State.ENGAGING, "An occupied corner waypoint releases failed cover travel through bounded existing navigation recovery")
	check(evidence.shots > 0 and guard.health.current < 1000, "An abandoned blocked route permits an actual visible return shot instead of permanent physical indecision")
	check(snaps <= 20, "Corner congestion does not repeatedly discard a bypass and reverse heading every physics frame")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Physical congestion recovery preserves material and equipment ownership")
	print("Occupied corner recovery: heading snaps ", snaps, " | recoveries ", evidence.recoveries, " | shots ", evidence.shots, " | final ", actor.position)
	arena.queue_free()
	await frames(30)


func run() -> void:
	test_directory = "res://.godot/action_commitment_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await perception_commitment()
	await reported_objective_commitment()
	await occupied_corner_recovery()
	check(accounting_valid, "Every accepted transfer preserves material and equipment invariants")
	print("Action commitment failures: ", failures)
	quit(1 if failures else 0)
