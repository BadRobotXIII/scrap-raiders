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


func create_arena(frozen: bool = true) -> Node3D:
	var arena := load("res://scenes/levels/social_betrayal_arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	if frozen:
		arena.set_physics_process(false)
		arena.robot.set_physics_process(false)
		arena.robot.input_adapter.set_physics_process(false)
		arena.robot.input_adapter.set_process_input(false)
		arena.robot.position = Vector3(100, 0.1, 100)
	await frames(10)
	if frozen:
		arena.process_entries()
		for actor in arena.raiders.values():
			actor.set_physics_process(false)
			actor.combat.weapon.set_physics_process(false)
	return arena


func run() -> void:
	var arena: Node3D = await create_arena()
	var a := arena.raiders[1] as Raider
	var b := arena.raiders[2] as Raider
	var c := arena.raiders[3] as Raider
	var assessment := a.betrayal
	check(assessment != null and b.betrayal == null and c.betrayal == null and a.carried_materials == 0 and b.carried_materials == 0, "Only authored opportunist gets a component; deployment grants no cargo")
	check(arena.ledger.collect(2, &"Salvage", 3) == 3, "Fixture moves finite stock through the authoritative ledger")
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 14)
	c.position = Vector3(18, 0.1, -18)
	a.transition(Raider.State.SELECTING)
	await frames(3)
	var transfers: int = arena.ledger.accepted_transfers
	var events: int = arena.social.relations.events().size()
	a.decide()
	assessment.tick(1.9)
	a.get_node("RaiderFeedback").refresh()
	check(a.state == Raider.State.ASSESSING_BETRAYAL and a.get_node("Alert").visible and "EYEING" in a.get_node("Alert").text, "Visible two-second hesitation uses Raider FSM without requiring a threat alert")
	check(arena.social.relations.events().size() == events and b.health.current == 100 and arena.ledger.accepted_transfers == transfers, "Assessment grants no hostility, damage or material transfer")
	b.position = Vector3(0, 0.1, 18)
	await frames(3)
	assessment.tick(0.2)
	check(a.state == Raider.State.SELECTING and assessment.elapsed == 0 and not assessment.spent, "Leaving range interrupts and resets continuous assessment")
	b.position = Vector3(0, 0.1, 14)
	await frames(3)
	assessment.decide()
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.4)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(0, 1.5, 11)
	arena.add_child(wall)
	await frames(3)
	assessment.tick(2)
	check(not assessment.spent and a.state == Raider.State.SELECTING, "Physical obstruction cancels betrayal rather than using remembered ally positions")
	wall.queue_free()
	await frames(3)
	assessment.decide()
	arena.robot.position = Vector3(3, 0.1, 8)
	await frames(3)
	assessment.tick(2)
	check(not assessment.spent and a.state == Raider.State.SELECTING, "Fresh visible machine threat cancels greed before relation mutation")
	arena.robot.position = Vector3(100, 0.1, 100)
	await frames(3)
	assessment.decide()
	a.health.apply_damage(50)
	check(assessment.elapsed == 0 and not assessment.can_assess(), "Accepted damage interrupts assessment; half health and cover/retreat prohibit reentry")
	a.health.current = 100
	a.combat.retreat_remaining = 2
	a.transition(Raider.State.SELECTING)
	check(not assessment.can_assess(), "Retreat cooldown cannot be overridden by a new greed decision")
	a.combat.retreat_remaining = 0
	a.transition(Raider.State.ENGAGING)
	check(not assessment.can_assess(), "Active combat cannot start opportunistic assessment")
	a.transition(Raider.State.SELECTING)
	assessment.decide()
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.NEUTRAL, "fixture neutral competitor", 0)
	assessment.tick(2)
	check(not assessment.spent and a.state == Raider.State.SELECTING, "Neutral salvage competition alone cannot trigger betrayal")
	arena.social.relations.set_attitude(1, 2, RaiderRelations.Attitude.ALLIED, "fixture ally restored", 0)
	events = arena.social.relations.events().size()
	assessment.decide()
	assessment.tick(1)
	check(not assessment.spent, "Interrupted time is not carried into the next assessment")
	assessment.tick(1)
	check(assessment.spent and assessment.victim_id == 2 and a.state == Raider.State.ENGAGING, "Exactly two continuous valid seconds commit hostility and ordinary combat intent")
	check(arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.HOSTILE and arena.social.relations.attitude(1, 3) == RaiderRelations.Attitude.ALLIED and arena.social.relations.attitude(2, 3) == RaiderRelations.Attitude.ALLIED, "Betrayal changes only the victim pair; third-party alliances and empty squads remain independent")
	assessment.tick(20)
	assessment.decide()
	check(arena.social.relations.events().size() == events + 1 and arena.ledger.accepted_transfers == transfers and b.carried_materials == 3 and a.carried_materials == 0, "One accepted initiation cannot oscillate or transfer cargo through hostility")
	a.combat.profile = a.combat.profile.duplicate()
	a.combat.profile.spread_degrees = 0
	a.combat.reposition_elapsed = 0
	a.combat.tick(0.6)
	check(b.health.current == 100, "Normal rifle aim warning follows the betrayal warning")
	a.combat.tick(0.1)
	check(b.health.current == 90 and b.health.last_damage_instigator_id == a.get_instance_id(), "Shared shot execution applies ordinary damage and instigator attribution")
	b.transition(Raider.State.SELECTING)
	b.combat.retreat_remaining = 0
	b.decide()
	check(b.current_target() == a and b.state == Raider.State.ENGAGING, "Victim independently perceives and retaliates against its new hostile")
	# Finish via the same shot executor, not a special betrayal kill/reward path.
	for index in range(9):
		a.combat.weapon.cooldown = 0
		a.combat.weapon.try_fire_at(a.target_point(b))
	check(b.health.current == 0 and b.carried_materials == 0 and arena.ledger.dropped_materials == 3 and arena.ledger.is_conserved(), "Ordinary lethal shots create one finite death drop with conserved materials")
	await frames(3)
	var drop := arena.drops.values()[0] as MaterialDrop
	a.position = drop.position + Vector3(0.4, 0, 0)
	a.threat_remaining = 0
	a.social.reports.clear()
	await frames(3)
	a.social.sense()
	a.salvage = drop
	a.transition(Raider.State.SCAVENGING)
	a.task_elapsed = a.scavenge_seconds
	arena._on_collection_requested(a)
	check(a.carried_materials == 3 and arena.ledger.dropped_materials == 0 and arena.ledger.lost_materials == 0 and arena.ledger.is_conserved(), "Opportunist must physically collect defeated ally cargo through normal loot validation")
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	check(assessment.stopped and not assessment.can_assess(), "Mission completion stops pending social assessment")
	arena.restart_mission()
	await frames(12)
	arena = current_scene
	check(arena.scenario_index == 11 and not arena.raiders[1].betrayal.spent and arena.social.relations.attitude(1, 2) == RaiderRelations.Attitude.ALLIED and arena.ledger.is_conserved(), "Restart rebuilds unspent opportunist, authored alliances and fresh finite stock")
	arena.queue_free()
	await frames(30)
	arena = await create_arena()
	a = arena.raiders[1]
	b = arena.raiders[2]
	c = arena.raiders[3]
	a.position = Vector3(0, 0.1, 8)
	b.position = Vector3(0, 0.1, 14)
	c.position = Vector3(18, 0.1, -18)
	assessment = a.betrayal
	a.transition(Raider.State.SELECTING)
	await frames(3)
	check(not assessment.qualifies(b), "Empty allies provide no betrayal incentive")
	var invalid_profile := assessment.profile.duplicate() as RaiderBetrayalProfile
	invalid_profile.assessment_seconds = NAN
	check(not invalid_profile.validation_error().is_empty(), "Malformed social tuning is rejected")
	var invalid_config := arena.config.duplicate() as MissionConfig
	invalid_config.preferred_entries = PackedStringArray(["unknown"])
	check(not invalid_config.validation_error().is_empty(), "Incomplete authored entry configuration is rejected")
	arena.ledger.collect(2, &"Salvage", 3)
	assessment.decide()
	arena.ledger.extract(2)
	assessment.tick(2)
	check(not assessment.spent and assessment.elapsed == 0, "Victim extraction invalidates an ongoing assessment without late hostility")
	b.position = Vector3(-18, 0.1, -18)
	c.position = Vector3(0, 0.1, 14)
	arena.ledger.collect(3, &"Salvage2", 3)
	await frames(3)
	assessment.decide()
	check(assessment.candidate == c and assessment.elapsed == 0, "New candidate starts a fresh assessment")
	events = arena.social.relations.events().size()
	arena.elapsed = arena.mission_duration
	arena.evaluate_mission(true)
	arena.finish_mission()
	assessment.tick(20)
	check(assessment.stopped and not assessment.spent and arena.social.relations.events().size() == events and arena.ledger.is_conserved(), "Deadline stops pending assessment without a late relation or material change")
	arena.queue_free()
	await frames(30)
	# Full natural encounter: no fixture cargo, teleports or forced activity.
	arena = await create_arena(false)
	var warned := false
	var loaded := false
	var committed := false
	for index in range(1100):
		await frames(1)
		if not arena.raiders.has(1) or not arena.raiders.has(2):
			continue
		a = arena.raiders.get(1)
		b = arena.raiders.get(2)
		warned = warned or a.state == Raider.State.ASSESSING_BETRAYAL
		loaded = loaded or b.carried_materials >= 3
		if a.betrayal.spent:
			committed = true
			break
	check(loaded and warned and committed, "Authored entries naturally scavenge, warn and initiate betrayal without free materials")
	check(arena.ledger.is_conserved() and arena.social.relations.attitude(1, 3) == RaiderRelations.Attitude.ALLIED and arena.social.relations.attitude(2, 3) == RaiderRelations.Attitude.ALLIED and arena.robot.get_node("Health").current == 100, "Natural encounter preserves accounting, observer relationships and distant robot separation")
	arena.queue_free()
	await frames(30)
	print("Stage M betrayal checks complete; failures: ", failures)
	quit(1 if failures else 0)
