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


func create_arena(count: int = 3) -> Node3D:
	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	arena.raider_count = count
	root.add_child(arena)
	current_scene = arena
	arena.get_node("Robot/Input").set_physics_process(false)
	arena.get_node("Robot/Input").set_process_input(false)
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
	return arena


func load_raiders(arena: Node3D) -> void:
	for actor in arena.raiders.values():
		actor.position = actor.salvage.position
		actor.scavenge_seconds = 0.1
		actor.extraction_seconds = 0.1
		actor.set_physics_process(true)
	await frames(20)
	for actor in arena.raiders.values():
		actor.set_physics_process(false)


func run() -> void:
	# Ledger and policy are independent; verify each accepted event's invariant.
	var ledger := MaterialLedger.new({&"A": 3, &"B": 3, &"C": 3}, [1, 2, 3])
	check(ledger.total_materials == 9 and ledger.is_conserved(), "Initial finite stock is nine materials")
	check(ledger.collect(1, &"A", 3) == 3 and ledger.is_conserved(), "First contested collection transfers finite stock")
	check(ledger.collect(2, &"A", 3) == 0 and ledger.is_conserved(), "Second collector cannot duplicate depleted stock")
	check(ledger.collect(2, &"B", 3) == 3 and ledger.is_conserved(), "Independent collector can use another location")
	var drop_id := ledger.defeat(1)
	check(drop_id > 0 and ledger.drop_source(drop_id) == 1 and ledger.is_conserved(), "Death creates identified ground allocation with source Raider")
	var rules := MissionRules.new()
	rules.evaluate(ledger)
	check(rules.phase == MissionRules.Phase.HUNTING and ledger.active_raiders == 2, "One death cannot end other Raiders' behavior")
	check(ledger.extract(2) and ledger.is_conserved(), "Extraction accounts only for the extracting Raider")
	check(ledger.defeat(3) == 0 and ledger.is_conserved(), "Empty death creates no materials")
	rules.evaluate(ledger)
	check(rules.phase == MissionRules.Phase.RECOVERING and ledger.protected_materials == 3, "Resolved Raiders enter recovery-only despite remaining protected stock")
	check(ledger.recover(drop_id) == 3 and ledger.is_conserved(), "Ground cargo transfers to recovered stock")
	rules.evaluate(ledger)
	check(rules.phase == MissionRules.Phase.FAILED and ledger.lost_materials == 3, "Final policy reports partial extraction after recovery finishes")
	var accepted := ledger.accepted_transfers
	check(ledger.defeat(1) == -1 and not ledger.extract(1) and ledger.recover(drop_id) == 0 and ledger.accepted_transfers == accepted, "Duplicate death/extraction/recovery rejected without changing ledger")
	ledger.seal()
	check(ledger.collect(3, &"C", 3) == 0 and ledger.is_conserved(), "Sealed ledger refuses late events")
	ledger = MaterialLedger.new({&"A": 2}, [1, 2])
	check(ledger.collect(1, &"A", 3) == 2 and ledger.collect(2, &"A", 3) == 0 and ledger.is_conserved(), "Partial salvage never exceeds available quantity")
	ledger = MaterialLedger.new({&"A": 9}, [1, 2, 3])
	for id in [1, 2, 3]:
		ledger.defeat(id)
	rules = MissionRules.new()
	rules.evaluate(ledger)
	check(rules.phase == MissionRules.Phase.SUCCEEDED and ledger.protected_materials == 9, "Untouched salvage does not block completion")
	ledger = MaterialLedger.new({&"A": 9}, [1, 2, 3])
	ledger.collect(1, &"A", 3)
	rules = MissionRules.new()
	rules.evaluate(ledger, true)
	check(ledger.carried_materials == 3 and ledger.protected_materials == 6 and ledger.lost_materials == 0 and ledger.is_conserved(), "Deadline policy does not reclassify still-carried cargo as extraction loss")

	# Actual actor timers and concurrent collection requests.
	var arena := create_arena()
	check(arena.raiders.size() == 3 and arena.salvage_points.size() == 3 and arena.ledger.total_materials == 9, "Default configuration registers three independent Raiders and salvage points")
	check(arena.raiders[1].salvage != arena.raiders[2].salvage and arena.raiders[2].salvage != arena.raiders[3].salvage, "Stable initial assignments distribute objectives")
	await load_raiders(arena)
	check(arena.ledger.carried_materials == 9 and arena.ledger.protected_materials == 0 and arena.ledger.is_conserved(), "Three real scavenging timers transfer nine units without duplication")
	var first := arena.raiders[1] as Raider
	var second := arena.raiders[2] as Raider
	var third := arena.raiders[3] as Raider
	third.set_physics_process(true)
	first.health.apply_damage(1000)
	second.health.apply_damage(1000)
	await frames(2)
	check(arena.drops.size() == 2 and arena.ledger.dropped_materials == 6 and arena.ledger.is_conserved(), "Same-frame deaths create two independent drop identities")
	check(arena.ledger.active_raiders == 1 and arena.mission.phase == MissionRules.Phase.HUNTING and not arena.get_node("Overlay/Summary").visible, "Other Raider and player remain active after two deaths")
	check(third.state == Raider.State.EXTRACTING and third.carried_materials == 3 and third.is_physics_processing(), "Unrelated Raider retains active simulation, state, and cargo")
	var ids: Array = arena.drops.keys()
	ids.sort()
	var a := arena.drops[ids[0]] as MaterialDrop
	var b := arena.drops[ids[1]] as MaterialDrop
	arena.robot.position = Vector3.ZERO
	a.position = Vector3(1, 0, 0)
	b.position = Vector3(-1, 0, 0)
	await frames(2)
	check(arena.selected_drop() == a, "Equal-distance pickup deterministically selects lower drop ID")
	b.position = Vector3(0.5, 0, 0)
	await frames(2)
	check(arena.selected_drop() == b and b.get_node("PickupHighlight").visible and not a.get_node("PickupHighlight").visible, "Nearest eligible drop alone drives highlight and interaction")
	check(arena.try_recover() and arena.ledger.recovered_materials == 3 and arena.ledger.ground_for(a.drop_id) == 3, "Recovering one stack leaves unrelated stack intact")
	check(arena.ledger.recover(ids[1]) == 0 and arena.ledger.is_conserved(), "Consumed identity cannot be recovered again")
	check(arena.mission.phase == MissionRules.Phase.HUNTING, "Recovery is allowed while another Raider is active")
	third.position = arena.get_node("Extraction").position
	third.set_physics_process(true)
	await frames(15)
	check(arena.mission.phase == MissionRules.Phase.RECOVERING and arena.ledger.lost_materials == 3 and arena.ledger.dropped_materials == 3, "Last extraction enters recovery-only without stopping player pickup")
	check(arena.robot.is_physics_processing() and arena.robot.get_node("Weapon").is_physics_processing(), "Recovery-only preserves player movement and combat controls")
	check(arena.try_recover() and arena.mission.phase == MissionRules.Phase.FAILED and arena.ledger.recovered_materials == 6 and arena.ledger.is_conserved(), "Partial-loss mission completes only after remaining drop recovery")
	arena.restart_mission()
	await frames(5)
	arena = current_scene
	check(arena.raiders.size() == 3 and arena.ledger.active_raiders == 3 and arena.ledger.protected_materials == 9 and arena.drops.is_empty() and arena.ledger.lost_materials == 0, "Multi-Raider restart resets all actors, stock, drops, and outcomes")
	arena.queue_free()
	await frames(3)

	# Ground cargo at timeout must remain distinct from extracted/lost cargo.
	arena = create_arena()
	await load_raiders(arena)
	arena.raiders[1].health.apply_damage(1000)
	arena.raiders[2].health.apply_damage(1000)
	third = arena.raiders[3]
	third.position = arena.get_node("Extraction").position
	third.set_physics_process(true)
	await frames(15)
	arena.mission_duration = 0.01
	await frames(2)
	check(arena.mission.phase == MissionRules.Phase.FAILED and arena.ledger.dropped_materials == 6 and arena.ledger.lost_materials == 3 and arena.ledger.is_conserved(), "Deadline distinguishes six unrecovered units from three extracted units")
	check(arena.get_node("Overlay/Summary/Content/Report").text.contains("Unrecovered ground: 6") and arena.get_node("Overlay/Summary/Content/Report").text.contains("Lost: 3"), "Deadline report preserves material categories")
	check(arena.ledger.recover(arena.drops.keys()[0]) == 0, "Deadline seals further material transfers")
	arena.queue_free()
	await frames(3)

	# Contention and fallback through the actual common AI implementation.
	arena = create_arena()
	first = arena.raiders[1]
	second = arena.raiders[2]
	first.salvage = arena.get_node("Salvage")
	second.salvage = first.salvage
	first.position = first.salvage.position + Vector3(-0.4, 0.1, 0)
	second.position = first.salvage.position + Vector3(0.4, 0.1, 0)
	first.scavenge_seconds = 0.1
	second.scavenge_seconds = 0.1
	first.set_physics_process(true)
	second.set_physics_process(true)
	await frames(20)
	check(arena.ledger.available(&"Salvage") == 0 and first.carried_materials + second.carried_materials == 3 and arena.ledger.is_conserved(), "Contending actors cannot each obtain the same three materials")
	var empty_actor := second if second.carried_materials == 0 else first
	check(empty_actor.salvage != arena.get_node("Salvage"), "Depleted objective causes deterministic fallback to another salvage point")
	var occupied: Array[Vector3] = [Vector3(0, 0.1, 0)]
	check(not arena.spawn_is_clear(Vector3(-7, 0.1, -5)) and not arena.spawn_is_clear(Vector3(0, 0.1, 0), occupied), "Spawn validation rejects obstacle overlap and duplicate positions")
	arena.queue_free()
	await frames(3)

	# Actual hitscan queries must resolve distinct Raider health/ledger identities.
	arena = create_arena()
	first = arena.raiders[1]
	second = arena.raiders[2]
	third = arena.raiders[3]
	arena.robot.position = Vector3(0, 0, 2)
	first.position = Vector3(0, 0.1, -4)
	second.position = Vector3(3, 0.1, -4)
	await frames(3)
	var weapon := arena.robot.get_node("Weapon") as HitscanWeapon
	arena.robot.camera_rig.camera.look_at(first.global_position + Vector3.UP)
	for index in range(4):
		weapon.try_fire()
		await frames(15)
	check(not is_instance_valid(first) and second.health.current == 100 and third.health.current == 100 and arena.ledger.active_raiders == 2, "Hitscan kills only its selected Raider and leaves other health/identities intact")
	arena.robot.camera_rig.camera.look_at(second.global_position + Vector3.UP)
	for index in range(4):
		weapon.try_fire()
		await frames(15)
	check(not is_instance_valid(second) and third.health.current == 100 and arena.ledger.active_raiders == 1 and arena.ledger.protected_materials == 9 and arena.ledger.is_conserved(), "Second independent weapon kill preserves third Raider and protected stock")
	arena.queue_free()
	await frames(3)

	# Bounded natural navigation smoke tests; no teleport or state manipulation.
	Engine.time_scale = 3.0
	for count in [3, 5]:
		arena = create_arena(count)
		for actor in arena.raiders.values():
			actor.set_physics_process(true)
		for index in range(1000):
			if arena.mission.is_finished():
				break
			await frames(1)
		check(arena.ledger.active_raiders == 0 and arena.mission.is_finished() and arena.ledger.is_conserved(), "%d Raiders independently navigate/scavenge/resolve within bounded simulation" % count)
		if arena.ledger.active_raiders > 0:
			for actor in arena.raiders.values():
				if is_instance_valid(actor):
					print("Unresolved R", actor.raider_id, " position ", actor.position, " state ", actor.state)
		arena.queue_free()
		await frames(3)
	Engine.time_scale = 1.0
	print("Stage A checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
