class_name DeploymentMetrics
extends Node
## Optional mission-local observer. Never supplies decisions or owns inventory.

const EVENT_LIMIT := 256
const COMBAT_STATES := [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]
var arena: Node3D
var actors: Dictionary = {}
var events: Array[Dictionary] = []
var counters: Dictionary = {}
var setup: Dictionary = {}
var objectives: Array[Dictionary] = []
var open_episodes: Dictionary = {}
var episode_count: int = 0
var episode_seconds: float = 0
var censored_count: int = 0
var discarded_events: int = 0
var sample_remaining: float = 0
var stopped: bool = false
var stop_reason: String = ""
var stop_time: float = 0
var peak_raiders: int = 0
var material_serial: int = 0
var equipment_serial: int = 0


func attach(owner_arena: Node3D) -> void:
	assert(arena == null) # Exactly one attachment per deployment.
	arena = owner_arena
	setup = serializable(arena.encounter.snapshot) if arena.encounter != null else {"seed": arena.debug_seed}
	setup["config"] = arena.config.resource_path
	setup["config_sha256"] = FileAccess.get_sha256(arena.config.resource_path)
	setup["profile_sources"] = []
	for profile in arena.resolved_profiles:
		setup.profile_sources.append({"path": profile.resource_path, "sha256": FileAccess.get_sha256(profile.resource_path)})
	setup["fingerprint"] = JSON.stringify(setup).sha256_text()
	arena.ledger.transfer_accepted.connect(on_material)
	if arena.flare_director != null:
		arena.flare_director.equipment.transfer_accepted.connect(on_equipment)
	var health := arena.robot.get_node("Health") as Health
	health.damaged.connect(on_player_damage)
	health.died.connect(on_player_death)
	observe_weapon(arena.robot.get_node("Weapon"), "player")
	if arena.ecosystem != null:
		for machine in arena.ecosystem.machines:
			machine.destroyed.connect(on_machine_death)
			observe_weapon(machine.weapon, str(machine.source_id))
	record("capture_started", {"fingerprint": setup.fingerprint})


func observe_weapon(weapon: Node, subject: String) -> void:
	if weapon != null:
		weapon.fired.connect(on_shot.bind(subject))


func register_actor(actor: Raider) -> void:
	if stopped or actors.has(actor.raider_id):
		return
	var id := actor.raider_id
	actors[id] = {"profile": actor.profile.display_name, "entry": arena.elapsed, "responder": actor.is_flare_responder}
	actor.state_changed.connect(on_state.bind(id))
	actor.navigation_recovered.connect(on_navigation.bind(id))
	observe_weapon(actor.combat.weapon if actor.combat != null else null, "R%d" % id)
	if actor.state in COMBAT_STATES:
		open_episodes[id] = arena.elapsed
	increment("admissions")
	if actor.is_flare_responder:
		increment("responder_admissions")
	record("admission", {"actor": id, "profile": actor.profile.display_name, "responder": actor.is_flare_responder})


func increment(key: String, amount: float = 1) -> void:
	counters[key] = float(counters.get(key, 0)) + amount


func on_material(kind: StringName, details: Dictionary) -> void:
	if stopped or int(details.serial) <= material_serial:
		return
	material_serial = int(details.serial)
	increment("material_" + str(kind) + "_events")
	increment("material_" + str(kind) + "_units", details.get("amount", 0))
	var entry := details.duplicate(true)
	if kind == &"defeat":
		var actor: Raider = arena.raiders.get(int(details.actor))
		entry["instigator"] = instigator(actor.health) if is_instance_valid(actor) else "unknown"
	record("material_" + str(kind), entry)


func on_equipment(kind: StringName, details: Dictionary) -> void:
	if stopped or int(details.serial) <= equipment_serial:
		return
	equipment_serial = int(details.serial)
	increment("equipment_" + str(kind) + "_events")
	increment("equipment_" + str(kind) + "_items", details.get("count", 0))
	record("equipment_" + str(kind), details)


func on_state(before: Raider.State, after: Raider.State, id: int) -> void:
	if stopped:
		return
	if after in COMBAT_STATES and not before in COMBAT_STATES:
		open_episodes[id] = arena.elapsed
	elif before in COMBAT_STATES and not after in COMBAT_STATES:
		close_episode(id, false)
	record("state", {"actor": id, "before": Raider.State.keys()[before], "after": Raider.State.keys()[after]})


func close_episode(id: int, censored: bool) -> void:
	if not open_episodes.has(id):
		return
	var duration := maxf(0, arena.elapsed - float(open_episodes[id]))
	episode_count += 1
	episode_seconds += duration
	censored_count += int(censored)
	record("combat_episode", {"actor": id, "duration": duration, "censored": censored})
	open_episodes.erase(id)


