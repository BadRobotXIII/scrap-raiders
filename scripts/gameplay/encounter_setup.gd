class_name EncounterSetup
extends Node
## Resolves finite starting conditions and reads events. No actor decisions.

var arena: Node3D
var layout: EncounterLayout
var snapshot: Dictionary = {}
var events: Array[String] = []
var members: Dictionary[String, Array] = {}
var sample_remaining: float = 0
var navigation_checked: bool = false
var observed_sites: Array[String] = []
var peak_autonomous_actors: int = 0
var details: String = ""


func resolve(config: MissionConfig, seed_value: int) -> String:
	var error := config.validation_error()
	if not error.is_empty():
		return error
	layout = choose_layout(config, seed_value)
	var positions: Array[Vector3] = []
	for path in layout.salvage_markers:
		var marker := arena.get_node_or_null(NodePath(path)) as Marker3D
		if marker == null:
			return "Missing encounter salvage marker: %s" % path
		if not marker.global_position.is_finite():
			return "Non-finite encounter location."
		for position in positions:
			if marker.global_position.distance_to(position) < 1:
				return "Overlapping encounter salvage locations."
		positions.append(marker.global_position)
	for path in layout.machine_routes:
		var route := arena.get_node_or_null(NodePath(path))
		if route == null or route.get_child_count() < 2:
			return "Missing encounter patrol route: %s" % path
		for point in route.get_children():
			if not point is Marker3D or not point.global_position.is_finite():
				return "Patrol points must be authored markers."
	var names := [&"Salvage", &"Salvage2", &"Salvage3"]
	for index in range(positions.size()):
		arena.get_node(NodePath(names[index])).global_position = positions[index]
		arena.salvage_quantities[names[index]] = layout.salvage_quantities[index]
	arena.resolved_profiles = layout.profiles.duplicate()
	arena.machine_routes = layout.machine_routes.duplicate()
	var profile_names: Array[String] = []
	for profile in layout.profiles:
		profile_names.append(profile.display_name)
	snapshot = {"seed": seed_value, "layout": layout.layout_id, "positions": positions.duplicate(), "quantities": layout.salvage_quantities.duplicate(), "entries": layout.entry_markers.duplicate(), "times": config.entry_times.duplicate(), "profiles": profile_names, "routes": layout.machine_routes.duplicate()}
	record("SETUP seed %d layout %s" % [seed_value, layout.layout_id])
	print(events[-1])
	return ""


static func choose_layout(config: MissionConfig, seed_value: int) -> EncounterLayout:
	var choices := config.encounter_layouts.duplicate()
	choices.sort_custom(func(a: EncounterLayout, b: EncounterLayout) -> bool: return str(a.layout_id) < str(b.layout_id))
	var random := RandomNumberGenerator.new()
	random.seed = hash("SCRAP encounter %d" % seed_value)
	return choices[random.randi_range(0, choices.size() - 1)]


func ground_valid(position: Vector3) -> bool:
	var floor_query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.2, position + Vector3.DOWN * 0.5, 1)
	var floor_hit := arena.get_world_3d().direct_space_state.intersect_ray(floor_query)
	if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP) < 0.7:
		return false
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	var closest := NavigationServer3D.map_get_closest_point(map, position)
	return NavigationServer3D.map_get_closest_point_owner(map, position).is_valid() and closest.distance_to(position) <= 0.6 and arena.reaches_any(map, closest, arena.extraction_points)


func geometry_clear(position: Vector3, flying: bool) -> bool:
	var shape := CapsuleShape3D.new()
	shape.height = 1.2 if flying else 1.8
	shape.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = position + Vector3.UP * (shape.height * 0.5 + 0.1)
	query.collision_mask = 1
	return arena.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func validate_navigation() -> String:
	for point in arena.salvage_points:
		if not ground_valid(point.global_position) or not geometry_clear(point.global_position, false):
			return "Invalid encounter salvage surface/navigation: %s" % point.name
	for index in range(layout.machine_routes.size()):
		var route := arena.get_node(NodePath(layout.machine_routes[index]))
		for point in route.get_children():
			if not geometry_clear(point.global_position, index == 0) or (index == 1 and not ground_valid(point.global_position)):
				return "Invalid encounter patrol point: %s/%s" % [route.name, point.name]
	navigation_checked = true
	return ""


