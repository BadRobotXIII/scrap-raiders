class_name ActorVisual
extends Node3D
## Reads actor motion and accepted shots. Never owns movement, aim, damage or cargo.
## The export contains presentation only; gameplay muzzle markers remain siblings.

@export var kind: StringName = &"raider"
@export var model_scene: PackedScene
@export var production_enabled: bool = true:
	set(value):
		production_enabled = value
		visible = value
		set_process(value)
@export_range(0.0, 10.0) var preview_speed: float = 0.0

var actor: Node3D
var model: Node3D
var appearance_index: int = 0
var animation_state: StringName = &"idle"
var observed_speed: float = 0.0
var shot_count: int = 0
var _weapon: ShotExecutor
var _health: Health
var _player: AnimationPlayer
var _upper_player: AnimationPlayer
var _clips: Dictionary[StringName, StringName] = {}
var _parts: Dictionary[StringName, Node3D] = {}
var _rest: Dictionary[StringName, Transform3D] = {}
var _mutable_cloth: Array[StandardMaterial3D] = []
var _cargo_material: StandardMaterial3D
var _armed: bool = false
var _cargo: int = 0
var _elapsed: float = 0.0
var _stride: float = 0.0
var _fire_remaining: float = 0.0
var _damage_remaining: float = 0.0
var _damage_meshes: Array[MeshInstance3D] = []
var _damage_overlays: Array[Material] = []
var _properties: Dictionary[StringName, bool] = {}
const SHOT_SECONDS: float = 0.16
const CLOTH_COLORS: Array[Color] = [Color(0.24, 0.29, 0.18), Color(0.28, 0.22, 0.16), Color(0.18, 0.24, 0.28)]
const SHADOWLESS_DETAILS: Array[StringName] = [&"hood", &"shoulderpad", &"packroll", &"cargo_indicator", &"left_wheel_mesh", &"right_wheel_mesh", &"left_rotor_mesh", &"right_rotor_mesh"]


func _ready() -> void:
	if model_scene != null:
		model = model_scene.instantiate() as Node3D
		add_child(model)
		_prepare_model()
		_apply_appearance()
		set_armed(_armed)
		set_cargo(_cargo)
	visible = production_enabled
	set_process(production_enabled)


static func appearance_for(mission_seed: int, actor_id: StringName) -> int:
	# Independent integer hash: this never consumes any gameplay RNG stream.
	var value: int = 2166136261
	for byte in ("actor_visual_w/%d/%s" % [mission_seed, actor_id]).to_utf8_buffer():
		value = ((value ^ byte) * 16777619) & 0x7fffffff
	return value % 3


func configure(owner_actor: Node3D, weapon: ShotExecutor = null, mission_seed: int = 0, actor_id: StringName = &"") -> void:
	if is_instance_valid(_weapon) and _weapon.fired.is_connected(_on_fired):
		_weapon.fired.disconnect(_on_fired)
	actor = owner_actor
	_properties.clear()
	if is_instance_valid(actor):
		_health = actor.get_node_or_null("Health") as Health
		for property in actor.get_property_list():
			_properties[StringName(property.name)] = true
	_weapon = weapon
	if is_instance_valid(_weapon):
		_weapon.fired.connect(_on_fired)
	set_armed(weapon != null)
	appearance_index = appearance_for(mission_seed, actor_id)
	_apply_appearance()


func set_armed(value: bool) -> void:
	_armed = value
	if model != null and kind == &"raider":
		var rifle := _find_named(model, &"Rifle")
		if rifle != null:
			rifle.visible = value


func set_cargo(amount: int) -> void:
	_cargo = maxi(0, amount)
	if _cargo_material != null:
		_cargo_material.albedo_color = Color(0.9, 0.57, 0.12) if _cargo > 0 else Color(0.13, 0.2, 0.18)
		_cargo_material.emission_enabled = _cargo > 0
		_cargo_material.emission = Color(0.2, 0.08, 0.01) if _cargo > 0 else Color.BLACK


