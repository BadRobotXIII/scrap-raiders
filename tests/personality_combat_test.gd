extends SceneTree

var failures: int = 0
var directory: String


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


func freeze(arena: Node3D) -> void:
	arena.set_physics_process(false)
	arena.encounter.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			actor.combat.weapon.set_physics_process(false)
			if actor.betrayal != null:
				actor.betrayal.spent = true
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)


func create(label: String, seed_value: int = 87017) -> Node3D:
	var arena := load("res://scenes/levels/personality_encounters_arena.tscn").instantiate() as Node3D
	arena.seed_override = seed_value
	arena.stash_path = directory + "/" + label + ".json"
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	for actor in arena.raiders.values():
		actor.position = Vector3(18, 0.1, -18)
	arena.ecosystem.machines[0].position = Vector3(100, 4, 100)
	var guard: SupportMachine = arena.ecosystem.machines[1]
	guard.position = Vector3(0, 0.1, 15)
	guard.health.maximum = 1000
	guard.health.current = 1000
	await frames(3)
	return arena


func reset_actor(actor: Raider, style: String) -> void:
	actor.set_physics_process(false)
	actor.combat.stop()
	actor.profile = load("res://resources/enemies/q_%s.tres" % style).duplicate()
	actor.transition(Raider.State.SELECTING)
	actor.position = Vector3(0, 0.1, 8)
	actor.velocity = Vector3.ZERO
	actor.health.current = actor.health.maximum
	actor.threat_remaining = 0
	actor.threat_source = "none"
	actor.combat_target = null
	actor.blocked_exits.clear()
	actor.blocked_salvage.clear()
	actor.select_extraction = actor.get_parent().choose_extraction
	actor._retry_remaining = 0
	actor.combat.weapon.enabled = true
	actor.combat.weapon.cooldown = 0
	actor.combat.profile = actor.combat.profile.duplicate()
	actor.combat.profile.spread_degrees = 0
	actor.combat.reserve_cover = func(_id: int) -> Node3D: return null
	actor.combat.retreat_remaining = 0
	actor.combat.reposition_elapsed = 0
	actor.combat.weapon.set_physics_process(false)


