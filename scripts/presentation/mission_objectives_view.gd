class_name MissionObjectivesView
extends Control
## Presentation only. The arena starts/settles; the objective owner supplies copies.

var arena: Node3D
var briefing: PanelContainer
var deploy_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	briefing = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.065, 0.085, 0.105, 0.98)
	briefing.add_theme_stylebox_override("panel", panel_style)
	arena.summary.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(briefing)
	briefing.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	briefing.offset_left = -440
	briefing.offset_right = 440
	briefing.offset_top = -300
	briefing.offset_bottom = 300
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	briefing.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var title := Label.new()
	title.text = arena.config.display_name
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	var information := Label.new()
	information.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	information.custom_minimum_size.x = 810
	information.text = arena.config.description + "\n\n"
	for definition in arena.config.objective_definitions:
		information.text += ("Required: " if definition.required else "Optional: ") + definition.description + "\n"
	information.text += "\n" + arena.config.risk_description
	information.text += "\n\nDeadline: %ds | Recall: hold E at the dock for %.0fs.\nEarly recall banks carried loot even if the primary is incomplete.\nDestruction or timeout forfeits this deployment's cargo; your stash is preserved." % [int(arena.mission_duration), arena.recall.channel_time]
	content.add_child(information)
	deploy_button = Button.new()
	deploy_button.text = "Deploy"
	deploy_button.custom_minimum_size.y = 48
	deploy_button.pressed.connect(arena.start_deployment)
	content.add_child(deploy_button)
	if arena.hybrid_inventory:
		var inventory_button := Button.new()
		inventory_button.text = "Stash / Prepared loadout [I]"
		inventory_button.pressed.connect(func() -> void: arena.interaction_mode.open_inventory())
		content.add_child(inventory_button)
	arena.get_node("Overlay/Summary/Content/Restart").text = "Prepare next deployment"


func prepare() -> void:
	if arena.mission.is_finished():
		briefing.hide()
		return
	if arena.deployment_started:
		begin()
		return
	briefing.show()
	for path in ["Robot/CombatHUD", "Robot/SurvivalHUD", "Overlay/MissionStatus", "Overlay/RaiderStatus", "Overlay/PickupPrompt"]:
		arena.get_node(path).hide()
	deploy_button.grab_focus()


func begin() -> void:
	briefing.hide()
	deploy_button.release_focus()
	for path in ["Robot/CombatHUD", "Robot/SurvivalHUD", "Overlay/MissionStatus", "Overlay/RaiderStatus"]:
		arena.get_node(path).show()


func describe_row(row: Dictionary, settled: bool = false) -> String:
	var prefix := "Required" if row.required else "Optional"
	if row.status == "completed":
		return "%s: %s [COMPLETE]" % [prefix, row.description]
	if settled:
		return "%s: %s [%s %d/%d]" % [prefix, row.description, str(row.status).to_upper(), mini(row.progress, row.target), row.target]
	if row.kind in [MissionObjectiveDefinition.Kind.BANK_MATERIALS, MissionObjectiveDefinition.Kind.BANK_EQUIPMENT]:
		var units := "materials" if row.kind == MissionObjectiveDefinition.Kind.BANK_MATERIALS else "equipment"
		return "%s: Carry %d/%d %s - recall to bank" % [prefix, row.carried, row.target, units]
	if row.kind == MissionObjectiveDefinition.Kind.EXTRACT:
		return "Required: Survive and recall at the dock"
	return "%s: Raiders defeated %d/%d" % [prefix, mini(row.progress, row.target), row.target]


func refresh() -> void:
	if arena.mission_objectives == null:
		return
	if not arena.deployment_started:
		arena.objectives.hide()
		return
	if not arena.mission.is_finished():
		var lines := PackedStringArray(["%s | %ds" % [arena.config.display_name, ceili(maxf(0, arena.mission_duration - arena.elapsed))]])
		for row in arena.mission_objectives.snapshot():
			lines.append(describe_row(row))
		arena.objectives.text = "\n".join(lines)
		arena.status.position.y = 190
	if arena.summary.visible and arena.mission_objectives.is_closed():
		arena.objectives.hide()
		arena.status.hide()
		arena.robot.get_node("SurvivalHUD").hide()
		var result: Dictionary = arena.mission_objectives.result()
		var outcome := "MISSION SUCCESS" if result.success else ("EXTRACTED - PRIMARY INCOMPLETE" if result.extracted else "DEPLOYMENT FAILED")
		var lines := PackedStringArray([result.mission_name, outcome, result.reason, ""])
		for row in result.objectives:
			lines.append(describe_row(row, true))
		lines.append("\nMaterials picked up %d | Banked %d | Forfeited %d" % [result.materials_picked_up, result.materials_banked, result.materials_forfeited])
		lines.append("Equipment picked up %d | Banked %d | Forfeited %d" % [result.equipment_picked_up, result.equipment_banked, result.equipment_forfeited])
		lines.append("Deployment: %.1fs | Press R or prepare next deployment." % result.duration)
		if arena.mission.player_destroyed:
			lines.append("World observation ended at %.1fs. Player results above are unchanged." % arena.elapsed)
		arena.get_node("Overlay/Summary/Content/Report").text = "\n".join(lines)