func _prepare_model() -> void:
	_player = _find_player(model)
	if _player != null:
		_player.stop()
		_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for name in _player.get_animation_list():
			var short_name := StringName(String(name).get_file().to_lower())
			if short_name in [&"idle", &"walk", &"run", &"aim", &"fire", &"death"]:
				_clips[short_name] = StringName(name)
		if kind == &"raider":
			_make_upper_layer()
	for part_name in [&"left_thigh", &"right_thigh", &"left_shin", &"right_shin", &"left_foot", &"right_foot", &"left_upper_arm", &"right_upper_arm", &"left_wheel", &"right_wheel", &"left_rotor", &"right_rotor", &"sensor_head", &"recoil"]:
		var part := _find_named(model, part_name)
		if part != null:
			_parts[part_name] = part
			_rest[part_name] = part.transform
	_rest[&"model"] = model.transform
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		# Body/chassis shadows already describe these small cosmetic details.
		# Keep main silhouettes and held weapons casting their ordinary shadows.
		if StringName(String(mesh.name).to_lower()) in SHADOWLESS_DETAILS:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material != null and (material.resource_name == "cloth_olive" or material.resource_path.get_file().get_basename() == "cloth_olive"):
				var local := material.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface, local)
				_mutable_cloth.append(local)
	var indicator := _find_named(model, &"cargo_indicator") as MeshInstance3D
	if indicator != null and indicator.mesh != null:
		var original := indicator.get_active_material(0) as StandardMaterial3D
		_cargo_material = original.duplicate() as StandardMaterial3D if original != null else StandardMaterial3D.new()
		indicator.set_surface_override_material(0, _cargo_material)


func _apply_appearance() -> void:
	if model == null or kind != &"raider":
		return
	for material in _mutable_cloth:
		material.albedo_color = CLOTH_COLORS[appearance_index]
	var hood := _find_named(model, &"Hood")
	var shoulder := _find_named(model, &"ShoulderPad")
	var roll := _find_named(model, &"PackRoll")
	if hood != null:
		hood.visible = appearance_index == 0
	if shoulder != null:
		shoulder.visible = appearance_index == 1
	if roll != null:
		roll.visible = appearance_index != 1


func _make_upper_layer() -> void:
	var library := AnimationLibrary.new()
	for short_name in [&"aim", &"fire"]:
		if not _clips.has(short_name):
			continue
		var clip := _player.get_animation(_clips[short_name]).duplicate() as Animation
		for index in range(clip.get_track_count() - 1, -1, -1):
			var path := String(clip.track_get_path(index)).to_lower()
			var upper := false
			for bone in ["spine", "chest", "neck", "head", "clavicle", "upper_arm", "forearm", "hand"]:
				if path.contains(":" + bone) or path.contains(":" + "left_" + bone) or path.contains(":" + "right_" + bone):
					upper = true
			if not upper or clip.track_get_type(index) not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
				clip.remove_track(index)
		library.add_animation(short_name, clip)
	_upper_player = AnimationPlayer.new()
	_upper_player.name = "VisualUpperBody"
	_upper_player.root_node = _player.root_node
	_upper_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_upper_player.add_animation_library(&"", library)
	_player.get_parent().add_child(_upper_player)


func _on_fired(_origin: Vector3, _endpoint: Vector3, _damaged: bool) -> void:
	if not production_enabled:
		return
	_fire_remaining = SHOT_SECONDS
	shot_count += 1
	if _upper_player != null and _upper_player.has_animation(&"fire"):
		_upper_player.play(&"fire", 0.025)


func _process(delta: float) -> void:
	if _damage_remaining > 0:
		_damage_remaining = maxf(0, _damage_remaining - delta)
		if _damage_remaining == 0:
			for index in range(_damage_meshes.size()):
				if is_instance_valid(_damage_meshes[index]): _damage_meshes[index].material_overlay = _damage_overlays[index]
	if not production_enabled or model == null:
		return
	if is_instance_valid(actor) and ((is_instance_valid(_health) and _health.current <= 0) or not actor.is_physics_processing()):
		return
	_elapsed += delta
	_fire_remaining = maxf(0.0, _fire_remaining - delta)
	observed_speed = preview_speed
	var body := actor as CharacterBody3D
	if body != null:
		var real_velocity := body.get_real_velocity()
		observed_speed = Vector2(real_velocity.x, real_velocity.z).length()
		if _properties.has(&"debug_movement_locked") and actor.get("debug_movement_locked"):
			observed_speed = 0.0
	if kind == &"raider":
		_update_raider(delta)
	else:
		_update_machine(delta, body)


