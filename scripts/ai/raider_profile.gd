class_name RaiderProfile
extends Resource

@export var display_name: String = "Raider"
@export var color: Color = Color.WHITE
@export var detection_radius: float = 8.0
@export var flee_distance: float = 8.0
@export var cargo_target: int = 3
@export var route_risk_weight: float = 2.0
@export var investigates: bool = false
@export var threat_memory: float = 3.0
@export_range(0.5, 20.0) var investigation_rearm_distance: float = 2.0
@export_range(0.0, 40.0) var hearing_radius: float = 12.0
@export var flees_from_gunfire: bool = false
