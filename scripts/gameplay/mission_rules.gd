class_name MissionRules
extends RefCounted
## Outcome policy only. Never writes quantities or transfers materials.

enum Phase { HUNTING, RECOVERING, SUCCEEDED, FAILED }

var phase: Phase = Phase.HUNTING
var reason: String = ""


func is_finished() -> bool:
	return phase in [Phase.SUCCEEDED, Phase.FAILED]


func evaluate(ledger: MaterialLedger, deadline_expired: bool = false) -> void:
	if is_finished():
		return
	if deadline_expired:
		phase = Phase.FAILED
		reason = "Deployment time expired. Ground cargo remains unrecovered, not extracted."
	elif ledger.active_raiders > 0:
		phase = Phase.HUNTING
	elif ledger.dropped_materials > 0:
		phase = Phase.RECOVERING
	elif ledger.lost_materials > 0:
		phase = Phase.FAILED
		reason = "All Raiders resolved; some materials escaped through extraction."
	else:
		phase = Phase.SUCCEEDED
		reason = "All Raiders resolved. Materials are protected or recovered."


func fail_setup(message: String) -> void:
	phase = Phase.FAILED
	reason = message
