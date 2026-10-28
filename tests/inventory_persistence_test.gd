extends SceneTree
var failures := 0
var directory: String

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func player() -> InventoryLedger:
	var ledger := InventoryLedger.new()
	ledger.configure_container("player", load("res://resources/inventory/player.tres"))
	return ledger

func migration_and_crash() -> void:
	var path := directory + "/migration.json"
	var old := PersistentStash.new(path)
	check(old.commit_rewards("a".repeat(32), 3, [{"id": 1, "name": "Raider rifle", "value": 4}]), "Build an accepted version-1 fixture")
	var bytes := FileAccess.get_file_as_bytes(path)
	var ledger := player()
	var stash := PersistentStash.new(path)
	check(stash.attach_inventory(ledger), "Version-1 stash migrates into the shared item authority")
	if not stash.last_error.is_empty(): print(stash.last_error)
	check(FileAccess.get_file_as_bytes(path + ".v1.bak") == bytes and stash.snapshot().materials == 3 and stash.snapshot().equipment.size() == 2, "Original bytes and quantities survive migration with one declared starter")
	var steel: Dictionary
	for item in ledger.records("stash"):
		if item.definition == "scrap_steel": steel = item
	var prepared := stash.persistent_command("prepare-steel", {"id": steel.id, "quantity": 2}, func(candidate: InventoryLedger) -> Dictionary: return candidate.transfer(steel.id, 2, "prepared"))
	check(prepared.ok and ledger.quantity("prepared", true) == 2, "Safe prepared cargo uses transactional shared transfers")
	var token := "b".repeat(32)
	check(stash.begin_inventory_deployment(token) and ledger.quantity("player", true) == 2 and ledger.weight("player") == 10000, "Durable debit precedes deployment and includes equipped weight")
	check(not stash.begin_inventory_deployment("c".repeat(32)), "A profile cannot start two active player deployments")
	var recovered := player()
	var restart := PersistentStash.new(path)
	check(restart.attach_inventory(recovered) and recovered.quantity("stash", true) == 1 and recovered.records("prepared").is_empty(), "Crash with active escrow forfeits the imported loadout once")
	var again := player()
	check(PersistentStash.new(path).attach_inventory(again) and again.quantity("stash", true) == 1 and again.records().size() == recovered.records().size(), "Repeated recovery cannot reissue starter or spent loadout")

func success_and_faults() -> void:
	var path := directory + "/success.json"
	var ledger := player()
	var stash := PersistentStash.new(path)
	check(stash.attach_inventory(ledger), "Fresh profile has a single prepared starter")
	stash.fail_before_commit = true
	var before := ledger.export_state()
	check(not stash.begin_inventory_deployment("d".repeat(32)) and ledger.export_state() == before, "Failed debit leaves the complete live loadout untouched")
	stash.fail_before_commit = false
	var token := "e".repeat(32)
	check(stash.begin_inventory_deployment(token), "Retry commits original prepared ownership")
	ledger.ensure_container("world", "stock")
	ledger.issue("world-copper", &"copper_winding", 3, "world")
	check(ledger.transfer(ledger.records("world")[0].id, 3, "player").ok, "Live loot joins imported gear without merging its cohort")
	stash.fail_before_commit = true
	before = ledger.export_state()
	check(not stash.settle_inventory(token, true) and ledger.export_state() == before and not ledger.player_settled, "Failed pre-commit extraction retains cargo for retry")
	stash.fail_before_commit = false
	stash.fail_cache_write = true
	check(stash.settle_inventory(token, true) and ledger.player_settled and ledger.quantity("stash", true, "world") == 3, "Committed journal return is successful even when the cache fails")
	check(stash.settle_inventory(token, true) and not stash.settle_inventory(token, false), "Exact settlement retry is safe; conflicting outcome cannot overwrite it")
	var loaded := player()
	var recovery := PersistentStash.new(path)
	check(recovery.attach_inventory(loaded) and recovery.used_backup and loaded.quantity("stash", true) == 3 and loaded.records("stash").size() == 2, "Reload recovers latest committed return, not a pre-debit cache")
	check(loaded.is_valid() and FileAccess.file_exists(path + ".journal/0000000003.json"), "Persistent reconstruction preserves item identities and sequence")
	var corrupt := FileAccess.open(path + ".journal/0000000003.json", FileAccess.WRITE)
	corrupt.store_string("broken")
	corrupt.close()
	var blocked := PersistentStash.new(path)
	check(not blocked.attach_inventory(player()) and not blocked.last_error.is_empty(), "Broken newest journal fails safely instead of restoring spendable older gear")