func present_fire() -> void:
	# Preview input reaches the same cosmetic recoil, never a ShotExecutor.
	_on_fired(Vector3.ZERO, Vector3.ZERO, false)

func present_damage() -> void:
	if model == null: return
	if _damage_meshes.is_empty():
		for node in model.find_children("*", "MeshInstance3D", true, false):
			_damage_meshes.append(node)
			_damage_overlays.append(node.material_overlay)
	var flash := StandardMaterial3D.new()
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.albedo_color = Color(0.95, 0.76, 0.45)
	for mesh in _damage_meshes: mesh.material_overlay = flash
	_damage_remaining = 0.12


func _aiming() -> bool:
	if not _armed or not is_instance_valid(actor):
		return false
	if _properties.has(&"combat"):
		var combat: Variant = actor.get("combat")
		return combat != null and actor.get("state") in [Raider.State.ENGAGING, Raider.State.TAKING_COVER, Raider.State.REPOSITIONING]
	if _properties.has(&"input_adapter"):
		var input: Variant = actor.get("input_adapter")
		return input != null and (input.aim_intent or input.fire_intent)
	return false


func _update_raider(delta: float) -> void:
	animation_state = &"run" if observed_speed > 3.4 else (&"walk" if observed_speed > 0.12 else &"idle")
	if _player != null and _clips.has(animation_state):
		var clip_name: StringName = _clips[animation_state]
		if _player.current_animation != clip_name:
			_player.play(clip_name, 0.1)
		_player.speed_scale = clampf(observed_speed / (4.5 if animation_state == &"run" else 3.0), 0.55, 1.6) if animation_state != &"idle" else 1.0
		_player.advance(delta)
	if _upper_player != null:
		var upper: StringName = &"fire" if _fire_remaining > 0 else (&"aim" if _aiming() else &"")
		if upper != &"" and _upper_player.has_animation(upper):
			if _upper_player.current_animation != upper:
				_upper_player.play(upper, 0.06)
			_upper_player.advance(delta)
		elif _upper_player.is_playing():
			_upper_player.stop()
		if upper != &"":
			animation_state = upper if observed_speed < 0.12 else StringName("%s_%s" % [animation_state, upper])


func _update_machine(delta: float, body: CharacterBody3D) -> void:
	_stride += delta * observed_speed * 3.0
	animation_state = &"locomotion" if observed_speed > 0.12 else &"idle"
	var swing := sin(_stride) * minf(0.48, observed_speed * 0.10)
	var airborne := kind == &"player" and body != null and not body.is_on_floor()
	model.transform = _rest[&"model"]
	for part_name in _parts:
		_parts[part_name].transform = _rest[part_name]
	if kind == &"player":
		var boosting: bool = _properties.has(&"boost_state") and actor.get("boost_state") == RobotController.BoostState.BOOSTING
		var posture := -0.2 if boosting else (0.3 if airborne else 0.0)
		_rotate_part(&"left_thigh", Vector3(posture if boosting or airborne else swing, 0, 0))
		_rotate_part(&"right_thigh", Vector3(posture if boosting or airborne else -swing, 0, 0))
		_rotate_part(&"left_shin", Vector3(-0.5 if airborne else -maxf(0, swing) * 0.9, 0, 0))
		_rotate_part(&"right_shin", Vector3(-0.5 if airborne else -maxf(0, -swing) * 0.9, 0, 0))
		_rotate_part(&"left_foot", Vector3(-0.15 if airborne else -swing * 0.35, 0, 0))
		_rotate_part(&"right_foot", Vector3(-0.15 if airborne else swing * 0.35, 0, 0))
		_rotate_part(&"left_upper_arm", Vector3(-swing * 0.2, 0, 0))
	elif kind == &"ground_machine":
		_rotate_part(&"left_wheel", Vector3(_stride * 1.7, 0, 0))
		_rotate_part(&"right_wheel", Vector3(_stride * 1.7, 0, 0))
	elif kind == &"flying_scout":
		_rotate_part(&"left_rotor", Vector3(0, _elapsed * 32.0, 0))
		_rotate_part(&"right_rotor", Vector3(0, -_elapsed * 32.0, 0))
		model.position.y += sin(_elapsed * 2.8) * 0.018
		animation_state = &"hover" if observed_speed < 0.12 else &"movement"
	if _parts.has(&"recoil"):
		_parts[&"recoil"].position.z += (_fire_remaining / SHOT_SECONDS) * 0.035
	if _fire_remaining > 0:
		animation_state = &"attack" if kind == &"ground_machine" else &"fire"


