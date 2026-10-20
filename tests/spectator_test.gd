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


func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func run() -> void:
	var arena := load("res://scenes/levels/mission_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	await frames(15)
	var spectator := arena.spectator as DeveloperSpectator
	var robot := arena.robot as RobotController
	var adapter := robot.input_adapter
	var normal_camera := robot.camera_rig.camera
	check(spectator != null and not spectator.active and not spectator.indicator.visible and normal_camera.is_current(), "Debug arena starts in normal player view with no spectator UI")
	var robot_position := robot.global_position
	var normal_transform := normal_camera.global_transform
	var rig_rotation := robot.camera_rig.rotation
	var pitch_rotation := robot.camera_rig.pitch_pivot.rotation
	var transfers: int = arena.ledger.accepted_transfers
	var mouse_mode := Input.mouse_mode
	spectator._input(key(KEY_F1))
	check(spectator.active and get_root().get_camera_3d() == spectator.camera and not normal_camera.is_current(), "F1 enters spectator and switches the single active camera")
	spectator.set_process(false)
	check(not adapter.gameplay_enabled and not robot.get_node("Weapon").enabled and not robot.get_node("CombatHUD").visible, "Spectator disables gameplay input, weapon and crosshair")
	check(arena.ledger.accepted_transfers == transfers, "Entering spectator does not create a ledger transfer")
	for index in range(3):
		spectator.leave()
		check(not spectator.active and normal_camera.is_current() and adapter.gameplay_enabled and robot.get_node("Weapon").enabled and Input.mouse_mode == mouse_mode, "Repeated exit restores camera, controls, weapon and prior mouse mode")
		spectator.enter()
		spectator.set_process(false)
	spectator.camera.global_position = Vector3(0, 5, 0)
	spectator.yaw = PI / 2
	spectator.fly(Vector2(0, -1), 0, false, 1)
	check(spectator.camera.global_position.is_equal_approx(Vector3(-10, 5, 0)), "W movement uses camera yaw horizontally")
	spectator.fly(Vector2(1, 0), 0, false, 1)
	check(spectator.camera.global_position.is_equal_approx(Vector3(-10, 5, -10)), "Strafe uses camera-relative horizontal right")
	var start := spectator.camera.global_position
	spectator.fly(Vector2.ZERO, 1, false, 1)
	spectator.fly(Vector2.ZERO, -1, true, 0.25)
	check(spectator.camera.global_position.is_equal_approx(start), "Ascending and accelerated descending use configured speed")
	spectator.apply_look(Vector2(0, -1000))
	check(absf(spectator.pitch) > deg_to_rad(89), "Spectator pitch rotates beyond player camera limits")
	spectator.camera.global_position = Vector3(0, 0.5, 21)
	spectator.yaw = 0
	spectator.fly(Vector2(0, 1), 0, true, 1)
	check(spectator.camera.global_position.z > 50, "Free camera passes through the solid arena boundary")
	spectator.fly(Vector2.ZERO, -1, true, 1)
	check(spectator.camera.global_position.y < -20, "Free camera passes below terrain without gravity or collision")
	Input.action_press("move_forward")
	Input.action_press("fire")
	Input.action_press("recover")
	Input.action_press("jump")
	Input.action_press("boost")
	adapter._physics_process(1.0 / 60)
	await frames(6)
	check(adapter.move_intent.is_zero_approx() and not adapter.fire_intent and not adapter.recover_held and not adapter.jump_requested and not adapter.boost_requested, "Gameplay actions cannot leak into robot while spectating")
	check(not robot.get_node("Weapon").try_fire(), "Direct player firing is also blocked while spectating")
	for action in ["move_forward", "fire", "recover", "jump", "boost"]:
		Input.action_release(action)
	check(robot.global_position == robot_position and robot.velocity == Vector3.ZERO, "Robot stays at exact world position throughout free flight")
	check(robot.camera_rig.rotation == rig_rotation and robot.camera_rig.pitch_pivot.rotation == pitch_rotation and normal_camera.global_transform.is_equal_approx(normal_transform), "Player camera orbit and transform remain untouched")
	spectator._input(key(KEY_ESCAPE))
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape releases spectator mouse")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	spectator._input(click)
	# The headless display always reports visible mouse; verify capture graphically too.
	check((DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED) and not adapter.fire_intent, "Click recaptures spectator mouse without firing (capture requires graphical display)")
	spectator._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Focus loss releases spectator cursor")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	arena.elapsed = 10
	arena.process_entries()
	await frames(5)
	var actor := arena.raiders[1] as Raider
	for other in arena.raiders.values():
		other.set_physics_process(false)
	actor.position = Vector3(-16, 0.1, -14)
	spectator.camera.global_position = actor.global_position + Vector3.UP
	await frames(3)
	actor.decide()
	check(not actor.threat_visible and actor.threat_remaining == 0 and actor.current_target() == robot, "Camera at Raider cannot be perceived or become a target while robot remains distant")
	spectator.select_next()
	check(spectator.selected == actor, "Inspection selects an existing Raider without changing its task")
	spectator.following = true
	spectator.follow_position = actor.global_position
	start = spectator.camera.global_position
	actor.position += Vector3.RIGHT
	spectator.follow_step()
	check(spectator.camera.global_position.is_equal_approx(start + Vector3.RIGHT), "Follow translates camera with selected Raider and never controls its movement")
	spectator.refresh_indicator()
	check(not arena.get_node("Overlay/FoundationStatus").visible and not spectator.indicator.text.contains("Target:") and spectator.indicator.text.contains("DEV SPECTATOR"), "Hidden debug HUD retains only a compact spectator indicator")
	var debug_event := InputEventAction.new()
	debug_event.action = "debug_hud"
	debug_event.pressed = true
	arena._unhandled_input(debug_event)
	check(arena.debug_visible, "Existing F3 developer HUD remains usable while spectating")
	check(arena.get_node("Overlay/FoundationStatus").visible and spectator.indicator.text.contains("Target:") and spectator.indicator.text.contains("Relationships: not implemented"), "F3 restores the banner and real target inspector")
	arena._unhandled_input(debug_event)
	check(not arena.get_node("Overlay/DebugStatus").visible and not arena.get_node("Overlay/FoundationStatus").visible and not spectator.indicator.text.contains("Target:") and arena.get_node("Overlay/MissionStatus").visible, "F3 hides developer details again while preserving mission information")
	actor.position = Vector3(-16, 0.1, -14)
	actor.salvage = arena.get_node("Salvage")
	actor.transition(Raider.State.SCAVENGING)
	actor.set_physics_process(true)
	var elapsed: float = arena.elapsed
	await frames(200)
	check(arena.elapsed > elapsed + 2 and arena.ledger.cargo_for(1) > 0, "Mission clock, Raider AI, physics and scavenging continue naturally while spectating")
	check(arena.ledger.is_conserved(), "Natural spectator run preserves material conservation")
	actor.health.apply_damage(1000)
	await frames(3)
	spectator.follow_step()
	check(not spectator.following and not is_instance_valid(spectator.selected) and arena.ledger.dropped_materials > 0, "Selected Raider death clears follow while normal loot transfer still occurs")
	spectator.leave()
	check(robot.global_position == robot_position and normal_camera.is_current() and adapter.gameplay_enabled, "Exiting after observing autonomous collection restores unchanged robot")
	adapter.set_physics_process(false)
	adapter.move_intent = Vector2(1, 0)
	await frames(10)
	check(robot.global_position.x > robot_position.x + 0.2, "Restored robot can physically move again")
	adapter.clear_intent()
	spectator.enter()
	spectator.set_process(false)
	arena.restart_mission()
	await frames(15)
	arena = current_scene
	spectator = arena.spectator
	robot = arena.robot
	check(not spectator.active and robot.camera_rig.camera.is_current() and robot.input_adapter.gameplay_enabled and not robot.debug_movement_locked and (DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED), "Restart from spectator creates a clean player camera and captured controls")
	# Armed scene: camera is far away but the unchanged physical robot is targetable.
	arena.select_scenario(3)
	await frames(15)
	arena = current_scene
	spectator = arena.spectator
	robot = arena.robot
	arena.set_physics_process(false)
	arena.elapsed = 10
	arena.process_entries()
	for other in arena.raiders.values():
		other.set_physics_process(false)
		other.combat.weapon.set_physics_process(false)
	actor = arena.raiders[1]
	actor.position = Vector3(0, 0.1, 8)
	robot.position = Vector3(0, 0.1, 14)
	await frames(3)
	spectator.enter()
	spectator.set_process(false)
	spectator.camera.global_position = Vector3(100, 100, 100)
	actor.combat.profile = actor.combat.profile.duplicate()
	actor.combat.profile.spread_degrees = 0
	actor.decide()
	actor.combat.tick(actor.combat.profile.warning_time + 0.01)
	check(robot.get_node("Health").current == 90 and actor.current_target() == robot, "Raider damages physical robot while spectator camera is far away")
	actor.combat.weapon.cooldown = 0
	robot.get_node("Health").apply_damage(85)
	actor.combat.tick(0.1)
	check(arena.mission.player_destroyed and not spectator.active and robot.camera_rig.camera.is_current() and not robot.input_adapter.gameplay_enabled and not robot.get_node("Weapon").enabled, "Lethal Raider shot exits spectator without re-enabling destroyed player")
	check(not spectator.enter() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and arena.ledger.is_conserved(), "Terminal deployment rejects spectator entry and preserves normal summary state")
	arena.queue_free()
	await frames(30)
	print("Stage J spectator checks complete; failures: ", failures)
	quit(1 if failures else 0)
