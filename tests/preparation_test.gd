extends "res://tests/inventory_world_test.gd"

func run() -> void:
	var ledger := InventoryLedger.new()
	ledger.configure_container("player", load("res://resources/inventory/player.tres"))
	ledger.hybrid = true
	var path := test_directory + "/preparation.json"
	var profile := PersistentStash.new(path)
	check(profile.attach_inventory(ledger) and profile.upgrade_application_profile(), "Existing profile upgrades through the same durable writer")
	var service := PreparationService.new(profile)
	var template := LoadoutTemplate.from_inventory(ledger, "Lightweight")
	var original := ledger.export_state()
	check(service.evaluate(template).status == "Ready" and ledger.export_state() == original, "Template preview is non-mutating and recognizes mounted mass")
	check(service.save_template("light", template).ok and ledger.export_state().records == original.records, "Saving desired definitions reserves no additional item instances")
	template.name = "Renamed"
	check(service.save_template("light", template).ok and service.save_template("copy", template).ok and service.delete_template("copy").ok, "Template edit, rename, duplicate and delete persist through one service")
	template.cargo = [{"definition": "missing_future_item", "quantity": 2}]
	check(service.evaluate(template).status == "Partially available" and service.evaluate(template).rows.size() == 2, "Unknown definitions remain visible with exact missing quantities")
	service.save_template("missing", template)
	original = ledger.export_state()
	check(not service.apply_template("missing").ok and ledger.export_state() == original, "Unavailable exact kit does not partially consume or rearrange inventory")
	check(service.apply_template("missing", true).ok and ledger.records("prepared").size() == 1, "Explicit partial preparation allocates only available exact definitions")
	var bad := {"name": "Bad weapon", "mounts": {"primary": "raider_rifle"}, "cargo": []}
	check(service.evaluate(bad).status != "Ready", "Human rifle remains incompatible in loadout validation")
	profile.fail_before_commit = true
	original = ledger.export_state()
	check(not service.execute("Transfer", ledger.records("prepared")[0].id, 1).ok and ledger.export_state() == original, "A failed preparation save leaves ownership unchanged")
	profile.fail_before_commit = false
	check(profile.persistent_command("capacity_fixture", {}, func(candidate: InventoryLedger) -> Dictionary:
		var steel := candidate.issue("template_steel", &"scrap_steel", 12, "stash", "imported")
		if not steel.ok: return steel
		return candidate.issue("template_tools", &"electronics_kit", 13, "stash", "imported")).ok, "Finite isolated template fixtures provide independent mass and slot limits")
	var heavy := {"name": "Too heavy", "mounts": {}, "cargo": [{"definition": "scrap_steel", "quantity": 12}]}
	var crowded := {"name": "Too many slots", "mounts": {}, "cargo": [{"definition": "electronics_kit", "quantity": 13}]}
	service.save_template("heavy", heavy)
	service.save_template("crowded", crowded)
	original = ledger.export_state()
	check(service.evaluate(heavy).status == "Unavailable" and not service.apply_template("heavy").ok and ledger.export_state() == original, "A fully owned overweight template is rejected atomically by actual inventory capacity")
	check(service.evaluate(crowded).status == "Unavailable" and not service.apply_template("crowded").ok and ledger.export_state() == original, "A fully owned template exceeding cargo slots cannot partially rearrange the kit")
	var token := "a".repeat(32)
	check(profile.begin_inventory_deployment(token, true, "asset_recovery", 87017), "Application attempt distinguishes committed-but-unstarted escrow")
	var restored := InventoryLedger.new()
	restored.configure_container("player", load("res://resources/inventory/player.tres"))
	var recovered := PersistentStash.new(path)
	check(recovered.attach_inventory(restored) and restored.records("prepared").size() == 1 and recovered.deployment_snapshot(token).status == "cancelled", "Startup returns an unstarted committed kit with its original identity")
	check(recovered.home_snapshot().templates.has("light"), "Template definitions survive reload independently of kit ownership")
	var running := "b".repeat(32)
	check(recovered.begin_inventory_deployment(running, true, "asset_recovery", 87018) and recovered.mark_running(running), "Running boundary is a durable distinct transition")
	var after_crash := InventoryLedger.new()
	var reload_profile := PersistentStash.new(path)
	check(reload_profile.attach_inventory(after_crash) and after_crash.records("prepared").is_empty() and reload_profile.deployment_snapshot(running).status == "failed", "Running crash retains accepted forfeiture rules without reissuing starter gear")
	check(after_crash.is_valid(), "Template, kit and crash operations retain common inventory invariants")
	print("Preparation failures: ", failures)
	quit(1 if failures else 0)
