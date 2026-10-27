extends "res://tests/inventory_world_test.gd"
## Real Recall, objectives, failure, restart and imported-loot accounting.

func run() -> void:
	var arena := create_arena("lifecycle", true)
	await frames(10)
	check(arena.start_deployment(), "Expanded normal loadout commits before active play")
	await frames(20)
	freeze(arena)
	var source: WorldLoot = arena.drops[-1]
	arena.robot.position = source.position + Vector3(0, 0.1, 1)
	await frames(3)
	check(arena.interaction_mode.open_inventory(source), "Physical source is accessible in the expanded world")
	arena.inventory_interaction.opened = source
	var taken := 0
	for item in arena.ledger.inventory.records(source.container_id):
		if arena.ledger.inventory.catalog.find(StringName(item.definition)).material_units == 0: continue
		var result: Dictionary = arena.inventory_interaction.take(source, item.id, item.quantity, true, arena.inventory_interaction.next_command(), -1, -1)
		if result.ok: taken += int(result.amount)
	check(taken >= 3 and arena.mission_objectives.snapshot()[0].progress == 0, "New source materials are carried readiness, not prematurely banked completion")
	arena.interaction_mode.close_inventory()
	arena.robot.position = arena.get_node("RecallDock").position + Vector3.UP * 0.1
	arena.robot.velocity = Vector3.ZERO
	await frames(10)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.recover_held = true
	arena.recall.step(0.1)
	for index in 60:
		if arena.mission.is_finished(): break
		arena.recall.step(0.1)
	check(arena.mission.player_extracted and arena.mission.phase == MissionRules.Phase.SUCCEEDED and arena.ledger.banked_materials == taken, "Real five-second Recall persists cargo before completing primary objectives")
	check(arena.mission_objectives.result().equipment_banked == 0 and arena.recall.stash.snapshot().equipment.size() == 1, "Imported starter returns safely without earning new-equipment objective credit")
	var result_snapshot: Dictionary = arena.mission_objectives.result()
	var token: String = arena.recall.deployment_id
	check(arena.recall.stash.settle_inventory(token, true) and not arena.recall.stash.settle_inventory(token, false), "Settlement receipt accepts exact retries and rejects outcome conflicts")
	arena.restart_mission()
	await frames(20)
	arena = current_scene
	check(not arena.deployment_started and arena.ledger.inventory.quantity("prepared") == 0 and arena.ledger.inventory.quantity("stash", true) == taken and not arena.mission_objectives.is_closed(), "Restart keeps banked ownership and creates fresh objectives without refilling a starter")
	check(arena.start_deployment(), "A second deployment may start with empty prepared equipment")
	await frames(15)
	freeze(arena)
	check(not arena.robot.get_node("Weapon").enabled and arena.ledger.inventory.quantity("stock:Salvage") > 0, "Empty-stash recovery remains possible through the finite world tool cache")
	source = arena.drops[-1]
	arena.robot.position = source.position + Vector3(0, 0.1, 1)
	await frames(3)
	arena.interaction_mode.open_inventory(source)
	arena.inventory_interaction.opened = source
	var recovered_weapon := ""
	for item in arena.ledger.inventory.records(source.container_id):
		if item.definition == "industrial_blaster":
			var taken_weapon: Dictionary = arena.inventory_interaction.take(source, item.id, 1, false, arena.inventory_interaction.next_command(), -1, -1)
			if taken_weapon.ok: recovered_weapon = item.id
	if not recovered_weapon.is_empty():
		arena.interaction_mode.view.select(recovered_weapon)
		arena.interaction_mode.view.perform("Equip / Unequip")
	arena.interaction_mode.close_inventory()
	check(not recovered_weapon.is_empty() and arena.robot.get_node("Weapon").try_fire_at(arena.robot.global_position + Vector3(0, 1, 8)), "An unarmed second deployment can recover, mount and physically fire the one finite world blaster")
	arena.robot.get_node("Health").apply_damage(1000)
	var current_result: Dictionary = arena.mission_objectives.result()
	check(not arena.mission.is_world_finished() and arena.mission.player_destroyed and current_result.materials_banked == 0 and result_snapshot.materials_banked == taken, "Player destruction settles once while autonomous world and previous results remain independent")
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Restart and both settlement outcomes preserve shared conservation")
	arena.queue_free()
	await frames(20)
	print("Inventory lifecycle failures: ", failures)
	quit(1 if failures else 0)
