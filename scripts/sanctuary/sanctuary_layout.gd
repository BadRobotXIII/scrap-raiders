class_name SanctuaryLayout
extends RefCounted
## Pure bounded geometry policy used both before save and during load.
static func footprint(row: Dictionary) -> Rect2:
	var definition := PlaceableDefinition.find(row.definition)
	var size := Vector2(definition.dimensions.x, definition.dimensions.z)
	if int(row.rotation) % 2 == 1: size = Vector2(size.y, size.x)
	return Rect2(Vector2(row.x, row.z) - size / 2, size)

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() > 8: return false
	var ids := {}
	var occupied: Array[Rect2] = []
	for row in value:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or row.id.length() > 64 or ids.has(row.id): return false
		if not row.get("definition") is String or PlaceableDefinition.find(row.definition) == null: return false
		if not row.get("rotation") is int or row.rotation < 0 or row.rotation > 3: return false
		for axis in ["x", "z"]:
			if not row.get(axis) is int and not row.get(axis) is float: return false
			if not is_finite(float(row[axis])) or absf(float(row[axis]) * 2 - roundf(float(row[axis]) * 2)) > 0.001: return false
		var area := footprint(row).grow(0.12)
		if not Rect2(1.5, -2, 6, 4).encloses(area): return false
		# Reserve body-width corridors from the central aisle to every fixed anchor.
		for x in [-7.0, 0.0, 7.0]:
			for z in [-4.7, 4.7]:
				var endpoint := Vector2(x, z)
				for step in 41:
					if area.grow(0.7).has_point(endpoint * step / 40.0): return false
		for prior in occupied:
			if area.intersects(prior): return false
		occupied.append(area)
		ids[row.id] = true
	return true

static func save(preparation: PreparationService, rows: Array) -> Dictionary:
	if not valid(rows): return {"ok": false, "reason": "Placement overlaps, leaves the marked area or blocks a protected route."}
	return preparation.metadata({"layout": rows}, func(home: Dictionary) -> Dictionary:
		home.layout = rows.duplicate(true)
		return {"ok": true})
