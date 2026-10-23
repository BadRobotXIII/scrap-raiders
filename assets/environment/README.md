# Original environment library

Eight editable Blender models, explicit glTF 2.0 GLBs, six shared Godot PBR materials and two original periodic 1024 px surface maps.

All geometry is original project work created with `tools/art_pipeline/build_asset.py`, saved as editable meshes in `source/` and exported using `export_asset.py`. Shared maps are original procedural work from `build_materials.py`, seed 65021; editable images/preview are retained in `source/materials/shared_surfaces.blend`. No third-party textures, models, logos or imagery are included. Director-supplied reference images informed forms/materials only and are not redistributed here.

The exact inventory, triangle counts, material use, dimensions and file hashes are in [asset_manifest.json](asset_manifest.json). Detailed commands, conventions, reimport instructions and QA are in the [art pipeline guide](../../docs/art_pipeline/README.md).

Source `.blend` and runtime `.glb` files are both intended for Git. `.gdignore` prevents Godot scanning editable source; it does not exclude sources from version control. Blender backups, Python caches, compiled Godot imports and game builds are ignored. No commit has been performed as part of delivery.
