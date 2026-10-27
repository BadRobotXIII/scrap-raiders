extends "res://tests/inventory_world_test.gd"
## Movement, dwell, limited cargo and one mixed death/extraction resolution.

func run() -> void:
	var arena := create_arena("raiders", true)
	await frames(10)
	check(arena.start_deployment(), "Expanded mission starts with shared inventory enabled")
	await frames(20)
	freeze(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	var actor: Raider = arena.raiders[1]
	var source: WorldLoot = arena.drops[-1]
	actor.position = source.position + Vector3(0, 0.1, 3)
	actor.combat_target = null
	actor.select_combat_target = Callable()
	actor.combat.stop()
	actor.combat.weapon.enabled = true
	actor.profile = actor.profile.duplicate(true)
	actor.profile.flee_distance = 0
	actor.social.loot_memory.clear()
	await frames(3)
	check(actor.loot_progress() == 0 and arena.ledger.inventory.weight("actor:1") == 4000, "Initial mounted rifle and kit do not satisfy newly acquired loot goals")
	actor.social.sense()
	check(actor.social.knows_drop(source), "Raider must observe the same registered physical cache")
	actor.transition(Raider.State.SELECTING)
	actor.decide()
	check(actor.salvage == source and actor.state == Raider.State.SCAVENGING, "Existing FSM selects reachable observed loot without another controller")
	var origin := actor.position
	actor.set_physics_process(true)
	for index in 1000:
		await frames(1)
		if actor.loot_progress() > 0: break
	actor.set_physics_process(false)
	check(actor.loot_progress() > 0 and origin.distance_to(actor.position) > 1 and actor.position.distance_to(source.position) < 0.8, "Physical Raider movement and dwell transfer finite mixed salvage")
	check(arena.ledger.inventory.weight("actor:1") <= 24000 and arena.ledger.inventory.occupied("actor:1") <= 6 and arena.ledger.is_conserved(), "Raider uses the same combined weight and cargo-slot limits")
	var expected: int = arena.ledger.inventory.records("actor:1").size()
	actor.health.apply_damage(1000)
	var drop_id: int = arena.ledger.inventory.actor_drops.get(1, 0)
	check(drop_id > 0 and arena.ledger.inventory.records("ground:%d" % drop_id).size() == expected and arena.flare_director.equipment_drops.is_empty(), "One death bundle contains both cargo and mounted gear with one flare edge")
	var before: Dictionary = arena.ledger.inventory.export_state()
	check(arena.ledger.defeat(1) < 0 and not arena.ledger.extract(1) and before == arena.ledger.inventory.export_state(), "Resolved actor cannot duplicate a drop or extract its former items")
	var other: Raider = arena.raiders[2]
	other.position = source.position + Vector3(0.3, 0.1, 0)
	other.social.sense()
	other.salvage = source
	other.transition(Raider.State.SCAVENGING)
	other.task_elapsed = other.scavenge_seconds
	var units_before: int = arena.ledger.inventory.quantity(source.container_id)
	var moved: int = arena.inventory_interaction.collect(other, source)
	check(moved > 0 and arena.ledger.inventory.quantity(source.container_id) == units_before - moved and other.loot_progress() > 0, "A second Raider collects only the remainder through the common access boundary")
	other.combat.stop()
	other.combat.weapon.enabled = true
	other.select_combat_target = Callable()
	other.position = arena.extraction_points[0].position + Vector3(0, 0.1, 2)
	other.extraction = arena.extraction_points[0]
	other.transition(Raider.State.EXTRACTING)
	other.set_physics_process(true)
	for index in 800:
		await frames(1)
		if arena.ledger.inventory.actor_outcomes[2] == MaterialLedger.Outcome.EXTRACTED: break
	check(arena.ledger.inventory.actor_outcomes[2] == MaterialLedger.Outcome.EXTRACTED and arena.ledger.inventory.quantity("extracted:2") > 0 and arena.ledger.is_conserved(), "Physical extraction resolves a recovered Raider loadout exactly once")
	# An observed empty cache remains known-empty, rather than becoming an
	# attractive 'unknown' route every perception tick.
	var empty_source: WorldLoot = arena.drops[-2]
	arena.ledger.inventory.move_contents(empty_source.container_id, "forfeited")
	var observer: Raider = arena.spawn_raider(3, empty_source.global_position + Vector3(0, 0.1, 1))
	observer.set_physics_process(false)
	await frames(3)
	observer.social.sense()
	check(observer.social.knows_drop(empty_source) and arena.choose_salvage(3) != empty_source, "Observed empty cache cannot cause repeated scavenge/select oscillation")
	arena.elapsed += arena.social.rules.memory_seconds + 1
	observer.social.known_drops()
	check(not observer.social.knows_drop(empty_source) and observer.social.searched_empty_cache(empty_source) and arena.choose_salvage(3) != empty_source, "Expired contents knowledge cannot restart a completed empty-cache search")
	arena.ledger.inventory.move_contents("forfeited", empty_source.container_id)
	observer.social.sense()
	check(not observer.social.searched_empty_cache(empty_source) and arena.choose_salvage(3) == empty_source, "Fresh direct observation can discover newly deposited loot at a previously empty cache")
	arena.queue_free()
	await frames(20)
	print("Inventory Raider failures: ", failures)
	quit(1 if failures else 0)
