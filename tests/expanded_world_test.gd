extends "res://tests/gameplay_integration_test.gd"
## U-specific physical geometry and lifecycle regressions; isolated finite fixtures.

const U_SCENE := "res://scenes/levels/expanded_salvage_complex.tscn"

func create_u(label: String, seed_value: int = 87017) -> Node3D:
	var arena := load(U_SCENE).instantiate() as Node3D
	# U's original physical/material contract remains a legacy-content fixture.
	arena.mission_config_override = load("res://resources/missions/expanded_asset_recovery.tres").duplicate(true)
	arena.mission_config_override.hybrid_inventory = false
	arena.stash_path = test_directory + "/" + label + ".json"
	arena.seed_override = seed_value
	root.add_child(arena)
	current_scene = arena
	arena.ledger.transfer_accepted.connect(audit_transfer.bind(arena))
	arena.flare_director.equipment.transfer_accepted.connect(audit_transfer.bind(arena))
	return arena

func park_world(arena: Node3D) -> void:
	park_actors(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(100, 3, 100)

func scene_contract() -> void:
	for seed_value in [87017, 87018]:
		var arena := create_u("contract_%d" % seed_value, seed_value)
		await frames(12)
		check(not arena.deployment_started and arena.elapsed == 0 and arena.raiders.is_empty(), "U briefing gates simulation and initial arrivals")
		check(arena.config.validation_error().is_empty() and arena.ledger.total_materials == 14 and arena.extraction_points.size() == 2, "U config preserves finite stock, two exits and mission rules")
		await start_frozen(arena)
		park_world(arena)
		await frames(3)
		check(arena.encounter.validate_navigation().is_empty(), "U selected stock and both patrols pass production navigation validation")
		var valid := true
		for marker in arena.get_node("RaiderSpawns").get_children():
			valid = valid and arena.entry_is_valid(marker.position)
		for marker in arena.get_node("EncounterSites").get_children():
			valid = valid and arena.encounter.ground_valid(marker.position) and arena.encounter.geometry_clear(marker.position, false)
		for cover in arena.get_node("CoverPoints").get_children():
			valid = valid and arena.encounter.ground_valid(cover.global_position) and arena.encounter.ground_valid(cover.get_node("Peek").global_position)
		for marker in arena.extraction_points + [arena.get_node("RecallDock")]:
			valid = valid and arena.encounter.ground_valid(marker.position)
		check(valid, "Every U entry, alternate stock site, exit and dock has supported connected navigation")
		var route := arena.get_node("ScoutRoute").get_children()
		var clear := true
		for index in range(route.size()):
			var query := PhysicsRayQueryParameters3D.create(route[index].position, route[(index + 1) % route.size()].position, 1)
			clear = clear and arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		check(clear, "Every outdoor scout leg is clear between endpoints")
		check(arena.raiders.size() == 2 and arena.robot.traversal_enabled and arena.social != null and arena.post_death != null, "U Deploy retains accepted gameplay composition")
		arena.queue_free()
		await frames(8)

func distant_collection() -> void:
	var arena := create_u("travel")
	await start_frozen(arena)
	park_world(arena)
	var actor: Raider = arena.raiders[1]
	var target := arena.get_node("Salvage3") as Node3D
	# Physical journey across the service route and the south loading ramp.
	target.position = Vector3(22, 1, 0)
	actor.position = Vector3(-26, 0.1, 20)
	actor.salvage = target
	actor.transition(Raider.State.SCAVENGING)
	await frames(3)
	actor.set_physics_process(true)
	var reached := false
	for index in range(2400):
		await frames(1)
		if actor.carried_materials > 0:
			reached = true
			break
	print("U TRAVEL ARRIVAL ", actor.position, " stock ", actor.salvage.name, " cargo ", actor.carried_materials)
	check(reached and actor.position.y > 0.8, "Raider physically crosses expanded level and ramps to collect finite raised stock")
	actor.set_physics_process(false)
	actor.extraction = arena.get_node("Extraction2")
	actor.transition(Raider.State.EXTRACTING)
	actor.set_physics_process(true)
	for index in range(1600):
		await frames(1)
		if not is_instance_valid(actor):break
	check(not arena.ledger.is_active(1) and arena.ledger.lost_materials > 0, "Loaded Raider physically descends and completes distant exit dwell")
	arena.queue_free()
	await frames(12)

func player_platform() -> void:
	var arena := create_u("ramps")
	await start_frozen(arena)
	park_world(arena)
	var robot: RobotController = arena.robot
	robot.position = Vector3(22, 0.1, -12)
	robot.camera_rig.rotation.y = 0
	robot.input_adapter.gameplay_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	robot.input_adapter.move_intent = Vector2(0, 1)
	robot.set_physics_process(true)
	await frames(95)
	check(robot.position.y > 0.8 and robot.position.z > -3, "Player physically ascends north loading ramp without new traversal mechanics")
	await frames(120)
	check(robot.position.y < 0.3 and robot.position.z > 11, "Player traverses deck and descends independent south ramp")
	robot.set_physics_process(false)
	robot.input_adapter.clear_intent()
	arena.queue_free()
	await frames(12)

func settlement_and_replay() -> void:
	var arena := create_u("settlement")
	await start_frozen(arena)
	park_world(arena)
	var victim: Raider = arena.raiders[1]
	victim.position = Vector3(0, 0.1, 20)
	arena.robot.position = victim.position
	arena.ledger.collect(1, &"Salvage", 3)
	victim.health.apply_damage(1000, victim.position, arena.robot.get_instance_id())
	await frames(3)
	check(arena.try_recover(), "U player recovers finite cargo through physical drop interaction")
	await finish_recall(arena)
	check(arena.mission.player_extracted and arena.ledger.banked_materials == 3 and arena.recall.stash.snapshot().materials == 3, "U objectives, Recall Dock and one-time persistent banking coexist")
	var result: Dictionary = arena.mission_objectives.result()
	arena.finish_mission()
	check(arena.mission_objectives.result() == result, "U repeated finish preserves immutable settled result")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	check(arena.scene_file_path == U_SCENE and arena.config.mission_id == &"expanded_asset_recovery" and not arena.deployment_started and arena.debug_seed == 87017, "U restart retains scene/config/seed and fresh briefing")
	await start_frozen(arena)
	arena.select_scenario(16, 87018, true)
	await frames(12)
	arena = current_scene
	check(arena.scene_file_path == U_SCENE and arena.debug_seed == 87018 and arena.config.seed == 87017 and arena.raiders.is_empty(), "U next seed preserves expanded scene without mutating config")
	await start_frozen(arena)
	park_world(arena)
	var carrier: Raider = arena.raiders[1]
	carrier.position = Vector3(0, 0.1, 20)
	arena.robot.position = carrier.position
	arena.ledger.collect(1, &"Salvage", 3)
	carrier.health.apply_damage(1000, carrier.position, 0)
	await frames(3)
	check(arena.try_recover(), "U failure fixture carries recovered finite cargo")
	arena.robot.get_node("Health").apply_damage(1000, Vector3.ZERO, 0)
	var frozen: Dictionary = arena.mission_objectives.result()
	check(arena.mission.player_destroyed and not arena.mission.is_world_finished(), "U player death leaves autonomous world active")
	arena.post_death.enter()
	check(arena.post_death.active, "U normal post-death follow works independently of developer permissions")
	arena.finish_mission()
	check(arena.mission_objectives.result() == frozen and arena.ledger.forfeited_materials == 3, "Spectating cannot resettle failed deployment or duplicate cargo forfeiture")
	arena.select_scenario(16)
	await frames(12)
	check(current_scene.scene_file_path == "res://scenes/levels/asset_recovery_arena.tscn" and current_scene.mission_config_override == null, "Explicit reference selection returns to compact Asset Recovery")
	current_scene.queue_free()
	await frames(12)


func cover_and_conflict() -> void:
	var arena := create_u("conflict")
	await start_frozen(arena)
	await all_entries(arena)
	park_world(arena)
	var a: Raider = arena.raiders[1]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	guard.position = Vector3(0, 0.1, -3)
	a.position = Vector3(-7, 0.1, -3)
	await frames(3)
	var health_before := guard.health.current
	a.combat.weapon.cooldown = 0
	a.combat.weapon.try_fire_at(guard.get_aim_position())
	check(guard.health.current == health_before, "Full yard cover physically blocks a rifle shot")
	a.position = arena.get_node("CoverPoints/YardWest/Peek").global_position + Vector3.UP * 0.1
	await frames(3)
	a.combat.weapon.cooldown = 0
	a.combat.weapon.try_fire_at(guard.get_aim_position())
	check(guard.health.current < health_before, "Authored peek permits a physically valid machine hit")
	guard.position = Vector3(100, 3, 100)
	var rival: Raider = arena.raiders[4]
	a.position = Vector3(6, 0.1, 23)
	rival.position = Vector3(6, 0.1, 29)
	await frames(3)
	for actor in [a, rival]:
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	for index in range(900):
		await frames(1)
		if a.health.current < a.health.maximum and rival.health.current < rival.health.maximum:break
	freeze(arena)
	check(a.health.current < a.health.maximum and rival.health.current < rival.health.maximum, "U hostile Raiders physically exchange damage through accepted personality decisions")
	check(arena.flare_director.living_count() <= 5 and arena.flare_director.committed <= 2, "U conflict retains population and finite response bounds")
	arena.queue_free()
	await frames(30)


func alternate_retreat() -> void:
	var arena := create_u("alternate_retreat")
	await start_frozen(arena)
	park_world(arena)
	var actor: Raider = arena.raiders[2]
	actor.position = Vector3(-26, 0.1, -10)
	# Close the normal north doorway in this fixture, then rebuild the same map.
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6, 4, 1)
	collision.shape = shape
	blocker.add_child(collision)
	blocker.position = Vector3(-22, 2, -14)
	arena.get_node("Geometry").add_child(blocker)
	arena.get_node("NavigationRegion3D").bake_navigation_mesh(false)
	await frames(12)
	check(arena.route_cost(actor, arena.get_node("Extraction")) < INF, "Closing processing's north doorway leaves an alternate reachable exit path")
	var inaccessible := Marker3D.new()
	inaccessible.position = Vector3(60, 0, 0)
	arena.add_child(inaccessible)
	check(is_inf(arena.route_cost(actor, inaccessible)), "U objective reachability rejects destinations beyond physical bounds")
	arena.ledger.collect(2, &"Salvage", 3)
	actor.extraction = arena.get_node("Extraction")
	actor.transition(Raider.State.FLEEING)
	actor.set_physics_process(true)
	var left_building := false
	for index in range(2400):
		await frames(1)
		if not is_instance_valid(actor):break
		left_building = left_building or actor.position.x > -13 or actor.position.z > 11
	check(left_building and not arena.ledger.is_active(2), "Cargo-carrying Cowardly Raider physically retreats through an alternate doorway and extracts")
	arena.queue_free()
	await frames(30)