func record(message: String) -> void:
	events.append("%.1fs %s" % [arena.elapsed, message])
	if events.size() > 64:
		events.pop_front()


func register_actor(actor: Raider) -> void:
	record("R%02d entered at (%.0f, %.0f)" % [actor.raider_id, actor.position.x, actor.position.z])
	actor.state_changed.connect(func(_previous: Raider.State, next: Raider.State) -> void:
		var objective := str(actor.salvage.name) if is_instance_valid(actor.salvage) else "none"
		record("R%02d %s | objective %s | cargo %d" % [actor.raider_id, Raider.State.keys()[next], objective, actor.carried_materials]))
	actor.cargo_collected.connect(func(amount: int) -> void: record("R%02d collected; carried %d" % [actor.raider_id, amount]))
	actor.extracted.connect(func(amount: int) -> void: record("R%02d extracted %d" % [actor.raider_id, amount]))


func describe() -> String:
	return details


func build_description() -> String:
	var lines: Array[String] = ["ENCOUNTERS seed %d | %s | live Raider cap %d" % [snapshot.seed, layout.layout_id, arena.max_active_raiders]]
	for point in arena.salvage_points:
		lines.append("%s at (%.0f, %.0f): %d stock | nearby %s" % [point.name, point.position.x, point.position.z, arena.ledger.available(point.name), members.get(str(point.name), [])])
	lines.append("Patrols %s | entries %s | quantities %s" % [layout.machine_routes, layout.entry_markers, layout.salvage_quantities])
	for index in range(maxi(0, events.size() - 6), events.size()):
		lines.append(events[index])
	var ids: Array = arena.raiders.keys()
	ids.sort()
	for id in ids:
		var actor = arena.raiders[id]
		if not is_instance_valid(actor) or not arena.ledger.is_active(id):
			continue
		var target := str(actor.current_target().name) if is_instance_valid(actor.current_target()) else "none"
		var salvage := str(actor.salvage.name) if is_instance_valid(actor.salvage) else "none"
		lines.append("R%02d %s %s | objective %s | target %s | cargo %d | threat %s" % [id, actor.profile.display_name, Raider.State.keys()[actor.state], salvage, target, actor.carried_materials, actor.threat_source])
		if actor.combat != null and actor.profile.combat_policy != RaiderProfile.CombatPolicy.BASELINE:
			lines.append("  " + actor.combat.describe_policy())
		var attitudes: Array[String] = []
		for other in ids:
			if arena.social != null and other != id and arena.ledger.is_active(other):
				attitudes.append("R%02d:%s" % [other, RaiderRelations.Attitude.keys()[arena.social.relations.attitude(id, other)]])
		lines.append("  " + ", ".join(attitudes))
	return "\n".join(lines)


func _physics_process(delta: float) -> void:
	if arena.mission.is_world_finished() or layout == null:
		return
	sample_remaining -= delta
	if sample_remaining > 0:
		return
	sample_remaining = 0.5
	var actors: Array[Node3D] = []
	for actor in arena.raiders.values():
		if is_instance_valid(actor) and actor.health.current > 0 and arena.ledger.is_active(actor.raider_id):
			actors.append(actor)
	if arena.ecosystem != null:
		actors.append_array(arena.ecosystem.machines)
	peak_autonomous_actors = maxi(peak_autonomous_actors, actors.size())
	for point in arena.salvage_points:
		var near: Array[String] = []
		for actor in actors:
			if is_instance_valid(actor) and actor.global_position.distance_to(point.global_position) <= 12:
				near.append("R%02d" % actor.raider_id if actor is Raider else str(actor.source_id))
		near.sort()
		if not near.is_empty() and not observed_sites.has(str(point.name)):
			observed_sites.append(str(point.name))
		if near != members.get(str(point.name), []):
			record("%s nearby %s" % [point.name, near])
		members[str(point.name)] = near
	details = build_description()
