class_name PreparationView
extends Control
var session: Node
var station_context: String = "deployment"
var close_action: Callable
var inventory_view: InventoryView
var body: VBoxContainer
var feedback: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = ApplicationTheme.theme()
	if station_context == "storage":
		var context := InventoryContext.new()
		context.preparation = session.preparation
		context.allowed = func() -> bool: return session.preparation.available() and is_visible_in_tree()
		context.close_requested = close
		inventory_view = InventoryView.new()
		inventory_view.context = context
		add_child(inventory_view)
		inventory_view.open()
		return
	body = ApplicationTheme.panel(self, {"maintenance": "Robot maintenance / Loadouts", "contracts": "Operations / Contracts", "deployment": "Deployment preparation", "fabrication": "Fabrication", "disassembly": "Salvage disassembly", "display": "Owned item display"}.get(station_context, "Preparation"), 980)
	var navigation := HFlowContainer.new()
	body.add_child(navigation)
	for entry in [["storage", "Storage"], ["maintenance", "Loadouts"], ["contracts", "Contracts"], ["deployment", "Ready / Deploy"], ["fabrication", "Fabricate"], ["disassembly", "Disassemble"]]:
		ApplicationTheme.button(navigation, entry[1], switch_to.bind(entry[0]))
	if station_context == "maintenance":
		var loadouts := LoadoutView.new()
		loadouts.preparation = session.preparation
		body.add_child(loadouts)
	elif station_context in ["fabrication", "disassembly"]:
		var workshop := WorkshopView.new()
		workshop.preparation = session.preparation
		workshop.context = station_context
		body.add_child(workshop)
	elif station_context == "display":
		var display := DisplayView.new()
		display.preparation = session.preparation
		body.add_child(display)
	else: contract_controls()
	ApplicationTheme.button(body, "Close / Back", close)

func contract_controls() -> void:
	var home: Dictionary = session.stash.home_snapshot()
	var picker := OptionButton.new()
	for contract in session.contracts:
		picker.add_item(contract.display_name)
		picker.set_item_metadata(picker.item_count - 1, str(contract.contract_id))
		if str(contract.contract_id) == home.contract: picker.select(picker.item_count - 1)
	body.add_child(picker)
	var description := ApplicationTheme.label(body, "")
	var show_description := func() -> void:
		var contract: ContractDefinition = session.contracts[picker.selected]
		description.text = contract.mission.description + "\n\n"
		for goal in contract.mission.objective_definitions: description.text += ("Required: " if goal.required else "Optional: ") + goal.description + "\n"
	picker.item_selected.connect(func(_index: int) -> void: show_description.call())
	show_description.call()
	ApplicationTheme.label(body, "Scenario seed (repeat the same configuration for debugging)")
	var seed_value := SpinBox.new()
	seed_value.min_value = 0
	seed_value.max_value = 2147483647
	seed_value.value = home.seed
	body.add_child(seed_value)
	feedback = ApplicationTheme.label(body, "")
	ApplicationTheme.button(body, "Select contract", func() -> void:
		var result: Dictionary = session.preparation.select_contract(str(picker.get_selected_metadata()), int(seed_value.value))
		feedback.text = "Contract selected." if result.ok else result.get("reason", "Selection failed."))
	var ledger: InventoryLedger = session.stash.inventory
	var armed := false
	for item in ledger.records("prepared"):
		if item.slot == "e:primary": armed = true
	ApplicationTheme.label(body, "%s\nPrepared cargo: %d / %d slots · %.1f / %.1f kg\nPrepared items are at risk after deployment starts. Early extraction banks cargo even with incomplete objectives.\nRaider rifles are cargo only; the robot equips industrial blasters." % ["Robot-compatible primary is prepared." if armed else "UNARMED — no compatible primary is mounted. You may deploy for recovery.", ledger.occupied("prepared"), ledger.container("prepared").slots, ledger.weight("prepared") / 1000.0, ledger.container("prepared").weight / 1000.0])
	var confirmation := ConfirmationDialog.new()
	confirmation.dialog_text = "Deploy with the selected contract and prepared kit? Carried equipment is at risk. Missing equipment will not be replaced."
	add_child(confirmation)
	confirmation.confirmed.connect(func() -> void:
		var result: Dictionary = session.preparation.select_contract(str(picker.get_selected_metadata()), int(seed_value.value))
		if result.ok: session.deploy()
		else: feedback.text = result.get("reason", "Selection failed."))
	ApplicationTheme.button(body, "Confirm readiness / Deploy", func() -> void: confirmation.popup_centered(Vector2i(620, 200)))
	ApplicationTheme.label(body, "Successful contracts recorded: %d" % session.stash.completed_contract_count())

func switch_to(context: String) -> void:
	session.open_preparation(context, close_action)

func close() -> void:
	if close_action.is_valid(): close_action.call()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_I and get_viewport().gui_get_focus_owner() is LineEdit: return
	if inventory_view != null and inventory_view.shortcut(event):
		get_viewport().set_input_as_handled()
	elif event.physical_keycode in [KEY_I, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		close()
