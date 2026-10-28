class_name PlayerInteractionMode
extends Node
## Sole permission resolver; camera controllers retain camera ownership.
enum Mode { BRIEFING, GAMEPLAY, INVENTORY, DEVELOPER, POST_DEATH, RESULTS }
var arena: Node3D
var current: Mode = Mode.BRIEFING
var view: InventoryView
var binding: EquipmentBinding

func setup() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = InventoryView.new()
	view.mode = self
	arena.get_node("Overlay").add_child(view)
	binding = EquipmentBinding.new()
	add_child(binding)
	binding.bind(arena.ledger.inventory, "player", arena.robot.get_node("Weapon"), func() -> bool: return current == Mode.GAMEPLAY and arena.deployment_started and not arena.mission.is_finished())
	refresh()

func refresh() -> void:
	var next := current
	if arena.mission.is_finished():
		next = Mode.POST_DEATH if arena.mission.player_destroyed and not arena.mission.is_world_finished() else Mode.RESULTS
	elif arena.spectator != null and arena.spectator.active: next = Mode.DEVELOPER
	elif current != Mode.INVENTORY: next = Mode.GAMEPLAY if arena.deployment_started else Mode.BRIEFING
	transition(next)

func transition(next: Mode) -> void:
	var changed := current != next
	current = next
	var input: RobotInput = arena.robot.input_adapter
	input.gameplay_enabled = current == Mode.GAMEPLAY
	if changed or not input.gameplay_enabled:
		input.clear_intent()
		arena.robot.stop_traversal()
	if current != Mode.INVENTORY:
		view.hide()
		arena.inventory_interaction.cancel()
	if changed:
		input.suppress_fire_until_release = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if current in [Mode.GAMEPLAY, Mode.DEVELOPER] else Input.MOUSE_MODE_VISIBLE
	if binding != null: binding.refresh()

func open_inventory(source: WorldLoot = null) -> bool:
	if arena.session_staging: return false
	refresh()
	if current not in [Mode.GAMEPLAY, Mode.BRIEFING]: return false
	if source != null and not arena.inventory_interaction.player_access(source): return false
	arena.recall.cancel()
	arena.flare_director.cancel_recovery()
	transition(Mode.INVENTORY)
	view.open(source)
	return true

func close_inventory() -> void:
	if current != Mode.INVENTORY: return
	current = Mode.GAMEPLAY if arena.deployment_started else Mode.BRIEFING
	transition(current)
	# Closing by key does not reuse a held mouse button as a shot.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if current == Mode.GAMEPLAY else Input.MOUSE_MODE_VISIBLE
	arena.robot.input_adapter.suppress_fire_until_release = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if current == Mode.INVENTORY and view.shortcut(event):
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_I:
			if current == Mode.INVENTORY: close_inventory()
			else: open_inventory()
			get_viewport().set_input_as_handled()
		elif current == Mode.INVENTORY and event.is_action_pressed("pause"):
			close_inventory()
			get_viewport().set_input_as_handled()
