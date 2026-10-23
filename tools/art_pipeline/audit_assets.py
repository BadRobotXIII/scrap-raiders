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
    assert len(assets) == 8
    assert sum(asset["triangles"] for asset in assets) < 25000
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-manifest", action="store_true")
    run(parser.parse_args().write_manifest)
