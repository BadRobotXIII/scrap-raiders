extends SceneTree

var failures: int = 0
var test_directory: String


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


func preview(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var path := test_directory + "/" + label + ".png"
		root.get_texture().get_image().save_png(path)
		print("PREVIEW: ", ProjectSettings.globalize_path(path))


func freeze(arena: Node3D) -> void:
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	for actor in arena.raiders.values():
		if is_instance_valid(actor):
			actor.set_physics_process(false)
			actor.combat.weapon.set_physics_process(false)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(false)
		if machine.weapon != null:
			machine.weapon.set_physics_process(false)


func create_arena(label: String) -> Node3D:
	var arena := load("res://scenes/levels/integrated_extraction_arena.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/" + label + ".json"
	root.add_child(arena)
	current_scene = arena
	freeze(arena)
	await frames(10)
	arena.process_entries()
	freeze(arena)
	return arena


func run() -> void:
	test_directory = "res://.godot/stage_o_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var policy := MissionRules.new()
	policy.post_death_spectating = true
	policy.requires_extraction = true
	policy.fail_player_destroyed()
	check(policy.is_finished() and not policy.is_world_finished() and not policy.complete_extraction(), "Deployment failure is permanent while world lifetime can continue")
	policy.evaluate(MaterialLedger.new(), true)
	policy.evaluate_world(true, true, 1)
	check(policy.is_world_finished() and policy.player_destroyed and not policy.player_extracted and not policy.deadline_expired, "World deadline cannot rewrite death outcome as a new player failure")
	var arena: Node3D = await create_arena("settlement")
	var prior := PersistentStash.new(arena.stash_path)
	prior.commit_rewards("a".repeat(32), 7, [])
	var prior_text := FileAccess.get_file_as_string(arena.stash_path)
	var killer := arena.raiders[1] as Raider
	var victim := arena.raiders[2] as Raider
	var other := arena.raiders[3] as Raider
	killer.position = Vector3(0, 0.1, 8)
	victim.position = Vector3(0, 0.1, 14)
	other.position = Vector3(18, 0.1, -18)
	arena.ledger.collect(2, &"Salvage", 3)
	victim.health.apply_damage(1000)
	await frames(3)
	var drop := arena.drops.values()[0] as MaterialDrop
	var recovered_drop_id := drop.drop_id
	arena.robot.position = drop.position
	await frames(3)
	check(arena.try_recover() and arena.flare_director.equipment.recover(2), "Death fixture recovers finite material and equipment through existing ledgers")
	arena.robot.position = Vector3(100, 0.1, 100)
	check(arena.spectator.enter(), "Developer camera may be active before lethal damage")
	var dead_position: Vector3 = arena.robot.position
	arena.robot.get_node("Health").apply_damage(1000, killer.position, killer.get_instance_id())
	var observer := arena.post_death as PostDeathSpectator
	check(arena.mission.player_destroyed and arena.mission.is_finished() and not arena.mission.is_world_finished() and observer.choice.visible and not arena.summary.visible, "Death offers Spectate/Return without shutting down world")
	check(not arena.spectator.active and not arena.spectator.enter() and not arena.robot.input_adapter.gameplay_enabled and not arena.robot.get_node("Weapon").enabled, "Death exits developer view and cannot restore player controls or free camera")
	check(arena.ledger.forfeited_materials == 3 and arena.flare_director.equipment.count_at(EquipmentLedger.Location.FORFEITED) == 2 and arena.ledger.is_conserved(), "Player cargo settles as forfeited once before observation")
	await preview("choice")
	var transfers: int = arena.ledger.accepted_transfers
	arena.finish_mission()
	arena._on_player_destroyed()
	check(arena.ledger.accepted_transfers == transfers and not arena.ledger.settle_player(false) and not arena.recall.complete() and FileAccess.get_file_as_string(arena.stash_path) == prior_text, "Repeated death/finish cannot settle twice, extract or change persistent stash")
	observer.choice.get_child(0).get_child(1).pressed.emit()
	check(observer.active and observer.selected == killer and arena.get_viewport().get_camera_3d() == arena.spectator_view.camera, "Spectate button prefers live lethal instigator and uses shared single active camera")
	observer.set_physics_process(false)
	await preview("follow")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	Input.parse_input_event(right)
	await frames(1)
	var motion := InputEventMouseMotion.new()
	motion.screen_relative = Vector2(100, -10000)
	observer._input(motion)
	check(observer.yaw != 0 and is_equal_approx(observer.pitch, deg_to_rad(35)), "RMB mouse orbit respects player pitch limits")
	right.pressed = false
	Input.parse_input_event(right)
	var eligible_count := observer.candidates().size()
	var seen: Array[Node3D] = []
	for index in range(eligible_count):
		seen.append(observer.selected)
		observer.cycle(1)
	check(seen.size() == 4 and seen.has(killer) and seen.has(other) and seen.has(arena.ecosystem.machines[0]) and seen.has(arena.ecosystem.machines[1]), "Cycling covers every live registered Raider and support machine exactly once")
	observer.cycle(-1)
	check(observer.selected == seen[-1], "Reverse cycling follows stable target order")
	var target_position: Vector3 = killer.position
	var camera_position: Vector3 = arena.spectator_view.global_position
	for action in ["move_forward", "jump", "boost", "fire", "recover"]:
		Input.action_press(action)
	await frames(3)
	for action in ["move_forward", "jump", "boost", "fire", "recover"]:
		Input.action_release(action)
	check(killer.position == target_position and arena.robot.position == dead_position and arena.spectator_view.global_position == camera_position and arena.ledger.accepted_transfers == transfers, "Gameplay/free-flight actions cannot move actors, translate follow view or transfer loot")
	# Following is physical-camera presentation only, including obstruction handling.
	observer.selected = killer
	observer.yaw = 0
	observer.pitch = 0
	observer.step()
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6, 5, 0.4)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = killer.position + Vector3(0, 1.3, 2)
	arena.add_child(wall)
	await frames(6)
	check(arena.spectator_view.arm.get_hit_length() < 3 and killer.position == target_position, "Follow spring arm shortens against cover without moving its actor")
	wall.queue_free()
	await frames(3)
	arena.spectator_view.camera.global_position = other.position + Vector3.UP
	other.decide()
	check(other.current_target() != arena.spectator_view.camera and not other.detects_actor(arena.robot), "Camera proximity never becomes a perceived gameplay threat")
	# Post-death autonomous transfers, reports, betrayal and real rifle damage.
	var source := arena.ecosystem.machines[0] as SupportMachine
	source.health.apply_damage(1000)
	check(arena.ecosystem.component_drop_ids.size() == 1 and arena.ledger.dropped_materials == 1, "Machine destruction still releases its preallocated component after player failure")
	check(arena.ledger.collect(3, &"Salvage2", 3) == 3 and arena.social.eligible(other, killer), "Human scavenging and rival eligibility continue after settlement")
	other.position = Vector3(0, 0.1, 14)
	await frames(3)
	killer.transition(Raider.State.SELECTING)
	killer.decide()
	killer.combat.profile = killer.combat.profile.duplicate()
	killer.combat.profile.spread_degrees = 0
	killer.combat.tick(0.7)
	check(other.health.current == 90, "Normal rival combat still fires and damages after player destruction")
	observer.selected = other
	other.health.apply_damage(1000)
	observer.step()
	check(observer.selected != other and observer.eligible(observer.selected) and arena.flare_director.committed == 2 and arena.ledger.dropped_materials == 4, "Target death cycles safely while cargo, equipment and flares remain authoritative")
	await frames(3)
	arena.elapsed = 8
	arena.flare_director.process_responses()
	freeze(arena)
	check(arena.raiders.has(4) and arena.raiders.has(5) and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Finite responders can enter and receive equipment/relations after player death")
	var newcomer := arena.raiders[4] as Raider
	newcomer.position = Vector3(0, 0.1, 14)
	observer.selected = newcomer
	check(arena.ledger.collect(4, &"Salvage3", 3) == 3, "Responder can scavenge remaining original stock")
	newcomer.transition(Raider.State.EXTRACTED)
	arena._on_extracted(3, newcomer)
	newcomer.queue_free()
	await frames(3)
	observer.step()
	check(is_instance_valid(observer.selected) and arena.ledger.lost_materials == 3 and arena.ledger.forfeited_materials == 3, "Extracted and freed target safely switches view; actual loss stays separate from forfeiture")
	var saved_reason: String = arena.mission.reason
	arena.elapsed = arena.mission_duration
	arena._physics_process(0.01)
	check(arena.mission.is_world_finished() and arena.summary.visible and not observer.active and not observer.choice.visible and arena.mission.reason == saved_reason, "World deadline ends observation without rewriting failed deployment")
	check(not arena.ledger.extract(1) and not arena.ledger.recover(recovered_drop_id) and FileAccess.get_file_as_string(arena.stash_path) == prior_text, "Final sealing rejects late transfers and preserves prior stash")
	var save_path: String = arena.stash_path
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	freeze(arena)
	check(arena.stash_path == save_path and arena.recall.stash.snapshot().materials == 7 and not arena.post_death.active and not arena.mission.is_finished() and arena.robot.input_adapter.gameplay_enabled and arena.robot.camera_rig.camera.is_current(), "Restart clears observer/world state and restores player control with prior stash")
	arena.queue_free()
	await frames(30)
	# Normal player controller must work without a developer adapter.
	arena = await create_arena("fallback")
	arena.spectator.queue_free()
	await frames(3)
	arena.robot.get_node("Health").apply_damage(1000)
	check(arena.post_death.enter() and arena.post_death.selected == arena.raiders[1], "Unknown instigator falls back to a live Raider without a developer controller")
	arena.post_death.return_button.pressed.emit()
	check(arena.summary.visible and arena.world_shutdown and not arena.robot.input_adapter.gameplay_enabled, "Return stops local observation and presents failure summary without revival")
	await preview("summary")
	arena.post_death.return_to_summary()
	check(arena.ledger.is_conserved(), "Repeated Return is idempotent")
	arena.queue_free()
	await frames(30)
	# No targets yet is distinct from a world with no future activity.
	arena = await create_arena("waiting")
	for actor in arena.raiders.values():
		actor.health.apply_damage(1000)
	for machine in arena.ecosystem.machines.duplicate():
		machine.health.apply_damage(1000)
	await frames(3)
	arena.robot.get_node("Health").apply_damage(1000)
	check(arena.post_death.enter() and arena.post_death.selected == null and not arena.mission.is_world_finished(), "Empty target list with pending responses allows passive observation")
	arena.post_death.set_physics_process(false)
	arena.elapsed = 8
	arena.flare_director.process_responses()
	freeze(arena)
	arena.post_death.step()
	check(arena.post_death.eligible(arena.post_death.selected), "A newly admitted finite responder automatically becomes a follow target")
	for actor in arena.raiders.values():
		if is_instance_valid(actor) and actor.health.current > 0:
			actor.health.apply_damage(1000)
	arena.evaluate_mission()
	arena.finish_mission()
	check(arena.world_shutdown and arena.summary.visible and not arena.post_death.active and arena.ledger.dropped_materials == 2 and arena.ledger.is_conserved(), "No survivors or pending entries ends observation despite remaining component loot")
	arena.queue_free()
	await frames(30)
	# Natural world simulation continues while the choice is open and after entry.
	arena = await create_arena("natural")
	for actor in arena.raiders.values():
		actor.set_physics_process(true)
		actor.combat.weapon.set_physics_process(true)
	for machine in arena.ecosystem.machines:
		machine.set_physics_process(true)
		if machine.weapon != null:
			machine.weapon.set_physics_process(true)
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	arena.robot.get_node("Health").apply_damage(1000)
	await frames(60)
	check(arena.elapsed > 0.8 and arena.post_death.choice.visible, "World keeps running while player chooses Spectate or Return")
	arena.post_death.enter()
	await frames(600)
	check(arena.elapsed > 9 and arena.ledger.accepted_transfers > 1 and arena.ledger.is_conserved() and not arena.summary.visible, "Natural post-death actors scavenge/fight while mission clock and accounting continue")
	check(not FileAccess.file_exists(arena.stash_path) and not arena.recall.complete(), "Natural observation cannot bank rewards or reopen recall")
	arena.post_death.return_to_summary()
	arena.queue_free()
	await frames(30)
	print("Stage O post-death spectator checks complete; failures: ", failures)
	quit(1 if failures else 0)
