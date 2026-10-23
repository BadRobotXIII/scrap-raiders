class_name RaiderProfile
extends Resource

enum CombatPolicy { BASELINE, GREEDY, CAUTIOUS, AGGRESSIVE }

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
@export var combat_policy: CombatPolicy = CombatPolicy.BASELINE
@export_range(0.5, 10.0) var combat_commit_seconds: float = 4.0
@export_range(0.5, 15.0) var escape_commit_seconds: float = 5.0
@export_range(0.3, 0.9) var combat_retreat_fraction: float = 0.6
@export_range(1.0, 18.0) var defense_distance: float = 6.0


func validation_error() -> String:
	if combat_policy < CombatPolicy.BASELINE or combat_policy > CombatPolicy.AGGRESSIVE:
		return "Invalid combat policy."
	if combat_policy == CombatPolicy.BASELINE:
		return ""
	if not is_finite(combat_commit_seconds) or combat_commit_seconds < 0.5 or combat_commit_seconds > 10 or not is_finite(escape_commit_seconds) or escape_commit_seconds < 0.5 or escape_commit_seconds > 15:
		return "Invalid combat commitment timing."
	if not is_finite(combat_retreat_fraction) or combat_retreat_fraction < 0.3 or combat_retreat_fraction > 0.9 or not is_finite(defense_distance) or defense_distance < 1 or defense_distance > 18 or not is_finite(threat_memory) or threat_memory <= 0 or threat_memory > 15:
		return "Invalid combat risk or observation tuning."
	return ""
