"""Original editable industrial models. Run in Blender 4.5.10 LTS.

Default refuses existing source files. --rebuild is an explicit destructive
regeneration of that one asset; normal artistic iteration uses export_asset.py.
All positions below are Blender coordinates: X width, Y depth, Z height.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from export_asset import export_asset

DEFINITIONS = {
    "industrial_wall_4m": ("structures", [4, 4, 1], 2400),
    "industrial_wall_2m": ("structures", [2, 4, 1], 1800),
    "steel_column_4m": ("structures", [0.4, 4, 0.4], 1200),
    "steel_edge_beam_4m": ("structures", [4, 0.3, 0.3], 1200),
    "control_cabinet": ("machinery", [0.8, 1.6, 0.4], 3000),
    "sorting_conveyor_base": ("machinery", [4, 1.2, 2], 6000),
    "utility_run_2m": ("props", [2, 0.26, 0.18], 2400),
    "scrap_bin": ("props", [1, 0.8, 0.8], 3000),
}
COLORS = {
    "concrete": ((0.29, 0.30, 0.28), 0, 0.9),
    "painted_steel_bluegray": ((0.13, 0.23, 0.25), 0, 0.64),
    "weathered_steel": ((0.20, 0.18, 0.15), 1, 0.63),
    "galvanized_steel": ((0.42, 0.46, 0.47), 1, 0.48),
    "rubber": ((0.035, 0.04, 0.04), 0, 0.78),
    "safety_yellow": ((0.77, 0.49, 0.06), 0, 0.64),
}
PARTS = []


def box(name, position, size, material, bevel=0.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(bpy.data.materials[material])
    if bevel:
        mod = obj.modifiers.new("edge_highlights", "BEVEL")
        mod.width = min(bevel, min(size) / 4)
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
        weighted = obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
        weighted.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=weighted.name)
    PARTS.append(obj)
    return obj


def cylinder(name, start, end, radius, material, sides=10):
    direction = Vector(end) - Vector(start)
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius,
                                       depth=direction.length, location=(Vector(start) + Vector(end)) / 2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(bpy.data.materials[material])
    PARTS.append(obj)


def wall(width):
    # Full solid envelope, rather than a thin screen over invisible thick collision.
    box("reinforced_plinth", (0, 0, 0.50), (width, 1, 1), "concrete")
    box("solid_backing", (0, 0, 2.50), (width, .96, 3), "concrete")
    for side in [-1, 1]:
        for index in range(int(width)):
            x = -width / 2 + index + .5
            box("painted_panel", (x, side * .49, 2.48), (.982, .02, 2.96), "painted_steel_bluegray", .002)
            for z in [1.1, 3.85]:
                # Small readable fasteners, within the original wall envelope.
                box("panel_fastener", (x + .40, side * .498, z), (.035, .004, .035), "galvanized_steel", .002)
        for x in [-width / 2 + .055, width / 2 - .055]:
            box("edge_post", (x, side * .484, 2.5), (.10, .032, 3), "galvanized_steel", .003)
    # Asymmetric service plate is an enduring front/orientation reference.
    box("front_service_plate", (-width / 2 + .34, .5, 1.45), (.44, .001, .32), "galvanized_steel", 0)


def column():
    box("web", (0, 0, 2), (.12, .35, 4), "weathered_steel")
    for x in [-.17, .17]:
        box("flange", (x, 0, 2), (.06, .4, 4), "weathered_steel")
    for z in [.025, 3.975]:
        box("end_plate", (0, 0, z), (.4, .4, .05), "weathered_steel", .004)


def beam():
    # End pivot; lies along Blender X / Godot X.
    box("web", (2, 0, .15), (4, .04, .26), "weathered_steel", .004)
    for z in [.025, .275]:
        box("flange", (2, 0, z), (4, .3, .05), "weathered_steel", .004)


def cabinet():
    box("cabinet_body", (0, 0, .8), (.8, .38, 1.6), "painted_steel_bluegray", .015)
    box("door", (0, .195, .8), (.75, .01, 1.53), "painted_steel_bluegray", .005)
    box("instrument_panel", (0, .201, 1.14), (.50, .002, .27), "rubber", .001)
    box("service_label", (0, .201, .66), (.22, .002, .13), "safety_yellow", .001)
    for z in [1.05, 1.15, 1.25]:
        box("instrument_slot", (-.09, .202, z), (.22, .001, .015), "safety_yellow", 0)
    box("latch", (.28, .202, .78), (.045, .002, .18), "rubber", .001)
    for z in [.2, 1.4]:
        box("hinge", (-.365, .195, z), (.025, .01, .09), "rubber", .001)


def conveyor():
    # Solid sorting enclosure matches the existing WorkBench collision exactly.
    box("solid_machine_base", (0, 0, .55), (4, 2, 1.1), "painted_steel_bluegray", .012)
    for y in [-.992, .992]:
        for x in [-1.45, -.48, .48, 1.45]:
            box("access_panel", (x, y, .54), (.90, .016, .80), "painted_steel_bluegray", .003)
            box("panel_latch", (x + .34, y, .61), (.04, .016, .16), "weathered_steel", .001)
    box("rubber_conveyor", (0, 0, 1.14), (3.76, 1.60, .08), "rubber", .006)
    for x in [-1.85 + i * .26 for i in range(15)]:
        box("belt_rib", (x, 0, 1.186), (.012, 1.55, .028), "rubber", .001)
    for y in [-.925, .925]:
        box("edge_guard", (0, y, 1.15), (4, .15, .1), "safety_yellow", .004)
    for x in [-1.98, 1.98]:
        box("end_cap", (x, 0, .55), (.04, 2, 1.1), "weathered_steel", .003)


def utility():
    for y, radius in [(-.045, .032), (.045, .022)]:
        cylinder("utility_pipe", (0, y, .15), (2, y, .15), radius, "galvanized_steel")
    for x in [.12, 1, 1.88]:
        box("mount", (x, 0, .025), (.07, .18, .05), "weathered_steel", .003)
        box("support", (x, 0, .10), (.035, .15, .10), "weathered_steel", .002)


def scrap_bin():
    box("bottom", (0, 0, .05), (1, .8, .1), "weathered_steel")
    for x in [-.475, .475]:
        box("side", (x, 0, .44), (.05, .8, .72), "painted_steel_bluegray", .006)
    for y in [-.375, .375]:
        box("end", (0, y, .44), (.9, .05, .72), "painted_steel_bluegray", .006)
    for x in [-.47, .47]:
        box("rim", (x, 0, .77), (.06, .8, .06), "weathered_steel", .003)
    for y in [-.37, .37]:
        box("rim", (0, y, .77), (1, .06, .06), "weathered_steel", .003)
    for i in range(5):
        part = box("salvaged_plate", (-.30 + i * .15, .06 * (-1) ** i, .36 + i * .055),
                   (.12, .45, .08), "weathered_steel", .004)
        part.rotation_euler.z = .12 * (-1) ** i
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def build(name, rebuild=False):
    category, dimensions, limit = DEFINITIONS[name]
    source = ROOT / "assets/environment/source" / category / (name + ".blend")
    output = ROOT / "assets/environment/exports" / category / (name + ".glb")
    if source.exists() and not rebuild:
        raise FileExistsError(f"Source exists: {source}. Export it, or explicitly --rebuild.")
    PARTS.clear()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    collection = bpy.data.collections.new("asset")
    bpy.context.scene.collection.children.link(collection)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1
    for material, (color, metallic, roughness) in COLORS.items():
        mat = bpy.data.materials.new(material)
        mat.use_nodes = True
        mat.diffuse_color = (*color, 1)
        node = mat.node_tree.nodes.get("Principled BSDF")
        node.inputs["Base Color"].default_value = (*color, 1)
        node.inputs["Metallic"].default_value = metallic
        node.inputs["Roughness"].default_value = roughness
        mat.use_backface_culling = True
    if name.startswith("industrial_wall"):
        wall(dimensions[0])
    else:
        {"steel_column_4m": column, "steel_edge_beam_4m": beam,
         "control_cabinet": cabinet, "sorting_conveyor_base": conveyor,
         "utility_run_2m": utility, "scrap_bin": scrap_bin}[name]()
    for obj in PARTS:
        for owner in list(obj.users_collection):
            owner.objects.unlink(obj)
        collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    asset = bpy.context.object
    asset.name = name
    # Bake position into the mesh and use a floor/end origin at the scene origin.
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.cube_project(cube_size=2, correct_aspect=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    asset.data.calc_loop_triangles()
    triangles = len(asset.data.loop_triangles)
    if triangles > limit:
        raise ValueError(f"{name}: {triangles} triangles exceeds review ceiling {limit}")
    asset["asset_id"] = name
    asset["origin"] = "floor_center" if name not in ["steel_edge_beam_4m", "utility_run_2m"] else "start"
    source.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    export_asset(output)
    print("ART_BUILD " + json.dumps({"asset": name, "triangles": triangles,
                                    "dimensions_godot": dimensions}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset", required=True, choices=DEFINITIONS)
    parser.add_argument("--rebuild", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    build(args.asset, args.rebuild)
