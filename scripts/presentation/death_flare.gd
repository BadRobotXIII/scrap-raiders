extends Node3D
## Cosmetic launch/signal only. Response scheduling belongs to FlareDirector.

var age: float = 0.0
var beacon: MeshInstance3D


func _ready() -> void:
	add_to_group("death_flares")
	beacon = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 0.15, 0.04)
	material.emission_enabled = true
	material.emission = Color(1, 0.12, 0.02)
	mesh.material = material
	beacon.mesh = mesh
	add_child(beacon)
	var label := Label3D.new()
	label.text = "DEATH FLARE"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 36
	label.position.y = 0.6
	beacon.add_child(label)
	var world := MissionPresentation.find_world(self)
	if world != null: world.play_spatial("signals/death_flare", global_position, &"Machines", -20)



func _process(delta: float) -> void:
	age += delta
	beacon.position.y = lerpf(0.3, 8, minf(1, age / 0.8))
	beacon.scale = Vector3.ONE * (1 + 0.15 * sin(age * 5))
	if age >= 20:
		queue_free()
