class_name UpgradeDefinition
extends Resource
@export var upgrade_id: String = "cargo_rack_1"
@export var display_name: String = "Cargo Rack I"
@export var cargo_slots: int = 16
@export var weight_limit_g: int = 45000

static func player_rules(home: Dictionary) -> InventoryRules:
	var rules := load("res://resources/inventory/player.tres").duplicate() as InventoryRules
	if home.get("upgrades", {}).get("cargo_rack_1", false):
		var upgrade := load("res://resources/workshop/cargo_rack_1.tres") as UpgradeDefinition
		rules.cargo_slots = upgrade.cargo_slots
		rules.weight_limit_g = upgrade.weight_limit_g
	return rules
