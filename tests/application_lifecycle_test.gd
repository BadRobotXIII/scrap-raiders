extends "res://tests/inventory_world_test.gd"
## Real application root, shared profile and multiple existing-world deployments.

func run() -> void:
	root.size = Vector2i(1600, 900)
	var app: Node = load("res://scenes/application/application.tscn").instantiate()
	var session: GameSession = app.get_node("GameSession")
	session.profile_path = test_directory + "/application.json"
	root.add_child(app)
	current_scene = app
	await frames(5)
	check(session.state == GameSession.State.TITLE and session.stash.home_snapshot().templates.is_empty(), "Title opens an isolated version-3 profile without reserving extra kits")
	var starter: String = session.stash.inventory.records("prepared")[0].id
	session.enter_sanctuary()
	await frames(5)
	var home := session.active_scene as Sanctuary
	check(home != null and home.registry.stations.size() == 6 and not home.robot.get_node("Health").apply_damage(1000) and not home.robot.get_node("Weapon").enabled, "Sanctuary reuses the robot and six stations with authoritative damage/fire disabled")
	check(home.navigate(&"storage") and session.panel.inventory_view.context.preparation == session.preparation, "Quick station entry opens the shared preparation authority")
	session.panel.inventory_view.select(starter)
	session.panel.inventory_view.perform("Transfer")
	check(session.stash.inventory.record(starter).container == "stash", "Physical-home storage persists actual equipped ownership")
	session.panel.inventory_view.perform("Equip / Unequip")
	check(session.stash.inventory.record(starter).slot == "e:primary", "The same stored item can be equipped at home")
	home.close_station()
	session.show_title()
	session.quick_prepare()
	await frames(5)
	check(session.state == GameSession.State.QUICK_PREPARATION and session.panel != null, "Quick Deploy opens preparation without constructing a hostile arena")
	var template := LoadoutTemplate.from_inventory(session.stash.inventory, "Recovery")
	check(session.preparation.save_template("recovery", template).ok and session.preparation.apply_template("recovery").ok, "A saved template prepares the same single reserved kit")
	session.deploy()
	check(session.state == GameSession.State.LOADING and not session.active_scene.interaction_mode.open_inventory(), "Staging rejects inventory hotkeys before the kit debit")
	await frames(22)
	check(session.state == GameSession.State.DEPLOYMENT and session.active_scene.deployment_started, "Selected contract stages, commits and activates an existing deployment")
	if session.state != GameSession.State.DEPLOYMENT:
		print("Startup detail: ", session.last_error, " profile: ", session.stash.last_error)
		app.queue_free()
		await frames(10)
		quit(1)
		return
	var arena := session.active_scene as Node3D
	freeze(arena)
	var source: WorldLoot = arena.drops[-1]
	arena.robot.position = source.position + Vector3(0, 0.1, 1)
	await frames(4)
	arena.interaction_mode.open_inventory(source)
	arena.inventory_interaction.opened = source
	arena.interaction_mode.view.perform("Take All")
	arena.interaction_mode.close_inventory()
	await recall(arena)
	var receipt := session.stash.deployment_snapshot(arena.session_attempt)
	check(receipt.get("status") == "extracted" and receipt.get("result", {}).get("success", false) and session.stash.completed_contract_count() == 1, "Successful extraction commits banked items and authoritative contract results together")
	session.return_home()
	await frames(5)
	check(session.state == GameSession.State.SANCTUARY and session.stash.inventory.record(starter).container == "stash" and session.preparation.available(), "Successful return reconstructs home ownership without reviving the terminal world ledger")
	check(session.preparation.apply_template("recovery").ok, "The extracted original weapon prepares for another deployment")
	session.deploy()
	await frames(22)
	arena = session.active_scene as Node3D
	freeze(arena)
	await recall(arena)
	receipt = session.stash.deployment_snapshot(arena.session_attempt)
	check(receipt.get("status") == "extracted" and not receipt.get("result", {}).get("success", true) and session.stash.completed_contract_count() == 1, "Early extraction banks a kit without inventing contract completion")
	session.return_home()
	await frames(5)
	session.preparation.apply_template("recovery")
	session.deploy()
	await frames(22)
	arena = session.active_scene as Node3D
	freeze(arena)
	var token: String = arena.session_attempt
	var carried_id: String = arena.ledger.inventory.records("player")[0].id
	var safe_count: int = arena.ledger.inventory.quantity("stash")
	session.stash.fail_before_commit = true
	arena.robot.get_node("Health").apply_damage(1000)
	check(session.stash.deployment_snapshot(token).status == "active" and not arena.ledger.inventory.player_settled, "Failed durable death settlement retains live items for an exact retry")
	session.return_home()
	check(session.active_scene == arena and session.stash.deployment_snapshot(token).status == "active", "Return cannot discard a pending settlement")
	session.stash.fail_before_commit = false
	session.return_home()
	await frames(5)
	check(session.state == GameSession.State.SANCTUARY and session.stash.deployment_snapshot(token).status == "failed" and session.stash.inventory.record(carried_id).is_empty() and session.stash.inventory.quantity("stash") == safe_count, "Retry settles death once, forfeits only carried gear and returns home")
	check(session.stash.home_snapshot().templates.has("recovery") and session.stash.completed_contract_count() == 1, "Three deployments preserve templates and do not duplicate completion")
	check(session.preparation.apply_template("recovery").ok, "A remaining safe weapon prepares for the failed-start comparison")
	var refundable: String = session.stash.inventory.records("prepared")[0].id
	session.startup_fault = "after_debit"
	session.deploy()
	await frames(22)
	check(session.state == GameSession.State.SANCTUARY and session.preparation.available(), "Failed activation cancels unstarted escrow and returns safely")
	check(session.stash.inventory.record(refundable).container == "prepared", "Failed activation refunds the same nonempty kit identity")
	session.startup_fault = ""
	session.deploy()
	await frames(22)
	arena = session.active_scene as Node3D
	freeze(arena)
	source = arena.drops[-1]
	arena.robot.position = source.position + Vector3(0, 0.1, 1)
	await frames(4)
	arena.interaction_mode.open_inventory(source)
	arena.inventory_interaction.opened = source
	arena.interaction_mode.view.perform("Take All")
	arena.interaction_mode.close_inventory()
	session.stash.fail_before_commit = true
	await recall(arena)
	check(not arena.mission.is_finished() and session.stash.deployment_snapshot(arena.session_attempt).status == "active", "A failed successful-Recall write does not end gameplay or bank items")
	token = arena.session_attempt
	arena.robot.get_node("Health").apply_damage(1000)
	session.stash.fail_before_commit = false
	session.return_home()
	await frames(5)
	receipt = session.stash.deployment_snapshot(token)
	check(receipt.status == "failed" and not receipt.result.extracted and not receipt.result.success and session.stash.completed_contract_count() == 1, "Death after an uncommitted successful Recall cannot publish its stale success or reward completion")
	check(session.stash.inventory.is_valid(), "Repeated lifecycle and fault paths retain one valid inventory")
	app.queue_free()
	await frames(25)
	print("Application lifecycle failures: ", failures)
	quit(1 if failures else 0)

func recall(arena: Node3D) -> void:
	arena.robot.position = arena.get_node("RecallDock").position + Vector3.UP * 0.1
	arena.robot.velocity = Vector3.ZERO
	await frames(12)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.recover_held = true
	for index in 65:
		if arena.mission.is_finished(): break
		arena.recall.step(0.1)
