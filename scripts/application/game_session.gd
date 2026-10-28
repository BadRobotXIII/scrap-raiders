class_name GameSession
extends Node
## Application transitions only. Arena, profile, inventory and objectives retain authority.
enum State { TITLE, SANCTUARY, QUICK_PREPARATION, LOADING, DEPLOYMENT, RESULTS, RETURNING, ERROR }
@export var profile_path: String = "user://stash.json"
var state: State = State.TITLE
var stash: PersistentStash
var preparation: PreparationService
var active_scene: Node
var panel: Control
var last_error: String = ""
var transition_busy: bool = false
var transition_generation: int = 0
var return_button: Button
var notice: Label
var abandon_confirmation: ConfirmationDialog
# Deterministic failure seam for isolated startup tests.
var startup_fault: String = ""
var contracts: Array[ContractDefinition] = [preload("res://resources/contracts/asset_recovery.tres"), preload("res://resources/contracts/salvage_complex.tres")]
@onready var slot: Node = get_parent().get_node("SceneSlot")
@onready var overlay: CanvasLayer = get_parent().get_node("Overlay")

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_viewport().gui_embed_subwindows = true
	retry_profile()

func retry_profile() -> void:
	if transition_busy or state not in [State.TITLE, State.ERROR] or (is_instance_valid(active_scene) and active_scene.get("session_profile") != null): return
	var authority := InventoryLedger.new()
	authority.hybrid = true
	authority.identity_prefix = Crypto.new().generate_random_bytes(16).hex_encode()
	stash = PersistentStash.new(profile_path)
	if not stash.attach_inventory(authority) or not stash.upgrade_application_profile():
		last_error = stash.last_error
		preparation = null
	else:
		preparation = PreparationService.new(stash)
		last_error = ""
		apply_settings()
	show_title()

func transition(next: State) -> void:
	state = next
	if preparation != null: preparation.enabled = state in [State.TITLE, State.SANCTUARY, State.QUICK_PREPARATION]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func clear_panel() -> void:
	if is_instance_valid(panel):
		panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null

func replace_scene(scene: Node) -> void:
	clear_panel()
	if is_instance_valid(active_scene):
		slot.remove_child(active_scene)
		active_scene.queue_free()
	active_scene = scene
	if scene != null: slot.add_child(scene)

func show_title() -> void:
	if transition_busy: return
	if is_instance_valid(active_scene) and active_scene.get("session_profile") != null: return
	transition(State.TITLE if preparation != null else State.ERROR)
	var title := preload("res://scenes/application/title_screen.tscn").instantiate()
	title.session = self
	replace_scene(title)

func enter_sanctuary() -> void:
	if transition_busy or preparation == null or state not in [State.TITLE, State.QUICK_PREPARATION, State.RETURNING]: return
	transition(State.SANCTUARY)
	var home := preload("res://scenes/sanctuary/sanctuary.tscn").instantiate()
	home.session = self
	replace_scene(home)

func quick_prepare() -> void:
	if transition_busy or preparation == null or state != State.TITLE: return
	transition(State.QUICK_PREPARATION)
	var screen := preload("res://scenes/application/quick_preparation.tscn").instantiate()
	screen.session = self
	replace_scene(screen)

func open_preparation(context: String, close_action: Callable) -> void:
	if transition_busy or state not in [State.SANCTUARY, State.QUICK_PREPARATION] or not preparation.available(): return
	clear_panel()
	var view := PreparationView.new()
	view.session = self
	view.station_context = context
	view.close_action = close_action
	panel = view
	overlay.add_child(view)

func settings() -> void:
	if transition_busy or preparation == null or not preparation.available(): return
	clear_panel()
	panel = Control.new()
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := ApplicationTheme.panel(panel, "Settings", 620)
	ApplicationTheme.label(body, "Master volume")
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = stash.home_snapshot().settings.volume
	body.add_child(volume)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = stash.home_snapshot().settings.fullscreen
	body.add_child(fullscreen)
	var feedback := ApplicationTheme.label(body, "Changes are saved only when confirmed.")
	ApplicationTheme.button(body, "Save", func() -> void:
		var result := preparation.metadata({"settings": [volume.value, fullscreen.button_pressed]}, func(home: Dictionary) -> Dictionary:
			home.settings = {"volume": volume.value, "fullscreen": fullscreen.button_pressed}
			return {"ok": true})
		if result.ok:
			apply_settings()
			clear_panel()
		else: feedback.text = result.get("reason", "Settings could not be saved."))
	ApplicationTheme.button(body, "Cancel", clear_panel)

