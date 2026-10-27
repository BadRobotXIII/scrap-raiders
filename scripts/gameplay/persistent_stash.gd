class_name PersistentStash
extends RefCounted
## Sole persistent inventory writer. A deployment receipt makes reward retries idempotent.

var path: String
var last_error: String = ""
var used_backup: bool = false
var _state: Dictionary = {}
var inventory: InventoryLedger
var cache_warning: String = ""
var _journal_hash: String = ""
# Deterministic fault seams used by isolated persistence tests, never game UI.
var fail_before_commit: bool = false
var fail_cache_write: bool = false
var fault_point: String = "" # Isolated persistence tests; never exposed in gameplay.


func _init(save_path: String) -> void:
	path = save_path


func snapshot() -> Dictionary:
	if _state.get("version") == 2:
		return _legacy_projection()
	return _state.duplicate(true)


func _empty() -> Dictionary:
	return {"version": 1, "materials": 0, "equipment": {}, "receipts": {}}


func _natural(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 1000000000 and floor(float(value)) == float(value)


func _token_valid(token: String) -> bool:
	if token.length() != 32:
		return false
	for character in token:
		if not "0123456789abcdef".contains(character):
			return false
	return true


func _valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not _natural(data.get("materials")):
		return false
	if not data.get("equipment") is Dictionary or not data.get("receipts") is Dictionary:
		return false
	var receipt_materials := 0
	for token in data.receipts:
		var receipt = data.receipts[token]
		if not _token_valid(str(token)) or not receipt is Dictionary or not _natural(receipt.get("materials")) or not receipt.get("equipment") is Dictionary:
			return false
		receipt_materials += int(receipt.materials)
		for item_id in receipt.equipment:
			var identity := "%s/%s" % [token, item_id]
			if not str(item_id).is_valid_int() or int(item_id) <= 0 or not data.equipment.has(identity) or data.equipment[identity] != receipt.equipment[item_id]:
				return false
	if receipt_materials != data.materials:
		return false
	for id in data.equipment:
		var item = data.equipment[id]
		var parts := str(id).split("/")
		if parts.size() != 2 or not data.receipts.has(parts[0]) or not data.receipts[parts[0]].equipment.has(parts[1]):
			return false
		if not item is Dictionary or not item.get("name") is String or item.name.is_empty() or item.name.length() > 100 or not _natural(item.get("value")):
			return false
	return true


func _read(save_path: String) -> Dictionary:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parsed := parser.parse(file.get_as_text())
	file.close()
	var data = parser.data if parsed == OK else null
	if not _valid(data):
		return {}
	# JSON numbers load as floats. Normalize validated integer fields before
	# comparing reward receipts and verified disk snapshots.
	data.version = 1
	data.materials = int(data.materials)
	for item in data.equipment.values():
		item.value = int(item.value)
	for receipt in data.receipts.values():
		receipt.materials = int(receipt.materials)
		for item in receipt.equipment.values():
			item.value = int(item.value)
	return data


func load_stash() -> bool:
	last_error = ""
	used_backup = false
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path + ".journal")):
		return _load_journal()
	var primary := _read(path)
	if not primary.is_empty():
		_state = primary
		return true
	# Never replace a newer version with an older backup.
	if FileAccess.file_exists(path):
		var parser := JSON.new()
		var error := parser.parse(FileAccess.get_file_as_string(path))
		var parsed = parser.data if error == OK else null
		if parsed is Dictionary and parsed.get("version", 1) != 1:
			last_error = "Unsupported stash version. Existing save preserved."
			return false
	var backup := _read(path + ".bak")
	if not backup.is_empty():
		_state = backup
		used_backup = true
		return true
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = "Stash and backup are unreadable. Existing files preserved."
		return false
	_state = _empty()
	return true


