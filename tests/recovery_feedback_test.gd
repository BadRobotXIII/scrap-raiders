extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func run() -> void:
	var arena := load("res://scenes/levels/integrated_extraction_arena.tscn").instantiate() as Node3D
	arena.stash_path = "res://.godot/stage_r_feedback_stash.json"
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)
	await frames(10)
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.combat.weapon.set_physics_process(false)
	var victim: Raider = arena.raiders[1]
	victim.position = Vector3(0, 0.1, 8)
	arena.robot.position = victim.position
	var collected: int = arena.ledger.collect(1, &"Salvage", 3)
	victim.health.apply_damage(1000)
	await frames(3)
	arena.ecosystem.awareness.observe(arena.ecosystem.machines[0].source_id, 2, arena.raiders[2].position, arena.elapsed)
	var accepted: bool = arena.try_recover()
	var visible_success: bool = arena.status.text == "Recovered 3 materials."
	print("Recovery accepted: ", accepted, " visible success: ", visible_success, " status: ", arena.status.text)
	var valid: bool = accepted and arena.ledger.recovered_materials == 3 and arena.ledger.is_conserved() and visible_success
	var transfers: int = arena.ledger.accepted_transfers
	arena.elapsed = 1.99
	arena.refresh_hud()
	valid = valid and arena.status.text == "Recovered 3 materials."
	arena.elapsed = 2.01
	arena.refresh_hud()
	valid = valid and arena.status.text.begins_with("Machine report:") and arena.ledger.accepted_transfers == transfers
	print("Notice retained, expired and restored routine feedback without transfers: ", valid)
	arena.queue_free()
	await frames(30)
	quit(0 if valid else 1)
