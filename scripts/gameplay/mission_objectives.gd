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
	refresh()


func _on_material(_kind: StringName, details: Dictionary) -> void:
	if is_closed() or int(details.serial) <= _material_serial:
		return
	_material_serial = int(details.serial)
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


func evaluated_rows(extracted: bool = false) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for definition in _definitions:
		var progress := 0
		var carried := 0
		match definition.kind:
			MissionObjectiveDefinition.Kind.BANK_MATERIALS:
				progress = _ledger.banked_materials
				carried = _ledger.recovered_materials
			MissionObjectiveDefinition.Kind.BANK_EQUIPMENT:
				progress = _equipment.count_at(EquipmentLedger.Location.BANKED)
				carried = _equipment.count_at(EquipmentLedger.Location.RECOVERED)
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


func close(mission: MissionRules, duration: float) -> void:
	if is_closed():
		return
	_rows = evaluated_rows(mission.player_extracted)
	for row in _rows:
		if row.status != "completed":
			row.status = "incomplete" if mission.player_extracted else ("expired" if mission.deadline_expired else "failed")
	var banked_items := _equipment.count_at(EquipmentLedger.Location.BANKED)
	var forfeited_items := _equipment.count_at(EquipmentLedger.Location.FORFEITED)
	_result = {"mission_id": str(_mission_id), "mission_name": _mission_name, "deployment_id": _deployment_id, "duration": duration, "extracted": mission.player_extracted, "destroyed": mission.player_destroyed, "expired": mission.deadline_expired, "success": mission.phase == MissionRules.Phase.SUCCEEDED, "reason": mission.reason, "objectives": _rows.duplicate(true), "materials_picked_up": _ledger.recovered_materials + _ledger.banked_materials + _ledger.forfeited_materials, "materials_banked": _ledger.banked_materials, "materials_forfeited": _ledger.forfeited_materials, "equipment_picked_up": _equipment.count_at(EquipmentLedger.Location.RECOVERED) + banked_items + forfeited_items, "equipment_banked": banked_items, "equipment_forfeited": forfeited_items}
	changed.emit()


func is_closed() -> bool:
	return not _result.is_empty()


func snapshot() -> Array[Dictionary]:
	return _rows.duplicate(true)


func result() -> Dictionary:
	return _result.duplicate(true)


func dispose() -> void:
	if _ledger.transfer_accepted.is_connected(_on_material):
		_ledger.transfer_accepted.disconnect(_on_material)
	if _equipment.transfer_accepted.is_connected(_on_equipment):
		_equipment.transfer_accepted.disconnect(_on_equipment)
