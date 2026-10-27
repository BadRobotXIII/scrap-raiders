class_name RaiderThreatMonitor
extends RefCounted
## Observation continuity only. Raider alone accepts states and movement goals.

enum Level { NONE, REPORTED, VISIBLE, DIRECT_ATTACK, CRITICAL }

const SIGHT_LOSS_SECONDS: float = 0.65
const REACQUIRE_SECONDS: float = 0.25

var target_id: int = 0
var unseen_seconds: float = 0.0
var visible_seconds: float = 0.0
var investigation_remaining: float = 0.0
var reported_investigation: bool = false


func reset() -> void:
	target_id = 0
	unseen_seconds = 0
	visible_seconds = 0
	investigation_remaining = 0
	reported_investigation = false


func observe_visibility(visible: bool, delta: float, observed_id: int) -> void:
	if target_id != observed_id:
		target_id = observed_id
		unseen_seconds = 0
		visible_seconds = 0
	if visible:
		visible_seconds += delta
		unseen_seconds = 0
	else:
		unseen_seconds += delta
		visible_seconds = 0


func tick(delta: float) -> void:
	investigation_remaining = maxf(0, investigation_remaining - delta)


func allows_interruption(level: Level, minimum: Level) -> bool:
	return level >= minimum


func retain_engagement() -> bool:
	return unseen_seconds < SIGHT_LOSS_SECONDS


func reacquired() -> bool:
	return visible_seconds >= REACQUIRE_SECONDS
