# Actor production and iteration

Stage W extends the [existing environment pipeline](README.md). Use Blender **4.5.10 LTS**, Godot **4.7.2 Standard**, explicit GLB exports and Forward+. Editable models, rig and clips are original project assets; supplied actor images are visual references, not copied textures/models. See the [inventory](../../assets/characters/actor_manifest.json) and [source notes](../../assets/characters/README.md).

## Source and runtime ownership

| Files | Owner and purpose |
| --- | --- |
| `assets/characters/source/<kind>/<kind>.blend` | Editable geometry, UVs, rig/bind data, named parts and Raider actions |
| `assets/characters/exports/<kind>/<kind>.glb` + `.import` | Explicit runtime model and tracked material/animation import settings |
| `resources/characters/materials/` | Four shared actor material resources; other materials/maps reuse Stage V |
| `scenes/characters/visuals/<kind>_visual.tscn` | Stable visual wrapper; gameplay components never go in an imported scene |
| `scripts/presentation/actor_visual.gd` | Read-only state/event adapter; animation selection, mechanical motion and private cosmetic materials |
| `scripts/components/death_tumble.gd` | Existing cosmetic physics/lifetime, now with a visual-only skinned/mechanical factory |

Kinds are `raider`, `player`, `ground_machine`, `flying_scout`. Source `.gdignore` prevents implicit Blender import. Runtime requires only GLBs, material/texture resources and wrappers; Blender is an authoring dependency. Track `.blend`, `.glb`, `.import` and script UIDs. Ignore Blender numeric backups and generated `.godot` outputs.

One Blender unit = one metre. Blender +Y front exports to Godot −Z; Godot +Y is up. Bipeds/ground platform use a floor-centre origin. Scout model geometry centres around y0.6 relative to the existing route root. Gameplay roots, collision, navigation, camera mounts and aim points retain their accepted transforms. Apply scale before skin binding; never repair an animated rig by automatically applying transforms during export.

## Raider rig and appearances

`raider.blend` has one 20-bone humanoid deform rig. The body and bounded optional `Hood`, `ShoulderPad`, `PackRoll` and `cargo_indicator` meshes share that rig. The initial protective clothing/armor uses simple rigid-segment weighting; this is not a facial or detailed cloth-deformation rig. Named sockets are `weapon_grip`, `pack_mount`, `head_mount` and read-only `visual_muzzle`. Godot imports one Skeleton3D plus skinned meshes and six named clips:

| Clip | Playback |
| --- | --- |
| `idle`, `walk`, `run` | Loop; locomotion follows actual planar movement |
| `aim` | Loop; filtered upper-body layer over locomotion |
| `fire` | One-shot visual response to an accepted ShotExecutor event |
| `death` | One-shot on an independent cosmetic death copy |

Loop behavior is set explicitly in Godot import settings; do not assume glTF preserves a Blender loop preference. The adapter uses manual playback for the living base/upper-body players, so stopped actors stop evaluation. It does not reproduce the AI FSM or emit gameplay actions from tracks. Keep clips free of method/event tracks that apply damage, spawn loot or move actor roots.

Three bounded wardrobe/palette combinations derive from a separate integer hash of mission seed, actor identity and a fixed visual salt. They do not consume gameplay RNG or depend on personality, allegiance or health. Mutable cloth/cargo materials are instance-local. The pack indicator reads accepted carried state; it is not another material counter.

## Mechanical parts and motion

Player parts include named `left/right_thigh`, `left/right_shin`, `left/right_foot` and arm pivots. Ground support uses `left_wheel`/`right_wheel`; the scout uses `left_rotor`/`right_rotor`. Sensors and weapon housings remain visibly directional. Mechanical motion lives in the Godot adapter, with simple local transforms, rather than a second conflicting set of Blender clips.

Actual CharacterBody3D movement drives gait/track motion. The existing player airborne/boost states select small leg postures. The unarmed scout uses rotor rotation and a small local hover offset. Accepted firing moves only a cosmetic recoil part. The live model root, gameplay muzzle and CharacterBody3D never receive animation-driven movement.

