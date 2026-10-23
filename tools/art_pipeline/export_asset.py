"""Blender: open an editable .blend, then --python this_file -- --output file.glb.

Export does not rebuild geometry or overwrite the editable source.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy


def export_asset(output):
    collection = bpy.data.collections.get("asset")
    if collection is None:
        raise ValueError("Source must contain an 'asset' collection")
    meshes = [obj for obj in collection.all_objects if obj.type == "MESH"]
    if not meshes:
        raise ValueError("No editable asset meshes")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        if any(abs(value - 1.0) > 0.00001 for value in obj.scale):
            raise ValueError(f"Apply scale: {obj.name}")
        if any(abs(value) > 0.00001 for value in obj.rotation_euler):
            raise ValueError(f"Apply rotation: {obj.name}")
        if obj.matrix_world.determinant() <= 0:
            raise ValueError(f"Negative transform: {obj.name}")
        if len(meshes) == 1 and obj.location.length > 0.00001:
            raise ValueError(f"Restore documented asset origin: {obj.name}")
        if not obj.data.uv_layers:
            raise ValueError(f"UV0 missing: {obj.name}")
        if any(slot.material is None for slot in obj.material_slots):
            raise ValueError(f"Missing material: {obj.name}")
        for slot in obj.material_slots:
            if slot.material.use_nodes:
                for node in slot.material.node_tree.nodes:
                    if node.type == "TEX_IMAGE":
                        if node.image is None:
                            raise ValueError(f"Unassigned texture: {obj.name}")
                        image = node.image
                        if not image.packed_file and not Path(bpy.path.abspath(image.filepath)).is_file():
                            raise ValueError(f"Missing source image: {image.filepath}")
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    output = Path(output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False,
        export_cameras=False, export_lights=False, export_texcoords=True,
        export_normals=True, export_materials="EXPORT",
    )
    print("ART_EXPORT " + json.dumps({"source": bpy.data.filepath, "output": str(output),
                                    "meshes": len(meshes), "blender": bpy.app.version_string}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    export_asset(args.output)
