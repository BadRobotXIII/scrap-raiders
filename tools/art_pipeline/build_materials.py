"""Original shared surface maps; run with Blender --background --factory-startup.

Saves editable images and a procedural node preview in source/materials.
Runtime materials are Godot resources, not opaque Blender node exports.
"""
import argparse
import sys
from pathlib import Path

import bpy
import numpy as np

ROOT = Path(__file__).resolve().parents[2]


def build(rebuild):
    source = ROOT / "assets/environment/source/materials/shared_surfaces.blend"
    if source.exists() and not rebuild:
        raise FileExistsError("Material source exists; explicit --rebuild required")
    size = 1024
    rng = np.random.default_rng(65021)
    y, x = np.mgrid[0:size, 0:size] / size
    # Periodic low-frequency variation plus restrained original surface grain.
    stain = (np.sin(x * 2 * np.pi * 3 + np.sin(y * 2 * np.pi)) *
             np.cos(y * 2 * np.pi * 2 + np.sin(x * 2 * np.pi * 2)))
    grain = rng.normal(0, .012, (size, size))
    streak = np.sin(x * 2 * np.pi * 27) * np.cos(y * 2 * np.pi * 2)
    maps = {"surface_wear": np.clip(.88 + stain * .055 + grain + streak * .012, .68, .99),
            "surface_roughness": np.clip(.91 + stain * .04 + grain, .78, 1)}
    directory = ROOT / "assets/environment/textures"
    for name, values in maps.items():
        rgba = np.ones((size, size, 4), dtype=np.float32)
        rgba[:, :, :3] = values[:, :, None]
        image = bpy.data.images.new(name, width=size, height=size, alpha=False)
        image.pixels.foreach_set(rgba.ravel())
        image.filepath_raw = str(directory / (name + ".png"))
        image.file_format = "PNG"
        image.save()
        image.pack()
    material = bpy.data.materials.new("editable_surface_preview")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = bpy.data.images["surface_wear"]
    material.node_tree.links.new(texture.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
    bpy.context.object.data.materials.clear()
    bpy.context.object.data.materials.append(material)
    source.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    print("ART_MATERIALS two original 1024px periodic shared maps; seed 65021")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--rebuild", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    build(args.rebuild)
