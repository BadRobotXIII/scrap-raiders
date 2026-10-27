class_name FeedbackProfile
extends Resource
## Discharge presentation data. No weapon damage, timing or firing permissions.

@export var color: Color = Color(1, 0.75, 0.25)
@export var sound_stem: String = "player"
@export var volume_db: float = -17
@export var light_energy: float = 1.2
@export var trace_seconds: float = 0.055

# Immutable shared resources load with this script, before deployment.
# Playback never opens a WAV on a firing/damage callback.
const AUDIO: Dictionary = {
	"weapons/player_01": preload("res://assets/audio/weapons/player_01.wav"),
	"weapons/player_02": preload("res://assets/audio/weapons/player_02.wav"),
	"weapons/raider_01": preload("res://assets/audio/weapons/raider_01.wav"),
	"weapons/raider_02": preload("res://assets/audio/weapons/raider_02.wav"),
	"weapons/guard_01": preload("res://assets/audio/weapons/guard_01.wav"),
	"weapons/guard_02": preload("res://assets/audio/weapons/guard_02.wav"),
	"impacts/metal": preload("res://assets/audio/impacts/metal.wav"),
	"impacts/concrete": preload("res://assets/audio/impacts/concrete.wav"),
	"impacts/equipment": preload("res://assets/audio/impacts/equipment.wav"),
	"impacts/machine_armor": preload("res://assets/audio/impacts/machine_armor.wav"),
	"impacts/raider_gear": preload("res://assets/audio/impacts/raider_gear.wav"),
	"impacts/hard_surface": preload("res://assets/audio/impacts/hard_surface.wav"),
	"actors/raider_hurt": preload("res://assets/audio/actors/raider_hurt.wav"),
	"actors/player_hurt": preload("res://assets/audio/actors/player_hurt.wav"),
	"actors/machine_hurt": preload("res://assets/audio/actors/machine_hurt.wav"),
	"actors/machine_destroy": preload("res://assets/audio/actors/machine_destroy.wav"),
	"actors/raider_death": preload("res://assets/audio/actors/raider_death.wav"),
	"machines/player_servo_loop": preload("res://assets/audio/machines/player_servo_loop.wav"),
	"machines/guard_drive_loop": preload("res://assets/audio/machines/guard_drive_loop.wav"),
	"machines/scout_rotor_loop": preload("res://assets/audio/machines/scout_rotor_loop.wav"),
	"environment/yard_wind_loop": preload("res://assets/audio/environment/yard_wind_loop.wav"),
	"environment/vent_loop": preload("res://assets/audio/environment/vent_loop.wav"),
	"environment/machinery_loop": preload("res://assets/audio/environment/machinery_loop.wav"),
	"interface/hit_confirm": preload("res://assets/audio/interface/hit_confirm.wav"),
	"interface/recovered": preload("res://assets/audio/interface/recovered.wav"),
	"interface/objective_complete": preload("res://assets/audio/interface/objective_complete.wav"),
	"interface/recall_complete": preload("res://assets/audio/interface/recall_complete.wav"),
	"interface/deployment_failed": preload("res://assets/audio/interface/deployment_failed.wav"),
	"signals/death_flare": preload("res://assets/audio/signals/death_flare.wav"),
}

static func sound(cue: String) -> AudioStream:
	return AUDIO.get(cue) as AudioStream
