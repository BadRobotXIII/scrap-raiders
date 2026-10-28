class_name StationRegistry
extends RefCounted
## Both navigation paths validate here and call the same station entry.
var sanctuary: Node3D
var stations: Dictionary = {}
var last_error: String = ""

func register(station: WorkshopStation) -> bool:
	if station.station_id.is_empty() or stations.has(station.station_id): return false
	stations[station.station_id] = station
	return true

func nearest() -> WorkshopStation:
	var selected: WorkshopStation
	var distance := 2.6
	for station in stations.values():
		var candidate: float = sanctuary.robot.global_position.distance_to(station.global_position)
		if candidate < distance:
			distance = candidate
			selected = station
	return selected

func anchor_valid(station: WorkshopStation) -> bool:
	var point := station.anchor()
	if absf(point.x) > 9 or absf(point.z) > 7: return false
	var world := sanctuary.get_world_3d().direct_space_state
	var floor_query := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP * 0.6, 1)
	if world.intersect_ray(floor_query).is_empty(): return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.56
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = point + Vector3.UP * 0.95
	query.collision_mask = 1
	query.exclude = [sanctuary.robot.get_rid()]
	if not world.intersect_shape(query, 1).is_empty(): return false
	# Fixed perimeter stations connect to a reserved central aisle. Neither props nor
	# later placement may occupy it; verify the direct standing-body sweep as well.
	query.transform.origin = Vector3(0, 0.95, 0)
	query.motion = point
	var sweep := world.cast_motion(query)
	return sweep.size() == 2 and sweep[0] >= 0.999

func open_station(id: StringName, quick: bool) -> bool:
	last_error = ""
	var station := stations.get(id) as WorkshopStation
	if station == null or not station.available:
		last_error = "Station is unavailable."
		return false
	if sanctuary.mode != sanctuary.Mode.WALKING:
		last_error = "Close the current interaction first."
		return false
	if not anchor_valid(station):
		last_error = "Station access is obstructed."
		return false
	if not quick:
		if sanctuary.robot.global_position.distance_to(station.global_position) > 2.6:
			last_error = "Move closer to the station."
			return false
		var query := PhysicsRayQueryParameters3D.create(sanctuary.robot.global_position + Vector3.UP, station.anchor() + Vector3.UP, 1)
		if not sanctuary.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			last_error = "Station access is blocked."
			return false
	sanctuary.robot.input_adapter.clear_intent()
	sanctuary.robot.stop_traversal()
	if quick: sanctuary.robot.global_position = station.anchor() + Vector3.UP * 0.05
	sanctuary.enter_station(station)
	return true