func on_navigation(details: Dictionary, id: int) -> void:
	if stopped:
		return
	var entry := details.duplicate(true)
	entry["actor"] = id
	increment("navigation_recoveries")
	record("navigation_recovery", entry)


func instigator(health: Health) -> String:
	var source := instance_from_id(health.last_damage_instigator_id) if health.last_damage_instigator_id > 0 else null
	return str(source.name) if is_instance_valid(source) and source is Node else "unknown"


func on_machine_death(machine: SupportMachine) -> void:
	if stopped:
		return
	increment("machine_deaths")
	record("machine_death", {"actor": machine.source_id, "instigator": instigator(machine.health)})


func on_player_damage(amount: float) -> void:
	if stopped:
		return
	increment("player_damage", amount)
	record("player_damage", {"amount": amount, "instigator": instigator(arena.robot.get_node("Health"))})


func on_player_death() -> void:
	# The coordinator may finish the world synchronously before this signal slot.
	# Player death still belongs in that final snapshot; no settlement is performed here.
	increment("player_deaths")
	record("player_death")


func on_shot(_origin: Vector3, _endpoint: Vector3, damaged: bool, subject: String) -> void:
	if stopped:
		return
	increment("shots")
	increment("damaging_shots", int(damaged))
	record("shot", {"actor": subject, "damaged": damaged})


func record(kind: String, details: Dictionary = {}) -> void:
	var entry: Dictionary = serializable(details)
	entry["kind"] = kind
	entry["time"] = arena.elapsed
	if events.size() == EVENT_LIMIT:
		events.pop_front()
		discarded_events += 1
	events.append(entry)


func sample() -> void:
	objectives.clear()
	var live := 0
	for actor in arena.raiders.values():
		if not is_instance_valid(actor) or not actor.is_inside_tree() or not arena.ledger.is_active(actor.raider_id):
			continue
		live += 1
		objectives.append({"actor": actor.raider_id, "state": Raider.State.keys()[actor.state], "position": serializable(actor.global_position), "navigation": actor.navigation_status, "salvage": str(actor.salvage.name) if is_instance_valid(actor.salvage) else "none", "target": str(actor.current_target().name) if is_instance_valid(actor.current_target()) else "none"})
	peak_raiders = maxi(peak_raiders, live)


func _physics_process(delta: float) -> void:
	if stopped or arena == null:
		return
	sample_remaining -= delta
	if sample_remaining <= 0:
		sample_remaining = 0.5
		sample()


func finish(reason: String) -> void:
	if stopped:
		return
	for id in open_episodes.keys():
		close_episode(id, true)
	if is_inside_tree():
		sample()
	stop_reason = reason
	stop_time = arena.elapsed
	stopped = true
	set_physics_process(false)


func snapshot() -> Dictionary:
	var ledger: MaterialLedger = arena.ledger
	var equipment := {}
	if arena.flare_director != null:
		for location in EquipmentLedger.Location.values():
			equipment[EquipmentLedger.Location.keys()[location]] = arena.flare_director.equipment.count_at(location)
	return {"setup": setup.duplicate(true), "duration": stop_time if stopped else arena.elapsed, "stopped": stopped, "reason": stop_reason, "actors": actors.duplicate(true), "counters": counters.duplicate(true), "combat_episodes": {"count": episode_count, "seconds": episode_seconds, "censored": censored_count, "open": open_episodes.size()}, "events": events.duplicate(true), "discarded_events": discarded_events, "unresolved": objectives.duplicate(true), "peak_raiders": peak_raiders, "response_tickets_committed": arena.flare_director.committed if arena.flare_director != null else 0, "materials": {"total": ledger.total_materials, "stock": ledger.protected_materials, "cargo": ledger.carried_materials, "ground": ledger.dropped_materials, "recovered": ledger.recovered_materials, "extracted": ledger.lost_materials, "banked": ledger.banked_materials, "forfeited": ledger.forfeited_materials, "valid": ledger.is_conserved()}, "equipment": equipment}


func export_json(path: String) -> Error:
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		return FileAccess.get_open_error()
	output.store_string(JSON.stringify(snapshot(), "\t"))
	return OK


static func serializable(value: Variant) -> Variant:
	if value is Vector3:
		return [value.x, value.y, value.z]
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = serializable(value[key])
		return result
	if value is Array or value is PackedFloat32Array or value is PackedInt32Array or value is PackedStringArray:
		var result: Array = []
		for item in value:
			result.append(serializable(item))
		return result
	return value
