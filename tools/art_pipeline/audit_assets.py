"""Validate exported glTF data without Blender/Godot or third-party packages.

--write-manifest refreshes the tracked inventory after intentional source/export
edits. Without it, verifies the current inventory hashes (does not mutate assets).
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MATERIALS = {"concrete", "painted_steel_bluegray", "weathered_steel", "galvanized_steel", "rubber", "safety_yellow"}
BASE_ASSETS = {"industrial_wall_4m", "industrial_wall_2m", "steel_column_4m", "steel_edge_beam_4m",
               "control_cabinet", "sorting_conveyor_base", "utility_run_2m", "scrap_bin"}
PILOT_ASSETS = {"processor_guard_2m", "maintenance_panel_1m"}
Y_LIMITS = {"processor_guard_2m": 1200, "maintenance_panel_1m": 2000, "scrap_bunker_panel_2m": 1200,
            "scrap_infill_1m": 1200, "pallet_load_1m": 1600, "freight_panel_2m": 1200,
            "vent_panel_2m": 1000, "utility_junction_0p4m": 600}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inspect(path):
    binary = path.read_bytes()
    magic, version, size = struct.unpack_from("<III", binary)
    assert magic == 0x46546C67 and version == 2 and size == len(binary), path
    length, chunk_type = struct.unpack_from("<II", binary, 12)
    assert chunk_type == 0x4E4F534A
    gltf = json.loads(binary[20:20 + length])
    assert not gltf.get("animations") and not gltf.get("cameras") and not gltf.get("skins")
    assert len(gltf["meshes"]) == 1 and len(gltf["nodes"]) == 1
    node = gltf["nodes"][0]
    assert node.get("scale", [1, 1, 1]) == [1, 1, 1]
    assert node.get("rotation", [0, 0, 0, 1]) == [0, 0, 0, 1]
    assert node.get("translation", [0, 0, 0]) == [0, 0, 0]
    assert not any(suffix in node["name"] for suffix in ["-col", "-navmesh", "-rigid"])
    triangles = 0
    minimum = [float("inf")] * 3
    maximum = [float("-inf")] * 3
    for primitive in gltf["meshes"][0]["primitives"]:
        assert primitive.get("mode", 4) == 4
        attributes = primitive["attributes"]
        assert all(key in attributes for key in ["POSITION", "NORMAL", "TEXCOORD_0"])
        accessor = gltf["accessors"][attributes["POSITION"]]
        minimum = [min(a, b) for a, b in zip(minimum, accessor["min"])]
        maximum = [max(a, b) for a, b in zip(maximum, accessor["max"])]
        count = gltf["accessors"][primitive["indices"]]["count"]
        assert count % 3 == 0
        triangles += count // 3
    materials = [material["name"] for material in gltf["materials"]]
    assert set(materials) <= MATERIALS
    assert all((ROOT / "resources/materials/environment" / (name + ".tres")).is_file() for name in materials)
    source = ROOT / "assets/environment/source" / path.parent.name / (path.stem + ".blend")
    assert source.is_file(), source
    return {"id": path.stem, "source": source.relative_to(ROOT).as_posix(),
            "export": path.relative_to(ROOT).as_posix(), "source_sha256": digest(source),
            "export_sha256": digest(path), "triangles": triangles,
            "minimum": minimum, "maximum": maximum,
            "dimensions": [round(b - a, 6) for a, b in zip(minimum, maximum)],
            "materials": materials, "surfaces": len(gltf["meshes"][0]["primitives"]),
            "origin": "start" if path.stem in ["steel_edge_beam_4m", "utility_run_2m"] else "floor_center",
            "provenance": "Original project geometry; tools/art_pipeline/build_asset.py; editable Blender source"}


def run(write):
    assets = [inspect(path) for path in sorted((ROOT / "assets/environment/exports").rglob("*.glb"))]
    ids = {asset["id"] for asset in assets}
    assert ids in [BASE_ASSETS, BASE_ASSETS | PILOT_ASSETS, BASE_ASSETS | set(Y_LIMITS)], "Unreviewed static asset set"
    assert sum(asset["triangles"] for asset in assets) < 20000
    assert sum(asset["triangles"] for asset in assets if asset["id"] in Y_LIMITS) <= 10000
    for asset in assets:
        if asset["id"] in Y_LIMITS:
            assert asset["triangles"] <= Y_LIMITS[asset["id"]] and asset["surfaces"] <= 3, asset["id"]
    manifest = {"schema": 1, "blender": "4.5.10 LTS", "godot": "4.7.2 Standard", "units": "metres",
                "front": "Blender +Y exported to Godot -Z", "assets": assets,
                "materials": sorted(MATERIALS),
                "textures": [{"path": path.relative_to(ROOT).as_posix(), "sha256": digest(path),
                              "size": [1024, 1024], "provenance": "Original periodic procedural map, seed 65021; build_materials.py"}
                             for path in sorted((ROOT / "assets/environment/textures").glob("*.png"))]}
    target = ROOT / "assets/environment/asset_manifest.json"
    if write:
        target.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    else:
        assert json.loads(target.read_text(encoding="utf-8")) == manifest, "Asset/source changed: review and refresh manifest"
    print(json.dumps({"assets": len(assets), "triangles": sum(asset["triangles"] for asset in assets),
                      "materials": len(MATERIALS), "textures": len(manifest["textures"])}, indent=2))


def actor_accessors(gltf, binary, accessor_index):
    accessor = gltf["accessors"][accessor_index]
    view = gltf["bufferViews"][accessor["bufferView"]]
    types = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}
    components = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[accessor["type"]]
    fmt = "<" + types[accessor["componentType"]] * components
    stride = view.get("byteStride", struct.calcsize(fmt))
    offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    return [struct.unpack_from(fmt, binary, offset + row * stride) for row in range(accessor["count"])]


def actor_matrix(node):
    if "matrix" in node:
        return [[node["matrix"][c * 4 + r] for c in range(4)] for r in range(4)]
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    scale = node.get("scale", [1, 1, 1])
    rotation = [[1 - 2 * (y*y + z*z), 2 * (x*y-z*w), 2 * (x*z+y*w)],
                [2 * (x*y+z*w), 1 - 2 * (x*x+z*z), 2 * (y*z-x*w)],
                [2 * (x*z-y*w), 2 * (y*z+x*w), 1 - 2 * (x*x+y*y)]]
    position = node.get("translation", [0, 0, 0])
    return [[rotation[r][c] * scale[c] if c < 3 else position[r] for c in range(4)] for r in range(3)] + [[0, 0, 0, 1]]


def matrix_product(a, b):
    return [[sum(a[r][i] * b[i][c] for i in range(4)) for c in range(4)] for r in range(4)]


def inspect_actor(path):
    data = path.read_bytes()
    magic, version, size = struct.unpack_from("<III", data)
    assert magic == 0x46546C67 and version == 2 and size == len(data)
    length, chunk_type = struct.unpack_from("<II", data, 12)
    assert chunk_type == 0x4E4F534A
    gltf = json.loads(data[20:20+length])
    binary_length, binary_type = struct.unpack_from("<II", data, 20+length)
    assert binary_type == 0x004E4942
    binary = data[28+length:28+length+binary_length]
    assert not gltf.get("cameras") and not gltf.get("extensions", {}).get("KHR_lights_punctual")
    nodes = gltf["nodes"]
    parents = {child: parent for parent, node in enumerate(nodes) for child in node.get("children", [])}
    def world(index):
        local = actor_matrix(nodes[index])
        return matrix_product(world(parents[index]), local) if index in parents else local
    minimum = [float("inf")] * 3
    maximum = [float("-inf")] * 3
    meshes = []
    for index, node in enumerate(nodes):
        assert all(abs(v-1) < .00001 for v in node.get("scale", [1, 1, 1])), node["name"]
        assert not any(suffix in node["name"] for suffix in ["-col", "-navmesh", "-rigid"])
        if "mesh" not in node:
            continue
        mesh = gltf["meshes"][node["mesh"]]
        triangle_count = 0
        for primitive in mesh["primitives"]:
            assert primitive.get("mode", 4) == 4
            attributes = primitive["attributes"]
            assert all(key in attributes for key in ["POSITION", "NORMAL", "TEXCOORD_0"])
            triangle_count += gltf["accessors"][primitive["indices"]]["count"] // 3
            # Skinned Blender vertices already use the rest armature frame;
            # mechanical part vertices use their named rigid pivot hierarchy.
            matrix = world(index)
            for position in actor_accessors(gltf, binary, attributes["POSITION"]):
                point = [sum(matrix[r][c] * (*position, 1)[c] for c in range(4)) for r in range(3)]
                minimum = [min(a, b) for a, b in zip(minimum, point)]
                maximum = [max(a, b) for a, b in zip(maximum, point)]
            if "skin" in node:
                assert "JOINTS_0" in attributes and "WEIGHTS_0" in attributes
                bone_count = len(gltf["skins"][node["skin"]]["joints"])
                for joints, weights in zip(actor_accessors(gltf, binary, attributes["JOINTS_0"]), actor_accessors(gltf, binary, attributes["WEIGHTS_0"])):
                    assert abs(sum(weights) - 1) < .0001
                    assert all(joint < bone_count for joint, weight in zip(joints, weights) if weight > 0)
        meshes.append({"name": node["name"], "triangles": triangle_count,
            "surfaces": len(mesh["primitives"]), "skinned": "skin" in node})
    names = {node["name"]: index for index, node in enumerate(nodes)}
    socket_names = [name for name in ["weapon_grip", "pack_mount", "head_mount", "visual_muzzle"] if name in names]
    sockets = {name: [round(world(names[name])[row][3], 6) for row in range(3)] for name in socket_names}
    clips = {}
    for animation in gltf.get("animations", []):
        times = [gltf["accessors"][sampler["input"]]["max"][0] for sampler in animation["samplers"]]
        clips[animation["name"]] = {"seconds": round(max(times), 4), "channels": len(animation["channels"])}
    skins = gltf.get("skins", [])
    bones = [nodes[index]["name"] for index in skins[0]["joints"]] if skins else []
    if path.stem == "raider":
        assert len(skins) == 1 and 20 <= len(bones) <= 28
        assert set(clips) == {"idle", "walk", "run", "aim", "fire", "death"}
        assert socket_names == ["weapon_grip", "pack_mount", "head_mount", "visual_muzzle"]
        assert sockets["visual_muzzle"] == [.35, 1.15, -.7]
    else:
        assert not skins and not clips, "Mechanical motion belongs only to the Godot visual adapter"
    materials = [material["name"] for material in gltf["materials"]]
    actor_materials = {"cloth_olive", "protective_polymer", "salvaged_metal", "opaque_lens"}
    assert set(materials) <= MATERIALS | actor_materials
    source = ROOT / "assets/characters/source" / path.parent.name / (path.stem + ".blend")
    assert source.is_file()
    return {"id": path.stem, "source": source.relative_to(ROOT).as_posix(), "export": path.relative_to(ROOT).as_posix(),
        "source_sha256": digest(source), "export_sha256": digest(path), "triangles": sum(mesh["triangles"] for mesh in meshes),
        "minimum": [round(value, 6) for value in minimum], "maximum": [round(value, 6) for value in maximum],
        "dimensions": [round(b-a, 6) for a, b in zip(minimum, maximum)], "meshes": meshes,
        "materials": materials, "skin_count": len(skins), "bones": bones, "clips": clips, "sockets": sockets,
        "nodes": list(names), "animation_owner": "Blender actions" if skins else "Godot actor visual adapter",
        "origin": "route_root_model_center_y_0.6" if path.stem == "flying_scout" else "floor_center",
        "provenance": "Original project geometry/rig/actions; build_actor.py; editable Blender source"}


def run_actors(write, partial=False):
    assets = [inspect_actor(path) for path in sorted((ROOT / "assets/characters/exports").rglob("*.glb"))]
    assert 1 <= len(assets) <= 4 if partial else len(assets) == 4
    manifest = {"schema": 2, "kind": "actors", "blender": "4.5.10 LTS", "godot": "4.7.2 Standard", "units": "metres",
        "front": "Blender +Y exported to Godot -Z", "assets": assets,
        "new_materials": ["cloth_olive", "opaque_lens", "protective_polymer", "salvaged_metal"],
        "shared_texture_manifest": "assets/environment/asset_manifest.json", "new_textures": []}
    target = ROOT / "assets/characters/actor_manifest.json"
    if write:
        target.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    else:
        assert json.loads(target.read_text(encoding="utf-8")) == manifest, "Actor/source changed: review and refresh manifest"
    print(json.dumps({"actors": len(assets), "triangles": sum(asset["triangles"] for asset in assets),
        "skins": sum(asset["skin_count"] for asset in assets), "new_textures": 0}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-manifest", action="store_true")
    parser.add_argument("--actors", action="store_true")
    parser.add_argument("--allow-partial", action="store_true", help="Pilot authoring only; final delivery requires all four")
    options = parser.parse_args()
    if options.actors:
        run_actors(options.write_manifest, options.allow_partial)
    else:
        run(options.write_manifest)