func _rotate_part(part_name: StringName, angle: Vector3) -> void:
	if _parts.has(part_name):
		var rest: Transform3D = _rest[part_name]
		_parts[part_name].basis = rest.basis * Basis.from_euler(angle)


func create_death_visual() -> Node3D:
	if not production_enabled or model_scene == null or model == null:
		return null
	# Instantiate the raw visual resource, never the actor or adapter. The copy has
	# no live actor reference and needs no callback when its animation completes.
	var result := Node3D.new()
	result.name = "TerminalVisual"
	var copy := model_scene.instantiate() as Node3D
	_strip_nonvisual(copy)
	_copy_pose(model, copy)
	result.add_child(copy)
	result.set_meta("actor_visual_kind", kind)
	result.set_meta("appearance_index", appearance_index)
	var terminal := _find_player(copy)
	if terminal != null and kind == &"raider":
		terminal.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
		for name in terminal.get_animation_list():
			if String(name).get_file().to_lower() == "death":
				terminal.play(name, 0.05)
				break
	else:
		_make_mechanical_terminal(result, copy)
	return result


static func _strip_nonvisual(node: Node) -> void:
	node.set_script(null)
	for child in node.get_children():
		if child.get_class() not in ["Node3D", "MeshInstance3D", "Skeleton3D", "BoneAttachment3D", "Marker3D", "AnimationPlayer"]:
			node.remove_child(child)
			child.free()
		else:
			_strip_nonvisual(child)


static func _copy_pose(source: Node, destination: Node) -> void:
	if source is Node3D and destination is Node3D:
		destination.transform = source.transform
		destination.visible = source.visible
	if source is Skeleton3D and destination is Skeleton3D:
		for index in range(source.get_bone_count()):
			var target: int = destination.find_bone(source.get_bone_name(index))
			if target >= 0:
				destination.set_bone_pose_position(target, source.get_bone_pose_position(index))
				destination.set_bone_pose_rotation(target, source.get_bone_pose_rotation(index))
				destination.set_bone_pose_scale(target, source.get_bone_pose_scale(index))
	if source is MeshInstance3D and destination is MeshInstance3D:
		destination.cast_shadow = source.cast_shadow
		# Mutable cloth/cargo overrides are snapshots too. A final ledger-backed
		# cargo refresh on the source must not recolor the independent death copy.
		destination.material_override = source.material_override.duplicate() as Material if source.material_override != null else null
		for surface in range(source.get_surface_override_material_count()):
			var material: Material = source.get_surface_override_material(surface)
			destination.set_surface_override_material(surface, material.duplicate() as Material if material != null else null)
	for child in source.get_children():
		var target := destination.get_node_or_null(NodePath(String(child.name)))
		if target != null:
			_copy_pose(child, target)


static func _make_mechanical_terminal(container: Node3D, copy: Node3D) -> void:
	var player := AnimationPlayer.new()
	player.name = "TerminalAnimation"
	container.add_child(player)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 0.4
	var track := clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(track, NodePath(String(copy.name)))
	clip.rotation_track_insert_key(track, 0.0, copy.quaternion)
	clip.rotation_track_insert_key(track, 0.4, copy.quaternion * Quaternion.from_euler(Vector3(0.18, 0, 0.14)))
	library.add_animation(&"destruction", clip)
	player.add_animation_library(&"", library)
	player.play(&"destruction")


static func _find_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


static func _find_named(root: Node, target_name: StringName) -> Node3D:
	if String(root.name).to_lower() == String(target_name).to_lower() and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null
