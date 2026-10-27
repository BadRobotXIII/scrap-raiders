class_name MissionConfig
extends Resource
## Mission definitions only. Runtime state belongs to the arena and ledger.

@export var mission_id: StringName
@export_multiline var description: String
@export_multiline var risk_description: String
@export var briefing_required: bool = false
@export var concise_hud: bool = false
@export var objective_definitions: Array[MissionObjectiveDefinition] = []
@export var display_name: String = "Intercept"
@export_range(1, 5) var raider_count: int = 3
@export_range(1, 3) var salvage_point_count: int = 3
@export_range(1, 99) var materials_per_point: int = 3
@export_range(10.0, 600.0) var duration: float = 180.0
@export var entry_times: PackedFloat32Array = PackedFloat32Array([0, 0, 0])
@export var spawn_markers: PackedStringArray = PackedStringArray(["Spawn1", "Spawn2", "Spawn3", "Spawn4", "Spawn5"])
@export var exits: PackedStringArray = PackedStringArray(["Extraction", "Extraction2"])
@export var seed: int = 4711
@export_range(0, 3) var ground_stacks: int = 0
@export_range(1, 99) var materials_per_stack: int = 3
@export var armed: bool = false
@export var death_flares: bool = false
@export var player_extraction: bool = false
@export var machine_ecosystem: bool = false
@export var experimental_traversal: bool = true
@export var social_rules: RaiderSocialConfig
@export var preferred_entries: PackedStringArray = []
@export var player_start_marker: StringName = &""
@export var post_death_spectating: bool = false
@export var encounter_layouts: Array[EncounterLayout] = []
@export_range(1, 5) var max_active_raiders: int = 5
@export var fallback_profiles: Array[RaiderProfile] = []
@export var hybrid_inventory: bool = false
@export var loot_table: LootTable


func validation_error() -> String:
	if hybrid_inventory and (loot_table == null or loot_table.salvage_definitions.is_empty() or not briefing_required):
		return "Hybrid inventory requires bounded loot and safe preparation."
	if not objective_definitions.is_empty():
		if mission_id.is_empty() or description.strip_edges().is_empty() or not player_extraction or not death_flares:
			return "Objective missions require identity, description, recall and equipment support."
		var objective_ids := {}
		var has_primary := false
		var has_extraction := false
		for objective in objective_definitions:
			if objective == null or not objective.validation_error().is_empty():
				return "Invalid mission objective."
			if objective_ids.has(objective.objective_id):
				return "Duplicate mission objective ID."
			objective_ids[objective.objective_id] = true
			has_primary = has_primary or (objective.required and objective.kind != MissionObjectiveDefinition.Kind.EXTRACT)
			has_extraction = has_extraction or (objective.required and objective.kind == MissionObjectiveDefinition.Kind.EXTRACT)
			if objective.kind == MissionObjectiveDefinition.Kind.BANK_MATERIALS:
				var pool := salvage_point_count * materials_per_point + ground_stacks * materials_per_stack + (2 if machine_ecosystem else 0)
				for layout in encounter_layouts:
					if layout == null:
						return "Invalid objective encounter layout."
					var layout_pool := ground_stacks * materials_per_stack + (2 if machine_ecosystem else 0)
					for amount in layout.salvage_quantities:
						layout_pool += amount
					if objective.target > layout_pool:
						return "Material objective exceeds an encounter's finite pool."
				if encounter_layouts.is_empty() and objective.target > pool:
					return "Material objective exceeds finite stock."
		if not has_primary or not has_extraction:
			return "Objectives require a primary and successful extraction."
	elif briefing_required:
		return "Briefing requires mission objectives."
	for profile in fallback_profiles:
		if profile == null or not profile.validation_error().is_empty():
			return "Invalid fallback Raider profile."
	if max_active_raiders < 1 or max_active_raiders > 5:
		return "Invalid live Raider limit."
	var layout_ids := {}
	for layout in encounter_layouts:
		if layout == null or not layout.validation_error(self).is_empty():
			return "Invalid encounter layout definition."
		if layout_ids.has(layout.layout_id):
			return "Duplicate encounter layout ID."
		layout_ids[layout.layout_id] = true
	if not preferred_entries.is_empty():
		if preferred_entries.size() != raider_count:
			return "Preferred entries must identify each Raider."
		for marker in preferred_entries:
			if not spawn_markers.has(marker):
				return "Preferred entry must belong to the spawn marker set."
	if social_rules != null and not social_rules.opportunist_ids.is_empty() and not armed:
		return "Betrayal requires an armed encounter."
	if social_rules != null and not social_rules.validation_error(raider_count).is_empty():
		return social_rules.validation_error(raider_count)
	if raider_count < 1 or raider_count > 5 or salvage_point_count < 1 or salvage_point_count > 3 or materials_per_point < 1:
		return "Invalid Raider or salvage quantities."
	if not is_finite(duration) or duration <= 0 or entry_times.size() != raider_count or spawn_markers.is_empty() or exits.is_empty():
		return "Missing entry schedule, spawn markers, exits, or duration."
	var previous := -1.0
	for time in entry_times:
		if not is_finite(time) or time < 0 or time < previous or time >= duration:
			return "Entry times must be ordered and precede the deadline."
		previous = time
	if ground_stacks < 0 or ground_stacks > 3 or materials_per_stack < 1:
		return "Invalid initial ground stock."
	return ""
