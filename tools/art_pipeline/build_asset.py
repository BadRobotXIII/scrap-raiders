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
    "processor_guard_2m": ("machinery", [2, 1.2, .15], 1200),
    "maintenance_panel_1m": ("machinery", [.8, 1.6, .35], 2000),
    "scrap_bunker_panel_2m": ("props", [2, 3, .2], 1200),
    "scrap_infill_1m": ("props", [1, .15, .8], 1200),
    "pallet_load_1m": ("props", [1, 1.2, 2], 1600),
    "freight_panel_2m": ("structures", [2, 3, .12], 1200),
    "vent_panel_2m": ("machinery", [2, 2, .2], 1000),
    "utility_junction_0p4m": ("props", [.4, .4, .18], 600),
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


def processor_guard():
    box("closed_guard_backing", (0, .0035, .6), (2, .137, 1.2), "rubber", .003)
    for x in [-.95, .95]:
        box("yellow_edge", (x, .068, .6), (.10, .014, 1.18), "safety_yellow", .002)
    for z in [.08, .42, 1.10]:
        box("guard_rail", (0, .068, z), (1.88, .014, .07), "safety_yellow", .002)
    for x in [-.78, -.52, -.26, 0, .26, .52, .78]:
        box("recessed_guard_rib", (x, .066, .76), (.035, .014, .56), "galvanized_steel", .002)
    box("stop_station", (.66, .070, .26), (.22, .01, .22), "safety_yellow", .001)
    cylinder("stop_button", (.66, .071, .26), (.66, .075, .26), .055, "rubber", 12)


def maintenance_panel():
    # Open face, closed recessed back; no outward door or walkable cavity.
    box("recess_back", (0, -.145, .8), (.8, .06, 1.6), "rubber", .003)
    for x in [-.37, .37]:
        box("frame_side", (x, 0, .8), (.06, .35, 1.6), "painted_steel_bluegray", .003)
    for z in [.04, 1.56]:
        box("frame_end", (0, 0, z), (.72, .35, .08), "painted_steel_bluegray", .003)
    for z in [.42, .92, 1.32]:
        box("service_rail", (0, -.06, z), (.60, .05, .045), "galvanized_steel", .003)
    for x in [-.23, -.08, .08]:
        box("remaining_module", (x, -.05, 1.14), (.10, .12, .23), "galvanized_steel", .004)
    for x in [-.21, .18]:
        cylinder("disconnected_conduit", (x, -.035, .15), (x, -.035, .68), .024, "galvanized_steel")
    for x in [-.22, .04, .22]:
        box("empty_tool_silhouette", (x, -.11, .70), (.05, .008, .19), "rubber", .001)


def bunker_panel():
    box("solid_retainer", (0, -.015, 1.5), (2, .17, 3), "painted_steel_bluegray", .005)
    for z in [.12, 1.0, 2.0, 2.88]:
        box("reinforcement", (0, .08, z), (2, .04, .09), "weathered_steel", 0)
    for x in [-.94, .94]:
        box("corner_post", (x, .08, 1.5), (.12, .04, 2.8), "weathered_steel", 0)
    box("stripped_plate_recess", (-.3, .073, 1.7), (.32, .006, .23), "weathered_steel", 0)


def scrap_infill():
    # Pressed bulk surface, not a pile of collectible-looking loose components.
    import random
    local = random.Random(87025)
    box("dense_bulk_backing", (0, 0, .025), (1, .8, .05), "weathered_steel", .002)
    for row in range(4):
        for col in range(5):
            height = local.uniform(.045, .1)
            box("pressed_plate", (-.4 + col * .2, -.3 + row * .2, .05 + height/2),
                (.18, .17, height), "weathered_steel" if (row+col)%3 else "painted_steel_bluegray", 0)


def pallet_load():
    box("sealed_pallet_plinth", (0, 0, .075), (1, 2, .15), "weathered_steel", .004)
    box("secured_industrial_load", (0, 0, .675), (1, 2, 1.05), "painted_steel_bluegray", .008)
    for x in [-.32, .32]:
        box("top_strap", (x, 0, 1.194), (.055, 2, .012), "rubber", .001)
        for y in [-.995, .995]:
            box("end_strap", (x, y, .675), (.055, .01, 1.03), "rubber", .001)
    for y in [-.55, .55]:
        box("top_seam", (0, y, 1.19), (.95, .018, .014), "weathered_steel", .001)


def freight_panel():
    box("closed_freight_skin", (0, -.02, 1.5), (2, .08, 3), "painted_steel_bluegray", .003)
    for x in [-.84 + i*.24 for i in range(8)]:
        box("corrugation", (x, .035, 1.5), (.10, .05, 2.8), "painted_steel_bluegray", 0)
    for x in [-.97, .97]:
        box("freight_edge", (x, .035, 1.5), (.06, .05, 3), "galvanized_steel", 0)
    for z in [.035, 2.965]:
        box("edge_rail", (0, .035, z), (2, .05, .07), "galvanized_steel", 0)


def vent_panel():
    box("opaque_vent_backing", (0, -.025, 1), (2, .15, 2), "painted_steel_bluegray", .004)
    for z in [.25 + i*.21 for i in range(8)]:
        box("closed_back_louver", (0, .07, z), (1.8, .06, .12), "galvanized_steel", 0)


def utility_junction():
    box("junction_case", (0, 0, .2), (.4, .16, .4), "galvanized_steel", .004)
    box("sealed_face", (0, .085, .2), (.33, .01, .33), "weathered_steel", .002)
    for x in [-.13, .13]:
        for z in [.07, .33]:
            cylinder("junction_fastener", (x, .086, z), (x, .09, z), .013, "galvanized_steel", 8)


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
         "utility_run_2m": utility, "scrap_bin": scrap_bin,
         "processor_guard_2m": processor_guard, "maintenance_panel_1m": maintenance_panel,
         "scrap_bunker_panel_2m": bunker_panel, "scrap_infill_1m": scrap_infill,
         "pallet_load_1m": pallet_load, "freight_panel_2m": freight_panel,
         "vent_panel_2m": vent_panel, "utility_junction_0p4m": utility_junction}[name]()
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