func social_opportunities() -> void:
	var arena := create_u("cooperation")
	await start_frozen(arena)
	park_world(arena)
	var a: Raider = arena.raiders[1]
	var b: Raider = arena.raiders[2]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	a.position = Vector3(-6, 0.1, 23)
	b.position = Vector3(-10, 0.1, 23)
	guard.position = Vector3(-6, 0.1, 29)
	var blocker := barrier(arena)
	blocker.position = Vector3(-6, 1.5, 26)
	await frames(3)
	b.decide()
	a.decide()
	check(a.threat_source == "ally report" and a.state == Raider.State.INVESTIGATING and not a.threat_visible, "U allied machine report starts independent occluded investigation")
	var origin := a.position
	a.set_physics_process(true)
	await frames(90)
	freeze(arena)
	check(a.position.distance_to(origin) > 0.3 and a.squad_id.is_empty() and b.squad_id.is_empty(), "U shared-threat response physically moves without creating a permanent squad")
	arena.queue_free()
	await frames(30)
	arena = create_u("betrayal")
	await start_frozen(arena)
	park_world(arena)
	a = arena.raiders[1]
	b = arena.raiders[2]
	a.position = Vector3(6, 0.1, 23)
	b.position = Vector3(6, 0.1, 29)
	arena.ledger.collect(2, &"Salvage", 3)
	await frames(3)
	a.decide()
	a.betrayal.tick(1)
	check(a.state == Raider.State.ASSESSING_BETRAYAL and not a.betrayal.spent, "U existing opportunist can assess richer visible ally")
	a.betrayal.tick(1)
	a.combat.tick(0.7)
	check(a.betrayal.spent and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.HOSTILE and b.health.current < 100, "U valid conditional betrayal changes its pair and fires a real shot")
	arena.queue_free()
	await frames(30)

func run() -> void:
	test_directory = "res://.godot/stage_u_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await scene_contract()
	await distant_collection()
	await alternate_retreat()
	await player_platform()
	await cover_and_conflict()
	await social_opportunities()
	await settlement_and_replay()
	check(accounting_valid, "Every accepted U transfer preserves material and equipment conservation")
	print("Expanded world failures: ", failures)
	quit(1 if failures else 0)
