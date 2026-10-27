extends SceneTree
## Real normal/expanded roots, isolated profiles, registered source access.
var failures: int = 0
var test_directory: String

func _init() -> void:
	test_directory = "res://.godot/stage_z_world_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition: failures += 1

func frames(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func create_arena(label: String, expanded: bool = false, seed_value: int = 87017) -> Node3D:
	var path := "res://scenes/levels/expanded_salvage_complex.tscn" if expanded else "res://scenes/levels/asset_recovery_arena.tscn"
	var arena := load(path).instantiate() as Node3D
	arena.stash_path = test_directory + "/" + label + ".json"
	arena.seed_override = seed_value
	root.add_child(arena)
	current_scene = arena
	return arena

func freeze(arena: Node3D) -> void:
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.position = Vector3(100 + actor.raider_id * 3, 0.1, 110)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		machine.position = Vector3(100, 3, 100)

func semantic_sources(arena: Node3D) -> Array:
	var result: Array = []
	for id in [-1, -2, -3]:
		var rows: Array = []
		for item in arena.ledger.inventory.records(arena.drops[id].container_id): rows.append([item.definition, item.quantity])
		result.append(rows)
	return result

func run() -> void:
	var original: Array = []
	for index in 2:
		var arena := create_arena("repeat%d" % index)
		await frames(12)
		check(arena.setup_error.is_empty() and arena.recall.save_error.is_empty(), "Normal hybrid inventory initializes safely before simulation")
		check(arena.ledger.inventory == arena.flare_director.equipment.inventory and arena.ledger.total_materials == 14, "One owner preserves fourteen finite material units")
		check(arena.drops.size() == 3 and arena.ledger.inventory.quantity("prepared") == 1 and not arena.robot.get_node("Weapon").enabled, "Three searchable sources and one safe starter are available during preparation")
		var manifest := semantic_sources(arena)
		if index == 0: original = manifest
		else: check(manifest == original, "Repeated seed preserves source manifests independently of profile identities")
		check(arena.start_deployment(), "Durable loadout debit precedes simulation")
		await frames(15)
		freeze(arena)
		check(arena.robot.get_node("Weapon").enabled and arena.ledger.inventory.records("prepared").is_empty(), "Deployed mounted blaster enables the existing weapon")
		var source: WorldLoot = arena.drops[-1]
		arena.robot.global_position = source.global_position + Vector3(0, 0.1, 1)
		await frames(3)
		check(arena.inventory_interaction.player_access(source), "Player access uses physical range and geometry in the normal scene")
		check(arena.interaction_mode.open_inventory(source), "Registered source opens a live two-inventory panel")
		arena.inventory_interaction.opened = source
		var item: Dictionary = arena.ledger.inventory.records(source.container_id)[0]
		var before: int = arena.ledger.inventory.quantity(source.container_id)
		var result: Dictionary = arena.inventory_interaction.take(source, item.id, 1, false, "take", -1, -1)
		check(result.ok and arena.ledger.inventory.quantity(source.container_id) == before - 1, "Source transfer changes authoritative ownership once")
		arena.robot.position += Vector3(5, 0, 0)
		var rejected: Dictionary = arena.inventory_interaction.take(source, item.id, 1, false, "remote", -1, -1)
		check(not rejected.ok and arena.ledger.is_conserved(), "Open panel cannot grant remote or duplicated loot")
		arena.queue_free()
		await frames(15)
	print("Inventory world failures: ", failures)
	quit(1 if failures else 0)
