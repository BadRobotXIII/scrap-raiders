# Actor sources and runtime exports

These are original SCRAP Raiders models, rig, and animation actions authored in
Blender 4.5.10 LTS. The director's reference images informed broad industrial
design interests; no reference mesh, texture, branding, or exact character was
copied. No third-party model or texture license is required.

`source/` contains editable `.blend` files and a `.gdignore` so Godot never
launches Blender implicitly. `exports/` contains explicit runtime GLBs and
their material/animation import settings. Runtime does not require Blender.
`actor_manifest.json` records source/export hashes, geometry, rig, clip and
socket inventories. Source backup files are generated artifacts.

One Blender unit is one metre. Blender +Y front exports to Godot -Z; Godot +Y
is up. Bipeds and ground support use floor-centre origins. Scout geometry is
centred at route-root y0.6, preserving the existing flying route convention.
Actor roots retain identity scale and do not receive animation tracks.

The Raider has one 20-bone deform skeleton shared by its body and optional
Hood, ShoulderPad and PackRoll meshes. `cargo_indicator` is a separate skinned
lamp, not an inventory object. `Rifle` holds the cosmetic fixed rifle; the
`visual_muzzle` socket is a read-only alignment reference. The six Blender
actions are `idle`, `walk`, `run`, `aim`, `fire`, and `death`; no root motion,
gameplay events, health, weapons, navigation or loot logic is exported.

Mechanical models use rigid named pivots. Their motion is owned by the Godot
visual adapter rather than conflicting Blender clips. Model reimport must not
change existing gameplay muzzle/collision/camera positions or animation policy.

The four shared actor materials reuse Stage V's original 1K wear and roughness
maps. Additional metal/paint/rubber resources are shared with the environment.
There are no new image textures or transparent lens materials.

For ordinary source editing, save the artist's file and export it explicitly:

```powershell
blender --background assets/characters/source/raider/raider.blend --python tools/art_pipeline/export_asset.py -- --mode actor --output assets/characters/exports/raider/raider.glb
godot --headless --path . --editor --quit
python tools/art_pipeline/audit_assets.py --actors --write-manifest
```

Inspect the export before accepting a new manifest. On first adding an actor,
run the editor import once, then apply external material mappings with
`godot --headless --path . --script tools/art_pipeline/configure_imports.gd -- --actors`
and reimport. Ordinary reimport preserves those mappings.

`build_actor.py --actor <id>` refuses to overwrite an existing editable source.
Its `--rebuild` option deliberately regenerates the one source and discards
artist edits; it is not the normal export workflow. `write_actor_materials.py`
likewise explicitly resets the four shared materials to their initial palette.
