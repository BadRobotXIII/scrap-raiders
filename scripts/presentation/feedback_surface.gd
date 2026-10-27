class_name FeedbackSurface
extends RefCounted
## Explicit collision metadata only. Never infers gameplay material properties.

const KINDS: Array[StringName] = [&"metal", &"concrete", &"industrial_equipment", &"machine_armor", &"raider_gear", &"hard_surface"]

static func normalized(value: StringName) -> StringName:
	return value if KINDS.has(value) else &"hard_surface"

static func color_for(value: StringName) -> Color:
	match normalized(value):
		&"concrete", &"hard_surface": return Color(0.66, 0.64, 0.57)
		&"raider_gear": return Color(0.7, 0.65, 0.48)
		&"machine_armor": return Color(0.45, 0.9, 1.0)
	return Color(1.0, 0.65, 0.19)

static func sound_for(value: StringName) -> String:
	var kind := normalized(value)
	return "impacts/" + ("equipment" if kind == &"industrial_equipment" else String(kind))
