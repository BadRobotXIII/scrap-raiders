extends "res://tests/gameplay_integration_test.gd"
## Enabled audio, active-camera listening and repeated mission ownership cleanup.

func run() -> void:
	test_directory = "res://.godot/stage_x_tests/audio_" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	for bus in [&"Weapons", &"Impacts", &"Machines", &"Environment", &"Interface", &"Music"]:
		check(AudioServer.get_bus_index(bus) >= 0, "Audio category exists: " + String(bus))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
	var valid: bool = manifest.assets.size() == 29
	for item in manifest.assets:
		var sound := load(item.path) as AudioStreamWAV
		valid = valid and sound != null and FileAccess.get_sha256(item.path) == item.sha256
		if item.loop: valid = valid and sound.loop_mode == AudioStreamWAV.LOOP_FORWARD
	check(valid, "All original audio resources match provenance hashes and authored loop modes")
	for repetition in range(3):
		var arena := await isolated_s("restart_%d" % repetition, 87018)
		var world: MissionPresentation = arena.presentation
		var transfers: int = arena.ledger.accepted_transfers
		var actor: Raider = arena.raiders[1]
		var robot_position: Vector3 = arena.robot.position
		var actor_state: Raider.State = actor.state
		arena.spectator.enter()
		arena.spectator.camera.global_position += Vector3(4, 5, 7)
		await frames(3)
		check(world.listener.global_transform.is_equal_approx(arena.spectator.camera.global_transform), "The single sound listener follows developer camera ownership")
		check(actor.state == actor_state and arena.robot.position == robot_position and arena.ledger.accepted_transfers == transfers, "Changing the listener cannot move actors, create awareness or transfer ownership")
		arena.spectator.leave()
		await frames(3)
		check(world.listener.global_transform.is_equal_approx(arena.robot.camera_rig.camera.global_transform), "Leaving spectator restores player-camera spatial listening")
		world.play_spatial("actors/machine_destroy", actor.position)
		world.play_interface("recovered")
		await frames(2)
		check(world.snapshot().voices > 0 and world.snapshot().voices <= 32, "Real enabled audio starts inside the bounded voice budget")
		arena.robot.get_node("Health").apply_damage(1000)
		check(arena.mission.player_destroyed and not arena.mission.is_world_finished() and world.accepting, "Player deployment death preserves ongoing world presentation and simulation")
		check(arena.post_death.enter(), "Post-death spectating can follow surviving autonomous actors")
		await frames(3)
		check(world.listener.global_transform.is_equal_approx(arena.spectator_view.camera.global_transform), "Restricted actor following uses the same presentation listener")
		arena.finish_mission()
		check(arena.ledger.is_conserved() and arena.flare_director.equipment.is_valid(), "Repeated finish cannot resettle material or equipment accounting")
		world.shutdown()
		check(world.snapshot().voices == 0 and not world.accepting, "World shutdown stops every owned voice rather than waiting for playback")
		arena.queue_free()
		await frames(30)
		check(get_nodes_in_group("mission_presentations").is_empty() and get_nodes_in_group("presentation_bursts").is_empty(), "Repeated scene removal leaves no presentation owner or stale emitters")
	# Audio mixing runs on wall time. Give its thread a bounded opportunity to
	# release stopped playback even when the rest of this suite runs fixed-fps.
	OS.delay_msec(200) # Test-only mixer drain; never part of mission teardown.
	await process_frame
	print("Audio lifecycle failures: ", failures)
	quit(1 if failures else 0)