func apply_settings() -> void:
	var settings_value := stash.home_snapshot().settings as Dictionary
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings_value.volume), 0.0001)))
	AudioServer.set_bus_mute(0, float(settings_value.volume) <= 0)
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings_value.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func selected_contract() -> ContractDefinition:
	var id: String = stash.home_snapshot().contract
	for contract in contracts:
		if str(contract.contract_id) == id: return contract
	return null

func deploy() -> void:
	if transition_busy or state not in [State.SANCTUARY, State.QUICK_PREPARATION]: return
	var contract := selected_contract()
	if contract == null or not contract.validation_error().is_empty() or not stash.inventory.is_valid():
		last_error = "Contract or equipment validation failed."
		return
	transition_busy = true
	transition_generation += 1
	var generation := transition_generation
	transition(State.LOADING)
	clear_panel()
	# Retire home input immediately; the binding below revokes its ledger commands.
	if is_instance_valid(active_scene): active_scene.process_mode = Node.PROCESS_MODE_DISABLED
	var arena := load(contract.scene_path).instantiate() as Node3D
	arena.stash_path = profile_path
	arena.session_profile = stash
	arena.session_attempt = Crypto.new().generate_random_bytes(16).hex_encode()
	arena.session_staging = true
	arena.session_return = return_home
	arena.seed_override = int(stash.home_snapshot().seed)
	arena.mission_config_override = contract.mission
	replace_scene(arena)
	if arena.setup_error.is_empty() and arena.recall != null: arena.stage_for_session()
	var ready := false
	for index in 120:
		await get_tree().physics_frame
		if generation != transition_generation: return
		if is_instance_valid(arena) and arena.is_inside_tree():
			var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
			NavigationServer3D.map_force_update(map)
			if readiness(arena):
				ready = true
				break
	if not ready or startup_fault == "before_debit":
		await abort_start(arena, "Deployment could not initialize; your prepared kit is safe.")
		return
	if not stash.begin_inventory_deployment(arena.recall.deployment_id, true, str(contract.contract_id), arena.debug_seed):
		await abort_start(arena, "Loadout debit failed: " + stash.last_error)
		return
	if startup_fault == "after_debit" or not stash.mark_running(arena.recall.deployment_id):
		await abort_start(arena, "Deployment activation failed; unstarted kit returned.")
		return
	arena.session_start_authorized = true
	arena.session_staging = false
	if not arena.start_deployment():
		last_error = "Committed deployment could not activate; return resolves its running loss policy."
		transition(State.ERROR)
	else:
		transition(State.DEPLOYMENT)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	install_return(arena)
	transition_busy = false

func readiness(arena: Node3D) -> bool:
	if not arena.setup_error.is_empty() or arena.mission.is_finished() or arena.recall == null or not arena.recall.save_error.is_empty() or arena.interaction_mode == null or arena.mission_objectives == null: return false
	if not is_instance_valid(arena.recall.dock) or NavigationServer3D.map_get_iteration_id(arena.get_node("NavigationRegion3D").get_navigation_map()) == 0: return false
	var position_value: Vector3 = arena.robot.global_position
	var floor_query := PhysicsRayQueryParameters3D.create(position_value + Vector3.UP, position_value + Vector3.DOWN, 1, [arena.robot.get_rid()])
	if arena.get_world_3d().direct_space_state.intersect_ray(floor_query).is_empty(): return false
	var map: RID = arena.get_node("NavigationRegion3D").get_navigation_map()
	return NavigationServer3D.map_get_closest_point(map, position_value).distance_to(position_value) < 1.2

func abort_start(arena: Node3D, message: String) -> void:
	if arena.recall != null:
		var attempt: String = arena.recall.deployment_id
		if stash.deployment_snapshot(attempt).get("phase") == "committed" and not stash.cancel_unstarted(attempt):
			last_error = "Kit recovery is pending: " + stash.last_error
			transition(State.ERROR)
			transition_busy = false
			install_return(arena)
			return
	last_error = message
	stash.result_builder = Callable()
	var home := InventoryLedger.new()
	home.hybrid = true
	home.identity_prefix = Crypto.new().generate_random_bytes(16).hex_encode()
	if not stash.bind_inventory(home):
		transition(State.ERROR)
		transition_busy = false
		install_return(arena)
		return
	transition_busy = false
	transition(State.RETURNING)
	enter_sanctuary()
	await get_tree().process_frame
	if is_instance_valid(active_scene): active_scene.message.text = last_error

