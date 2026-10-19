class_name MaterialDrop
extends Node3D
## Owns this world's stack; consuming it is a one-time synchronous transfer.

@export var materials: int = 0


func _ready() -> void:
	$Label3D.text = "%d RECOVERABLE MATERIALS" % materials
	set_pickup_available(false)


func set_pickup_available(available: bool) -> void:
	$PickupHighlight.visible = available
	$Label3D.text = "[E] RECOVER %d MATERIALS" % materials if available else "%d RECOVERABLE MATERIALS" % materials


func consume() -> int:
	var amount := materials
	materials = 0
	queue_free()
	return amount
