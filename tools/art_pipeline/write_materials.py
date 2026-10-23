"""Create the six shared Godot PBR resources from linear Blender preview colors.

StandardMaterial3D's source-color property is stored as sRGB values. Keeping
that conversion explicit prevents the same numeric linear color going dark.
This is an explicit material rebuild; ordinary .tres edits survive GLB reimport.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PALETTE = {
    "concrete": ((.29, .30, .28), 0, .94),
    "painted_steel_bluegray": ((.13, .23, .25), 0, .72),
    "weathered_steel": ((.20, .18, .15), 1, .69),
    "galvanized_steel": ((.42, .46, .47), 1, .52),
    "rubber": ((.035, .04, .04), 0, .86),
    "safety_yellow": ((.77, .49, .06), 0, .70),
}


def srgb(value):
    return 12.92 * value if value <= .0031308 else 1.055 * value ** (1 / 2.4) - .055


if __name__ == "__main__":
    for name, (color, metal, roughness) in PALETTE.items():
        text = f'''[gd_resource type="StandardMaterial3D" load_steps=3 format=3]
[ext_resource type="Texture2D" path="res://assets/environment/textures/surface_wear.png" id="1"]
[ext_resource type="Texture2D" path="res://assets/environment/textures/surface_roughness.png" id="2"]
[resource]
resource_name = "{name}"
albedo_color = Color({", ".join(f"{srgb(v):.6f}" for v in color)}, 1)
albedo_texture = ExtResource("1")
metallic = {metal}
roughness = {roughness}
roughness_texture = ExtResource("2")
roughness_texture_channel = 0
'''
        (ROOT / "resources/materials/environment" / (name + ".tres")).write_text(text, encoding="utf-8")
