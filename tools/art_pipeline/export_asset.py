"""Blender: open an editable .blend, then --python this_file -- --output file.glb.

Export does not rebuild geometry or overwrite the editable source.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy


def export_asset(output, mode="static"):
    if mode == "actor":
        return export_actor(output)
    if mode != "static":
        raise ValueError("Unknown asset mode: " + mode)
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


def export_actor(output):
    """Explicit actor path; the accepted static export path above stays unchanged.

    The artist-authored armature/hierarchy is exported as-is. Never apply or
    rebuild animated transforms here. Blender actions are individually named;
    only armature actions are exported, rather than whichever NLA strip is active.
    """
    collection = bpy.data.collections.get("asset")
    if collection is None:
        raise ValueError("Source must contain an 'asset' collection")
    objects = list(collection.all_objects)
    meshes = [obj for obj in objects if obj.type == "MESH"]
    armatures = [obj for obj in objects if obj.type == "ARMATURE"]
    if not meshes or len(armatures) > 1:
        raise ValueError("Actor requires meshes and at most one shared armature")
    for obj in objects:
        if obj.type not in {"MESH", "ARMATURE", "EMPTY"}:
            raise ValueError("Unsupported actor object: " + obj.name)
        if any(abs(value - 1) > 0.00001 for value in obj.scale):
            raise ValueError("Apply scale before binding, not during export: " + obj.name)
        if obj.matrix_world.determinant() <= 0:
            raise ValueError("Negative actor transform: " + obj.name)
    for obj in meshes:
        if not obj.data.uv_layers or any(slot.material is None for slot in obj.material_slots):
            raise ValueError("Actor requires UV0 and assigned materials: " + obj.name)
        armature_modifiers = [modifier for modifier in obj.modifiers if modifier.type == "ARMATURE"]
        if armature_modifiers:
            if len(armature_modifiers) != 1 or armature_modifiers[0].object not in armatures:
                raise ValueError("Skin must reference the shared armature: " + obj.name)
            for vertex in obj.data.vertices:
                weights = [group.weight for group in vertex.groups if group.weight > 0.000001]
                if not weights or len(weights) > 4 or abs(sum(weights) - 1) > 0.0001:
                    raise ValueError("Skin weights must be normalized, at most four: " + obj.name)
    if armatures:
        bones = armatures[0].data.bones
        if not 20 <= len(bones) <= 28:
            raise ValueError("Raider export requires its reviewed 20-28 bone rig")
        required = {"idle", "walk", "run", "aim", "fire", "death"}
        actual = {action.name for action in bpy.data.actions}
        if actual != required:
            raise ValueError("Export only the six named Raider actions: " + repr(actual))
        if not {"weapon_grip", "pack_mount", "head_mount", "visual_muzzle"}.issubset({o.name for o in objects}):
            raise ValueError("Actor attachment sockets are missing")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = armatures[0] if armatures else meshes[0]
    output = Path(output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_animations=bool(armatures),
        export_animation_mode="ACTIONS",
        export_anim_single_armature=True, export_reset_pose_bones=True,
        export_force_sampling=True, export_frame_range=False,
        export_def_bones=True, export_leaf_bone=False, export_skins=True,
        export_cameras=False, export_lights=False, export_texcoords=True,
        export_normals=True, export_materials="EXPORT", export_extras=True,
    )
    print("ACTOR_EXPORT " + json.dumps({"source": bpy.data.filepath, "output": str(output),
        "meshes": len(meshes), "armatures": len(armatures), "blender": bpy.app.version_string}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--mode", choices=["static", "actor"], default="static")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    export_asset(args.output, args.mode)
