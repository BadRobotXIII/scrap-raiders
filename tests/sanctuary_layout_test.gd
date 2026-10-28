extends "res://tests/inventory_world_test.gd"

func run() -> void:
	var app: Node = load("res://scenes/application/application.tscn").instantiate()
	var session: GameSession = app.get_node("GameSession")
	session.profile_path = test_directory + "/layout.json"
	root.add_child(app)
	current_scene = app
	session.enter_sanctuary()
	await frames(10)
	var home := session.active_scene as Sanctuary
	var rows := [{"id": "cabinet1", "definition": "cabinet", "x": 4.5, "z": 0, "rotation": 0}]
	check(SanctuaryLayout.valid(rows) and home.placement_clear(rows[0], ""), "Bounded saved pose is physically clear off protected routes")
	check(SanctuaryLayout.save(session.preparation, rows).ok, "Valid placement saves once through existing metadata transaction")
	home.rebuild_layout()
	await frames(4)
	check(home.placed.get_child_count() == 1 and not home.placement_clear(rows[0], ""), "Saved decoration has matching physical collision")
	check(home.placement_clear(rows[0], "cabinet1"), "Moving an existing prop excludes only that prop's old collider")
	for station in home.registry.stations.values(): check(home.registry.anchor_valid(station), "Placed prop preserves actual station standing routes")
	var invalid := rows.duplicate(true)
	invalid.append(rows[0].duplicate(true))
	invalid[1].id = "overlap"
	var before := session.stash.home_snapshot()
	check(not SanctuaryLayout.save(session.preparation, invalid).ok and session.stash.home_snapshot() == before, "Overlapping placement cannot change saved layout")
	invalid = rows.duplicate(true)
	invalid[0].x = 0
	check(not SanctuaryLayout.valid(invalid), "Protected central aisle cannot be occupied")
	invalid[0].x = 4.6
	check(not SanctuaryLayout.valid(invalid), "Unsnapped persisted poses are rejected")
	invalid[0].x = NAN
	check(not SanctuaryLayout.valid(invalid), "Nonfinite placement coordinates fail safely")
	var editor := LayoutEditor.new()
	editor.sanctuary = home
	home.transition(Sanctuary.Mode.PLACEMENT)
	home.ui_layer.add_child(editor)
	await frames(2)
	editor.point = Vector2(5.5, 0)
	editor.rotate_preview()
	editor.cancel()
	await frames(3)
	check(session.stash.home_snapshot() == before and home.mode == Sanctuary.Mode.WALKING, "Move/rotate preview cancellation leaves saved state untouched and restores walking")
	var near_robot: Dictionary = rows[0].duplicate(true)
	near_robot.x = snappedf(home.robot.position.x, 0.5)
	near_robot.z = snappedf(home.robot.position.z, 0.5)
	check(not home.placement_clear(near_robot, ""), "Physical placement refuses to entomb the robot")
	session.stash.fail_before_commit = true
	check(not SanctuaryLayout.save(session.preparation, []).ok and session.stash.home_snapshot() == before, "Layout save failure preserves previous layout")
	session.stash.fail_before_commit = false
	session.show_title()
	session.enter_sanctuary()
	await frames(6)
	check(session.active_scene.placed.get_child_count() == 1, "Returning home reconstructs saved furniture")
	app.queue_free()
	await frames(20)
	print("Sanctuary layout failures: ", failures)
	quit(1 if failures else 0)
