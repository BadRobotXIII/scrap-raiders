extends "res://tests/personality_combat_test.gd"
## Reuses controlled-scene helpers; this suite overrides the base run entirely.


func run() -> void:
	directory = "res://.godot/stage_q_integration/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var arena := await create("integration")
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	reset_actor(a, "aggressive")
	await frames(3)
	a.decide()
	var position_before := a.position
	var observed_before := a.combat.observed_position
	var transfers: int = arena.ledger.accepted_transfers
	check(arena.spectator.enter(), "Q comparison permits existing developer spectator")
	arena.spectator.set_process(false)
	arena.spectator.camera.position = a.position + Vector3(0.1, 1, 0.1)
	a.decide()
	check(a.position == position_before and a.current_target() == guard and a.combat.observed_position == observed_before and arena.ledger.accepted_transfers == transfers, "Camera proximity cannot change Q target, observation, movement or ownership")
	arena.spectator.leave()
	# Lose line of sight and then exercise the actual navigation failure path.
	guard.position = Vector3(100, 0.1, 100)
	await frames(3)
	a.decide()
	check(a.combat.pursuing, "Valid unseen observation starts pursuit without tracking live target")
	a.recover_navigation(a.investigation_position)
	a.recover_navigation(a.investigation_position)
	a.decide()
	check(not a.combat.pursuing and a.state == Raider.State.SCAVENGING, "Failed pursuit route releases intent instead of trapping SELECTING until timeout")
	# Rival eligibility remains a relationship decision, not a personality rule.
	reset_actor(a, "aggressive")
	b.position = Vector3(0, 0.1, 15)
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.HOSTILE, "test hostility", 1)
	await frames(3)
	a.decide()
	check(a.current_target() == b and a.state == Raider.State.ENGAGING, "Aggressive can independently select a visible hostile Raider")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.NEUTRAL, "test ceasefire", 2)
	a.decide()
	check(not a.combat.observation_valid() and not a.combat.owns_state(), "Ceasefire invalidates combat interest without creating new hostility")
	guard.position = Vector3(0, 0.1, 15)
	b.position = Vector3(18, 0.1, -18)
	await frames(3)
	a.decide()
	guard.health.apply_damage(10000)
	await frames(3)
	a.decide()
	check(not a.combat.observation_valid() and a.state == Raider.State.SCAVENGING and arena.ledger.is_conserved(), "Destroyed machine releases combat interest and its preallocated component exactly once")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.HOSTILE, "test resumes", 3)
	b.position = Vector3(0, 0.1, 15)
	await frames(3)
	a.decide()
	b.transition(Raider.State.EXTRACTED)
	b.extracted.emit(b.carried_materials)
	b.queue_free()
	await frames(3)
	a.decide()
	check(not a.combat.observation_valid() and a.state == Raider.State.SCAVENGING, "Extracted rival releases target safely after node cleanup")
	# The response path uses configured Q copies even beyond initial layout IDs.
	a.health.apply_damage(1000)
	await frames(3)
	arena.elapsed = 8
	arena.flare_director.process_responses()
	var responder := arena.raiders.get(6) as Raider
	check(is_instance_valid(responder) and responder.profile.combat_policy != RaiderProfile.CombatPolicy.BASELINE and arena.flare_director.committed == 1, "Finite flare responder uses opted-in fallback profile with unchanged response budget")
	freeze(arena)
	var snapshot: Dictionary = arena.encounter.snapshot.duplicate(true)
	var stash: String = arena.stash_path
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 14 and arena.stash_path == stash and arena.encounter.snapshot == snapshot and arena.ledger.protected_materials == 14 and arena.flare_director.committed == 0, "Q restart preserves preset, seed and isolated stash while resetting actors and accounting")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F5
	key.pressed = true
	key.shift_pressed = true
	key.ctrl_pressed = true
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 14 and arena.debug_seed == 87018, "Next-seed control retains Q comparison mode")
	key.ctrl_pressed = false
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 13 and arena.debug_seed == 87018, "Q-to-P comparison preserves the chosen seed")
	key.alt_pressed = true
	arena._unhandled_input(key)
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.scenario_index == 14 and arena.debug_seed == 87018, "P-to-Q comparison preserves the same authored opportunity layout")
	arena.process_entries()
	freeze(arena)
	a = arena.raiders[1]
	a.position = Vector3(0, 0.1, 8)
	arena.robot.position = Vector3(100, 0.1, 100)
	var pickup: int = arena.ledger.release_source(&"ScoutComponents")
	arena.ledger.recover(pickup)
	var before_death: int = arena.ledger.accepted_transfers
	arena.robot.get_node("Health").apply_damage(1000, a.position, a.get_instance_id())
	arena.recall.settle_failure()
	check(arena.mission.player_destroyed and not arena.mission.is_world_finished() and arena.ledger.forfeited_materials == 1, "Q player death irreversibly forfeits recovered loot once while world remains active")
	check(arena.ledger.accepted_transfers == before_death + 1 and arena.post_death.enter(), "One settlement permits existing restricted post-death follow mode")
	arena.post_death.set_physics_process(false)
	var policy := a.combat.describe_policy()
	var ownership: int = arena.ledger.accepted_transfers
	arena.post_death.cycle(1)
	arena.post_death.step()
	check(a.combat.describe_policy() == policy and arena.ledger.accepted_transfers == ownership and not arena.recall.complete(), "Post-death target cycling cannot change policy, accounting or failed deployment")
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(arena.mission.is_world_finished() and not arena.post_death.active and not a.combat.weapon.enabled and a.combat.escape_remaining == 0 and arena.ledger.is_conserved(), "Deadline while observing stops policy timers and actors without a second settlement")
	arena.select_scenario(13)
	await frames(12)
	arena = current_scene
	freeze(arena)
	arena.process_entries()
	freeze(arena)
	check(arena.scenario_index == 13 and arena.config.fallback_profiles.is_empty() and arena.raiders[1].profile.combat_policy == RaiderProfile.CombatPolicy.BASELINE, "Returning to accepted P restores baseline profiles without leaked Q state")
	arena.queue_free()
	await frames(30)
	# Observe both complete configurations naturally. No winner, betrayal or
	# particular material outcome is required; all scheduling remains bounded.
	for seed_value in [87017, 87018]:
		arena = load("res://scenes/levels/personality_encounters_arena.tscn").instantiate()
		arena.seed_override = seed_value
		arena.stash_path = directory + "/natural_%d.json" % seed_value
		root.add_child(arena)
		current_scene = arena
		freeze(arena)
		await frames(10)
		arena.process_entries()
		for actor in arena.raiders.values():
			actor.set_physics_process(true)
			actor.combat.weapon.set_physics_process(true)
		for machine in arena.ecosystem.machines:
			machine.set_physics_process(true)
			if machine.weapon != null:
				machine.weapon.set_physics_process(true)
		arena.set_physics_process(true)
		arena.flare_director.set_physics_process(true)
		arena.encounter.set_physics_process(true)
		arena.recall.set_physics_process(true)
		arena.robot.set_physics_process(false)
		arena.robot.input_adapter.set_physics_process(false)
		arena.robot.input_adapter.set_process_input(false)
		arena.robot.position = Vector3(100, 0.1, 100)
		Engine.time_scale = 8
		var moving := false
		var policy_activity := false
		var positions := {}
		var invariants := true
		for index in range(1100):
			await frames(1)
			var live := 0
			for actor in arena.raiders.values():
				if not is_instance_valid(actor):
					continue
				live += 1
				if positions.has(actor.raider_id) and actor.position.distance_to(positions[actor.raider_id]) > 0.1:
					moving = true
				positions[actor.raider_id] = actor.position
				policy_activity = policy_activity or actor.combat.escaping or actor.combat.defending or actor.combat.pursuing or actor.combat.owns_state()
			invariants = invariants and live <= 5 and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid()
		Engine.time_scale = 1
		check(invariants and moving and policy_activity and arena.elapsed > 105, "Natural Q layout %d sustains autonomous activity with finite population and conserved ownership" % seed_value)
		print("Q NATURAL seed %d | %s | time %.1f | entered %d | lost %d | stock %d | %s" % [seed_value, arena.encounter.layout.layout_id, arena.elapsed, arena.entry_log.size(), arena.ledger.lost_materials, arena.ledger.protected_materials, arena.mission.reason])
		arena.queue_free()
		await frames(30)
	print("Stage Q integration checks complete; failures: ", failures)
	quit(1 if failures else 0)
