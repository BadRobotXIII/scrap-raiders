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


func write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func create_arena(save_name: String) -> Node3D:
	var arena := load("res://scenes/levels/extraction_arena.tscn").instantiate() as Node3D
	arena.stash_path = test_directory + "/" + save_name
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	arena.robot.input_adapter.set_physics_process(false)
	arena.robot.input_adapter.set_process_input(false)
	arena.robot.set_physics_process(false)
	return arena


func deploy(arena: Node3D) -> void:
	await frames(8)
	arena.elapsed = 10
	arena.process_entries()
	for actor in arena.raiders.values():
		actor.set_physics_process(false)
		actor.combat.weapon.set_physics_process(false)


func recover_load(arena: Node3D) -> void:
	# Real death/material pickup, with direct gear transfer isolating extraction policy.
	var actor := arena.raiders[1] as Raider
	actor.position = Vector3(0, 0.1, 12)
	arena.ledger.collect(1, &"Salvage", 3)
	actor.health.apply_damage(100)
	await frames(3)
	arena.robot.position = Vector3(0, 0.1, 12)
	await frames(3)
	check(arena.try_recover(), "Recovered mission materials become deployment cargo")
	arena.flare_director.equipment.recover(1)
	arena.robot.position = arena.get_node("RecallDock").position
	arena.robot.velocity = Vector3.ZERO
	arena.robot.input_adapter.recover_held = true
	await frames(3)


