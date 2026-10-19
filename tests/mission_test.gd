extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)


func conserved(rules: MissionRules) -> bool:
	return rules.protected_materials + rules.carried_materials + rules.dropped_materials + rules.recovered_materials + rules.lost_materials == 3


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func create_arena() -> Node3D:
	var arena := load("res://scenes/levels/test_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.get_node("Robot/Input").set_physics_process(false)
	arena.get_node("Robot/Input").set_process_input(false)
	return arena


func run() -> void:
	var rules := MissionRules.new()
	check(not rules.scavenge(-1) and not rules.scavenge(4) and not rules.recover(3), "Invalid/out-of-phase material transfers rejected")
	check(rules.scavenge(3) and conserved(rules), "Scavenging transfers protected stock to carried cargo")
	check(not rules.scavenge(3) and not rules.defeat(2), "Duplicate scavenging and inconsistent death amounts rejected")
	check(rules.defeat(3) and rules.phase == MissionRules.Phase.RECOVERING and conserved(rules), "Loaded defeat waits for cargo recovery")
	check(not rules.extract(3) and not rules.defeat(3), "Resolved Raider cannot produce a second outcome")
	check(rules.recover(3) and rules.recovered_materials == 3 and conserved(rules), "Recovery credits mission inventory exactly once")
	check(not rules.recover(3) and not rules.extract(3), "Completed mission rejects late transfers")
	rules.expire()
	check(rules.phase == MissionRules.Phase.SUCCEEDED, "Timeout cannot overwrite success")
	rules = MissionRules.new()
	check(rules.defeat(0) and rules.protected_materials == 3 and rules.is_finished(), "Stopping an empty Raider protects all stock")
	rules = MissionRules.new()
	check(rules.extract(0) and rules.phase == MissionRules.Phase.SUCCEEDED, "Empty extraction loses no materials")
	rules = MissionRules.new()
	rules.scavenge(3)
	check(rules.extract(3) and rules.lost_materials == 3 and rules.phase == MissionRules.Phase.FAILED and conserved(rules), "Loaded extraction records loss and failure")
	rules = MissionRules.new()
	rules.scavenge(3)
	rules.defeat(3)
	rules.expire()
	check(rules.phase == MissionRules.Phase.FAILED and rules.dropped_materials == 3 and conserved(rules), "Timeout preserves unrecovered cargo accounting")

	var arena := create_arena()
	var raider := arena.get_node("Raider") as Raider
	var robot := arena.get_node("Robot") as RobotController
	raider.position = arena.get_node("Salvage").position
	raider.scavenge_seconds = 0.1
	await frames(20)
	raider.health.apply_damage(1000)
	await frames(2)
	check(arena.mission.phase == MissionRules.Phase.RECOVERING and not arena.get_node("Overlay/Summary").visible, "Loaded kill keeps gameplay active until pickup")
	check(not arena.try_recover(), "Distant pickup rejected")
	var drop := arena.cargo_drop as MaterialDrop
	robot.position = drop.position + Vector3(0, 0, 1)
	var cover := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 0.2)
	collision.shape = shape
	cover.add_child(collision)
	arena.add_child(cover)
	cover.position = drop.position + Vector3(0, 1, 0.5)
	await frames(3)
	check(not arena.try_recover(), "Pickup cannot pass through solid cover")
	cover.queue_free()
	await frames(3)
	check(arena.can_recover(), "Nearby unobstructed cargo is recoverable")
	robot.input_adapter.pickup_intent = true
	await frames(2)
	check(arena.mission.recovered_materials == 3 and arena.mission.phase == MissionRules.Phase.SUCCEEDED, "Logical E intent transfers world stack into recovered inventory")
	check(not arena.try_recover() and arena.mission.recovered_materials == 3, "Repeated pickup does not duplicate credit")
	check(not is_instance_valid(drop) and get_nodes_in_group("material_drops").is_empty(), "Recovered world stack removed")
	check(arena.get_node("Overlay/Summary").visible and arena.get_node("Overlay/Summary/Content/Report").text.contains("Recovered: 3"), "Success summary reports recovered materials")
	check(not robot.is_physics_processing() and not robot.get_node("Weapon").is_physics_processing() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Mission end stops controls/combat and releases cursor")
	# Exercise the actual restart button's connection and scene reload.
	arena.get_node("Overlay/Summary/Content/Restart").pressed.emit()
	await frames(5)
	arena = current_scene
	check(arena != null and arena.mission.phase == MissionRules.Phase.HUNTING and arena.mission.protected_materials == 3 and arena.mission.recovered_materials == 0, "Restart creates a fresh mission ledger")
	check(arena.get_node("Raider/Health").current == 100 and not arena.get_node("Overlay/Summary").visible and get_nodes_in_group("material_drops").is_empty(), "Restart restores Raider, HUD, and clean world")
	arena.get_node("Robot/Input").set_physics_process(false)
	arena.get_node("Robot/Input").set_process_input(false)
	raider = arena.get_node("Raider") as Raider
	raider.health.apply_damage(1000)
	await frames(2)
	check(arena.mission.phase == MissionRules.Phase.SUCCEEDED and arena.mission.protected_materials == 3, "Early interception succeeds without requiring nonexistent loot")
	var restart_event := InputEventAction.new()
	restart_event.action = "restart"
	restart_event.pressed = true
	arena._unhandled_input(restart_event)
	await frames(5)
	arena = current_scene
	check(arena.mission.phase == MissionRules.Phase.HUNTING, "Restart action reloads after terminal outcome")
	arena.mission_duration = 0.01
	await frames(3)
	check(arena.mission.phase == MissionRules.Phase.FAILED and arena.get_node("Overlay/Summary/Content/Report").text.contains("Deployment time expired"), "Deployment deadline produces failure summary")
	arena.queue_free()
	await frames(3)

	arena = create_arena()
	raider = arena.get_node("Raider") as Raider
	raider.position = arena.get_node("Salvage").position
	raider.scavenge_seconds = 0.1
	await frames(20)
	raider.position = arena.get_node("Extraction").position
	raider.extraction_seconds = 0.1
	await frames(20)
	check(arena.mission.phase == MissionRules.Phase.FAILED and arena.mission.lost_materials == 3, "Real Raider extraction signal records lost materials")
	check(arena.get_node("Overlay/Summary/Content/Report").text.contains("Lost: 3"), "Failure summary reports extracted materials")
	arena.queue_free()
	await frames(3)
	print("Mission checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
