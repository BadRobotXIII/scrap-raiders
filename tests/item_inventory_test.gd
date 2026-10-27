extends SceneTree
## Shared player/Raider capacity, identity, atomicity and legacy conservation.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var items := InventoryLedger.new()
	check(items.catalog.definitions.size() == 12 and items.catalog.validation_error().is_empty(), "Compact catalog has stable valid definitions")
	items.ensure_container("source", "stock")
	check(items.issue("finite_supply", &"scrap_steel", 12, "source").ok, "Authorized supply creates finite stacks")
	check(not items.issue("finite_supply", &"scrap_steel", 12, "source").ok, "Supply permit cannot issue twice")
	var rules := InventoryRules.new()
	rules.cargo_slots = 2
	rules.weight_limit_g = 7000
	items.configure_container("player", rules)
	var stack: Dictionary = items.records("source")[0]
	var before := items.export_state()
	check(not items.transfer(stack.id, stack.quantity, "player").ok and items.export_state() == before, "Oversized exact transfer rejects without changing state or IDs")
	var moved := items.transfer(stack.id, stack.quantity, "player", true, "take_fitting")
	check(moved.ok and moved.amount == 2 and moved.remainder == stack.quantity - 2 and items.weight("player") == 6000, "Explicit partial transfer reports its remainder and respects weight")
	check(items.transfer(stack.id, stack.quantity, "player", true, "take_fitting") == moved and items.quantity("player") == 2, "Identical command retry cannot collect twice")
	check(not items.transfer(stack.id, 1, "player", true, "take_fitting").ok, "Conflicting reuse of command ID rejects")
	var carried: Dictionary = items.records("player")[0]
	check(items.split(carried.id, 1).ok and items.occupied("player") == 2 and items.weight("player") == 6000, "Stack split preserves quantities and mass while occupying a slot")
	before = items.export_state()
	check(not items.split(carried.id, 0).ok and items.export_state() == before, "Invalid split leaves authoritative state unchanged")
	check(items.is_valid() and items.material_total() == 12, "Split and partial transfers conserve every generated unit")
	var copy := items.records("player")
	copy[0].quantity = 999
	check(items.quantity("player") == 2, "Snapshots cannot mutate live ownership")
	var shared := InventoryLedger.new()
	var materials := MaterialLedger.new({&"stock": 6}, [1, 2], {}, shared)
	var equipment := EquipmentLedger.new(shared)
	check(equipment.assign_loadout(1, false) and materials.collect(1, &"stock", 3) == 3, "Legacy interfaces share one authoritative inventory")
	var id := materials.defeat(1)
	check(id > 0 and equipment.ground_count(1) == 2 and materials.ground_for(id) == 3, "Actor death atomically moves mixed cargo and equipment")
	check(equipment.resolve(1) and not equipment.resolve(1) and materials.defeat(1) == -1, "Repeated actor resolution cannot create another drop")
	check(materials.recover(id) == 3 and equipment.recover(1), "Both compatibility recovery paths use shared transfers")
	check(materials.settle_player(true) and equipment.settle_player(true) and materials.is_conserved() and equipment.is_valid(), "Combined player settlement conserves both projected economies")
	var robot := InventoryLedger.new()
	robot.configure_container("player", load("res://resources/inventory/player.tres"))
	robot.ensure_container("cache", "stock")
	robot.issue("blaster", &"industrial_blaster", 1, "player")
	robot.issue("human", &"raider_rifle", 1, "cache")
	var blaster: Dictionary = robot.records("player")[0]
	check(robot.transfer(blaster.id, 1, "player", false, "", -1, -1, "primary").ok, "Compatible equipment mounts through the same transfer boundary")
	before = robot.export_state()
	check(not robot.transfer(robot.records("cache")[0].id, 1, "player", false, "", -1, -1, "primary").ok and before == robot.export_state(), "Incompatible human weapon cannot replace robot equipment")
	check(robot.weight("player") == 4000 and robot.occupied("player") == 0, "Mounted equipment counts toward mass without consuming cargo slots")
	before = robot.export_state()
	check(robot.fit_value("cache", "player") == 4 and before == robot.export_state(), "Fit query includes existing mounted mass without consuming identity or changing ownership")
	print("Item inventory failures: ", failures)
	quit(1 if failures else 0)