func commit_rewards(token: String, materials: int, items: Array[Dictionary]) -> bool:
	if not _token_valid(token) or not _natural(materials):
		last_error = "Invalid extraction reward."
		return false
	if not load_stash():
		return false
	if _state.get("version") == 2:
		return _commit_legacy_v2(token, materials, items)
	var reward := {"materials": materials, "equipment": {}}
	for item in items:
		if not _natural(item.get("id")) or item.id <= 0 or reward.equipment.has(str(int(item.id))):
			last_error = "Invalid or duplicate equipment identity."
			return false
		reward.equipment[str(int(item.id))] = {"name": item.get("name"), "value": item.get("value")}
	if _state.receipts.has(token):
		if _state.receipts[token] == reward:
			return true
		last_error = "Deployment receipt does not match this reward."
		return false
	var candidate := _state.duplicate(true)
	candidate.materials += materials
	candidate.receipts[token] = reward
	for item_id in reward.equipment:
		candidate.equipment["%s/%s" % [token, item_id]] = reward.equipment[item_id]
	if not _valid(candidate):
		last_error = "Invalid stash data."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_error = "Cannot create stash directory."
		return false
	var temporary := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if temporary == null:
		last_error = "Cannot write stash temporary file."
		return false
	temporary.store_string(JSON.stringify(candidate))
	temporary.flush()
	var write_error := temporary.get_error()
	temporary.close()
	if write_error != OK or _read(path + ".tmp") != candidate:
		last_error = "Stash write verification failed."
		return false
	# Back up only a validated primary; preserve a good backup after recovery.
	if not _read(path).is_empty() and DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
		last_error = "Cannot preserve stash backup."
		return false
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		last_error = "Cannot atomically replace stash."
		return false
	_state = candidate
	return true

func _legacy_projection() -> Dictionary:
	var result := {"version": 2, "materials": 0, "equipment": {}, "receipts": _state.get("legacy_receipts", {}).duplicate(true)}
	var catalog := load("res://resources/items/catalog.tres") as ItemCatalog
	for item in _state.get("inventory", {}).get("records", {}).values():
		if item.container not in ["stash", "prepared", "quarantine"]: continue
		var definition := catalog.find(StringName(item.definition))
		if definition == null: continue
		result.materials += int(item.quantity) * definition.material_units
		if definition.material_units == 0:
			result.equipment[item.id] = {"name": item.metadata.get("legacy_name", definition.display_name), "value": item.metadata.get("legacy_value", definition.base_value)}
	return result

func _profile_valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 2 or not data.get("profile_id") is String or not _token_valid(data.profile_id): return false
	if not _natural(data.get("sequence")) or not data.get("inventory") is Dictionary or not data.get("operations") is Dictionary or not data.get("deployments") is Dictionary or not data.get("legacy_receipts") is Dictionary: return false
	var check := InventoryLedger.new()
	for deployment in data.deployments.values():
		if not deployment is Dictionary or deployment.get("status") not in ["active", "failed", "extracted"] or not deployment.get("imports") is Array or not deployment.get("returns") is Array: return false
	return check.import_state(InventoryLedger.quarantine_missing(data.inventory, check.catalog))

func _load_journal() -> bool:
	if FileAccess.file_exists(path):
		var version_parser := JSON.new()
		if version_parser.parse(FileAccess.get_file_as_string(path)) == OK and version_parser.data is Dictionary and int(version_parser.data.get("version", 0)) > 2:
			last_error = "Unsupported newer inventory profile. Existing files preserved."
			return false
	var directory := path + ".journal"
	var files := DirAccess.get_files_at(directory)
	files.sort()
	var latest: Dictionary = {}
	var previous := ""
	var sequence := 0
	for name in files:
		if not name.ends_with(".json"): continue
		var file_path := directory.path_join(name)
		if FileAccess.get_file_as_bytes(file_path).size() > 16000000:
			last_error = "Inventory journal exceeds the supported safety limit; files preserved."
			return false
		var parser := JSON.new()
		var parsed: Variant = parser.data if parser.parse(FileAccess.get_file_as_string(file_path)) == OK else null
		if not parsed is Dictionary:
			last_error = "Inventory journal is damaged; spending is blocked and files are preserved."
			return false
		var checksum: String = parsed.get("checksum", "")
		parsed.erase("checksum")
		parsed = InventoryLedger.normalize_json(parsed)
		if parsed.get("sequence") != sequence + 1 or parsed.get("previous") != previous or JSON.stringify(parsed).sha256_text() != checksum or not _profile_valid(parsed.get("state")):
			last_error = "Inventory journal continuity or checksum failed; files preserved."
			return false
		sequence += 1
		if parsed.state.sequence != sequence:
			last_error = "Inventory snapshot sequence disagrees with its journal."
			return false
		previous = checksum
		latest = parsed.state
	if latest.is_empty():
		last_error = "Inventory journal has no verified committed state. Existing save preserved."
		return false
	# The journal is authoritative. A damaged/stale cache cannot restore spent gear.
	_state = latest
	_journal_hash = previous
	var cache: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	used_backup = not cache is Dictionary or InventoryLedger.normalize_json(cache) != latest
	return true

