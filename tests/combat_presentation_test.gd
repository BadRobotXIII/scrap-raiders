extends "res://tests/gameplay_integration_test.gd"
## Physical shot/event/effect ownership, including the approved muzzle correction.

func run() -> void:
	test_directory = "res://.godot/stage_x_tests/combat_" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var arena := await isolated_s("shots", 87018)
	var actor: Raider = arena.raiders[1]
	actor.position = Vector3(0, 0.1, 14)
	arena.robot.position = Vector3(0, 0.1, 8)
	actor.health.maximum = 1000
	actor.health.current = 1000
	var muzzle := actor.get_node("Visuals/RifleMuzzle") as Marker3D
	var before := muzzle.global_transform
	var collider := actor.get_node("CollisionShape3D") as CollisionShape3D
	var collision_before := collider.global_transform
	actor.health.apply_damage(1)
	check(muzzle.global_transform.is_equal_approx(before) and collider.global_transform == collision_before, "Accepted damage flinches cosmetic meshes without changing actual muzzle or collider")
	await frames(10)
	check(muzzle.global_transform.is_equal_approx(before), "The complete flinch/restoration leaves the fixed muzzle invariant")
	var world: MissionPresentation = arena.presentation
	var weapon: HitscanWeapon = arena.robot.get_node("Weapon")
	var events := {"shots": 0, "hits": 0, "normal": Vector3.ZERO, "position": Vector3.ZERO, "kind": &""}
	weapon.fired.connect(func(_a: Vector3, _b: Vector3, _hit: bool) -> void: events.shots += 1)
	weapon.impact_resolved.connect(func(point: Vector3, normal: Vector3, _incoming: Vector3, kind: StringName, _damaged: bool) -> void:
		events.hits += 1
		events.normal = normal
		events.position = point
		events.kind = kind)
	await frames(3)
	var shown := world.shots_presented
	weapon.cooldown = 0
	weapon.enabled = false
	check(not weapon.try_fire_at(actor.position + Vector3.UP) and events.shots == 0 and world.shots_presented == shown, "Rejected disabled fire produces no discharge or impact")
	weapon.enabled = true
	check(weapon.try_fire_at(actor.position + Vector3.UP), "Real accepted muzzle shot executes")
	check(events.shots == 1 and world.shots_presented == shown + 1 and events.hits == 1 and events.kind == &"raider_gear", "One accepted shot has exactly one discharge and one tagged physical impact")
	check(events.position.is_finite() and events.normal.length() > 0.9 and actor.health.current == 974, "Impact carries physical position/normal while original damage calculation remains exact")
	check(arena.robot.get_node("CombatHUD/Feedback").hit_remaining > 0, "Hit confirmation follows actual accepted damage")
	check(not weapon.try_fire_at(actor.position + Vector3.UP) and events.shots == 1, "Same-tick cooldown rejection cannot duplicate effects")
	var wall := barrier(arena)
	wall.set_meta("feedback_surface", &"metal")
	await frames(3)
	weapon.cooldown = 0
	weapon.try_fire_at(actor.position + Vector3.UP)
	check(events.kind == &"metal" and actor.health.current == 974 and events.position.z < 12, "An actual intervening metal wall receives impact and blocks target damage")
	wall.queue_free()
	await frames(3)
	weapon.cooldown = 0
	var impacts: int = events.hits
	weapon.try_fire_at(arena.robot.position + Vector3.UP * 40)
	check(events.hits == impacts and events.shots == 3, "Accepted sky miss has a discharge but never fabricates a surface impact")
	var same := world.shots_presented
	world.register_actor(arena.robot, &"player", weapon)
	weapon.cooldown = 0
	weapon.try_fire_at(actor.position + Vector3.UP)
	check(world.shots_presented == same + 1, "Registering the same actor twice cannot duplicate subscriptions")
	var origin := muzzle.global_position
	var deaths := world.deaths_presented
	actor.health.apply_damage(1000)
	actor.health.apply_damage(1000)
	await frames(3)
	check(world.deaths_presented == deaths + 1 and not is_instance_valid(actor), "Authoritative death presents once after the source actor is removed")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Death presentation leaves existing finite loot settlement authoritative")
	var ownership: int = arena.ledger.accepted_transfers
	seed(9182)
	var expected := randi()
	seed(9182)
	for index in range(100): world.impact(origin, Vector3.UP, &"unknown", Vector3.DOWN)
	check(randi() == expected, "Impact variation cannot consume the global or gameplay random stream")
	var counts := world.snapshot()
	check(counts.bursts <= 16 and counts.particles <= 256 and counts.lights <= 4 and counts.voices <= 32, "Simultaneous world effects honor burst, particle, light and voice caps")
	var accepted_impacts := world.impacts_presented
	world.impact(Vector3.INF, Vector3.ZERO, &"metal", Vector3.ZERO)
	check(world.impacts_presented == accepted_impacts and FeedbackSurface.normalized(&"unknown") == &"hard_surface", "Invalid geometry is rejected and untagged surfaces use the reliable generic fallback")
	await frames(130)
	check(world.snapshot().bursts == 0 and get_nodes_in_group("presentation_tracers").is_empty(), "Impact/destruction and tracer lifetimes end independently of actor lifetime")
	check(arena.ledger.accepted_transfers == ownership, "Presentation admission, randomness and expiry cannot create transfers")
	arena.queue_free()
	await frames(30)
	check(get_nodes_in_group("mission_presentations").is_empty() and get_nodes_in_group("presentation_bursts").is_empty(), "Scene removal releases the presentation world and all transients")
	print("Combat presentation failures: ", failures)
	quit(1 if failures else 0)
