class_name MachineEcosystem
extends Node
## Composition/target queries only. Individual actors retain their state machines.

var arena: Node3D
var awareness := MachineAwareness.new()
var machines: Array[SupportMachine] = []
var component_drop_ids: Array[int] = []


func setup() -> void:
	for definition in [["ScoutComponents", arena.machine_routes[0], true], ["GuardComponents", arena.machine_routes[1], false]]:
		var actor := SupportMachine.new()
		actor.name = definition[0]
		actor.source_id = StringName(definition[0])
		actor.flying = definition[2]
		actor.arena = arena
		actor.awareness = awareness
		for marker in arena.get_node(definition[1]).get_children():
			actor.route.append(marker.global_position)
		actor.position = arena.to_local(actor.route[0])
		arena.add_child(actor)
		actor.destroyed.connect(_on_destroyed)
		machines.append(actor)


func choose_target(actor: Raider) -> Node3D:
	var candidates: Array[Node3D] = [arena.robot]
	for machine in machines:
		if is_instance_valid(machine) and machine.health.current > 0:
			candidates.append(machine)
	var selected: Node3D
	var best := INF
	for machine in candidates:
		if not actor.detects_machine(machine):
			continue
		var score := actor.global_position.distance_squared_to(machine.global_position)
		if machine == actor.combat_target:
			score *= 0.7 # Keep a visible target unless a meaningfully closer one appears.
		if score < best:
			best = score
			selected = machine
	return selected


func component_drops() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for id in component_drop_ids:
		var drop = arena.drops.get(id)
		if is_instance_valid(drop) and arena.ledger.ground_for(id) > 0:
			result.append(drop)
	return result


func _on_destroyed(machine: SupportMachine) -> void:
	machines.erase(machine)
	if arena.mission.is_world_finished():
		return
	var id: int = arena.ledger.release_source(machine.source_id)
	if id <= 0:
		return
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	var position := NavigationServer3D.map_get_closest_point(map, machine.global_position)
	position.y -= 0.5 # Same bake/agent height offset as the arena.
	arena.present_drop(id, position)
	component_drop_ids.append(id)
	arena.after_event()


func stop() -> void:
	for machine in machines:
		if is_instance_valid(machine):
			machine.stop()
