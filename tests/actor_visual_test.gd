extends "res://tests/gameplay_integration_test.gd"
## Presentation is exercised with real movement, shots and irreversible deployment death.


func visual(actor: Node3D) -> ActorVisual:
	return actor.get_node("Visuals/ActorVisual") as ActorVisual


func named(node: Node, label: String) -> Node3D:
	if String(node.name).to_lower() == label.to_lower() and node is Node3D:
		return node as Node3D
	for child in node.get_children():
		var result := named(child, label)
		if result != null:
			return result
	return null


func pose(skeleton: Skeleton3D) -> Array:
	var result: Array = []
	for bone in range(skeleton.get_bone_count()):
		result.append(skeleton.get_bone_pose_rotation(bone))
	return result


func create_visual_fixture(label: String, production: bool = true, scenario_seed: int = 87018) -> Node3D:
	var arena := load("res://scenes/levels/asset_recovery_arena.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/" + label + ".json"
	arena.seed_override = scenario_seed
	arena.production_actor_visuals = production
	root.add_child(arena)
	current_scene = arena
	await start_frozen(arena)
	arena.ledger.transfer_accepted.connect(audit_transfer.bind(arena))
	arena.flare_director.equipment.transfer_accepted.connect(audit_transfer.bind(arena))
	return arena


func physical_contract(actor: CharacterBody3D) -> Array:
	var collision := actor.find_children("*", "CollisionShape3D", true, false)[0] as CollisionShape3D
	var shape := collision.shape as CapsuleShape3D
	return [actor.collision_layer, actor.collision_mask, collision.position, shape.radius, shape.height]


func arena_contract(arena: Node3D) -> Dictionary:
	var result := {
		"robot": physical_contract(arena.robot),
		"muzzle": arena.robot.get_node("Visuals/Muzzle").position,
		"camera": [arena.robot.camera_rig.position, arena.robot.camera_rig.spring_arm.spring_length, arena.robot.camera_rig.camera.fov, arena.robot.camera_rig.spring_arm.collision_mask],
		"stock": arena.ledger.total_materials,
		"pending": arena.pending_ids.duplicate(),
		"config": arena.config.resource_path,
	}
	for id in arena.raiders:
		var actor: Raider = arena.raiders[id]
		result[str(id)] = [physical_contract(actor), actor.position, actor.profile.resource_path, actor.get_node("Visuals/RifleMuzzle").position, actor.agent.radius, actor.health.maximum]
	for machine in arena.ecosystem.machines:
		result[str(machine.source_id)] = [physical_contract(machine), machine.position, machine.route, machine.health.maximum, machine.get_aim_position() - machine.global_position, machine.weapon.muzzle.position if machine.weapon != null else null]
	return result


func production_contract() -> void:
	var arena := await create_visual_fixture("contracts")
	var before := arena_contract(arena)
	check(visual(arena.robot).production_enabled and not arena.robot.get_node("Visuals/Body").visible, "Normal mission uses the production player while retaining the primitive fallback")
	for actor in arena.raiders.values():
		check(visual(actor).appearance_index == ActorVisual.appearance_for(arena.debug_seed, StringName(str(actor.raider_id))), "Raider appearance derives solely from seed and actor identity")
		check(visual(actor).production_enabled and not actor.get_node("Visuals/Body").visible and not actor.get_node("Visuals/Rifle").visible, "Human model owns visible body/rifle presentation without duplicate primitives")
	for machine in arena.ecosystem.machines:
		check(visual(machine).production_enabled and (machine.weapon == null) == machine.flying, "Machines receive their matching production model and scout remains unarmed")
	check(before.muzzle == Vector3(0.6, 1.15, -0.7) and before.camera[0] == Vector3(0, 1.8, 0) and before.camera[1] == 5.0 and before.camera[2] == 70.0, "Accepted player shot origin and shoulder-camera contract remain exact")
	arena.queue_free()
	await frames(8)
	var legacy := await create_visual_fixture("legacy_contracts", false)
	check(arena_contract(legacy) == before, "Production/primitive selection changes no collider, navigation radius, seed population, route, stock, aim or shot origin")
	check(not visual(legacy.robot).production_enabled and legacy.robot.get_node("Visuals/Body").visible, "Opt-out fixture restores the supported primitive presentation")
	legacy.queue_free()
	await frames(8)


func independent_appearance_and_playback() -> void:
	seed(654321)
	var expected := randf()
	seed(654321)
	var combinations: Array[int] = []
	for id in range(24):
		var choice := ActorVisual.appearance_for(87017 + id / 5, StringName(str(id)))
		if not combinations.has(choice):
			combinations.append(choice)
	check(randf() == expected and combinations.size() == 3, "Bounded appearance variety consumes no gameplay/global RNG state")
	var packed := load("res://scenes/characters/visuals/raider_visual.tscn") as PackedScene
	var first := packed.instantiate() as ActorVisual
	var second := packed.instantiate() as ActorVisual
	root.add_child(first)
	root.add_child(second)
	first.configure(null, null, 87017, &"1")
	second.configure(null, null, 87017, &"2")
	first.preview_speed = 3.0
	second.preview_speed = 0
	first.set_cargo(3)
	second.set_cargo(0)
	var a := named(first.model, "cargo_indicator") as MeshInstance3D
	var b := named(second.model, "cargo_indicator") as MeshInstance3D
	check(a.get_active_material(0) != b.get_active_material(0) and a.get_active_material(0).emission_enabled and not b.get_active_material(0).emission_enabled, "Loaded cue changes one Raider's mutable material without recoloring another")
	await frames(20)
	var rig_a := first.model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var rig_b := second.model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	check(first.animation_state == &"walk" and second.animation_state == &"idle" and pose(rig_a) != pose(rig_b), "Two instances animate their real imported skins independently")
	first.set_armed(true)
	second.set_armed(false)
	check(named(first.model, "Rifle").visible and not named(second.model, "Rifle").visible, "Armed appearance is per instance and does not create a second weapon")
	var terminal := first.create_death_visual()
	root.add_child(terminal)
	var snapshot_indicator := named(terminal, "cargo_indicator") as MeshInstance3D
	var snapshot_material := snapshot_indicator.get_active_material(0) as StandardMaterial3D
	first.set_cargo(0)
	check(snapshot_material != a.get_active_material(0) and snapshot_material.emission_enabled, "Terminal snapshot owns mutable cargo appearance after the live source refreshes")
	terminal.queue_free()
	first.queue_free()
	second.queue_free()
	await frames(5)


func movement_and_shots() -> void:
	var arena := await create_visual_fixture("movement")
	park_actors(arena)
	for machine in arena.ecosystem.machines:
		machine.position = Vector3(100, 3, 100)
	var robot: RobotController = arena.robot
	robot.position = Vector3(0, 0.1, 20)
	robot.camera_rig.rotation.y = 0
	robot.input_adapter.gameplay_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	robot.input_adapter.move_intent = Vector2(0, -1)
	robot.set_physics_process(true)
	var start := robot.position
	await frames(24)
	check(robot.position.distance_to(start) > 0.5 and visual(robot).observed_speed > 0.5 and visual(robot).animation_state == &"locomotion", "Actual CharacterBody movement drives mechanical gait without model root motion")
	var thigh := named(visual(robot).model, "left_thigh")
	check(thigh != null and absf(thigh.rotation.x) > 0.01, "A named mechanical joint articulates during real walking")
	robot.input_adapter.clear_intent()
	await frames(12)
	robot.set_physics_process(false)
	robot.position = Vector3(100, 0.1, 100)
	var actor: Raider = arena.raiders[1]
	var guard: SupportMachine = arena.ecosystem.machines[1]
	actor.position = Vector3(0, 0.1, 20)
	var salvage := actor.salvage
	salvage.position = Vector3(0, 0.1, 26)
	actor.transition(Raider.State.SCAVENGING)
	actor.set_physics_process(true)
	var raider_origin := actor.position
	await frames(24)
	check(actor.position.distance_to(raider_origin) > 0.25 and visual(actor).observed_speed > 0.5 and String(visual(actor).animation_state).contains("walk"), "Actual Raider navigation drives its imported walk skin rather than moving a visual root")
	actor.set_physics_process(false)
	actor.position = Vector3(0, 0.1, 20)
	guard.position = Vector3(0, 0.1, 14)
	await frames(4)
	var health_before := guard.health.current
	var shots_before := visual(actor).shot_count
	var origin: Transform3D = actor.get_node("Visuals/RifleMuzzle").transform
	actor.combat.weapon.cooldown = 0
	check(actor.combat.weapon.try_fire_at(guard.get_aim_position()) and guard.health.current < health_before, "Production rifle sends a real valid physical hit through the accepted executor")
	check(visual(actor).shot_count == shots_before + 1 and not actor.combat.weapon.try_fire_at(guard.get_aim_position()), "Only accepted shots drive recoil; cooldown rejection produces no extra event")
	check(actor.get_node("Visuals/RifleMuzzle").transform == origin and visual(actor).shot_count == shots_before + 1, "Cosmetic recoil cannot move the authoritative muzzle or double fire")
	actor.set_physics_process(true)
	await frames(1)
	check(String(visual(actor).animation_state).contains("fire"), "An accepted shot reaches the skinned fire layer while locomotion remains independent")
	actor.set_physics_process(false)
	check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Real production movement and firing preserve finite accounting")
	arena.queue_free()
	await frames(30)


func death_and_spectating() -> void:
	var arena := await create_visual_fixture("death")
	park_actors(arena)
	arena.robot.position = Vector3(100, 0.1, 100)
	var victim: Raider = arena.raiders[1]
	victim.position = Vector3(0, 0.1, 20)
	var adapter := visual(victim)
	adapter.set_armed(false)
	var rig := adapter.model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var hand := rig.find_bone("left_upper_arm")
	rig.set_bone_pose_rotation(hand, Quaternion(Vector3.RIGHT, 0.3))
	var prior_pose := pose(rig)
	var prior_appearance := adapter.appearance_index
	victim.get_node("DeathTumble").lifetime = 0.9
	arena.ledger.collect(1, &"Salvage", 3)
	victim.health.apply_damage(1000, victim.position, 0)
	var bodies := get_nodes_in_group("death_tumbles")
	check(bodies.size() == 1, "Skinned death creates exactly one accepted cosmetic body")
	if bodies.is_empty():
		arena.queue_free()
		await frames(5)
		return
	var body := bodies[0] as RigidBody3D
	var terminal := body.get_node("TerminalVisual") as Node3D
	var copy_rig := terminal.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	check(body.collision_layer == 0 and body.collision_mask == 1 and body.mass == 8 and terminal.get_meta("appearance_index") == prior_appearance, "Death retains cosmetic physics policy and the selected appearance")
	check(pose(copy_rig) == prior_pose and not named(terminal, "Rifle").visible, "Death snapshots the current skinned pose and hidden accessory before gameplay cleanup")
	var clean := true
	for node in terminal.find_children("*", "", true, false):
		clean = clean and node.get_script() == null and not node is CollisionObject3D and not node is Health and not node is NavigationAgent3D and not node is ShotExecutor
	check(clean, "Terminal subtree contains no actor controller, health, navigation, weapon or callbacks")
	await frames(12)
	check(not is_instance_valid(victim) and is_instance_valid(body) and pose(copy_rig) != prior_pose, "Bounded terminal skin animation continues after its source actor is freed")
	check(arena.ledger.dropped_materials == 3 and arena.flare_director.equipment.ground_count(1) > 0, "Death visuals neither duplicate nor delay the ordinary finite loot release")
	var camera_origin: Vector3 = arena.robot.position
	var transfers: int = arena.ledger.accepted_transfers
	check(arena.spectator.enter(), "Developer spectator still activates with production actors")
	arena.spectator.camera.position = Vector3(-40, 12, 40)
	await frames(5)
	check(arena.robot.position == camera_origin and not arena.robot.input_adapter.gameplay_enabled and arena.ledger.accepted_transfers == transfers, "Independent camera movement cannot teleport the actor, enable gameplay or transfer cargo")
	arena.spectator.leave()
	check(root.get_camera_3d() == arena.robot.camera_rig.camera, "Leaving developer mode restores the single authoritative player camera")
	arena.robot.get_node("Health").apply_damage(1000, Vector3.ZERO, arena.raiders[2].get_instance_id())
	var frozen: Dictionary = arena.mission_objectives.result()
	check(arena.post_death.enter() and arena.post_death.selected == arena.raiders[2] and not arena.mission.is_world_finished(), "Production player death remains irreversible while normal actor following and world simulation continue")
	var selected: Node3D = arena.post_death.selected
	arena.post_death.cycle(1)
	check(arena.post_death.selected != selected and arena.post_death.eligible(arena.post_death.selected), "Normal spectator switching selects surviving gameplay actors rather than visual bones")
	arena.finish_mission()
	check(arena.mission_objectives.result() == frozen and arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Spectating and repeated finish cannot resettle deployment or corrupt loot")
	arena.restart_mission()
	await frames(12)
	check(get_nodes_in_group("death_tumbles").is_empty() and not current_scene.deployment_started and visual(current_scene.robot).production_enabled, "Restart clears terminal copies and rebuilds clean production visuals at briefing")
	current_scene.queue_free()
	await frames(30)


func run() -> void:
	test_directory = "res://.godot/stage_w_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	await production_contract()
	await independent_appearance_and_playback()
	await movement_and_shots()
	await death_and_spectating()
	check(accounting_valid and accepted_events > 0, "Every accepted material/equipment transfer preserves its authoritative invariant")
	print("Actor visual failures: ", failures)
	quit(1 if failures else 0)