func run() -> void:
	test_directory = "res://.godot/stage_g_tests/" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var path := test_directory + "/stash.json"
	var a := "a".repeat(32)
	var b := "b".repeat(32)
	var c := "c".repeat(32)
	var items: Array[Dictionary] = [{"id": 1, "name": "Raider rifle", "value": 4}]
	var kit: Array[Dictionary] = [{"id": 1, "name": "Electronics kit", "value": 2}]
	var stash := PersistentStash.new(path)
	check(stash.load_stash() and stash.snapshot().materials == 0 and not FileAccess.file_exists(path), "Absent stash loads empty without writing player data")
	check(stash.commit_rewards(a, 3, items) and stash.snapshot().materials == 3, "Verified atomic commit stores extraction rewards")
	if not stash.last_error.is_empty():
		print("Save diagnostic: ", stash.last_error)
	stash = PersistentStash.new(path)
	check(stash.commit_rewards(a, 3, items) and stash.snapshot().materials == 3 and stash.snapshot().equipment.size() == 1, "Saved receipt prevents duplicate reward after service restart")
	check(not stash.commit_rewards(a, 9, items) and stash.snapshot().materials == 3, "Conflicting reward for the same deployment is rejected")
	check(stash.commit_rewards(b, 2, kit) and stash.snapshot().materials == 5 and stash.snapshot().equipment.size() == 2, "Separate deployments preserve globally distinct equipment identities")
	write_text(path, "{truncated")
	stash = PersistentStash.new(path)
	check(stash.load_stash() and stash.used_backup and stash.snapshot().materials == 3, "Corrupt primary restores the previous validated backup")
	check(stash.commit_rewards(b, 2, kit) and stash.snapshot().materials == 5, "Backup recovery can safely replay an unrecorded extraction receipt")
	check(stash.commit_rewards(c, 1, []) and stash.snapshot().materials == 6, "Subsequent commits safely replace an existing backup")
	write_text(path, "bad primary")
	write_text(path + ".bak", "bad backup")
	check(not stash.load_stash() and not stash.commit_rewards(a, 3, items) and FileAccess.get_file_as_string(path) == "bad primary", "Unrecoverable corruption blocks rewards and preserves existing files")
	var future := test_directory + "/future.json"
	write_text(future, '{"version":99}')
	check(not PersistentStash.new(future).commit_rewards(a, 3, items) and FileAccess.get_file_as_string(future) == '{"version":99}', "Unsupported save versions cannot be overwritten")
	var orphan := test_directory + "/orphan.json"
	write_text(orphan + ".tmp", "uncommitted data")
	var empty := PersistentStash.new(orphan)
	check(empty.load_stash() and empty.snapshot().materials == 0, "Orphan temporary file cannot grant uncommitted rewards")
	var malformed: Array[Dictionary] = [{"id": 1, "name": "A", "value": 1}, {"id": 1, "name": "B", "value": 1}]
	check(not empty.commit_rewards(a, 0, malformed) and not FileAccess.file_exists(orphan), "Duplicate input equipment IDs are rejected before any save replacement")
	# Extraction policy must never auto-complete an otherwise resolved deployment.
	var ledger := MaterialLedger.new({&"A": 3}, [1])
	ledger.defeat(1)
	var policy := MissionRules.new()
	policy.requires_extraction = true
	policy.evaluate(ledger)
	check(not policy.is_finished() and policy.complete_extraction(), "Resolving all Raiders still requires explicit player extraction")
	policy.fail_player_destroyed()
	policy.evaluate(ledger, true)
	check(policy.player_extracted and not policy.player_destroyed and policy.phase == MissionRules.Phase.SUCCEEDED, "First terminal extraction cannot be overwritten by late death or timeout")

	var arena := create_arena("successful.json")
	await deploy(arena)
	await recover_load(arena)
	var recall := arena.recall as RecallController
	check(recall.eligible() and arena.ledger.active_raiders == 2 and not arena.mission.is_finished(), "Recall is available while other Raiders and responses remain active")
	recall.step(0)
	recall.step(2)
	check(recall.elapsed == 2 and not FileAccess.file_exists(arena.stash_path), "Partial channel cannot bank deployment cargo")
	arena.robot.input_adapter.recover_held = false
	recall.step(0.1)
	check(recall.elapsed == 0 and not recall.channeling, "Releasing E resets extraction progress")
	arena.robot.input_adapter.recover_held = true
	recall.step(0)
	recall.step(2)
	arena.robot.get_node("Health").apply_damage(10)
	check(recall.elapsed == 0 and not recall.channeling, "Incoming damage immediately cancels recall")
	recall.step(0)
	arena.robot.input_adapter.fire_intent = true
	recall.step(2)
	check(not recall.channeling, "Firing prevents recall completion")
	arena.robot.input_adapter.fire_intent = false
	arena.robot.input_adapter.move_intent = Vector2.RIGHT
	recall.step(0.1)
	check(not recall.channeling, "Movement intent prevents recall from starting")
	arena.robot.input_adapter.move_intent = Vector2.ZERO
	arena.robot.velocity = Vector3.RIGHT
	recall.step(0.1)
	check(not recall.channeling, "Residual physical velocity prevents recall from starting")
	arena.robot.velocity = Vector3.ZERO
	recall.step(0)
	arena.robot.position += Vector3.RIGHT * 0.5
	recall.step(2)
	check(not recall.channeling, "Physical displacement cancels recall even without movement input")
	arena.robot.position = Vector3(0, 0.1, 16)
	await frames(3)
	check(not recall.eligible(), "Leaving dock range rejects recall eligibility")
	arena.robot.position = arena.get_node("RecallDock").position
	await frames(3)
	recall.step(0)
	recall.step(4.99)
	check(not arena.mission.is_finished() and arena.ledger.recovered_materials == 3, "Full five-second channel is required before settlement")
	recall.step(0.02)
	check(arena.mission.player_extracted and arena.mission.phase == MissionRules.Phase.SUCCEEDED and arena.ledger.banked_materials == 3 and arena.ledger.recovered_materials == 0 and arena.ledger.is_conserved(), "Successful recall banks material cargo without changing Raider loss or ground categories")
	check(arena.flare_director.equipment.count_at(EquipmentLedger.Location.BANKED) == 2 and recall.stash.snapshot().equipment.size() == 2 and recall.stash.snapshot().materials == 3, "Extracted equipment and materials credit the persistent stash exactly once")
	check(not recall.complete() and not arena.ledger.settle_player(true), "Repeated completion cannot settle or reward the deployment twice")
	var save_name: String = arena.stash_path
	arena.restart_mission()
	await frames(8)
	arena = current_scene
	arena.set_physics_process(false)
	arena.flare_director.set_physics_process(false)
	arena.recall.set_physics_process(false)
	check(arena.scenario_index == 5 and arena.stash_path == save_name and arena.recall.stash.snapshot().materials == 3 and arena.ledger.banked_materials == 0, "Restart preserves persistent stash while resetting deployment and isolated save path")
	arena.queue_free()
	await frames(3)

	for failure in ["death", "deadline"]:
		var failure_path: String = test_directory + "/" + failure + ".json"
		var prior_stash := PersistentStash.new(failure_path)
		prior_stash.commit_rewards("d".repeat(32), 7, [])
		var before_failure_save := FileAccess.get_file_as_string(failure_path)
		arena = create_arena(failure + ".json")
		await deploy(arena)
		await recover_load(arena)
		recall = arena.recall
		recall.step(0)
		recall.step(4.99)
		if failure == "death":
			arena.robot.get_node("Health").apply_damage(1000)
		else:
			arena.elapsed = arena.mission_duration
			arena._physics_process(0.01)
		recall.step(0.1)
		check(arena.mission.phase == MissionRules.Phase.FAILED and arena.ledger.forfeited_materials == 3 and arena.ledger.lost_materials == 0 and arena.ledger.banked_materials == 0 and arena.ledger.is_conserved(), "%s before channel completion forfeits cargo separately from Raider loss" % failure)
		check(arena.flare_director.equipment.count_at(EquipmentLedger.Location.FORFEITED) == 2 and FileAccess.get_file_as_string(arena.stash_path) == before_failure_save and arena.recall.stash.snapshot().materials == 7, "%s forfeits equipment while preserving all previously banked inventory" % failure)
		check(not recall.complete(), "Late extraction cannot overwrite %s" % failure)
		arena.queue_free()
		await frames(3)

	arena = create_arena("write_failure.json")
	await deploy(arena)
	await recover_load(arena)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(arena.stash_path + ".tmp"))
	recall = arena.recall
	recall.step(0)
	recall.step(5.01)
	check(not arena.mission.is_finished() and arena.ledger.recovered_materials == 3 and arena.ledger.banked_materials == 0 and not recall.save_error.is_empty(), "Save failure keeps deployment and cargo intact for retry instead of falsely granting extraction")
	check(not FileAccess.file_exists(arena.stash_path), "Failed save cannot create a partial primary inventory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arena.stash_path + ".tmp")) # Own empty test directory only.
	recall.step(0)
	recall.step(5.01)
	check(arena.mission.player_extracted and recall.stash.snapshot().materials == 3 and recall.save_error.is_empty(), "Retry after a repaired save destination banks the original cargo once")
	arena.queue_free()
	await frames(3)
	# Natural scheduling runs the complete channel against actual mission timers.
	arena = create_arena("natural.json")
	await deploy(arena)
	await recover_load(arena)
	arena.set_physics_process(true)
	arena.flare_director.set_physics_process(true)
	arena.recall.set_physics_process(true)
	Engine.time_scale = 3
	for index in range(160):
		if arena.mission.is_finished():
			break
		await frames(1)
	check(arena.mission.player_extracted and arena.ledger.banked_materials == 3 and arena.recall.stash.snapshot().materials == 3 and arena.ledger.is_conserved(), "Natural five-second recall banks cargo through real physics scheduling")
	Engine.time_scale = 1
	arena.queue_free()
	await frames(3)
	print("Stage G checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
