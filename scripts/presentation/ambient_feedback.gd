extends Node3D
## Authored local ambience, independent of AI hearing and mission scheduling.

@export var cue: String = "environment/vent_loop"
@export var volume_db: float = -32
var player: AudioStreamPlayer3D
var world: MissionPresentation

func _ready() -> void:
	call_deferred("_bind_world")

func _bind_world() -> void:
	world = MissionPresentation.find_world(self)
	if world == null: return
	player = AudioStreamPlayer3D.new()
	player.bus = &"Environment"
	player.max_distance = 22
	player.unit_size = 4
	player.volume_db = volume_db
	add_child(player)
	if world.add_loop(player): player.stream = FeedbackProfile.sound(cue)

func _process(_delta: float) -> void:
	if player == null or world == null: return
	var active: bool = world.enabled and world.accepting and (world.arena == null or world.arena.deployment_started)
	for child in get_children():
		if child is CPUParticles3D: child.emitting = active
	if active and player.stream != null and not player.playing: player.play()
	elif not active and player.playing: player.stop()

func _exit_tree() -> void:
	if player != null:
		player.stop()
		player.stream = null
