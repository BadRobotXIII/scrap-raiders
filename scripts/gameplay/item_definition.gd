class_name ItemDefinition
extends Resource
## Immutable type data. Runtime ownership belongs exclusively to InventoryLedger.

enum Category { MATERIAL, MECHANICAL, ELECTRONICS, WEAPON, ARMOR, POWER, MOBILITY, UTILITY }
@export var definition_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category = Category.MATERIAL
@export var icon: Texture2D
@export var unit_weight_g: int = 0
@export var max_stack: int = 1
@export var base_value: int = 0
@export var material_units: int = 0
@export var mount: StringName
@export var compatible_actors: PackedStringArray = []
@export var weapon: WeaponDefinition

func validation_error() -> String:
	if definition_id.is_empty() or display_name.is_empty() or category not in Category.values():
		return "Item needs a stable identity, name and category."
	if unit_weight_g < 0 or unit_weight_g > 1000000 or max_stack < 1 or max_stack > 1000 or base_value < 0 or base_value > 1000000 or material_units not in [0, 1]:
		return "Invalid item weight, stack, value or material credit."
	if not mount.is_empty() and (max_stack != 1 or compatible_actors.is_empty()):
		return "Mounted equipment must be unique and declare compatibility."
	if weapon != null and mount != &"primary":
		return "Weapon binding requires a primary mount."
	return ""
