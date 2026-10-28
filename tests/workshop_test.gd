extends "res://tests/inventory_world_test.gd"

func run() -> void:
	var ledger := InventoryLedger.new()
	ledger.hybrid = true
	var path := test_directory + "/workshop.json"
	var profile := PersistentStash.new(path)
	check(profile.attach_inventory(ledger) and profile.upgrade_application_profile(), "Workshop profile opens through the accepted writer")
	var preparation := PreparationService.new(profile)
	var service := WorkshopService.new(preparation)
	check(profile.persistent_command("finite_workshop_supply", {}, func(candidate: InventoryLedger) -> Dictionary:
		for pair in [["raider_rifle", 2], ["worn_response_rifle", 1], ["servo_motor", 4], ["control_pcb", 2]]:
			var issued := candidate.issue("fixture:" + str(pair[0]), StringName(pair[0]), pair[1], "stash", "imported")
			if not issued.ok: return issued
		return {"ok": true}).ok, "Isolated finite stash provides recipe inputs")
	var before := ledger.export_state()
	check(service.preview("strip_raider_rifle").ok and ledger.export_state() == before, "Recipe preview never consumes or allocates identities")
	var revision: int = ledger.container("stash").revision
	var result := service.execute("strip_raider_rifle", "strip_once", revision)
	check(result.ok and ledger.is_valid() and result.transformation.inputs.size() == 1, "Recipe records exact inputs, output identities and authorized conservation deltas")
	before = ledger.export_state()
	check(service.execute("strip_raider_rifle", "strip_once", revision) == result and ledger.export_state() == before, "Replayed persistent command returns its receipt without consuming another rifle")
	check(not service.execute("recover_servo", "stale", revision).ok and ledger.export_state() == before, "Stale stash revision cannot execute a changed preview")
	profile.fail_before_commit = true
	check(not service.execute("recover_servo", "fault", ledger.container("stash").revision).ok and ledger.export_state() == before, "Failed journal commit leaves recipe ingredients and output identities untouched")
	profile.fail_before_commit = false
	for id in ["strip_response_rifle", "recover_servo", "fabricate_blaster"]:
		check(service.execute(id, id, ledger.container("stash").revision).ok and ledger.is_valid(), "Approved recipe executes atomically: " + id)
	var rifle_id := ""
	for item in ledger.records("stash"):
		if item.definition == "raider_rifle": rifle_id = item.id
	check(service.display_item(rifle_id).ok and ledger.record(rifle_id).container == "display:workshop", "Display reserves the same owned identity")
	check(not service.preview("strip_raider_rifle").ok, "Displayed equipment is excluded from recipes")
	check(service.display_item("").ok and ledger.record(rifle_id).container == "stash", "Removing display returns the original identity")
	before = ledger.export_state()
	profile.fail_before_commit = true
	check(not service.execute("cargo_rack_1", "upgrade_fault", ledger.container("stash").revision).ok and ledger.export_state() == before and profile.home_snapshot().upgrades.is_empty(), "Failed upgrade save changes neither cost, capacity nor progression")
	profile.fail_before_commit = false
	check(service.execute("cargo_rack_1", "upgrade_once", ledger.container("stash").revision).ok, "Paid Cargo Rack I commits resources and progression together")
	check(ledger.container("prepared").slots == 16 and ledger.container("player").weight == 45000 and ledger.container("escrow").slots == 16, "Upgrade changes actual prepared, escrow and player capacity")
	check(load("res://resources/inventory/player.tres").cargo_slots == 12 and load("res://resources/inventory/raider.tres").cargo_slots == 6, "Copied upgrade rules preserve shared defaults and Raider policy")
	before = ledger.export_state()
	check(not service.execute("cargo_rack_1", "upgrade_twice", ledger.container("stash").revision).ok and ledger.export_state() == before, "Upgrade cannot charge twice")
	check(profile.persistent_command("capacity_items", {}, func(candidate: InventoryLedger) -> Dictionary: return candidate.issue("capacity_items", &"electronics_kit", 13, "stash", "imported")).ok, "Finite items exercise additional slots")
	var template := {"name": "Expanded cargo", "mounts": {}, "cargo": [{"definition": "electronics_kit", "quantity": 13}]}
	check(preparation.save_template("expanded", template).ok and preparation.apply_template("expanded").ok and ledger.occupied("prepared") == 13, "Upgrade permits a real kit exceeding the former slot limit")
	check(service.display_item(rifle_id).ok, "Display assignment persists with upgrade")
	var restored := InventoryLedger.new()
	var reopened := PersistentStash.new(path)
	check(reopened.attach_inventory(restored) and restored.is_valid() and restored.container("prepared").slots == 16, "Cold reload reconstructs upgraded capacity before accepting the larger kit")
	check(restored.record(rifle_id).container == "display:workshop" and reopened.home_snapshot().display_assignments.workshop == rifle_id, "Cold reload reserves one display identity with matching metadata")
	var simulation := InventoryLedger.new()
	check(reopened.bind_inventory(simulation) and simulation.container("player").slots == 16, "New deployment binding inherits permanent upgrade")
	var app: Node = load("res://scenes/application/application.tscn").instantiate()
	var session: GameSession = app.get_node("GameSession")
	session.profile_path = path
	root.add_child(app)
	current_scene = app
	session.quick_prepare()
	session.deploy()
	for index in 180:
		await frames(1)
		if session.state != GameSession.State.LOADING: break
	check(session.state == GameSession.State.DEPLOYMENT and session.stash.inventory.container("player").slots == 16 and session.stash.inventory.occupied("player") == 13, "Actual app deployment admits the larger upgraded kit without downgrading capacity")
	session.return_home()
	await frames(5)
	check(session.state == GameSession.State.SANCTUARY and session.stash.inventory.record(rifle_id).container == "display:workshop", "Return preserves safe display ownership independently of deployed cargo loss")
	app.queue_free()
	await frames(20)
	# Output placement failure after inputs are tentatively consumed must roll back.
	var bounded := InventoryLedger.new()
	var rules := InventoryRules.new()
	rules.cargo_slots = 1
	bounded.ensure_container("stash", "stash", rules)
	bounded.issue("one_servo", &"servo_motor", 1, "stash", "imported")
	before = bounded.export_state()
	check(not bounded.transform_recipe("recover_servo", "no_output_room").ok and bounded.export_state() == before, "Two-output recipe cannot consume input when only one output slot fits")
	var preview := service.fabrication_preview({"industrial_blaster": 2, "armor_plating": 1})
	check(not preview.ok and preview.unsupported == ["armor_plating"] and preview.rows[0].required == 2, "Fabrication planning aggregates ingredients and reports unsupported missing items without mutation")
	check(not service.fabrication_preview({"industrial_blaster": 1}, {"scrap_steel": 1000}).ok, "Kit ingredients cannot also fund its missing weapon")
	var malformed := bounded.export_state()
	malformed.transformations = []
	check(not bounded.import_state(malformed), "Malformed transformation evidence is rejected without an exception")
	var planning_ledger := InventoryLedger.new()
	var planning_profile := PersistentStash.new(test_directory + "/craftability.json")
	planning_profile.attach_inventory(planning_ledger)
	planning_profile.upgrade_application_profile()
	planning_profile.persistent_command("planning_fixture", {}, func(candidate: InventoryLedger) -> Dictionary:
		for pair in [["scrap_steel", 12], ["copper_winding", 1], ["electronics_kit", 13]]:
			var issued := candidate.issue("plan:" + str(pair[0]), StringName(pair[0]), pair[1], "stash", "imported")
			if not issued.ok: return issued
		return {"ok": true})
	var planner := PreparationService.new(planning_profile)
	var desired := {"name": "Craftable pair", "mounts": {"primary": "industrial_blaster"}, "cargo": [{"definition": "industrial_blaster", "quantity": 1}]}
	before = planning_ledger.export_state()
	check(planner.evaluate(desired).status == "Craftable" and planning_ledger.export_state() == before, "Craftable status validates a simulated kit without allocating live identities")
	desired.cargo.append({"definition": "electronics_kit", "quantity": 13})
	check(planner.evaluate(desired).status != "Craftable" and planning_ledger.export_state() == before, "Craftability cannot bypass the kit slot or weight limit")
	var steel_id := ""
	for item in planning_ledger.records("stash"):
		if item.definition == "scrap_steel": steel_id = item.id
	var display_service := WorkshopService.new(planner)
	var displayed_quantity: int = planning_ledger.record(steel_id).quantity
	check(display_service.display_item(steel_id).ok, "Display can reserve a complete material stack")
	planning_profile.persistent_command("second_steel_stack", {}, func(candidate: InventoryLedger) -> Dictionary: return candidate.issue("second_steel_stack", &"scrap_steel", 1, "stash", "imported"))
	check(display_service.display_item("").ok and planning_ledger.record(steel_id).get("quantity") == displayed_quantity, "Returning displayed stack preserves its identity beside a merge-compatible stash stack")
	print("Workshop failures: ", failures)
	quit(1 if failures else 0)