func install_return(arena: Node3D) -> void:
	return_button = ApplicationTheme.button(arena.get_node("Overlay"), "Abandon / Return to Sanctuary", request_return)
	return_button.theme = ApplicationTheme.theme()
	return_button.position = Vector2(1250, 18)
	notice = Label.new()
	notice.position = Vector2(1050, 70)
	notice.custom_minimum_size.x = 520
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arena.get_node("Overlay").add_child(notice)
	abandon_confirmation = ConfirmationDialog.new()
	abandon_confirmation.theme = ApplicationTheme.theme()
	abandon_confirmation.dialog_text = "Abandon this deployment and return home? All carried equipment and cargo will be forfeited. Safe storage is preserved."
	arena.get_node("Overlay").add_child(abandon_confirmation)
	abandon_confirmation.confirmed.connect(return_home)
	abandon_confirmation.canceled.connect(cancel_abandon)

func request_return() -> void:
	if transition_busy or not is_instance_valid(active_scene): return
	if active_scene.mission.is_finished() or active_scene.session_staging:
		return_home()
		return
	active_scene.robot.input_adapter.gameplay_enabled = false
	active_scene.robot.input_adapter.clear_intent()
	active_scene.robot.input_adapter.suppress_fire_until_release = true
	active_scene.robot.stop_traversal()
	active_scene.robot.get_node("Weapon").enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	abandon_confirmation.popup_centered(Vector2i(680, 200))

func cancel_abandon() -> void:
	if not is_instance_valid(active_scene) or active_scene.get("session_profile") == null: return
	active_scene.interaction_mode.refresh()
	active_scene.robot.input_adapter.suppress_fire_until_release = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if active_scene.mission.is_finished() else Input.MOUSE_MODE_CAPTURED

func return_home() -> void:
	if transition_busy or not is_instance_valid(active_scene) or not active_scene.get("session_profile") is PersistentStash: return
	transition_busy = true
	var arena := active_scene as Node3D
	var receipt := stash.deployment_snapshot(arena.session_attempt)
	if receipt.get("phase") == "committed":
		await abort_start(arena, "Unstarted deployment cancelled; kit returned.")
		return
	if not arena.mission.is_finished():
		arena.mission.fail_abandoned()
		arena.finish_mission()
	if stash.deployment_snapshot(arena.session_attempt).get("status") == "active":
		arena.recall.settle_failure()
		arena.finalize_player_result()
	if stash.deployment_snapshot(arena.session_attempt).get("status") == "active":
		last_error = "Settlement is pending. Retry Return after resolving the save error."
		if is_instance_valid(notice): notice.text = last_error + "\n" + stash.last_error
		transition_busy = false
		return
	transition(State.RETURNING)
	if not arena.mission.is_world_finished(): arena.mission.stop_world("Returned to Sanctuary.")
	arena.finish_mission()
	stash.result_builder = Callable()
	var home := InventoryLedger.new()
	home.hybrid = true
	home.identity_prefix = Crypto.new().generate_random_bytes(16).hex_encode()
	if not stash.bind_inventory(home):
		last_error = stash.last_error
		transition(State.ERROR)
		transition_busy = false
		return
	transition_busy = false
	enter_sanctuary()

func _process(_delta: float) -> void:
	if state == State.DEPLOYMENT and is_instance_valid(active_scene) and active_scene.mission.is_finished():
		transition(State.RESULTS)
		if is_instance_valid(return_button): return_button.text = "Return to Sanctuary"

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEPLOYMENT and not transition_busy and event.is_action_pressed("pause") and active_scene.interaction_mode.current == PlayerInteractionMode.Mode.GAMEPLAY:
		get_viewport().set_input_as_handled()
		request_return()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if transition_busy: return
		if state in [State.DEPLOYMENT, State.RESULTS, State.ERROR] and is_instance_valid(active_scene) and active_scene.get("session_profile") != null:
			return_home()
			if state != State.SANCTUARY: return
		get_tree().quit()
