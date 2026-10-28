class_name InventoryContext
extends RefCounted
## View adapter. Arena access and safe preparation share commands, never balances.
var arena: Node3D
var preparation: PreparationService
var allowed: Callable
var close_requested: Callable

static func for_arena(mode: PlayerInteractionMode) -> InventoryContext:
	var context := InventoryContext.new()
	context.arena = mode.arena
	context.preparation = PreparationService.new(mode.arena.recall.stash)
	context.allowed = func() -> bool: return not mode.arena.session_staging and mode.current == PlayerInteractionMode.Mode.INVENTORY and not mode.arena.mission.is_finished()
	context.close_requested = mode.close_inventory
	return context

func inventory() -> InventoryLedger:
	return preparation.stash.inventory

func active() -> bool:
	return is_instance_valid(arena) and arena.deployment_started

func permitted() -> bool:
	return allowed.is_valid() and allowed.call()

func close() -> void:
	if close_requested.is_valid(): close_requested.call()

func execute(action: String, id: String, amount: int, source: WorldLoot, source_revision: int, player_revision: int) -> Dictionary:
	if not permitted(): return {"ok": false, "reason": "Inventory access ended."}
	var authority := inventory()
	var item := authority.record(id)
	if not active(): return preparation.execute(action, id, amount, source_revision if item.get("container") == "stash" else player_revision)
	var command: String = arena.inventory_interaction.next_command()
	if action == "Take All" and is_instance_valid(source):
		var total := 0
		var outcomes := PackedStringArray()
		for entry in authority.records(source.container_id):
			var result: Dictionary = arena.inventory_interaction.take(source, entry.id, entry.quantity, true, arena.inventory_interaction.next_command(), -1, -1)
			total += int(result.get("amount", 0)) if result.ok else 0
			outcomes.append("%s: %s" % [authority.catalog.find(StringName(entry.definition)).display_name, "%d accepted; %d remaining" % [result.get("amount", 0), int(entry.quantity) - int(result.get("amount", 0))] if result.ok else result.get("reason", "Unavailable")])
		return {"ok": total > 0, "amount": total, "reason": "%d units accepted. Remainders stay in the source.\n%s" % [total, "\n".join(outcomes)]}
	if action in ["Take", "Take fitting"] and is_instance_valid(source): return arena.inventory_interaction.take(source, id, amount, action == "Take fitting", command, source_revision, player_revision)
	if item.get("container") == "player":
		if action == "Split": return authority.split(id, amount, command)
		if action == "Equip / Unequip": return PreparationService.equip(authority, item, "player")
		if action == "Drop": return arena.inventory_interaction.drop(id, amount, command)
		if action == "Transfer" and is_instance_valid(source): return arena.inventory_interaction.put(source, id, amount, command, source_revision, player_revision)
	return {"ok": false, "reason": "Select an item and an available action."}
