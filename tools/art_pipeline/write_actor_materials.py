"""Explicit shared actor material reset. Reuses V's original periodic 1K maps."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PALETTE = {
    "cloth_olive": ((.12, .145, .095), 0, .88),
    "protective_polymer": ((.035, .045, .049), 0, .70),
    "salvaged_metal": ((.21, .235, .23), .70, .57),
    "opaque_lens": ((.04, .42, .38), .20, .30),
}


def srgb(value):
    return 12.92 * value if value <= .0031308 else 1.055 * value ** (1 / 2.4) - .055


for name, (color, metallic, roughness) in PALETTE.items():
    target = ROOT / "resources/characters/materials" / (name + ".tres")
    target.parent.mkdir(parents=True, exist_ok=True)
    albedo = ", ".join(f"{srgb(channel):.8f}" for channel in color)
    lens = name == "opaque_lens"
    content = f'''[gd_resource type="StandardMaterial3D" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/environment/textures/surface_wear.png" id="1"]
[ext_resource type="Texture2D" path="res://assets/environment/textures/surface_roughness.png" id="2"]

[resource]
resource_name = "{name}"
albedo_color = Color({albedo}, 1)
albedo_texture = ExtResource("1")
metallic = {metallic}
roughness = {roughness}
roughness_texture = ExtResource("2")
uv1_scale = Vector3(2, 2, 1)
'''
    if lens:
        content += 'emission_enabled = true\nemission = Color(0.035, 0.23, 0.19, 1)\nemission_energy_multiplier = 0.5\n'
    target.write_text(content, encoding="utf-8")
    print(target.relative_to(ROOT))
