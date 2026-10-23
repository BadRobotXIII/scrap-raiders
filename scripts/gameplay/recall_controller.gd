class_name RecallController
extends Node
## Owns the recall channel and coordinates reward persistence with ledger settlement.

var arena: Node3D
var stash: PersistentStash
var deployment_id: String
var elapsed: float = 0.0
var channel_time: float = 5.0
var start_position: Vector3
var channeling: bool = false
var save_error: String = ""
var dock: Node3D
var label: Label3D
var stash_label: Label


func setup() -> void:
	process_physics_priority = 40
	deployment_id = Crypto.new().generate_random_bytes(16).hex_encode()
	stash = PersistentStash.new(arena.stash_path)
	if not stash.load_stash():
		save_error = stash.last_error
	dock = arena.get_node("RecallDock")
	var mesh := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.5
	ring.outer_radius = 1.8
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.25, 0.7, 1)
	ring.material = material
	mesh.mesh = ring
	mesh.position.y = 0.08
	dock.add_child(mesh)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.6
	label.font_size = 40
	dock.add_child(label)
	stash_label = Label.new()
	stash_label.position = Vector2(24, 610)
	stash_label.add_theme_font_size_override("font_size", 18)
	stash_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stash_label.add_theme_constant_override("outline_size", 4)
	stash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.get_node("Overlay").add_child(stash_label)
	refresh_stash()
	refresh()


func eligible() -> bool:
	if not arena.deployment_started or arena.mission.is_finished() or arena.robot.get_node("Health").current <= 0 or arena.elapsed >= arena.mission_duration:
		return false
	if arena.robot.global_position.distance_to(dock.global_position) > 2.0:
		return false
	var query := PhysicsRayQueryParameters3D.create(arena.robot.global_position + Vector3.UP, dock.global_position + Vector3.UP * 0.3, 1)
	query.hit_from_inside = true
	return arena.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func cancel() -> void:
	elapsed = 0
	channeling = false


func can_channel() -> bool:
	var input: RobotInput = arena.robot.input_adapter
	var velocity := Vector2(arena.robot.velocity.x, arena.robot.velocity.z)
	if arena.robot.traversal_enabled and (input.jump_requested or input.boost_requested or not arena.robot.is_on_floor() or arena.robot.boost_state == RobotController.BoostState.BOOSTING):
		return false
	return eligible() and input.recover_held and not input.fire_intent and input.move_intent.is_zero_approx() and velocity.length() <= 0.1 and arena.selected_drop() == null and arena.flare_director.selected_drop() == null


func step(delta: float) -> void:
	if arena.mission.is_finished():
		return
	if not can_channel():
		cancel()
	elif not channeling:
		channeling = true
		start_position = arena.robot.global_position
		elapsed = 0
	elif start_position.distance_to(arena.robot.global_position) > 0.25:
		cancel()
	else:
		elapsed += delta
		if elapsed >= channel_time:
			complete()
	refresh()


func complete() -> bool:
	if not channeling or elapsed < channel_time or not can_channel() or start_position.distance_to(arena.robot.global_position) > 0.25 or not arena.ledger.can_settle_player() or not arena.flare_director.equipment.can_settle_player():
		return false
	var items: Array[Dictionary] = arena.flare_director.equipment.recovered_items()
	if not stash.commit_rewards(deployment_id, arena.ledger.recovered_materials, items):
		save_error = stash.last_error
		cancel()
		refresh_stash()
		return false
	save_error = ""
	refresh_stash()
	arena.ledger.settle_player(true)
	arena.flare_director.equipment.settle_player(true)
	arena.complete_player_extraction()
	return true


func settle_failure() -> void:
	cancel()
	if not arena.mission.player_extracted:
		arena.ledger.settle_player(false)
		arena.flare_director.equipment.settle_player(false)
		if arena.mission.player_destroyed:
			arena.mission.reason = "Robot destroyed. Carried loot forfeited; stash unchanged."
		elif arena.mission.deadline_expired:
			arena.mission.reason = "Recall deadline expired. Carried loot forfeited; stash unchanged."
	set_physics_process(false)
	refresh()


func refresh() -> void:
	label.text = "RECALL DOCK" if arena.uses_concise_hud() else "RECALL DOCK\nHold [E] %.1fs" % maxf(0, channel_time - elapsed)
	if arena.mission.is_finished():
		label.text = "RECALL COMPLETE" if arena.mission.player_extracted else "RECALL UNAVAILABLE"
	if eligible() and arena.selected_drop() == null and arena.flare_director.selected_drop() == null:
		arena.get_node("Overlay/PickupPrompt").show()
		arena.get_node("Overlay/PickupPrompt").text = "Hold [E] Recall %.1fs" % maxf(0, channel_time - elapsed)


func refresh_stash() -> void:
	# Inventory changes only on load/save, not every physics tick.
	var state := stash.snapshot()
	stash_label.text = "STASH | Materials %d | Equipment %d" % [state.get("materials", 0), state.get("equipment", {}).size()]
	var counts := {}
	for item in state.get("equipment", {}).values():
		counts[item.name] = int(counts.get(item.name, 0)) + 1
	var names := counts.keys()
	names.sort()
	var descriptions := PackedStringArray()
	for item_name in names:
		descriptions.append("%s x%d" % [item_name, counts[item_name]])
	if not descriptions.is_empty():
		stash_label.text += "\n" + " | ".join(descriptions)
	if not save_error.is_empty():
		stash_label.text += "\nRecall save failed: %s Retry at dock." % save_error
	elif stash.used_backup:
		stash_label.text += " | Backup restored"


func _physics_process(delta: float) -> void:
	step(delta)