func unknown_and_invalid() -> void:
	var path := directory + "/unknown.json"
	var old := PersistentStash.new(path)
	old.commit_rewards("f".repeat(32), 0, [{"id": 1, "name": "Uncatalogued heirloom", "value": 19}])
	var ledger := player()
	check(PersistentStash.new(path).attach_inventory(ledger) and ledger.records("quarantine").size() == 1, "Unknown legacy equipment is preserved visibly in quarantine")
	var preserved: Dictionary = ledger.records("quarantine")[0]
	check(preserved.metadata.legacy_name == "Uncatalogued heirloom" and not ledger.transfer(preserved.id, 1, "prepared").ok, "Unsupported item keeps original data without bypassing compatibility")
	var invalid := ledger.export_state()
	invalid.records[preserved.id].quantity = -1
	var before := ledger.export_state()
	check(not ledger.import_state(invalid) and before == ledger.export_state(), "Malformed reconstructed ownership cannot partially overwrite the ledger")
	var modern_path := directory + "/missing.json"
	var modern := PersistentStash.new(modern_path)
	var live := player()
	check(modern.attach_inventory(live), "Modern missing-reference fixture starts from a valid profile")
	var profile := modern._state.duplicate(true)
	var item_id: String = profile.inventory.records.keys()[0]
	profile.inventory.records[item_id].definition = "retired_blaster"
	profile.inventory.initial = {"retired_blaster|imported": 1}
	check(modern._commit_profile(profile, "fixture-retired-definition", "explicit-test-fixture"), "A verified obsolete definition is retained as evidence")
	var restored := player()
	var replacement := PersistentStash.new(modern_path)
	check(replacement.attach_inventory(restored) and restored.records("quarantine").size() == 1 and restored.records("quarantine")[0].metadata.missing_definition == "retired_blaster", "Missing modern definitions preserve identity and payload in quarantine")
	var again := player()
	check(PersistentStash.new(modern_path).attach_inventory(again) and again.records("quarantine")[0].id == item_id, "Quarantined missing references survive another complete save/load cycle")
	var future := FileAccess.open(modern_path, FileAccess.WRITE)
	future.store_string(JSON.stringify({"version": 4}))
	future.close()
	check(not PersistentStash.new(modern_path).attach_inventory(player()), "A future primary cannot be overwritten from an older journal")
	var oversized_path := directory + "/oversized.json"
	var oversized := PersistentStash.new(oversized_path)
	oversized.commit_rewards("e".repeat(32), 50001, [])
	var preserved_hash := FileAccess.get_sha256(oversized_path)
	check(not oversized.attach_inventory(player()) and FileAccess.get_sha256(oversized_path) == preserved_hash and not DirAccess.dir_exists_absolute(oversized_path + ".journal"), "Oversized migration refuses expansion and preserves source bytes")

func run() -> void:
	directory = "res://.godot/stage_z_persistence_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	migration_and_crash()
	success_and_faults()
	unknown_and_invalid()
	fault_boundaries()
	print("Inventory persistence failures: ", failures)
	quit(1 if failures else 0)

func fault_boundaries() -> void:
	for fault in ["before_temporary_write", "after_temporary_write", "before_journal_rename", "after_journal_rename"]:
		var path: String = directory + "/fault_" + fault + ".json"
		var live := player()
		var stash := PersistentStash.new(path)
		check(stash.attach_inventory(live), "Fault fixture initializes: " + fault)
		var before := live.export_state()
		stash.fault_point = fault
		var result := stash.persistent_command("cancel-kit", {"source": "prepared"}, func(candidate: InventoryLedger) -> Dictionary: return candidate.transfer_group("prepared", "stash"))
		var committed: bool = fault == "after_journal_rename"
		check(result.ok == committed and (committed or live.export_state() == before), "Commit-boundary ownership remains truthful: " + fault)
		var loaded := player()
		check(PersistentStash.new(path).attach_inventory(loaded) and loaded.quantity("stash") == int(committed) and loaded.quantity("prepared") == int(not committed), "Reload selects only committed ownership: " + fault)
