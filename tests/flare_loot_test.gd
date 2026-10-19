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
	var arena := load("res://scenes/levels/loot_pressure_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	return arena


func freeze_actors(arena: Node3D) -> void:
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			actor.combat.weapon.set_physics_process(false)


func run() -> void:
	var equipment := EquipmentLedger.new()
	check(equipment.assign_loadout(1, false) and not equipment.assign_loadout(1, false), "Equipment loadout assigned once per actor")
	equipment.assign_loadout(2, true)
	check(equipment.value_at(EquipmentLedger.Location.CARRIED, 1) == 6 and equipment.value_at(EquipmentLedger.Location.CARRIED, 2) == 1, "Responder equipment is substantially less valuable than ordinary loadouts")
	check(equipment.resolve(1) and not equipment.resolve(1), "Accepted death moves equipment to ground exactly once")
	check(equipment.recover(1) and not equipment.recover(1) and equipment.is_valid(), "Identified equipment cannot be credited twice")
	check(equipment.resolve(2, true) and equipment.count_at(EquipmentLedger.Location.EXTRACTED) == 1, "Extracted loadout is recorded without creating a ground drop")
	equipment.seal()
	check(not equipment.assign_loadout(3, false) and not equipment.resolve(3), "Sealed equipment rejects late allocations and transfers")
	var ledger := MaterialLedger.new({&"A": 9}, [1])
	check(ledger.register_raider(2) and not ledger.register_raider(2) and ledger.total_materials == 9 and ledger.is_conserved(), "Reinforcement registration adds identity without creating materials")
	ledger.defeat(1)
	ledger.defeat(2)
	var policy := MissionRules.new()
	policy.evaluate(ledger, false, 1, 2)
	check(policy.phase == MissionRules.Phase.HUNTING, "Committed reinforcement prevents early mission completion")
	policy.evaluate(ledger, false, 0, 2)
	check(policy.phase == MissionRules.Phase.RECOVERING, "Equipment alone keeps the recovery phase playable")

	var arena := create_arena()
	await frames(8)
	arena.process_entries()
	freeze_actors(arena)
	var director := arena.flare_director as FlareDirector
	var first := arena.raiders[1] as Raider
	var second := arena.raiders[2] as Raider
	var third := arena.raiders[3] as Raider
	arena.robot.position = Vector3(100, 0, 100)
	first.position = Vector3(0, 0.1, 8)
	second.position = Vector3(-3, 0.1, 8)
	third.position = Vector3(20, 0.1, -18)
	await frames(3)
	first.health.apply_damage(100)
	check(director.handled_deaths.size() == 1 and director.equipment_drops.size() == 1 and director.tickets.size() == 1 and director.local_jobs.size() == 1, "Empty Raider death creates gear, one flare, one bounded ticket, and nearby local response")
	check(get_nodes_in_group("death_flares").size() == 1 and arena.ledger.dropped_materials == 0, "Flare/equipment presentation does not invent material cargo")
	director.accepted_death(first)
	check(director.tickets.size() == 1 and get_nodes_in_group("death_flares").size() == 1, "Duplicate death notification cannot duplicate flares or responses")
	arena.elapsed = 1.9
	director.process_responses()
	check(second.state != Raider.State.INVESTIGATING and arena.raiders.size() == 3, "Response delays prevent immediate local convergence or spawning")
	arena.elapsed = 2
	director.process_responses()
	check(second.state == Raider.State.INVESTIGATING and second.investigation_position == Vector3(0, 0.1, 8) and arena.raiders.size() == 3, "Existing nearby Raider investigates before any reinforcement is admitted")
	arena.elapsed = 7.9
	director.process_responses()
	check(director.responder_ids.is_empty(), "Additional units respect the eight-second delay")
	# Block every authored marker, then restore it to verify admission retry.
	var positions: Array[Vector3] = []
	for point in arena.spawn_order:
		positions.append(point.position)
		point.position = Vector3(-8, 0.1, 3)
	arena.elapsed = 8
	director.process_responses()
	check(director.tickets.size() == 1 and director.responder_ids.is_empty(), "Blocked reinforcement stays pending without teleporting")
	for index in range(positions.size()):
		arena.spawn_order[index].position = positions[index]
	director.rules = director.rules.duplicate()
	director.rules.active_cap = 2
	director.process_responses()
	check(director.tickets.size() == 1 and director.living_count() == 2, "Active cap defers due reinforcement even when entry points are clear")
	director.rules.active_cap = 5
	director.process_responses()
	freeze_actors(arena)
	check(director.tickets.is_empty() and director.responder_ids.size() == 1 and arena.ledger.total_materials == 9 and arena.ledger.is_conserved(), "Valid entry admits the armed responder without changing material stock")
	var responder := arena.raiders[4] as Raider
	check(responder.is_flare_responder and director.equipment.value_at(EquipmentLedger.Location.CARRIED, 4) == 1, "Responder has its own low-value ledger-backed loadout")
	responder.health.apply_damage(100)
	second.health.apply_damage(100)
	check(director.committed == 2 and director.tickets.size() == 1 and director.handled_deaths.size() == 3, "Responder and simultaneous ordinary deaths cannot exceed the finite response budget")
	await frames(3)
	arena.elapsed = 16
	director.process_responses()
	freeze_actors(arena)
	check(director.responder_ids.size() == 2 and director.committed == 2, "Second and final reinforcement uses the remaining committed ticket")
	arena.raiders[5].health.apply_damage(100)
	third.health.apply_damage(100)
	check(director.tickets.is_empty() and director.committed == 2 and not arena.mission.is_finished(), "Further deaths still flare and drop loot but cannot create an infinite response chain")
	check(arena.mission.phase == MissionRules.Phase.RECOVERING and director.equipment.ground_count() == 8, "All five resolutions enter equipment-only recovery rather than instant success")
	await frames(3)
	# Same eligible target drives prompt and recovery; all interruptions reset progress.
	var drop := director.equipment_drops[1] as EquipmentDrop
	check(not director.eligible(drop), "Distant equipment is ineligible for both prompt and transfer")
	drop.position = Vector3(-5, 0.1, -5)
	arena.robot.position = Vector3(-9, 0.1, -5)
	await frames(3)
	check(not director.eligible(drop), "Equipment recovery cannot reach through solid cover")
	drop.position = Vector3(0, 0.1, 8)
	arena.robot.position = drop.global_position
	await frames(3)
	var overlapping := director.equipment_drops[2] as EquipmentDrop
	var original_drop_position := overlapping.position
	overlapping.position = drop.position
	check(director.selected_drop() == drop, "Overlapping equipment targets break nearest-distance ties by actor identity")
	overlapping.position = original_drop_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	arena.robot.input_adapter.recover_held = true
	director.update_recovery(0)
	director.update_recovery(0.8)
	check(director.recovery_elapsed > 0 and director.selected_drop() == drop, "Holding E begins recovery on the nearest eligible gear stack")
	arena.robot.input_adapter.recover_held = false
	director.update_recovery(1)
	check(director.recovery_elapsed == 0 and director.equipment.ground_count(1) == 2, "Releasing E cancels progress without consuming items")
	arena.robot.input_adapter.recover_held = true
	director.update_recovery(0)
	director.update_recovery(0.8)
	arena.robot.get_node("Health").apply_damage(10)
	check(director.recovery_elapsed == 0 and director.recovering_id == 0, "Incoming damage immediately interrupts equipment recovery")
	director.update_recovery(0)
	arena.robot.input_adapter.fire_intent = true
	director.update_recovery(1)
	check(director.recovering_id == 0, "Firing prevents equipment recovery")
	arena.robot.input_adapter.fire_intent = false
	director.update_recovery(0)
	arena.robot.position += Vector3(0.5, 0, 0)
	director.update_recovery(1)
	check(director.recovery_elapsed == 0, "Physical movement interrupts recovery even without input intent")
	arena.robot.position = drop.position
	await frames(3)
	director.update_recovery(0)
	director.update_recovery(1.49)
	check(director.equipment.ground_count(1) == 2, "Recovery cannot transfer items before the full hold duration")
	director.update_recovery(0.02)
	check(director.equipment.ground_count(1) == 0 and director.equipment.count_at(EquipmentLedger.Location.RECOVERED) == 2 and director.equipment_drops.size() == 4, "Completed hold transfers exactly one loadout and preserves unrelated drops")
	for remaining in director.equipment_drops.values().duplicate():
		arena.robot.position = remaining.global_position
		await frames(3)
		director.update_recovery(0)
		director.update_recovery(1.51)
	check(arena.mission.phase == MissionRules.Phase.SUCCEEDED and director.equipment.is_valid() and arena.ledger.is_conserved(), "Final equipment recovery completes mission with both ownership invariants intact")
	check(not director.equipment.recover(1) and not arena.ledger.register_raider(99), "Terminal deployment seals both ledgers")
	arena.restart_mission()
	await frames(8)
	arena = current_scene
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	freeze_actors(arena)
	check(arena.scenario_index == 4 and arena.flare_director.committed == 0 and arena.flare_director.equipment.ground_count() == 0, "Restart retains Loot Pressure and resets budget, drops and outcomes")
	director = arena.flare_director
	arena.raiders[1].health.apply_damage(100)
	var budget_before: int = director.committed
	var gear_before: int = director.equipment.ground_count()
	arena.elapsed = arena.mission_duration
	arena._physics_process(0.01)
	director.process_responses()
	check(arena.mission.is_finished() and director.committed == budget_before and director.equipment.ground_count() == gear_before and arena.ledger.lost_materials == 0, "Deadline stops pending responses and preserves unrecovered equipment separately from material loss")
	check(not director.equipment.recover(1) and director.responder_ids.is_empty(), "Deadline seals equipment and cannot admit a late responder")
	arena.queue_free()
	await frames(3)
	# Real physics scheduling exercises the two-second local and eight-second entry.
	arena = create_arena()
	await frames(8)
	arena.process_entries()
	freeze_actors(arena)
	director = arena.flare_director
	arena.robot.position = Vector3(100, 0, 100)
	first = arena.raiders[1]
	second = arena.raiders[2]
	first.position = Vector3(0, 0.1, 8)
	second.position = Vector3(-4, 0.1, 8)
	arena.raiders[3].position = Vector3(20, 0.1, -18)
	await frames(3)
	var local_times: Array[float] = []
	second.state_changed.connect(func(_previous: Raider.State, next: Raider.State) -> void:
		if next == Raider.State.INVESTIGATING:
			local_times.append(arena.elapsed))
	first.health.apply_damage(100)
	var flare := get_nodes_in_group("death_flares")[0] as Node3D
	var began_at: float = arena.elapsed
	second.set_physics_process(true)
	arena.set_physics_process(true)
	director.set_physics_process(true)
	Engine.time_scale = 3
	await frames(25)
	check(flare.beacon.position.y > 0.3 and flare.is_inside_tree(), "Cosmetic flare visibly rises during natural simulation")
	for index in range(220):
		if director.responder_ids.size() > 0:
			break
		await frames(1)
	check(not local_times.is_empty() and local_times[0] - began_at >= 2 and local_times[0] - began_at < 8, "Natural scheduling notifies an existing Raider before reinforcements")
	check(director.responder_ids.size() == 1 and arena.elapsed - began_at >= 8 and arena.ledger.is_conserved() and director.equipment.is_valid(), "Natural delayed admission preserves both ledgers")
	var ground_at_death: int = director.equipment.ground_count()
	arena.robot.get_node("Health").apply_damage(1000)
	director.process_responses()
	check(arena.mission.player_destroyed and not director.is_physics_processing() and director.equipment.ground_count() == ground_at_death and not director.equipment.recover(1), "Player destruction stops responses and seals unrecovered equipment without mutation")
	Engine.time_scale = 1
	arena.queue_free()
	await frames(3)
	print("Stage F checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