func run() -> void:
	directory = "res://.godot/stage_q_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var p: MissionConfig = load("res://resources/missions/emergent_encounters.tres")
	var q: MissionConfig = load("res://resources/missions/personality_encounters.tres")
	check(q.validation_error().is_empty() and p.fallback_profiles.is_empty(), "Q configuration validates without changing P fallback profiles")
	for index in range(p.encounter_layouts.size()):
		var before := p.encounter_layouts[index]
		var after := q.encounter_layouts[index]
		check(before.layout_id == after.layout_id and before.salvage_markers == after.salvage_markers and before.salvage_quantities == after.salvage_quantities and before.entry_markers == after.entry_markers and before.machine_routes == after.machine_routes, "Q preserves P layout, stock, entries and patrols")
		for actor_index in range(before.profiles.size()):
			check(before.profiles[actor_index].combat_policy == RaiderProfile.CombatPolicy.BASELINE and after.profiles[actor_index].combat_policy != RaiderProfile.CombatPolicy.BASELINE, "Only copied Q profiles opt into personality combat")
	var malformed := q.fallback_profiles[0].duplicate() as RaiderProfile
	malformed.escape_commit_seconds = NAN
	check(not malformed.validation_error().is_empty(), "Nonfinite commitment tuning is rejected")
	var arena := await create("decisions")
	var a: Raider = arena.raiders[1]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	reset_actor(a, "greedy")
	await frames(3)
	a.decide()
	check(a.state == Raider.State.SCAVENGING and a.current_target() == guard, "Greedy prioritizes salvage over the same optional seven-metre fight")
	var slot := Marker3D.new()
	arena.add_child(slot)
	slot.position = Vector3(-6.5, 0, 5.5)
	a.combat.cover = slot
	a.combat.destination = slot
	a.transition(Raider.State.TAKING_COVER)
	a.combat.observation_remaining = 0
	guard.position = Vector3(100, 0.1, 100)
	await frames(3)
	a.decide()
	check(a.state == Raider.State.TAKING_COVER and a.combat.destination == slot, "Greedy finishes selected cover work instead of switching to salvage during occlusion")
	guard.position = Vector3(0, 0.1, 15)
	reset_actor(a, "cowardly")
	await frames(3)
	a.decide()
	var escape := a.combat.escape_remaining
	for index in range(10):
		a.decide()
	check(a.state == Raider.State.FLEEING and a.combat.escaping and a.combat.escape_remaining == escape, "Cowardly initiates and retains escape rather than repeatedly restarting it")
	var origin := a.position
	a.set_physics_process(true)
	await frames(100)
	a.set_physics_process(false)
	check(a.position.distance_to(origin) > 3 and a.combat.escaping, "Cautious intent executes actual physical escape movement")
	guard.position = Vector3(100, 0.1, 100)
	await frames(3)
	a.decide()
	check(a.combat.escaping, "Brief loss of sight does not cancel escape commitment")
	a.combat.escape_remaining = 0
	a.combat.observation_remaining = 0
	a.hear_gunfire(a.position + Vector3(1, 0, 0))
	a.decide()
	check(a.combat.escaping and a.combat.escape_remaining == 0, "Fresh audible danger retains escape without restarting its commitment timer")
	a.threat_remaining = 0
	a.decide()
	check(not a.combat.escaping and a.state == Raider.State.SCAVENGING, "Safe empty Raider resumes independent objectives after escape and observation expire")
	guard.position = Vector3(0, 0.1, 15)
	reset_actor(a, "cowardly")
	a.select_extraction = func(_id: int) -> Node3D: return null
	await frames(3)
	a.decide()
	check(a.combat.escaping and a.combat.escape_blocked and a.state == Raider.State.ENGAGING, "No reachable exit makes cautious Raider defend without forgetting escape")
	a.combat.tick(a.combat.profile.warning_time + 0.01)
	check(guard.health.current == 990, "Blocked escape permits a real defensive rifle hit")
	a.combat.cover = slot
	a.combat.destination = slot
	a.transition(Raider.State.TAKING_COVER)
	a._retry_remaining = 0
	a.decide()
	check(a.state == Raider.State.TAKING_COVER and a.combat.destination == slot and a.combat.escape_blocked and a._retry_remaining > 0, "Failed escape retry preserves active defensive cover work")
	var blocked_timer := a._retry_remaining
	a.health.apply_damage(1, guard.get_aim_position(), guard.get_instance_id())
	check(a.combat.escaping and a._retry_remaining == blocked_timer, "Repeated damage does not restart blocked-exit retry timing")
	a.select_extraction = arena.choose_extraction
	a._retry_remaining = 0
	a.decide()
	check(a.state == Raider.State.FLEEING and not a.combat.escape_blocked, "Reopened escape resumes physical retreat instead of remaining in combat")
	reset_actor(a, "aggressive")
	await frames(3)
	a.decide()
	check(a.state == Raider.State.ENGAGING and a.combat.observation_valid(), "Aggressive engages the same optional visible opponent")
	var observation := a.combat.observed_position
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 3, 0.4)
	collision.shape = shape
	wall.add_child(collision)
	arena.add_child(wall)
	wall.position = Vector3(0, 1.5, 11)
	await frames(3)
	a.decide()
	var snapshot := a.investigation_position
	check(a.state == Raider.State.INVESTIGATING and a.combat.pursuing, "Aggressive pursues a saved sighting after physical occlusion")
	guard.position = Vector3(5, 0.1, 15)
	await frames(3)
	a.hear_gunfire(Vector3(-5, 1, 14))
	a.decide()
	check(a.combat.observed_position == observation and a.investigation_position == snapshot and not a.detects_current_target(), "Unseen movement and gunfire cannot relocate the pursuit snapshot")
	check(not a.consider_allied_report(Vector3(-10, 0, 10), 4) and not a.investigate_flare(Vector3(-12, 0, 12)) and a.investigation_position == snapshot, "Lower-priority allied and flare reports cannot replace committed pursuit")
	var hull := guard.health.current
	a.combat.tick(0.8)
	check(guard.health.current == hull, "Occluded pursuit cannot fire a tracking shot")
	a.combat.tick(a.profile.threat_memory + 0.1)
	a.decide()
	check(not a.combat.pursuing and a.state == Raider.State.SCAVENGING, "Pursuit expires despite unrelated gunfire memory")
	wall.queue_free()
	guard.position = Vector3(0, 0.1, 15)
	await frames(3)
	reset_actor(a, "aggressive")
	await frames(3)
	a.decide()
	a.health.apply_damage(75, guard.get_aim_position(), guard.get_instance_id())
	check(a.state == Raider.State.FLEEING and a.combat.escaping, "Critical survival overrides aggressive commitment")
	var diagnostics := a.combat.describe_policy()
	check(diagnostics.contains("AGGRESSIVE") and diagnostics.contains("escape") and arena.social.describe(a).contains(diagnostics), "Developer inspection explains policy and authoritative commitment timers")
	check(arena.ledger.is_conserved() and arena.recall.stash.snapshot().materials == 0, "Policy-only decisions cannot alter ownership or stash")
	arena.queue_free()
	await frames(30)
	# Run a real collection, bounded defense and timed extraction with one
	# material allocation. No direct cargo creation or actor quantity writes.
	arena = await create("cargo")
	a = arena.raiders[1]
	guard = arena.ecosystem.machines[1]
	reset_actor(a, "greedy")
	guard.position = Vector3(100, 0.1, 100)
	a.position = arena.get_node("Salvage").position + Vector3(0, 0.1, 0)
	await frames(3)
	a.set_physics_process(true)
	await frames(220)
	a.set_physics_process(false)
	check(a.carried_materials == 6 and arena.ledger.protected_materials == 8 and arena.ledger.is_conserved(), "Natural Greedy scavenging physically collects the finite six-unit stock")
	reset_actor(a, "greedy")
	guard.position = Vector3(0, 0.1, 15)
	await frames(3)
	a.decide()
	check(a.combat.escaping and a.state == Raider.State.FLEEING, "The same visible threat makes loaded Greedy preserve its actual cargo")
	reset_actor(a, "greedy")
	await frames(3)
	a.health.apply_damage(1, guard.get_aim_position(), guard.get_instance_id())
	a.decide()
	check(a.combat.defending and not a.combat.escaping and a.state == Raider.State.ENGAGING, "Observed attacker triggers bounded Greedy defense even while carrying cargo")
	var commit := a.combat.commit_remaining
	a.health.apply_damage(1, guard.get_aim_position(), guard.get_instance_id())
	check(a.combat.commit_remaining == commit, "Repeated hits cannot extend Greedy defense indefinitely")
	a.combat.weapon.set_physics_process(true)
	a.set_physics_process(true)
	await frames(100)
	a.set_physics_process(false)
	check(guard.health.current < 1000 and a.carried_materials == 6, "Bounded defense fires actual shots without transferring carried materials")
	a.combat.commit_remaining = 0
	a.decide()
	check(a.combat.escaping and a.state == Raider.State.FLEEING, "Greedy disengages to preserve cargo after completing defense")
	guard.position = Vector3(100, 0.1, 100)
	a.position = a.extraction.position + Vector3(0, 0.1, 1.5)
	await frames(3)
	a.set_physics_process(true)
	await frames(300)
	check(not is_instance_valid(a) and arena.ledger.lost_materials == 6 and arena.ledger.carried_materials == 0 and arena.ledger.is_conserved(), "Physical escape and timed extraction settle exactly the six stolen units once")
	check(arena.recall.stash.snapshot().materials == 0, "AI extraction never banks player rewards")
	arena.queue_free()
	await frames(30)
	print("Stage Q personality combat checks complete; failures: ", failures)
	quit(1 if failures else 0)
