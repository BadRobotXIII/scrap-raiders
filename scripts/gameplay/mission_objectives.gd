class_name MissionObjectives
extends RefCounted
## Sole objective-status owner. Ledgers remain the only inventory writers.

signal changed
var _definitions: Array[MissionObjectiveDefinition] = []
var _ledger: MaterialLedger
var _equipment: EquipmentLedger
var _mission_id: StringName
var _mission_name: String
var _deployment_id: String
var _player_id: int
var _credited_victims: Dictionary[int, bool] = {}
var _material_serial: int = 0
var _equipment_serial: int = 0
var _rows: Array[Dictionary] = []
var _result: Dictionary = {}


func _init(config: MissionConfig, ledger: MaterialLedger, equipment: EquipmentLedger, player_id: int, deployment_id: String) -> void:
	for definition in config.objective_definitions:
		_definitions.append(definition.duplicate(true))
	_ledger = ledger
	_equipment = equipment
	_player_id = player_id
	_deployment_id = deployment_id
	_mission_id = config.mission_id
	_mission_name = config.display_name
	_ledger.transfer_accepted.connect(_on_material)
	_equipment.transfer_accepted.connect(_on_equipment)
	if ledger.inventory.hybrid: ledger.inventory.changed.connect(_inventory_changed)
	refresh()


func _on_material(_kind: StringName, details: Dictionary) -> void:
	if is_closed() or int(details.serial) <= _material_serial:
		return
	_material_serial = int(details.serial)
	refresh()

func _inventory_changed(_event: Dictionary) -> void:
	refresh()


func _on_equipment(_kind: StringName, details: Dictionary) -> void:
	if is_closed() or int(details.serial) <= _equipment_serial:
		return
	_equipment_serial = int(details.serial)
	refresh()


func accepted_defeat(event: Dictionary) -> void:
	if is_closed() or event.get("deployment_id") != _deployment_id or not event.get("eligible", false) or int(event.get("instigator", 0)) != _player_id:
		return
	var victim := int(event.get("victim", 0))
	if victim <= 0 or _credited_victims.has(victim):
		return
	_credited_victims[victim] = true
	refresh()


func evaluated_rows(extracted: bool = false, authority: InventoryLedger = null) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for definition in _definitions:
		var progress := 0
		var carried := 0
		match definition.kind:
			MissionObjectiveDefinition.Kind.BANK_MATERIALS:
				progress = _ledger.banked_materials if authority == null else authority.quantity("stash", true, "world") + authority.quantity("banked", true, "world")
				carried = _ledger.recovered_materials if authority == null else authority.quantity("player", true, "world")
			MissionObjectiveDefinition.Kind.BANK_EQUIPMENT:
				progress = _equipment.count_at(EquipmentLedger.Location.BANKED) if authority == null else authority.equipment_summary(EquipmentLedger.Location.BANKED).x
				carried = _equipment.count_at(EquipmentLedger.Location.RECOVERED) if authority == null else authority.equipment_summary(EquipmentLedger.Location.RECOVERED).x
			MissionObjectiveDefinition.Kind.EXTRACT:
				progress = int(extracted)
			MissionObjectiveDefinition.Kind.DEFEAT_HOSTILE_RAIDERS:
				progress = _credited_victims.size()
		rows.append({"id": str(definition.objective_id), "description": definition.description, "kind": definition.kind, "target": definition.target, "required": definition.required, "progress": progress, "carried": carried, "status": "completed" if progress >= definition.target else "pending"})
	return rows


func refresh() -> void:
	if is_closed():
		return
	var next := evaluated_rows()
	if next != _rows:
		_rows = next
		changed.emit()


func required_satisfied(extraction_confirmed: bool) -> bool:
	# Called explicitly after BOTH ledger settlements, never from HUD callbacks.
	for row in evaluated_rows(extraction_confirmed):
		if row.required and row.status != "completed":
			return false
	return true


func preview_settlement(authority: InventoryLedger, extracted: bool, mission: MissionRules, duration: float) -> Dictionary:
	var rows := evaluated_rows(extracted, authority)
	var required := true
	for row in rows:
		if row.required and row.status != "completed": required = false
	var policy := MissionRules.new()
	policy.requires_extraction = true
	if extracted: policy.complete_extraction(required)
	else:
		policy.phase = MissionRules.Phase.FAILED
		policy.player_destroyed = mission.player_destroyed
		policy.deadline_expired = mission.deadline_expired
		policy.reason = mission.reason
	return _build_result(policy, duration, authority)

func _build_result(mission: MissionRules, duration: float, authority: InventoryLedger = null) -> Dictionary:
	var materials := authority if authority != null else _ledger.inventory
	var equipment := authority if authority != null else _equipment.inventory
	var rows := evaluated_rows(mission.player_extracted, authority)
	for row in rows:
		if row.status != "completed": row.status = "incomplete" if mission.player_extracted else ("expired" if mission.deadline_expired else "failed")
	var banked := materials.quantity("stash", true, "world") + materials.quantity("banked", true, "world")
	var forfeited := materials.quantity("forfeited", true, "world")
	var banked_items := equipment.equipment_summary(EquipmentLedger.Location.BANKED).x
	var forfeited_items := equipment.equipment_summary(EquipmentLedger.Location.FORFEITED).x
	return {"mission_id": str(_mission_id), "mission_name": _mission_name, "deployment_id": _deployment_id, "duration": duration, "extracted": mission.player_extracted, "destroyed": mission.player_destroyed, "expired": mission.deadline_expired, "success": mission.phase == MissionRules.Phase.SUCCEEDED, "reason": mission.reason, "objectives": rows, "materials_picked_up": materials.quantity("player", true, "world") + banked + forfeited, "materials_banked": banked, "materials_forfeited": forfeited, "equipment_picked_up": equipment.equipment_summary(EquipmentLedger.Location.RECOVERED).x + banked_items + forfeited_items, "equipment_banked": banked_items, "equipment_forfeited": forfeited_items}

func publish_committed(result: Dictionary) -> bool:
	if result.get("deployment_id") != _deployment_id or not result.get("objectives") is Array: return false
	if is_closed(): return _result == result
	_result = result.duplicate(true)
	_rows.assign(result.objectives)
	changed.emit()
	return true

func close(mission: MissionRules, duration: float) -> void:
	if is_closed(): return
	publish_committed(_build_result(mission, duration))


func is_closed() -> bool:
	return not _result.is_empty()


func snapshot() -> Array[Dictionary]:
	return _rows.duplicate(true)


func result() -> Dictionary:
	return _result.duplicate(true)


func dispose() -> void:
	if _ledger.inventory.changed.is_connected(_inventory_changed): _ledger.inventory.changed.disconnect(_inventory_changed)
	if _ledger.transfer_accepted.is_connected(_on_material):
		_ledger.transfer_accepted.disconnect(_on_material)
	if _equipment.transfer_accepted.is_connected(_on_equipment):
		_equipment.transfer_accepted.disconnect(_on_equipment)
