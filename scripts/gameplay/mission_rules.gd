class_name MissionRules
extends RefCounted
## Sole owner of mission phase and material accounting for the one-Raider slice.

enum Phase { HUNTING, RECOVERING, SUCCEEDED, FAILED }

var phase: Phase = Phase.HUNTING
var protected_materials: int = 3
var carried_materials: int = 0
var dropped_materials: int = 0
var recovered_materials: int = 0
var lost_materials: int = 0
var reason: String = ""


func is_finished() -> bool:
	return phase in [Phase.SUCCEEDED, Phase.FAILED]


func scavenge(amount: int) -> bool:
	if phase != Phase.HUNTING or carried_materials != 0 or amount <= 0 or amount > protected_materials:
		return false
	protected_materials -= amount
	carried_materials = amount
	return true


func defeat(amount: int) -> bool:
	if phase != Phase.HUNTING or amount != carried_materials:
		return false
	carried_materials = 0
	dropped_materials = amount
	if amount == 0:
		phase = Phase.SUCCEEDED
		reason = "The Raider was stopped before stealing materials."
	else:
		phase = Phase.RECOVERING
	return true


func extract(amount: int) -> bool:
	if phase != Phase.HUNTING or amount != carried_materials:
		return false
	carried_materials = 0
	lost_materials = amount
	phase = Phase.FAILED if amount > 0 else Phase.SUCCEEDED
	reason = "The Raider escaped with stolen materials." if amount > 0 else "The Raider fled empty; all materials remain protected."
	return true


func recover(amount: int) -> bool:
	if phase != Phase.RECOVERING or amount <= 0 or amount != dropped_materials:
		return false
	dropped_materials = 0
	recovered_materials += amount
	phase = Phase.SUCCEEDED
	reason = "All stolen materials recovered."
	return true


func expire() -> void:
	if not is_finished():
		phase = Phase.FAILED
		reason = "Deployment time expired."
