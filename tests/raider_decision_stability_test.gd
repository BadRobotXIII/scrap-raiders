extends "res://tests/gameplay_integration_test.gd"
## Physical regressions for allied contact and competing visible opponents.


func allied_passing() -> void:
	var arena := await isolated_s("passing", 87018)
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 12)
	var south: Node3D = arena.get_node("Salvage")
	var north: Node3D = arena.get_node("Salvage2")
	south.position = Vector3(0, 0, 18)
	north.position = Vector3(0, 0, 2)
	a.salvage = south
	b.salvage = north
	a.transition(Raider.State.SCAVENGING)
	b.transition(Raider.State.SCAVENGING)
	await frames(3)
	a.set_physics_process(true)
	b.set_physics_process(true)
	var yaw_a := a.visuals.rotation.y
	var yaw_b := b.visuals.rotation.y
	var snaps_a := 0
	var snaps_b := 0
	for index in range(240):
		await frames(1)
		if absf(angle_difference(yaw_a, a.visuals.rotation.y)) > 1:
			snaps_a += 1
		if absf(angle_difference(yaw_b, b.visuals.rotation.y)) > 1:
			snaps_b += 1
		yaw_a = a.visuals.rotation.y
		yaw_b = b.visuals.rotation.y
	print("Allied passing heading snaps: ", snaps_a, "/", snaps_b)
	check(snaps_a <= 8 and snaps_b <= 8, "Allied contact does not generate repeated per-frame heading reversals")
	check(a.position.z > 16 and b.position.z < 4, "Both allied bodies physically pass and continue their independent objectives")
	check(arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED and arena.ledger.is_conserved(), "Passing cannot create hostility or material changes")
	arena.queue_free()
	await frames(30)


func pursuit_with_competing_target() -> void:
	var arena := await isolated_s("pursuit", 87018)
	await all_entries(arena)
	var observer: Raider = arena.raiders[4]
	var original: Raider = arena.raiders[1]
	var alternative: Raider = arena.raiders[2]
	observer.position = Vector3(0, 0.1, 8)
	original.position = Vector3(0, 0.1, 14)
	alternative.position = Vector3(-5, 0.1, 14)
	await frames(3)
	observer.decide()
	check(observer.combat_target == original, "Aggressive Raider initially observes the nearer eligible opponent")
	var wall := barrier(arena)
	await frames(3)
	observer.decide()
	check(observer.combat.pursuing and not observer.threat_visible, "Occluded opponent starts existing bounded snapshot pursuit")
	var snapshot := observer.investigation_position
	original.position.z = 18
	await frames(3)
	observer.decide()
	check(observer.combat_target == original and observer.combat.pursuing and observer.investigation_position == snapshot, "Another visible opponent cannot replace a still-valid committed pursuit or track unseen movement")
	var origin := observer.position
	observer.set_physics_process(true)
	observer.combat.weapon.set_physics_process(true)
	await frames(45)
	freeze(arena)
	check(observer.position.distance_to(origin) > 0.3, "Retained pursuit makes actual navigation progress instead of reconsidering targets in place")
	# A currently visible eligible attacker still interrupts commitment through the accepted damage path.
	alternative.position = observer.position + Vector3(-4, 0, 0)
	await frames(3)
	observer.health.apply_damage(1, alternative.position, alternative.get_instance_id())
	check(observer.combat_target == alternative, "Observed incoming attacker retains immediate defensive priority")
	# A new pursuit expires, rather than holding an unseen actor indefinitely.
	original.position = Vector3(100, 0.1, 100)
	wall.queue_free()
	await frames(3)
	observer.combat.observation_remaining = 0
	observer.threat_remaining = 0
	alternative.health.apply_damage(1000)
	observer.decide()
	check(observer.combat_target != alternative and not observer.combat.pursuing, "Resolved opponent or expired observation releases commitment")
	arena.queue_free()
	await frames(30)


func competing_attackers() -> void:
	var arena := await isolated_s("attackers", 87018)
	await all_entries(arena)
	var observer: Raider = arena.raiders[4]
	var first: Raider = arena.raiders[1]
	var second: Raider = arena.raiders[2]
	observer.position = Vector3(0, 0.1, 8)
	first.position = Vector3(0, 0.1, 14)
	second.position = Vector3(-4, 0.1, 8)
	# Isolate target/aim commitment from cover travel; weapon cadence and LOS stay real.
	observer.combat.reserve_cover = func(_id: int) -> Node3D: return null
	await frames(3)
	observer.set_physics_process(true)
	observer.combat.weapon.set_physics_process(true)
	var shots := {"count": 0}
	observer.combat.weapon.fired.connect(func(_origin: Vector3, _end: Vector3, _hit: bool) -> void: shots.count += 1)
	var switches := 0
	var previous: Node3D
	for index in range(240):
		await frames(1)
		if index % 12 == 0:
			var source := first if index % 24 == 0 else second
			observer.health.apply_damage(1, source.position, source.get_instance_id())
		if observer.combat_target != previous:
			switches += 1
			previous = observer.combat_target
	print("Competing attackers: switches ", switches, " shots ", shots.count)
	check(switches <= 4 and shots.count >= 2, "Alternating observed hits cannot reset every aim warning and starve actual return fire")
	check(observer.health.current == 80, "Attacker focus never suppresses or reduces incoming damage")
	var focused := observer.combat_target as Raider
	var other := first if focused == second else second
	focused.health.apply_damage(1000)
	observer.health.apply_damage(1, other.position, other.get_instance_id())
	check(observer.combat_target == other, "Target death releases attacker focus immediately for another visible attacker")
	observer.health.apply_damage(70, other.position, other.get_instance_id())
	check(observer.combat.escaping and observer.state == Raider.State.FLEEING, "Critical survival overrides the attacker response window")
	arena.queue_free()
	await frames(30)


func run() -> void:
	test_directory = "res://.godot/stage_t_decision_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await allied_passing()
	await pursuit_with_competing_target()
	await competing_attackers()
	check(accounting_valid, "All accepted transfers preserve material and equipment invariants")
	print("Raider decision stability failures: ", failures)
	quit(1 if failures else 0)
