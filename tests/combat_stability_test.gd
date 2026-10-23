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
	arena.stash_path = "res://.godot/combat_stability_tests/%s.json" % Crypto.new().generate_random_bytes(8).hex_encode()
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
		actor.combat.weapon.set_physics_process(false)
		if actor.betrayal != null:
			actor.betrayal.spent = true
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)
	var a := arena.raiders[1] as Raider
	var b := arena.raiders[2] as Raider
	var guard := arena.ecosystem.machines[1] as SupportMachine
	arena.robot.position = Vector3(100, 0.1, 100)
	arena.ecosystem.machines[0].position = Vector3(100, 4, 100)
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(18, 0.1, -18)
	guard.position = Vector3(0, 0.1, 14)
	a.combat.profile = a.combat.profile.duplicate()
	a.combat.profile.spread_degrees = 0
	await frames(3)
	a.decide()
	check(a.current_target() == guard and a.state == Raider.State.ENGAGING, "Visible guard starts a normal engagement")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.HOSTILE, "fixture rivalry", 1)
	b.position = Vector3(2, 0.1, 8)
	await frames(3)
	a.combat.aim_elapsed = 0.4
	for index in range(10):
		a.decide()
	check(a.current_target() == guard and a.state == Raider.State.ENGAGING and a.combat.aim_elapsed == 0.4, "Closer rival does not cancel an ongoing guard engagement or warning")
	# A physical wall interrupts sight, but does not make a visible rival steal
	# the remembered target or cancel the cover route.
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.4)
	collision.shape = shape
	wall.add_child(collision)
	arena.add_child(wall)
	wall.position = Vector3(0, 1.5, 11)
	await frames(3)
	check(not a.detects_actor(guard) and arena.social.choose_target(a) == guard, "Brief occlusion preserves remembered opponent without granting sight")
	wall.queue_free()
	await frames(3)
	a.combat_target = b
	a.transition(Raider.State.ENGAGING)
	guard.position = a.position + Vector3(0, 0, 0.7)
	# Exercise the no-cover case: a healthy fighter must retaliate rather than
	# endlessly renewing a retreat timer each time the nearby guard hits it.
	var reserve := a.combat.reserve_cover
	a.combat.reserve_cover = func(_id: int) -> Node3D: return null
	await frames(3)
	check(a.detects_actor(guard), "Guard remains visible at physical capsule contact distance")
	a.health.apply_damage(5, guard.get_aim_position(), guard.get_instance_id())
	check(a.current_target() == guard and a.state == Raider.State.ENGAGING, "Observed guard damage redirects retaliation from the rival without available cover")
	a.combat.tick(a.combat.profile.warning_time + 0.01)
	check(guard.health.current == 70, "Contacting Raider actually returns a physical shot into the guard")
	a.health.apply_damage(5, guard.get_aim_position(), guard.get_instance_id())
	check(a.combat.aim_elapsed > 0 and a.combat.retreat_remaining == 0, "Repeated noncritical hits do not suppress all return fire")
	a.recover_navigation(a.position)
	a.recover_navigation(a.position)
	check(a.state == Raider.State.ENGAGING and a.current_target() == guard, "Blocked combat route retains a visible opponent instead of seeking scrap")
	a.combat.reserve_cover = reserve
	# Existing authored wall has protected slots and reachable peek points.
	a.position = Vector3(-5, 0.1, 3)
	guard.position = Vector3(-15, 0.1, 3)
	b.position = Vector3(18, 0.1, -18)
	await frames(3)
	a.health.apply_damage(5, guard.get_aim_position(), guard.get_instance_id())
	var cover := a.combat.cover
	check(cover != null and a.state == Raider.State.TAKING_COVER, "Damage still requests protective authored cover when available")
	a.task_elapsed = 0.6
	a.health.apply_damage(5, guard.get_aim_position(), guard.get_instance_id())
	check(a.combat.cover == cover and a.task_elapsed == 0.6, "Repeated damage preserves cover reservation and dwell progress")
	# A new visible attacker can change aim without erasing physical cover work.
	b.position = Vector3(-5, 0.1, 5)
	await frames(3)
	check(a.detects_actor(b) and arena.social.eligible(b, a), "Cover attacker fixture is visible and hostile")
	a.health.apply_damage(1, b.position + Vector3.UP, b.get_instance_id())
	check(a.current_target() == b and a.state == Raider.State.TAKING_COVER and a.combat.cover == cover and a.task_elapsed == 0.6, "Attacker switch preserves the active cover route and task clock")
	a.combat_target = guard
	b.position = Vector3(-7, 0.1, -9)
	await frames(3)
	check(not a.detects_actor(b), "Occluded attacker fixture has no line of sight")
	a.health.apply_damage(1, b.position + Vector3.UP, b.get_instance_id())
	check(a.current_target() == guard, "Unseen attacker does not grant an omniscient target switch")
	guard.health.apply_damage(1000)
	await frames(3)
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 14)
	await frames(3)
	a.decide()
	check(a.current_target() == b, "Destroyed guard releases target commitment so the visible rival can be selected")
	a.transition(Raider.State.ENGAGING)
	a.threat_remaining = 0
	b.position = Vector3(100, 0.1, 100)
	await frames(3)
	a.decide()
	check(not a.combat.owns_state(), "Expired unseen engagement releases the fighter for ordinary objectives")
	a.health.apply_damage(1000)
	check(arena.ledger.is_conserved(), "Combat switching and death preserve authoritative material conservation")
	arena.queue_free()
	await frames(30)
	print("Combat stability checks complete; failures: ", failures)
	quit(1 if failures else 0)
