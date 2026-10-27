class_name EquipmentBinding
extends Node
## Ownership enables existing weapon simulation. No new equipment statistics.
var ledger: InventoryLedger
var container_id: String
var weapon: ShotExecutor
var controls_allowed: Callable

func bind(authority: InventoryLedger, source: String, executor: ShotExecutor, permission: Callable = Callable()) -> void:
	ledger = authority
	container_id = source
	weapon = executor
	controls_allowed = permission
	ledger.changed.connect(_changed)
	refresh()

func _changed(_event: Dictionary) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(weapon): return
	var mounted := false
	for item in ledger.records(container_id):
		var definition := ledger.catalog.find(StringName(item.definition))
		if item.slot == "e:primary" and definition != null and definition.weapon == weapon.definition: mounted = true
	weapon.enabled = mounted and not ledger.container(container_id).get("closed", true) and (not controls_allowed.is_valid() or controls_allowed.call())
