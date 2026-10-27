"""Original Stage W actor authoring. Blender 4.5 LTS, metric, +Y front.

Regeneration is deliberately opt-in. Ordinary artist iteration opens the saved
blend and runs export_asset.py --mode actor, preserving edits and animation.
The mesh is economical authored geometry, not a reconstruction of supplied art.
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

MATERIALS = {
    "cloth_olive": ((.12, .145, .095), 0, .88),
    "protective_polymer": ((.035, .045, .049), 0, .70),
    "salvaged_metal": ((.21, .235, .23), .70, .57),
    "opaque_lens": ((.04, .42, .38), .20, .30),
    "safety_yellow": ((.77, .49, .06), 0, .64),
    "rubber": ((.035, .04, .04), 0, .78),
    "painted_steel_bluegray": ((.13, .23, .25), 0, .64),
    "weathered_steel": ((.20, .18, .15), 1, .63),
}
PARTS = []


def move_asset(obj):
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    bpy.data.collections["asset"].objects.link(obj)
    return obj


def finish(obj, name, material, bone=None, bevel=0):
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(bpy.data.materials[material])
    if bevel:
        modifier = obj.modifiers.new("machined_edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        modifier = obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
        modifier.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    if bone:
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1, "REPLACE")
    move_asset(obj)
    PARTS.append(obj)
    return obj


def box(name, pos, size, mat, bone=None, bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.dimensions = size
    return finish(obj, name, mat, bone, min(bevel, min(size) / 4))


def ellipsoid(name, pos, size, mat, bone=None, sides=12, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=sides, ring_count=rings, radius=1, location=pos)
    obj = bpy.context.object
    obj.scale = size
    obj = finish(obj, name, mat, bone)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def cylinder(name, start, end, radius, mat, bone=None, sides=12):
    delta = Vector(end) - Vector(start)
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=delta.length,
                                      location=(Vector(start) + Vector(end)) * .5)
    obj = bpy.context.object
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    return finish(obj, name, mat, bone)


def empty(name, pos=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.data.collections["asset"].objects.link(obj)
    obj.location = pos
    if parent:
        obj.parent = parent
    return obj


def join(parts, name, parent=None, origin=(0, 0, 0), rig=None):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.context.scene.cursor.location = origin
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.cube_project(cube_size=1)
    bpy.ops.object.mode_set(mode="OBJECT")
    if rig:
        modifier = obj.modifiers.new("shared_skin", "ARMATURE")
        modifier.object = rig
        obj.parent = rig
    elif parent:
        bpy.context.view_layer.update()
        matrix = obj.matrix_world.copy()
        obj.parent = parent
        bpy.context.view_layer.update()
        obj.matrix_world = matrix
    return obj


def current_part(name, start, parent=None, origin=(0, 0, 0), rig=None):
    return join(PARTS[start:], name, parent, origin, rig)


def one_surface(obj, material):
    """Keep small articulated limbs to one pass; geometry supplies joint detail."""
    obj.data.materials.clear()
    obj.data.materials.append(bpy.data.materials[material])
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    return obj


def create_rig():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.object
    rig.name = "RaiderRig"
    move_asset(rig)
    bones = rig.data.edit_bones
    bones.remove(bones[0])
    definitions = [
        ("root", (0, 0, 0), (0, 0, .15), None),
        ("pelvis", (0, 0, .87), (0, 0, 1.02), "root"),
        ("spine", (0, 0, 1.02), (0, 0, 1.25), "pelvis"),
        ("chest", (0, 0, 1.25), (0, 0, 1.47), "spine"),
        ("neck", (0, 0, 1.47), (0, 0, 1.57), "chest"),
        ("head", (0, 0, 1.57), (0, 0, 1.80), "neck"),
    ]
    for side, sign in [("left", -1), ("right", 1)]:
        shoulder = (sign * .205, 0, 1.43)
        elbow = (-.23, .23, 1.22) if sign < 0 else (.32, .16, 1.19)
        wrist = (.22, .47, 1.15) if sign < 0 else (.35, .38, 1.15)
        hand_tip = (.28, .55, 1.15) if sign < 0 else (.35, .46, 1.15)
        definitions += [
            (side + "_clavicle", (sign * .03, 0, 1.43), shoulder, "chest"),
            (side + "_upper_arm", shoulder, elbow, side + "_clavicle"),
            (side + "_forearm", elbow, wrist, side + "_upper_arm"),
            (side + "_hand", wrist, hand_tip, side + "_forearm"),
            (side + "_thigh", (sign * .125, 0, .90), (sign * .135, .01, .49), "pelvis"),
            (side + "_shin", (sign * .135, .01, .49), (sign * .135, 0, .12), side + "_thigh"),
            (side + "_foot", (sign * .135, 0, .12), (sign * .135, .16, .07), side + "_shin"),
        ]
    for name, head, tail, parent in definitions:
        bone = bones.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    for name, pos, bone in [
        ("weapon_grip", (.35, .38, 1.15), "right_hand"),
        ("pack_mount", (0, -.18, 1.32), "chest"),
        ("head_mount", (0, 0, 1.79), "head"),
    ]:
        socket = empty(name, pos)
        bpy.context.view_layer.update()
        matrix = socket.matrix_world.copy()
        socket.parent, socket.parent_type, socket.parent_bone = rig, "BONE", bone
        bpy.context.view_layer.update()
        socket.matrix_world = matrix
    return rig


def create_raider():
    rig = create_rig()
    # Human proportions: cloth joint volumes bridge separate protective plates.
    ellipsoid("jacket", (0, -.015, 1.29), (.235, .15, .255), "cloth_olive", "chest", 16, 10)
    ellipsoid("waist", (0, 0, 1.025), (.195, .125, .13), "cloth_olive", "spine")
    box("chest_plate", (0, .125, 1.325), (.34, .055, .27), "salvaged_metal", "chest", .022)
    box("belt", (0, .003, .99), (.39, .265, .065), "protective_polymer", "pelvis", .014)
    box("belt_buckle", (0, .143, .99), (.065, .015, .05), "salvaged_metal", "pelvis", .003)
    for x in [-.16, .16]:
        box("suspenders", (x, .15, 1.25), (.035, .025, .32), "protective_polymer", "chest", .004)
        box("utility_pouch", (x, .125, 1.055), (.10, .075, .09), "cloth_olive", "spine", .009)
    ellipsoid("pelvis_cloth", (0, 0, .91), (.20, .12, .15), "cloth_olive", "pelvis")
    cylinder("neck_seal", (0, 0, 1.47), (0, 0, 1.58), .082, "protective_polymer", "neck")
    ellipsoid("masked_head", (0, 0, 1.67), (.115, .105, .145), "protective_polymer", "head", 16, 10)
    box("brow_plate", (0, .081, 1.74), (.205, .055, .075), "salvaged_metal", "head", .014)
    for x in [-.052, .052]:
        cylinder("goggle_rim", (x, .075, 1.69), (x, .12, 1.69), .045, "salvaged_metal", "head", 16)
        cylinder("goggle_lens", (x, .119, 1.69), (x, .125, 1.69), .032, "opaque_lens", "head", 16)
    cylinder("respirator", (0, .07, 1.60), (0, .16, 1.60), .061, "protective_polymer", "head", 12)
    for x in [-.047, .047]:
        cylinder("filter", (x, .105, 1.585), (x, .145, 1.585), .029, "salvaged_metal", "head", 10)
    for side, sign in [("left", -1), ("right", 1)]:
        upper, fore, hand = [rig.data.bones[side + suffix] for suffix in ["_upper_arm", "_forearm", "_hand"]]
        cylinder("jacket_sleeve", upper.head_local, upper.tail_local, .084, "cloth_olive", upper.name, 12)
        ellipsoid("shoulder_seal", upper.head_local, (.09, .09, .09), "cloth_olive", upper.name)
        ellipsoid("elbow_seal", fore.head_local, (.073, .073, .073), "protective_polymer", fore.name)
        cylinder("forearm_sleeve", fore.head_local, fore.tail_local, .064, "cloth_olive", fore.name, 12)
        cylinder("work_glove", hand.head_local, hand.tail_local, .054, "protective_polymer", hand.name, 10)
        thigh, shin, foot = [side + suffix for suffix in ["_thigh", "_shin", "_foot"]]
        cylinder("trousers_upper", (sign * .125, 0, .86), (sign * .135, .01, .49), .095, "cloth_olive", thigh, 12)
        ellipsoid("trouser_knee", (sign * .135, .01, .49), (.09, .09, .095), "cloth_olive", shin)
        cylinder("trousers_lower", (sign * .135, .01, .48), (sign * .135, 0, .16), .073, "cloth_olive", shin, 12)
        box("knee_guard", (sign * .135, .08, .49), (.135, .06, .13), "salvaged_metal", shin, .015)
        box("boot_shaft", (sign * .135, 0, .19), (.155, .155, .21), "protective_polymer", shin, .016)
        box("work_boot", (sign * .135, .055, .065), (.17, .29, .13), "protective_polymer", foot, .022)
        box("boot_toe", (sign * .135, .16, .075), (.16, .09, .08), "salvaged_metal", foot, .012)
    # Backpack remains part of the shared deform mesh and never creates loot.
    box("salvage_pack", (0, -.19, 1.275), (.31, .18, .35), "cloth_olive", "chest", .025)
    for x in [-.105, .105]:
        box("pack_strap", (x, -.285, 1.28), (.025, .015, .32), "protective_polymer", "chest", .004)
    body = join(PARTS[:], "RaiderBody", rig=rig)
    body["role"] = "shared_skinned_body"
    start = len(PARTS)
    ellipsoid("padded_hood", (0, -.018, 1.705), (.13, .115, .12), "cloth_olive", "head", 16, 8)
    # Open-faced cap leaves goggles and mask readable from the front.
    box("cap_peak", (0, .11, 1.79), (.22, .12, .025), "cloth_olive", "head", .004)
    current_part("Hood", start, rig=rig)
    start = len(PARTS)
    ellipsoid("asymmetric_plate", (-.235, -.015, 1.435), (.11, .12, .075), "salvaged_metal", "left_upper_arm")
    current_part("ShoulderPad", start, rig=rig)
    start = len(PARTS)
    cylinder("pack_roll", (-.19, -.19, 1.50), (.19, -.19, 1.50), .067, "cloth_olive", "chest", 12)
    for x in [-.12, .12]:
        cylinder("roll_tie", (x - .012, -.19, 1.50), (x + .012, -.19, 1.50), .071, "cloth_olive", "chest", 12)
    current_part("PackRoll", start, rig=rig)
    start = len(PARTS)
    box("cargo_lamp", (0, -.286, 1.31), (.075, .015, .035), "opaque_lens", "chest", .003)
    current_part("cargo_indicator", start, rig=rig)
    # Fixed barrel end is the existing gameplay shot marker; the action only
    # moves the receiver and hands behind it, never this root or visual_muzzle.
    rifle = empty("Rifle")
    start = len(PARTS)
    box("rifle_receiver", (.35, .40, 1.15), (.075, .26, .10), "protective_polymer", bevel=.008)
    cylinder("rifle_barrel", (.35, .50, 1.15), (.35, .70, 1.15), .022, "salvaged_metal", sides=12)
    box("rifle_stock", (.35, .19, 1.15), (.065, .18, .08), "protective_polymer", bevel=.006)
    box("rifle_magazine", (.35, .41, 1.07), (.055, .085, .10), "salvaged_metal", bevel=.005)
    box("rifle_sight", (.35, .43, 1.22), (.028, .10, .032), "salvaged_metal", bevel=.003)
    current_part("RifleMesh", start, parent=rifle)
    empty("visual_muzzle", (.35, .70, 1.15))
    create_actions(rig)


def create_actions(rig):
    rig.animation_data_create()
    fps = 30
    bpy.context.scene.render.fps = fps
    for name, duration in [("idle", 2), ("walk", 1), ("run", .6), ("aim", 1), ("fire", .20), ("death", .7)]:
        action = bpy.data.actions.new(name)
        rig.animation_data.action = action
        action.use_fake_user = True
        frames = max(2, round(duration * fps))
        for frame in range(frames + 1):
            phase = frame / frames
            wave = math.sin(phase * math.tau)
            for bone in rig.pose.bones:
                bone.rotation_mode = "XYZ"
                bone.rotation_euler = (0, 0, 0)
                bone.location = (0, 0, 0)
            if name in {"walk", "run"}:
                stride = .42 if name == "walk" else .65
                for side, sign in [("left", 1), ("right", -1)]:
                    rig.pose.bones[side + "_thigh"].rotation_euler.x = wave * stride * sign
                    rig.pose.bones[side + "_shin"].rotation_euler.x = -max(0, wave * sign) * stride * .7
                    rig.pose.bones[side + "_foot"].rotation_euler.x = -wave * stride * sign * .25
                rig.pose.bones["pelvis"].rotation_euler.y = wave * .04
                rig.pose.bones["spine"].rotation_euler.z = wave * .025
                rig.pose.bones["chest"].rotation_euler.x = -.035 if name == "walk" else -.07
            elif name == "idle":
                rig.pose.bones["chest"].rotation_euler.x = wave * .014
                rig.pose.bones["head"].rotation_euler.z = wave * .018
            elif name == "aim":
                rig.pose.bones["head"].rotation_euler.x = -.055 + wave * .005
                rig.pose.bones["chest"].rotation_euler.x = -.018
            elif name == "fire":
                recoil = math.sin(phase * math.pi) ** 2
                rig.pose.bones["chest"].rotation_euler.x = recoil * .025
                rig.pose.bones["right_forearm"].rotation_euler.x = recoil * .06
                rig.pose.bones["left_forearm"].rotation_euler.x = recoil * .03
            elif name == "death":
                collapse = phase * phase * (3 - 2 * phase)
                rig.pose.bones["spine"].rotation_euler.x = collapse * .22
                rig.pose.bones["head"].rotation_euler.x = collapse * .25
                rig.pose.bones["left_upper_arm"].rotation_euler.z = collapse * .12
                rig.pose.bones["right_upper_arm"].rotation_euler.z = -collapse * .12
                rig.pose.bones["left_thigh"].rotation_euler.x = collapse * .10
            for bone in rig.pose.bones:
                # No root translation, actor movement, method calls or events.
                if bone.name != "root":
                    bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        for slot in action.slots:
            slot.name_display = "RaiderRig"
    rig.animation_data.action = bpy.data.actions["idle"]
    bpy.context.scene.frame_set(0)


def rigid_part(name, parent, build_function, origin=(0, 0, 0)):
    start = len(PARTS)
    build_function()
    return current_part(name, start, parent=parent, origin=origin)


def create_player():
    # Floor-centred industrial biped: shoulder-camera scale is the existing
    # capsule/body, not the taller construction machine in the reference.
    start = len(PARTS)
    box("utility_torso", (0, -.035, 1.24), (.66, .42, .56), "safety_yellow", bevel=.035)
    box("recessed_face", (0, .19, 1.51), (.43, .07, .19), "rubber", bevel=.018)
    box("power_backpack", (0, -.22, 1.34), (.46, .18, .47), "safety_yellow", bevel=.025)
    for x in [-.24, .24]:
        box("service_panel", (x, .192, 1.19), (.13, .016, .24), "safety_yellow", bevel=.005)
        box("lower_hazard", (x, .204, 1.10), (.12, .009, .028), "rubber", bevel=.001)
        cylinder("shoulder_pin", (x * 1.34, 0, 1.41), (x * 1.65, 0, 1.41), .095, "salvaged_metal", sides=12)
    box("waist_flex", (0, 0, .91), (.32, .26, .13), "rubber", bevel=.015)
    box("hip_crossbeam", (0, 0, .82), (.52, .27, .12), "safety_yellow", bevel=.018)
    cylinder("antenna", (-.20, -.15, 1.55), (-.20, -.15, 1.78), .009, "rubber", sides=6)
    # Two readable exhaust fins and restrained visible fasteners.
    for x in [-.15, 0, .15]:
        box("cooling_fin", (x, -.32, 1.35), (.045, .04, .30), "salvaged_metal", bevel=.004)
    current_part("Chassis", start)
    sensor = empty("sensor_head", (0, .20, 1.51))
    start = len(PARTS)
    for x in [-.105, .105]:
        cylinder("sensor_rim", (x, .21, 1.52), (x, .255, 1.52), .052, "salvaged_metal", sides=16)
        cylinder("sensor", (x, .253, 1.52), (x, .26, 1.52), .038, "opaque_lens", sides=16)
    current_part("SensorMesh", start, sensor, (0, .20, 1.51))
    for side, sign in [("left", -1), ("right", 1)]:
        hip = Vector((sign * .22, 0, .83))
        knee = Vector((sign * .23, .025, .44))
        ankle = Vector((sign * .23, 0, .12))
        thigh = empty(side + "_thigh", hip)
        start = len(PARTS)
        cylinder("hip_bearing", hip - Vector((.08, 0, 0)), hip + Vector((.08, 0, 0)), .09, "salvaged_metal")
        cylinder("upper_leg_hydraulic", hip, knee, .055, "rubber")
        box("upper_leg_casing", (sign * .23, -.015, .64), (.19, .20, .30), "safety_yellow", bevel=.02)
        box("upper_leg_plate", (sign * .23, .10, .66), (.16, .025, .21), "safety_yellow", bevel=.005)
        one_surface(current_part(side + "_thigh_mesh", start, thigh, hip), "safety_yellow")
        shin = empty(side + "_shin", knee)
        bpy.context.view_layer.update()
        matrix = shin.matrix_world.copy()
        shin.parent = thigh
        shin.matrix_world = matrix
        start = len(PARTS)
        cylinder("knee_bearing", knee - Vector((.105, 0, 0)), knee + Vector((.105, 0, 0)), .078, "salvaged_metal")
        cylinder("shin_piston", knee, ankle, .045, "salvaged_metal")
        box("shin_guard", (sign * .23, .07, .28), (.16, .10, .26), "safety_yellow", bevel=.015)
        for z in [.20, .28, .36]:
            box("shin_hazard", (sign * .23, .125, z), (.15, .008, .025), "rubber", bevel=.001)
        one_surface(current_part(side + "_shin_mesh", start, shin, knee), "salvaged_metal")
        foot = empty(side + "_foot", ankle)
        bpy.context.view_layer.update()
        matrix = foot.matrix_world.copy()
        foot.parent = shin
        foot.matrix_world = matrix
        start = len(PARTS)
        box("foot_base", (sign * .23, .05, .055), (.24, .37, .11), "rubber", bevel=.012)
        box("foot_steel_toe", (sign * .23, .16, .095), (.235, .12, .06), "salvaged_metal", bevel=.008)
        one_surface(current_part(side + "_foot_mesh", start, foot, ankle), "rubber")
    start = len(PARTS)
    cylinder("left_upper_arm", (-.37, 0, 1.4), (-.43, .08, 1.12), .065, "rubber")
    cylinder("left_forearm", (-.43, .08, 1.12), (-.43, .24, 1.01), .055, "salvaged_metal")
    box("left_arm_guard", (-.43, .04, 1.25), (.15, .16, .24), "safety_yellow", bevel=.02)
    for x in [-.49, -.37]:
        box("work_claw", (x, .285, 1.00), (.04, .14, .07), "salvaged_metal", bevel=.005)
    cylinder("right_upper_arm", (.37, 0, 1.41), (.46, .10, 1.11), .065, "rubber")
    cylinder("right_forearm", (.46, .10, 1.11), (.60, .34, 1.15), .055, "salvaged_metal")
    box("right_arm_guard", (.44, .065, 1.25), (.14, .16, .25), "safety_yellow", bevel=.018)
    current_part("ToolArms", start)
    recoil = empty("recoil")
    start = len(PARTS)
    box("blaster_receiver", (.60, .34, 1.15), (.21, .35, .18), "safety_yellow", bevel=.025)
    box("blaster_cooling", (.60, .44, 1.255), (.13, .17, .025), "rubber", bevel=.004)
    current_part("BlasterReceiver", start, recoil)
    start = len(PARTS)
    cylinder("blaster_barrel", (.60, .50, 1.15), (.60, .70, 1.15), .048, "salvaged_metal", sides=16)
    current_part("FixedBarrel", start)
    empty("visual_muzzle", (.60, .70, 1.15))
    empty("weapon_grip", (.60, .34, 1.15))
    empty("pack_mount", (0, -.31, 1.35))
    empty("head_mount", (0, 0, 1.62))


def create_ground():
    # Existing 0.8 x 1 m body envelope, with only the accepted muzzle extending.
    start = len(PARTS)
    box("hull", (0, 0, .41), (.59, .78, .30), "painted_steel_bluegray", bevel=.035)
    box("bumper", (0, .43, .28), (.64, .08, .10), "rubber", bevel=.014)
    for x in [-.32, .32]:
        box("track_body", (x, 0, .235), (.18, .86, .38), "rubber", bevel=.04)
        for y in [-.34, -.20, -.06, .08, .22, .36]:
            box("track_cleat", (x, y, .048), (.18, .055, .025), "rubber", bevel=.003)
            box("track_cleat", (x, y, .422), (.18, .055, .025), "rubber", bevel=.003)
        box("fender", (x, 0, .475), (.20, .88, .07), "painted_steel_bluegray", bevel=.012)
    cylinder("mast", (0, -.06, .5), (0, -.06, .87), .115, "painted_steel_bluegray", sides=12)
    box("mast_armour", (0, .025, .69), (.28, .14, .30), "painted_steel_bluegray", bevel=.025)
    current_part("Chassis", start)
    for side, sign in [("left", -1), ("right", 1)]:
        pivot = empty(side + "_wheel", (sign * .415, 0, .235))
        start = len(PARTS)
        cylinder("drive_hub", (sign * .395, 0, .235), (sign * .425, 0, .235), .145, "painted_steel_bluegray", sides=16)
        for z in [.155, .315]:
            box("hub_marker", (sign * .428, 0, z), (.005, .035, .04), "opaque_lens", bevel=.001)
        one_surface(current_part(side + "_wheel_mesh", start, pivot, (sign * .415, 0, .235)), "painted_steel_bluegray")
    sensor = empty("sensor_head", (0, -.06, .89))
    start = len(PARTS)
    box("sensor_tower", (0, -.06, .91), (.31, .26, .38), "painted_steel_bluegray", bevel=.028)
    box("front_sensor_frame", (0, .075, .93), (.24, .025, .25), "rubber", bevel=.008)
    for z, radius in [(.87, .035), (1.00, .048)]:
        cylinder("sensor_optic", (0, .09, z), (0, .11, z), radius, "opaque_lens", sides=16)
    current_part("SensorMesh", start, sensor, (0, -.06, .89))
    recoil = empty("recoil")
    start = len(PARTS)
    box("pulse_receiver", (0, .25, .70), (.19, .30, .14), "painted_steel_bluegray", bevel=.016)
    current_part("PulseReceiver", start, recoil)
    start = len(PARTS)
    cylinder("pulse_barrel", (0, .39, .70), (0, .65, .70), .029, "rubber", sides=12)
    current_part("FixedBarrel", start)
    empty("visual_muzzle", (0, .65, .70))
    empty("weapon_grip", (0, .25, .70))
    empty("head_mount", (0, -.06, 1.10))


def create_scout():
    # Unarmed; route-root convention unchanged, visual centre at height 0.6.
    start = len(PARTS)
    box("sensor_bus", (0, 0, .60), (.32, .42, .18), "rubber", bevel=.028)
    box("upper_power_pack", (0, -.02, .72), (.20, .25, .10), "salvaged_metal", bevel=.016)
    for x in [-.36, .36]:
        cylinder("rotor_spar", (0, 0, .60), (x, 0, .60), .028, "salvaged_metal", sides=8)
        # Open duct rings rather than a dense cage that hides facing.
        bpy.ops.mesh.primitive_torus_add(major_radius=.20, minor_radius=.018,
            major_segments=20, minor_segments=6, location=(x, 0, .60))
        finish(bpy.context.object, "protective_duct", "salvaged_metal")
        for y in [-.18, .18]:
            cylinder("duct_standoff", (x, y, .59), (x, y, .70), .008, "rubber", sides=6)
        box("landing_tip", (x, -.12, .45), (.04, .10, .04), "rubber", bevel=.006)
    current_part("Chassis", start)
    for side, sign in [("left", -1), ("right", 1)]:
        pivot = empty(side + "_rotor", (sign * .36, 0, .60))
        start = len(PARTS)
        cylinder("rotor_hub", (sign * .36, 0, .58), (sign * .36, 0, .64), .035, "rubber", sides=12)
        for angle in [0, math.pi / 2]:
            obj = box("propeller", (sign * .36, 0, .61), (.33, .035, .012), "rubber", bevel=.002)
            obj.rotation_euler.z = angle
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        current_part(side + "_rotor_mesh", start, pivot, (sign * .36, 0, .60))
    sensor = empty("sensor_head", (0, .235, .60))
    start = len(PARTS)
    box("directional_sensor", (0, .235, .60), (.20, .10, .15), "salvaged_metal", bevel=.014)
    cylinder("large_front_optic", (0, .28, .60), (0, .30, .60), .058, "opaque_lens", sides=16)
    box("orientation_mark", (0, .285, .68), (.07, .012, .018), "opaque_lens", bevel=.002)
    current_part("SensorMesh", start, sensor, (0, .235, .60))
    empty("head_mount", (0, 0, .77))


def make_materials():
    for name, (color, metallic, roughness) in MATERIALS.items():
        material = bpy.data.materials.new(name)
        material.diffuse_color = (*color, 1)
        material.use_nodes = True
        shader = material.node_tree.nodes.get("Principled BSDF")
        shader.inputs["Base Color"].default_value = (*color, 1)
        shader.inputs["Metallic"].default_value = metallic
        shader.inputs["Roughness"].default_value = roughness


def build(name, rebuild):
    source = ROOT / "assets/characters/source" / name / (name + ".blend")
    output = ROOT / "assets/characters/exports" / name / (name + ".glb")
    if source.exists() and not rebuild:
        raise FileExistsError("Artist source exists. Open/export it, or explicitly --rebuild: " + str(source))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name == "asset":
            bpy.data.collections.remove(collection)
    collection = bpy.data.collections.new("asset")
    bpy.context.scene.collection.children.link(collection)
    PARTS.clear()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1
    make_materials()
    {"raider": create_raider, "player": create_player,
     "ground_machine": create_ground, "flying_scout": create_scout}[name]()
    source.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    export_asset(output, "actor")
    print("ACTOR_BUILD " + json.dumps({"actor": name, "source": str(source), "export": str(output)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--actor", required=True, choices=["raider", "player", "ground_machine", "flying_scout"])
    parser.add_argument("--rebuild", action="store_true")
    options = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    build(options.actor, options.rebuild)