func _commit_profile(candidate: Dictionary, operation: String, payload_hash: String) -> bool:
	last_error = ""
	cache_warning = ""
	if not _profile_valid(candidate):
		last_error = "Candidate inventory profile is invalid."
		return false
	if fail_before_commit:
		last_error = "Injected failure before inventory commit."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var directory := absolute + ".journal"
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		last_error = "Cannot create inventory journal."
		return false
	var seq: int = int(_state.get("sequence", 0)) + 1
	candidate.sequence = seq
	var entry := {"sequence": seq, "previous": _journal_hash, "operation": operation, "payload_hash": payload_hash, "state": candidate}
	entry["checksum"] = JSON.stringify(entry).sha256_text()
	var target := directory.path_join("%010d.json" % seq)
	if FileAccess.file_exists(target):
		last_error = "Inventory sequence already exists; reload before retrying."
		return false
	if fault_point == "before_temporary_write":
		last_error = "Injected temporary-write failure."
		return false
	var temporary := FileAccess.open(target + ".tmp", FileAccess.WRITE)
	if temporary == null:
		last_error = "Cannot write inventory transaction."
		return false
	temporary.store_string(JSON.stringify(entry))
	temporary.flush()
	var error := temporary.get_error()
	temporary.close()
	if fault_point == "after_temporary_write":
		last_error = "Injected failure after uncommitted temporary write."
		return false
	if error != OK or InventoryLedger.normalize_json(JSON.parse_string(FileAccess.get_file_as_string(target + ".tmp"))) != entry:
		last_error = "Inventory transaction write verification failed."
		return false
	if fault_point == "before_journal_rename":
		last_error = "Injected failure before journal rename."
		return false
	if DirAccess.rename_absolute(target + ".tmp", target) != OK:
		last_error = "Cannot commit inventory transaction; reload before retrying."
		return false
	# Commit has happened. A cache failure from this point is recoverable success.
	_state = candidate.duplicate(true)
	_journal_hash = entry.checksum
	if fail_cache_write or fault_point == "after_journal_rename":
		cache_warning = "Profile cache unavailable; committed inventory is safe in its journal."
		return true
	var cache := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if cache != null:
		cache.store_string(JSON.stringify(_state))
		cache.flush()
		error = cache.get_error()
		cache.close()
	else: error = ERR_CANT_CREATE
	if error != OK or InventoryLedger.normalize_json(JSON.parse_string(FileAccess.get_file_as_string(path + ".tmp"))) != _state:
		cache_warning = "Profile cache verification failed; committed journal will restore it."
		return true
	if FileAccess.file_exists(path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if _profile_valid(old): DirAccess.copy_absolute(absolute, absolute + ".bak")
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		cache_warning = "Profile cache replacement failed; committed journal will restore it."
	return true

func attach_inventory(authority: InventoryLedger) -> bool:
	if not load_stash(): return false
	if _state.get("version") == 1 and not _migrate_v1(): return false
	var restored := InventoryLedger.quarantine_missing(_state.inventory, authority.catalog)
	if restored != _state.inventory:
		var candidate := _state.duplicate(true)
		candidate.inventory = restored
		if not _commit_profile(candidate, "quarantine_missing:%d" % int(candidate.sequence), JSON.stringify(restored).sha256_text()): return false
	if not _recover_abandoned(): return false
	if not authority.admit_persistent(_state.inventory):
		last_error = "Persistent inventory could not be admitted without duplicate ownership."
		return false
	inventory = authority
	return true

func _migrate_v1() -> bool:
	var old := _state.duplicate(true)
	# Validate size before expanding scalar balances into stack records.
	if int(old.materials) > 50000 or old.equipment.size() > 4000:
		last_error = "Legacy inventory is too large for automatic migration. Original data preserved."
		return false
	var ledger := InventoryLedger.new()
	ledger.identity_prefix = Crypto.new().generate_random_bytes(16).hex_encode()
	for pair in [["stash", "stash"], ["prepared", "prepared"], ["escrow", "escrow"], ["quarantine", "quarantine"]]: ledger.ensure_container(pair[0], pair[1])
	ledger.configure_container("prepared", load("res://resources/inventory/player.tres"))
	ledger.configure_container("escrow", load("res://resources/inventory/player.tres"))
	if int(old.materials) > 0 and not ledger.issue("v1_material_balance", &"scrap_steel", int(old.materials), "stash", "imported").ok:
		last_error = "Legacy material conversion failed; original preserved."
		return false
	var names := {"Raider rifle": &"raider_rifle", "Worn response rifle": &"worn_response_rifle", "Electronics kit": &"electronics_kit"}
	for id in old.equipment:
		var item: Dictionary = old.equipment[id]
		var known: bool = names.has(item.name)
		var definition: StringName = names.get(item.name, &"unsupported_legacy")
		var metadata := {"legacy_name": item.name, "legacy_value": item.value}
		if not ledger.issue("v1_item:" + str(id), definition, 1, "stash" if known else "quarantine", "imported", metadata, str(id)).ok:
			last_error = "Legacy equipment conversion failed; original preserved."
			return false
	var starter := ledger.issue("z_initial_kit", &"industrial_blaster", 1, "prepared", "imported")
	if not starter.ok or not ledger.transfer(starter.ids[0], 1, "prepared", false, "", -1, -1, "primary").ok: return false
	var source := path + ".bak" if used_backup else path
	var original_hash := FileAccess.get_sha256(source) if FileAccess.file_exists(source) else "new-profile"
	if FileAccess.file_exists(source):
		var absolute := ProjectSettings.globalize_path(source)
		var backup := ProjectSettings.globalize_path(path + ".v1.bak")
		if FileAccess.file_exists(backup) and FileAccess.get_sha256(backup) != original_hash:
			last_error = "Existing original migration backup differs; files preserved."
			return false
		if not FileAccess.file_exists(backup) and DirAccess.copy_absolute(absolute, backup) != OK:
			last_error = "Cannot preserve original version-1 save."
			return false
	var candidate := {"version": 2, "sequence": 0, "profile_id": ledger.identity_prefix, "catalog_version": 1, "inventory": ledger.persistent_state(), "operations": {}, "deployments": {}, "legacy_receipts": old.receipts, "migration": {"source_sha256": original_hash, "starter_issued": true}}
	return _commit_profile(candidate, "migrate-v1", original_hash)

func _candidate_ledger() -> InventoryLedger:
	var candidate := InventoryLedger.new()
	var state: Dictionary = inventory.export_state() if inventory != null else _state.inventory
	if not candidate.import_state(state): return null
	return candidate

func persistent_command(operation: String, payload: Dictionary, action: Callable) -> Dictionary:
	if inventory == null: return {"ok": false, "reason": "Storage is unavailable."}
	for deployment in _state.deployments.values():
		if deployment.status == "active": return {"ok": false, "reason": "Stash transfers are available only during preparation."}
	var digest := JSON.stringify(payload).sha256_text()
	if _state.operations.has(operation):
		return _state.operations[operation].result.duplicate(true) if _state.operations[operation].hash == digest else {"ok": false, "reason": "Conflicting persistent command."}
	var candidate := _candidate_ledger()
	if candidate == null: return {"ok": false, "reason": "Inventory checkpoint is invalid."}
	var result: Dictionary = action.call(candidate)
	if not result.get("ok", false): return result
	var profile := _state.duplicate(true)
	profile.inventory = candidate.persistent_state()
	profile.operations[operation] = {"hash": digest, "result": result.duplicate(true)}
	if not _commit_profile(profile, operation, digest): return {"ok": false, "reason": last_error}
	if not inventory.install_state(candidate.export_state(), "persistent_command"):
		last_error = "Committed inventory requires reload; dependent actions blocked."
		return {"ok": false, "reason": last_error}
	return result

func begin_inventory_deployment(token: String) -> bool:
	if inventory == null or not _token_valid(token): return false
	if _state.deployments.has(token): return false
	for deployment in _state.deployments.values():
		if deployment.status == "active": return false
	var candidate := _candidate_ledger()
	if candidate == null: return false
	var moved := candidate.transfer_group("prepared", "escrow", "", true)
	if not moved.ok:
		last_error = moved.reason
		return false
	var profile := _state.duplicate(true)
	profile.inventory = candidate.persistent_state()
	profile.deployments[token] = {"status": "active", "imports": candidate.records("escrow"), "returns": []}
	if not _commit_profile(profile, "deploy:" + token, JSON.stringify(profile.deployments[token]).sha256_text()): return false
	if not inventory.install_state(candidate.export_state(), "deployment_debit"): return false
	return inventory.transfer_group("escrow", "player", "", true).ok

func settle_inventory(token: String, extracted: bool) -> bool:
	if inventory == null or not _state.deployments.has(token): return false
	var deployment: Dictionary = _state.deployments[token]
	if deployment.status != "active": return deployment.status == ("extracted" if extracted else "failed")
	var candidate := _candidate_ledger()
	if candidate == null: return false
	var returned := candidate.records("player")
	if not candidate.settle_player(extracted, "stash"): return false
	var profile := _state.duplicate(true)
	profile.inventory = candidate.persistent_state()
	profile.deployments[token].status = "extracted" if extracted else "failed"
	profile.deployments[token].returns = returned if extracted else []
	profile.deployments[token]["lost"] = [] if extracted else returned
	if not _commit_profile(profile, "settle:" + token, JSON.stringify(profile.deployments[token]).sha256_text()): return false
	return inventory.install_state(candidate.export_state(), "deployment_settlement")

func _recover_abandoned() -> bool:
	for token in _state.deployments:
		if _state.deployments[token].status != "active": continue
		var ledger := InventoryLedger.new()
		if not ledger.import_state(_state.inventory): return false
		ledger.ensure_container("forfeited", "forfeited")
		if not ledger.transfer_group("escrow", "forfeited").ok: return false
		var candidate := _state.duplicate(true)
		candidate.inventory = ledger.persistent_state()
		candidate.deployments[token].status = "failed"
		candidate.deployments[token]["lost"] = candidate.deployments[token].imports
		if not _commit_profile(candidate, "recover-abandoned:" + str(token), str(token)): return false
	return true

func _commit_legacy_v2(token: String, materials: int, items: Array[Dictionary]) -> bool:
	var reward := {"materials": materials, "equipment": {}}
	for item in items:
		if not _natural(item.get("id")) or item.id <= 0 or reward.equipment.has(str(int(item.id))): return false
		reward.equipment[str(int(item.id))] = {"name": item.get("name"), "value": item.get("value")}
	if _state.legacy_receipts.has(token): return _state.legacy_receipts[token] == reward
	var candidate := InventoryLedger.new()
	if not candidate.import_state(_state.inventory): return false
	if materials > 0 and not candidate.issue("legacy_reward:" + token, &"scrap_steel", materials, "stash", "imported").ok: return false
	var names := {"Raider rifle": &"raider_rifle", "Worn response rifle": &"worn_response_rifle", "Electronics kit": &"electronics_kit"}
	for id in reward.equipment:
		var item: Dictionary = reward.equipment[id]
		if not item.name is String or item.name.is_empty() or not _natural(item.value): return false
		var definition: StringName = names.get(item.name, &"unsupported_legacy")
		if not candidate.issue("legacy_reward:%s/%s" % [token, id], definition, 1, "stash" if names.has(item.name) else "quarantine", "imported", {"legacy_name": item.name, "legacy_value": item.value}, "%s/%s" % [token, id]).ok: return false
	var profile := _state.duplicate(true)
	profile.inventory = candidate.persistent_state()
	profile.legacy_receipts[token] = reward
	return _commit_profile(profile, "legacy_reward:" + token, JSON.stringify(reward).sha256_text())
