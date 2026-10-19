class_name RaiderCombat
extends Node
## Combat decisions use the Raider's FSM. This component owns aim timers and intent.

var actor: Raider
var profile: RaiderCombatProfile
var weapon: ShotExecutor
var reserve_cover: Callable
var release_cover: Callable
var cover: Node3D
var destination: Node3D
var aim_elapsed: float = 0.0
var reposition_elapsed: float = 0.0
var retreat_remaining: float = 0.0
var random := RandomNumberGenerator.new()


func setup(owner_actor: Raider, definition: RaiderCombatProfile, seed_value: int) -> void:
	actor = owner_actor
	profile = definition
	random.seed = seed_value + actor.raider_id * 7919
	weapon = ShotExecutor.new()
	weapon.definition = profile.weapon
	weapon.shooter = actor
	weapon.muzzle = actor.get_node("Visuals/RifleMuzzle")
	weapon.shot_mask = 3
	weapon.damage_mask = 2
	add_child(weapon)
	actor.get_node("RaiderFeedback").setup_weapon(weapon)
	actor.get_node("Visuals/Rifle").show()
	actor.state_changed.connect(_on_state_changed)


func owns_state() -> bool:
	return actor.state in [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]


func _on_state_changed(_previous: Raider.State, next: Raider.State) -> void:
	aim_elapsed = 0
	if next not in [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		release()
	if next in [Raider.State.DEAD, Raider.State.EXTRACTED]:
		stop()


func release() -> void:
	if release_cover.is_valid():
		release_cover.call(actor.raider_id)
	cover = null
	destination = null


func stop() -> void:
	weapon.enabled = false
	weapon.set_physics_process(false)
	release()


func choose_cover() -> bool:
	release()
	cover = reserve_cover.call(actor.raider_id) if reserve_cover.is_valid() else null
	if cover == null:
		return false
	destination = cover
	actor.transition(Raider.State.TAKING_COVER)
	return true


func decide() -> bool:
	if actor.health.current <= actor.health.maximum * profile.retreat_health_fraction or retreat_remaining > 0:
		if actor.state == Raider.State.EXTRACTING:
			return true
		if actor.state == Raider.State.FLEEING and is_instance_valid(actor.extraction) and actor.global_position.distance_to(actor.extraction.global_position) < 0.8:
			actor.transition(Raider.State.EXTRACTING)
		elif actor.state != Raider.State.FLEEING and actor._choose_exit():
			actor.transition(Raider.State.FLEEING)
		return true
	if actor.state in [Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]:
		# Finish the selected route using the stored observation. Shooting still
		# requires fresh visibility, and the navigation watchdog can abandon it.
		return true
	if owns_state() and actor.threat_remaining <= 0:
		actor.transition(Raider.State.SELECTING)
		return false
	if actor.threat_visible and actor.global_position.distance_to(actor.current_target().global_position) <= profile.engagement_range:
		if actor.state != Raider.State.ENGAGING:
			actor.transition(Raider.State.ENGAGING)
		return true
	if actor.state == Raider.State.ENGAGING:
		if not choose_cover():
			actor.begin_investigation()
		return true
	return false


func on_damaged() -> void:
	aim_elapsed = 0
	if actor.health.current <= actor.health.maximum * profile.retreat_health_fraction:
		retreat_remaining = 4.0
		if actor._choose_exit():
			actor.transition(Raider.State.FLEEING)
	elif not choose_cover():
		retreat_remaining = 2.0
		if actor._choose_exit():
			actor.transition(Raider.State.FLEEING)


func on_arrived(_delta: float) -> void:
	if actor.state == Raider.State.TAKING_COVER and actor.task_elapsed >= profile.cover_hold:
		destination = cover.get_node("Peek")
		actor.transition(Raider.State.REPOSITIONING)
	elif actor.state == Raider.State.REPOSITIONING:
		reposition_elapsed = 0
		actor.transition(Raider.State.ENGAGING)


func tick(delta: float) -> void:
	retreat_remaining = maxf(0, retreat_remaining - delta)
	if actor.state != Raider.State.ENGAGING:
		aim_elapsed = 0
		return
	# Recheck visibility at firing time, not just the slower perception interval.
	if not actor.detects_robot() or actor.global_position.distance_to(actor.current_target().global_position) > profile.engagement_range:
		aim_elapsed = 0
		return
	var facing := actor.current_target().global_position - actor.global_position
	actor.visuals.rotation.y = atan2(-facing.x, -facing.z)
	aim_elapsed += delta
	reposition_elapsed += delta
	if reposition_elapsed >= profile.reposition_interval:
		reposition_elapsed = 0
		if choose_cover():
			return
	if aim_elapsed < profile.warning_time or weapon.cooldown > 0:
		return
	var aim := actor.target_point(actor.current_target())
	var distance := weapon.muzzle.global_position.distance_to(aim)
	var spread := tan(deg_to_rad(profile.spread_degrees)) * distance
	aim += Vector3(random.randf_range(-spread, spread), random.randf_range(-spread, spread), random.randf_range(-spread, spread))
	weapon.try_fire_at(aim)
