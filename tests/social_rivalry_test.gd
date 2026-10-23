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


func run() -> void:
	var ledger := MaterialLedger.new({&"Salvage": 9}, [1, 2, 3])
	var relations := RaiderRelations.new(ledger)
	check(relations.attitude(1, 2) == RaiderRelations.Attitude.NEUTRAL, "Unspecified relationship defaults to neutral")
	check(not relations.set_attitude(1, 99, RaiderRelations.Attitude.HOSTILE, "invalid", 0) and not relations.set_attitude(1, 1, RaiderRelations.Attitude.ALLIED, "self", 0), "Unknown and self relationships are rejected")
	check(relations.set_attitude(1, 2, RaiderRelations.Attitude.ALLIED, "independent alliance", 0) and relations.attitude(2, 1) == RaiderRelations.Attitude.ALLIED, "Explicit alliance is symmetric and does not require squad registration")
	check(not relations.set_attitude(2, 1, RaiderRelations.Attitude.ALLIED, "duplicate", 0), "Duplicate relation event is rejected")
	var history := relations.events()
	history[0].reason = "mutated copy"
	check(relations.events()[0].reason == "independent alliance" and ledger.accepted_transfers == 0, "Relation diagnostics are detached and cannot change materials")
	ledger.defeat(3)
	check(not relations.set_attitude(1, 3, RaiderRelations.Attitude.HOSTILE, "late", 1), "Resolved Raider cannot initiate a new pair relationship")
	relations.seal()
	check(not relations.set_attitude(1, 2, RaiderRelations.Attitude.HOSTILE, "sealed", 1), "Sealed relations reject late transitions")
	var rules := RaiderSocialConfig.new()
	rules.allied_pairs = [Vector2i(1, 2)]
	rules.hostile_pairs = [Vector2i(2, 1)]
	check(not rules.validation_error(3).is_empty(), "Conflicting authored pairs fail setup validation")
	var arena := load("res://scenes/levels/social_rivalry_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	await frames(10)
	arena.process_entries()
	for other in arena.raiders.values():
		other.set_physics_process(false)
		other.combat.weapon.set_physics_process(false)
	check(arena.pending_ids.is_empty() and arena.raiders.size() == 3 and arena.ledger.total_materials == 9, "Social preset admits three Raiders with nine preallocated materials")
	check(arena.flare_director == null and arena.ecosystem == null and arena.recall == null and arena.robot.traversal_enabled, "Rivalry retains player traversal without flares, persistence or support machines")
	var a := arena.raiders[1] as Raider
	var b := arena.raiders[2] as Raider
	var c := arena.raiders[3] as Raider
	check(a.squad_id.is_empty() and b.squad_id.is_empty() and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED, "Allied Raiders remain independent actors with no permanent squad")
	arena.robot.position = Vector3(100, 0.1, 100)
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(-15, 0.1, 14)
	c.position = Vector3(0, 0.1, 14)
	a.combat.profile = a.combat.profile.duplicate()
	a.combat.profile.spread_degrees = 0
	await frames(3)
	a.decide()
	check(a.current_target() == c and a.state == Raider.State.ENGAGING, "Raider selects visible hostile human with distant robot")
	a.combat.tick(0.1)
	check(c.health.current == 100, "Rival shot retains normal aim warning")
	a.combat.tick(a.combat.profile.warning_time)
	check(c.health.current == 90 and c.health.last_damage_instigator_id == a.get_instance_id(), "Physical rival hit deals ten damage and records actual instigator identity")
	check(c.last_threat_position.is_equal_approx(a.combat.weapon.muzzle.global_position), "Damage response uses hit origin rather than distant player position")
	a.combat.weapon.cooldown = 0
	b.position = Vector3(0, 0.1, 11)
	await frames(3)
	a.combat.weapon.try_fire_at(c.global_position + Vector3.UP)
	check(b.health.current == 100 and c.health.current == 90, "Allied body blocks rival shot without friendly damage or penetration")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.NEUTRAL, "neutral competition test", 1)
	a.combat.weapon.cooldown = 0
	a.combat.weapon.try_fire_at(b.global_position + Vector3.UP)
	check(b.health.current == 100 and b.health.last_damage_instigator_id == 0, "Neutral body is protected from damage and receives no false hit attribution")
	b.position = Vector3(-15, 0.1, 14)
	arena.social.relations.set_attitude(1, 3, RaiderRelations.Attitude.NEUTRAL, "ceasefire test", 1)
	await frames(3)
	a.decide()
	check(a.current_target() != c and not a.detects_current_target(), "No-longer-hostile target loses combat eligibility and aim")
	arena.social.relations.set_attitude(1, 3, RaiderRelations.Attitude.HOSTILE, "rivalry resumes", 1)
	a.decide()
	check(a.current_target() == c and a.combat.aim_elapsed == 0, "Resuming rivalry requires a fresh target warning")
	# Block line of sight with the actual graybox obstacle.
	a.position = Vector3(-7, 0.1, -9)
	c.position = Vector3(-7, 0.1, -1)
	await frames(3)
	check(not a.detects_actor(c), "Solid geometry blocks rival perception")
	# Neutral relationship does not reserve salvage or share cargo.
	a.position = arena.get_node("Salvage").position
	b.position = a.position + Vector3(0.5, 0, 0)
	c.position = Vector3(18, 0.1, -18)
	a.threat_remaining = 0
	b.threat_remaining = 0
	await frames(3)
	check(arena.choose_salvage(1) == arena.get_node("Salvage") and arena.choose_salvage(2) == arena.get_node("Salvage"), "Neutral Raiders can both choose the same finite salvage stock")
	for actor in [a, b]:
		actor.salvage = arena.get_node("Salvage")
		actor.transition(Raider.State.SCAVENGING)
		actor.task_elapsed = actor.scavenge_seconds
		arena._on_collection_requested(actor)
	check(arena.ledger.cargo_for(1) == 3 and arena.ledger.cargo_for(2) == 0 and arena.ledger.is_conserved(), "First neutral competitor collects stock; second cannot duplicate or share it")
	check(arena.choose_salvage(2) != arena.get_node("Salvage"), "Depleted contested stock makes neutral competitor select another objective")
	var spectator := arena.spectator as DeveloperSpectator
	spectator.enter()
	spectator.set_process(false)
	spectator.selected = a
	arena.debug_visible = true
	arena.refresh_hud()
	spectator.refresh_indicator()
	check(spectator.indicator.text.contains("NEUTRAL") and spectator.indicator.text.contains("Squad: none"), "Spectator exposes relationships separately from absent squad membership")
	spectator.leave()
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.ALLIED, "temporary alliance against machine", 2)
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(2, 0.1, 8)
	arena.robot.position = Vector3(0, 0.1, 14)
	arena.robot.set_physics_process(false)
	b.combat.profile = b.combat.profile.duplicate()
	b.combat.profile.spread_degrees = 0
	await frames(3)
	a.decide()
	b.decide()
	check(a.current_target() == arena.robot and b.current_target() == arena.robot and a.squad_id.is_empty() and b.squad_id.is_empty(), "Allied Raiders can independently attack the same machine without permanent squad membership")
	arena.robot.position = Vector3(100, 0.1, 100)
	a.health.apply_damage(1000)
	b.health.apply_damage(1000)
	await frames(3)
	check(c.health.current == 90 and arena.ledger.dropped_materials == 3 and arena.ledger.is_conserved(), "Simultaneous rival scenario deaths preserve independent health and normal cargo drops")
	c.decide()
	check(is_instance_valid(c.current_target()), "Combat remains safe after targets are freed")
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(not arena.social.relations.set_attitude(1, 3, RaiderRelations.Attitude.ALLIED, "late", 999) and not c.combat.weapon.enabled, "Terminal policy seals relations and stops all hostile weapons")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	arena.set_physics_process(false)
	arena.process_entries()
	for other in arena.raiders.values():
		other.set_physics_process(false)
		other.combat.weapon.set_physics_process(false)
	check(arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED and arena.ledger.protected_materials == 9, "Restart restores authored attitudes and finite stock")
	# Run actual common FSM/physics without forcing targets or health.
	# Isolate the autonomous rivalry from a stationary player who is otherwise
	# a valid opponent within rifle range of the authored entry positions.
	arena.robot.set_physics_process(false)
	arena.robot.position = Vector3(100, 0.1, 100)
	var damaged := false
	var combat_death := false
	for actor in arena.raiders.values():
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	var robot_origin: Vector3 = arena.robot.position
	for index in range(300):
		await frames(1)
		for actor in arena.raiders.values():
			if is_instance_valid(actor) and actor.health.current < actor.health.maximum:
				damaged = true
			if not is_instance_valid(actor):
				combat_death = true
	check(damaged and arena.robot.get_node("Health").current == 100 and arena.robot.position.distance_to(robot_origin) < 0.2, "Authored rivalry produces natural human combat without player intervention")
	check(combat_death, "Natural rival weapon combat can defeat a Raider through the shared death path")
	check(arena.ledger.is_conserved(), "Natural rivalry maintains material conservation")
	arena.select_scenario(3)
	await frames(12)
	arena = current_scene
	check(arena.social == null and arena.raiders[1].combat.weapon.damage_mask == 2, "Existing Survival retains its original Raider-friendly damage configuration")
	arena.queue_free()
	await frames(30)
	print("Stage K social rivalry checks complete; failures: ", failures)
	quit(1 if failures else 0)
