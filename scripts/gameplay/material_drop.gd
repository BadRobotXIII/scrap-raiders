class_name MaterialDrop
extends Node3D
## Visual representation of a ledger stack. Cannot create, consume, or credit stock.

var ledger: MaterialLedger
var drop_id: int = 0
var materials: int:
	get:
		return ledger.inventory.quantity(inventory_container(), true, "world") if ledger != null else 0

func inventory_container() -> String:
	return "ground:%d" % drop_id

func content_count() -> int:
	return ledger.inventory.quantity(inventory_container()) if ledger != null else 0


func _ready() -> void:
	assert(ledger != null and materials > 0 and drop_id > 0)
	set_pickup_available(false)


func set_pickup_available(available: bool) -> void:
	$PickupHighlight.visible = available
	$Label3D.text = "[E] RECOVER %d MATERIALS" % materials if available else "%d RECOVERABLE MATERIALS" % materials
