class_name RaiderBetrayalProfile
extends Resource
## Opt-in social tuning; does not modify existing personality/combat resources.

@export var minimum_victim_cargo: int = 3
@export var assessment_seconds: float = 2.0
@export var range_limit: float = 8.0
@export var minimum_health_fraction: float = 0.5


func validation_error() -> String:
	if minimum_victim_cargo < 1 or not is_finite(assessment_seconds) or assessment_seconds <= 0 or not is_finite(range_limit) or range_limit <= 0 or not is_finite(minimum_health_fraction) or minimum_health_fraction < 0 or minimum_health_fraction >= 1:
		return "Invalid betrayal tuning."
	return ""
