class_name PersistentStash
extends RefCounted
## Sole persistent inventory writer. A deployment receipt makes reward retries idempotent.

var path: String
var last_error: String = ""
var used_backup: bool = false
var _state: Dictionary = {}


func _init(save_path: String) -> void:
	path = save_path


func snapshot() -> Dictionary:
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
