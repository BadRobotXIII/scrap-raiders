extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func run() -> void:
	var arena := load("res://scenes/levels/emergent_encounters_arena.tscn").instantiate() as Node3D
	arena.stash_path = "res://.godot/combat_movement_tests/%s.json" % Crypto.new().generate_random_bytes(8).hex_encode()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.encounter.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	await frames(10)
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.position = Vector3(18, 0.1, -18)
		if actor.betrayal != null:
			actor.betrayal.spent = true
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)
	var a := arena.raiders[1] as Raider
	var scout := arena.ecosystem.machines[0] as SupportMachine
	var guard := arena.ecosystem.machines[1] as SupportMachine
	arena.robot.position = Vector3(100, 0.1, 100)
	scout.position = Vector3(100, 4, 100)
	a.combat.profile = a.combat.profile.duplicate()
	a.combat.profile.spread_degrees = 0
	a.combat.reserve_cover = func(_id: int) -> Node3D: return null
	guard.health.maximum = 1000
	guard.health.current = 1000
	a.position = Vector3(0, 0.1, 8)
	guard.position = Vector3(0, 0.1, 8.75)
	await frames(3)
	a.decide()
	a.set_physics_process(true)
	var touching_frames := 0
	for index in range(120):
		await frames(1)
		if a.position.distance_to(guard.position) < 1.0:
			touching_frames += 1
	check(a.position.distance_to(guard.position) > 2 and touching_frames < 30, "Natural combat movement opens a gap from a contacting stationary guard")
	check(guard.health.current < 1000, "Spacing movement preserves actual return fire")
	a.set_physics_process(false)
	# A cover path intentionally passes through the guard. Exercise actual
	# navigation and collisions, not just a forced watchdog transition.
	a.position = Vector3(0, 0.1, 8)
	guard.position = Vector3(0, 0.1, 10)
	var cover := Marker3D.new()
	arena.add_child(cover)
	cover.position = Vector3(0, 0, 14)
	var peek := Marker3D.new()
	peek.name = "Peek"
	cover.add_child(peek)
	peek.position = Vector3(0, 0, 2)
	a.combat.cover = cover
	a.combat.destination = cover
	a.combat.profile.cover_hold = 100
	a.transition(Raider.State.TAKING_COVER)
	await frames(3)
	a.set_physics_process(true)
	var sidestep := 0.0
	for index in range(210):
		await frames(1)
		sidestep = maxf(sidestep, absf(a.position.x))
	check(a.position.z > 12.5 and sidestep > 0.65 and guard.health.current > 0, "Physical cover route steers around a live blocking guard and reaches its far side")
	a.set_physics_process(false)
	a.transition(Raider.State.SELECTING)
	a.position = Vector3(0, 0.1, 8)
	guard.position = Vector3(18, 0.1, -18)
	scout.position = Vector3(0, 3.5, 14)
	scout.health.maximum = 1000
	scout.health.current = 1000
	a.combat_target = null
	a.threat_remaining = 0
	await frames(3)
	a.decide()
	check(a.current_target() == scout and a.detection_range == a.combat.profile.engagement_range, "Armed Greedy acquires scout with its existing rifle detection range")
	scout.position = Vector3(0, 3.5, 19)
	await frames(3)
	check(a.detects_current_target(), "Moving scout remains visible within rifle range")
	var shots := [0]
	a.combat.weapon.fired.connect(func(_origin: Vector3, _endpoint: Vector3, _damaged: bool): shots[0] += 1)
	a.combat.reserve_cover = func(_id: int) -> Node3D: return cover
	a.set_physics_process(true)
	await frames(200)
	check(a.current_target() == scout and a.state == Raider.State.ENGAGING and shots[0] >= 3 and scout.health.current <= 970, "Unanswered scout engagement continues beyond the old cover interval even with available cover")
	a.set_physics_process(false)
	scout.position = Vector3(0, 3.5, 29)
	await frames(3)
	check(not a.detects_current_target(), "Engagement tracking still rejects opponents beyond rifle range")
	a.transition(Raider.State.SELECTING)
	check(not a.detects_current_target(), "Ordinary perception also rejects the out-of-range scout")
	# Finish a peek and apply frequent small hits during the normal warning.
	scout.position = Vector3(100, 4, 100)
	guard.position = Vector3(0, 0.1, 14)
	a.combat_target = guard
	a.threat_remaining = 5
	a.combat.profile.cover_hold = 1
	a.combat.reserve_cover = func(_id: int) -> Node3D: return cover
	a.combat.cover = cover
	a.combat.destination = peek
	await frames(3)
	a.transition(Raider.State.REPOSITIONING)
	a.combat.on_arrived(0)
	shots[0] = 0
	a.combat.weapon.cooldown = 0
	a.set_physics_process(true)
	for index in range(125):
		await frames(1)
		if index % 18 == 0:
			a.health.apply_damage(1, guard.get_aim_position(), guard.get_instance_id())
	check(shots[0] >= 2 and a.state == Raider.State.ENGAGING, "Completed peek returns at least two shots despite repeated noncritical incoming hits")
	a.set_physics_process(false)
	a.combat.return_fire_remaining = 0
	a.health.apply_damage(1, guard.get_aim_position(), guard.get_instance_id())
	check(a.state == Raider.State.TAKING_COVER, "Cover reactions resume after the bounded return-fire window")
	a.health.current = 31
	a.health.apply_damage(2, guard.get_aim_position(), guard.get_instance_id())
	check(a.state == Raider.State.FLEEING, "Critical damage still overrides cover and firing with retreat")
	check(arena.ledger.is_conserved(), "Physical movement and firing preserve material conservation")
	arena.queue_free()
	await frames(30)
	print("Combat movement checks complete; failures: ", failures)
	quit(1 if failures else 0)