Keep these gameplay marker coordinates unchanged, relative to the existing controller-facing `Visuals` root:

| Actor | Fixed shot marker |
| --- | --- |
| Player `Visuals/Muzzle` | (0.6, 1.15, −0.7) |
| Raider `Visuals/RifleMuzzle` | (0.35, 1.15, −0.7) |
| Ground support weapon marker | (0, 0.7, −0.65) |
| Scout | No weapon or shot marker |

Align the visible barrel to the read-only model socket and those existing markers. Pose hands/grips around the weapon. Do not solve clipping by moving the actual shot origin or changing a weapon definition. Existing muzzle/tracer/damage feedback remains authoritative.

## Ordinary artist edit/export/reimport

1. Open the existing `.blend`, edit geometry/weights/actions, and save it. Preserve collection `asset`, stable named parts, rig bind transforms and required sockets/clips.
2. Export explicitly; actor mode is required for bones/actions and articulated hierarchies:

```powershell
blender --background assets/characters/source/raider/raider.blend --python tools/art_pipeline/export_asset.py -- --mode actor --output assets/characters/exports/raider/raider.glb
godot --headless --path . --editor --quit
```

3. Inspect two independent instances, animation, materials, sockets and body/weapon alignment. Update inventory only after accepting the source/export pair:

```powershell
python tools/art_pipeline/audit_assets.py --actors --write-manifest
godot --headless --path . --script res://tests/actor_import_test.gd
godot --headless --path . --script res://tests/actor_visual_test.gd
```

On initial import or intentional material/clip-setting changes, perform one editor import first, then:

```powershell
godot --headless --path . --script res://tools/art_pipeline/configure_imports.gd -- --actors
godot --headless --path . --editor --quit
```

This remaps shared external materials, disables suffix-generated physics, and records loop modes. It invalidates only the owned GLBs' generated checksums when necessary; it does not delete the user's cache. Ordinary source reimports retain external material resources and wrapper scripts.

The static exporter/import/audit modes remain available without `--mode actor` / `--actors`. W's pilot verified an accepted V wall re-export remains byte-identical. Actor export refuses negative/unapplied scale, missing UV/materials, invalid skin weights and missing required Raider clips/sockets. It preserves artist-authored animated transforms rather than rebuilding them.

`build_actor.py --actor <kind>` creates an initial original model and refuses an existing source. Its explicit `--rebuild` regenerates that source, discarding artist edits; **do not use it for ordinary editing**. `write_actor_materials.py` resets the initial shared palette and is likewise an explicit authoring operation, not part of reimport.

## Death and supported primitive fixtures

After authoritative death, the existing tumble creates one cosmetic body with the same layer0/mask1, forces and four-second lifetime. If an active ActorVisual is present, it instantiates only the raw model, copies the current pose/appearance with private mutable materials and starts a terminal clip. The copy owns no actor, Health, navigation, input, weapon executor, ledger or loot callbacks. It continues after the source is freed and requires no animation-finished callback for gameplay cleanup.

Legacy primitive targets use the original static-copy fallback. `production_actor_visuals=false` on an arena before it enters the tree enables supported primitive fixtures; default deployments use production visuals. Never delay accounting, target removal or settlement until an animation completes. No ragdoll or new corpse-persistence system is introduced.

## Inspection and review

```powershell
godot --path . res://scenes/characters/actor_inspection.tscn
```

Use **0** for overview, **1–6** for close views, **Left/Right** to rotate the selected preview and **Space** to pause presentation. The scene has a metre grid and no gameplay actors/accounting. It shows three independent Raider appearances plus the player, ground support and scout. It does not replace normal-scene validation.

Review silhouettes/materials from the real shoulder, free and follow cameras; gait while turning/aiming; muzzle convergence and shots blocked by cover; cargo cues; hit/death transitions; machine patrol and rotor/track motion; source edit/reimport; finite loot, extraction and restart. Compare fixed seeded deployments and peak accepted populations, including simultaneous cosmetic death copies. Full character art, face/finger animation, cloth simulation, IK and root motion remain outside this foundation.
