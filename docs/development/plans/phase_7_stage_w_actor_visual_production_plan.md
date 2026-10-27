# Stage W: character and machine visual-production proposal

Prepared **2026-10-22**. **Approved by the director on 2026-10-22; implemented, validated and accepted at Checkpoint W on 2026-10-23 as recorded in the Stage X ledger.** See the [delivery report](../reports/stage_w_actor_visual_production.md) for actual assets, validation, rendering exception and remaining review. Based on the [director's ledger](../ledgers/phase_7_stage_w_character_machine_visuals.md), four attached actor references, subsequent design descriptions and the accepted [Stage V report](../reports/stage_v_environment_art.md). The original approved proposal below is retained as scope history; delivery details and limitations are recorded separately.

## Recommended direction and bounded scope

Produce four original actor identities in **grounded industrial science fiction with restrained stylization**. Reuse V's metre scale, explicit GLB exports, editable Blender sources and external Godot materials. Prioritize recognizable silhouettes, functional joints, legible facing and readable action at the actual shoulder/follow camera distance. The attached references establish design interests, not a request to reproduce their exact characters, branding or mesh details.

| Actor | Direction from the director's references | Initial original design |
| --- | --- | --- |
| Human Raider | Improvised protection, respirator/helmet, patched clothing, salvage pack, recognizable rifle | Human proportions; workwear and layered scavenged plates; three bounded clothing/headgear/pack combinations on one humanoid rig. Keep hands, head, weapon and carried pack readable; avoid the reference's dense spikes, dangling miniature gadgets and copied markings. |
| Player machine | Durable yellow industrial biped, visible joints, compact mechanical torso, readable tools/attachments | Broad utility torso, recessed sensor face, articulated legs and a distinctive right-side housing for the **existing** blaster. Muted ochre paint, dark flexible joints and a few genuine hazard accents. Fit the accepted body/camera rather than adopt the reference's full tall/wide proportions. |
| Ground support | Compact tracked chassis, directional sensors, visible gun mounting | Low twin-track security/maintenance platform, front sensor cluster and a short pulse-emitter housing aligned to the existing shot origin. Use exposed mechanical connections and restrained sensor light. No new turret targeting, projectile or armament capability. |
| Flying scout | Lightweight protected observation drone, visible sensors/propulsion, obvious front | Compact ducted propulsion frame with partial protective hoops, a contrasting front sensor and a visible upper/lower orientation. Borrow the idea of protected rotors, not a dense full wire sphere that obscures facing. No weapon: the existing scout observes and reports. |

Appearance is cosmetic. No shape/color corresponds automatically to Greedy, Cowardly, Aggressive, allied or hostile. Retain accepted cargo/damage/firing cues without turning clothing into hidden-state labels. Existing debug labels remain optional diagnostics.

The complete W scope is one reusable Raider rig with three appearance combinations, one player machine, one ground support model, one scout, the minimal animation sets below, stable attachment conventions, a visual inspection scene and integration into existing actor factories/scenes. No new equipment equipping, mission routing, actor types, corpse system or world expansion.

## Repository findings and protected contracts

Current Git has existing documentation/acceptance edits and untracked architecture/test-index records; preserve these. HEAD is `a431d34` (Initial commit), so the accepted delivery manifests and reports, rather than assumptions about stage-labelled commits, identify the gameplay baseline. No commit or publication is authorized.

| Actor/system | Actual implementation | Contract and consequence |
| --- | --- | --- |
| Player | `scenes/player/robot.tscn`, `scripts/player/robot_controller.gd` | CharacterBody3D owns velocity/jump/boost. Capsule radius **0.55 m**, height **1.8 m**, centre y **0.9**. `Visuals` owns facing; retain this node and physics dimensions. |
| Player camera/weapon | `robot_camera.gd`, `hitscan_weapon.gd`, `shot_executor.gd` | CameraRig y **1.8**, shoulder offset **1 m**, arm **5 m**, FOV **70°**. Fixed `Visuals/Muzzle` at **(0.6, 1.15, −0.7)** supplies the shot origin. Model around these anchors, not vice versa. |
| Raider | `scenes/raiders/raider.tscn`, `scripts/ai/raider.gd` | CharacterBody3D, capsule radius **0.35**, height **1.8**, centre y **0.9**; NavigationAgent radius **0.4**. Existing head top is about **1.82 m**. Preserve FSM, aim points, path settings and collision. |
| Raider visuals/combat | `raider.gd`, `raider_combat.gd`, `raider_feedback.gd` | Code writes `Visuals/Body.material_override`, shows `Visuals/Rifle`, uses `Visuals/RifleMuzzle` at **(0.35, 1.15, −0.7)**, and changes `Visuals/Backpack.material_override` for cargo. A blind mesh swap would break these paths or override all new materials. |
| Ground/scout | `scripts/gameplay/machine_ecosystem.gd`, `scripts/ai/support_machine.gd` | No authored machine scene: `SupportMachine.new()` builds collision, mesh, health, navigation and optional weapon inside `_ready()`. Both use capsule radius **0.4**, height **1.2**, centre y **0.6**. Existing ground visual is **0.8 × 0.8 × 1 m**; scout **1.2 × 0.35 × 0.8 m**, centred y **0.6**, flying at authored route height. |
| Machine aim/fire | `support_machine.gd` | Aim point is root + y **0.6**. Ground muzzle is **(0, 0.7, −0.65)** under rotating `visuals`. Scout has **no weapon**. Preserve roots, routes, aim positions and fire cadence. |
| Death presentation | `scripts/components/death_tumble.gd` | Builds a separate cosmetic RigidBody3D, layer **0**, mask **1**, four-second lifetime; copies visible MeshInstance3D meshes/transforms only. It does **not** copy skeleton/skin deformation or animation. Existing actor cleanup cannot wait for a clip. |
| Hit/shot effects | `hit_reaction.gd`, `player_damage_feedback.gd`, `raider_feedback.gd`, `support_fire_feedback.gd`, `combat_feedback.gd` | Existing health-driven flash/squash and fired-event feedback should remain. Avoid a second damage/shot authority or stacking multiple large hit motions. Player damage view hides the live visuals on death. |
| Equipment/loot | `equipment_drop.gd`, `material_drop.gd`, the two ledgers | Drops remain independent ledger-backed world objects. A carried pack/rifle is cosmetic, never another equipment allocation. No loose-drop redesign is needed to replace actor visuals. |
| Spectators | `developer_spectator.gd`, `post_death_spectator.gd`, `spectator_camera.gd` | Follow actor roots + y **1.3**, not a model bone. Retain eligibility, current-camera ownership and permissions during death/extraction. |

Body silhouette targets are approximately the existing 1.8 m player/Raider and current machine extents. Weapons/hands/packs already protrude beyond simple capsules; document the existing extent and constrain additional cosmetic protrusion rather than falsely claim all geometry fits a capsule. No broad armor, cage or track extension may imply substantial new bullet-blocking geometry. Review visual-versus-hit-volume correspondence from front, side, aim and death poses.

## Visual architecture

Keep authoritative scene roots and existing `Visuals` transforms. Add a reusable visual-only child and one small adapter per actor family where necessary; common attachment/clip helpers may be shared if actual duplication justifies them. Do not introduce another actor controller or recreate the gameplay FSM in an AnimationTree.

```text
Existing CharacterBody3D                  gameplay authority, unchanged
├─ Collision / Health / NavigationAgent   unchanged
├─ Visuals                               existing controller-owned facing transform
│  ├─ Muzzle or RifleMuzzle               existing authoritative shot marker
│  └─ ActorVisual                         new visual wrapper + presentation adapter
│     ├─ imported GLB rig/hierarchy
│     ├─ cosmetic attachment anchors
│     └─ AnimationPlayer / small blends   no gameplay method tracks or root motion
├─ existing combat/input components      unchanged decisions and shot resolution
└─ DeathTumble                           existing cosmetic lifetime/collision policy
```

The adapter reads planar velocity, enabled/terminal state and accepted health/fire events. It writes only visual descendants, material instances and animation playback. No calls to actor transitions, `move_and_slide()`, damage, collection, ledger transfer, stash settlement or target selection originate in animation code. Simulation stop/briefing freezes locomotion presentation; restart disconnects/free scene-owned subscriptions. On resume/reimport, initialize from current authoritative state rather than assume idle.

For machines, replace only the primitive-visual construction portion of `SupportMachine._ready()` with a preloaded visual wrapper chosen by its existing `flying` flag. Keep machine creation, Health, NavigationAgent, weapon creation, masks, patrol routes and death signals in their current owner. There is no need to turn the whole ecosystem into a new scene/factory framework.

The current `Visuals/Rifle` show/hide path must continue to control the new rifle appearance. Retain it as a compatibility root or replace that one presentation call with an explicit adapter method. Keep legacy primitive presentation available for supported regression fixtures. Route cargo cues through the adapter while preserving `Visuals/Backpack` behavior in the primitive path. Disable the old personality-wide body tint only for the new appearance path; do not change personality data or AI decisions. New per-instance material copies prevent one Raider's cargo/tint from changing all shared instances.

### Weapons, packs and rig attachments

- Preserve existing gameplay muzzle paths, local coordinates and their controller-owned facing. No animation track or BoneAttachment3D drives those authoritative markers.
- Model the visual barrel to meet the existing muzzle at its authored aim pose. Arms/grips attach or pose around that stable weapon housing; recoil moves cosmetic parts behind it. Small visual muzzle effects use the accepted `fired` origin, avoiding a new apparent shot origin.
- Use a small stable vocabulary of visual sockets: `weapon_grip`, `pack_mount`, `head_mount`, and a read-only `visual_muzzle` reference for checking alignment. Raider sockets can use BoneAttachment3D; mechanical sockets can use Node3D. Do not infer sockets from exporter-generated node indices.
- A plain humanoid arm at the existing right-side rifle anchor may require bent elbows/shoulder pose. Prove this in the Raider pilot before producing variants. Prefer a limited aim/recoil upper-body layer over changing the ray origin or adding IK.
- Packs/accessories are reusable cosmetic meshes, present only in their chosen appearance. Read ledger-backed carried state for the existing loaded-pack cue; do not spawn/assign equipment from a clip or change equipment counts.

## Rig and animation plan

Use **one skinned humanoid Raider rig** with a small named deform skeleton: root/pelvis, spine/chest, neck/head, clavicle/upper-arm/forearm/hand and thigh/shin/foot chains. Aim for **roughly 20–28 deform bones**, no face/finger rig or exported control bones, at most four normalized influences per vertex. Humanoid clothing/armor/pack variants share bind/rest transforms and clip names. Original source controls may be richer than the export, but export only required deformation bones.

Use articulated rigid node hierarchies for player/ground/scout initially. A mechanical skeleton is unnecessary unless the player pilot demonstrates a concrete export/playback advantage. Tracks/wheels, leg joints, sensor heads and rotor hubs need named local pivots rather than whole-body scale tricks. Any hover/body lean is a small offset on a visual child, never actor translation.

| Actor | Required initial presentation | Driver and limits |
| --- | --- | --- |
| Raider | `idle`, `walk`, `run`, `aim`, `fire`, `death` | Velocity drives locomotion with short crossfades; combat state/actual aim drives aim pose; accepted shot drives fire. Death is a terminal one-shot. Carrying uses pack attachment/pose, not a separate inventory mechanic. |
| Player | `idle`, `locomotion`, `fire`, `destruction` | Mechanical gait from actual planar motion; cosmetic recoil from shots. Small airborne/boost posture from existing traversal state avoids walking in mid-air without adding new traversal behavior. |
| Ground | idle/movement, `attack`, `destruction` | Track/wheel motion follows actual travelled movement; housing/sensor follows accepted body facing. Attack only after a real shot, not during scanning. |
| Scout | hover/movement, `destruction` | Rotor spin, restrained visual response/hover; front sensor follows accepted travel/facing. No fire clip or new targeting capability. |

Reuse health flash and existing hit feedback first. Do not require four additional authored hit clips when the current effect already communicates damage. Retain the minimal Raider aim pose while stationary; walk/run may blend with an upper-body aim/recoil layer. Use AnimationPlayer and simple blend/one-shot composition; add a small AnimationTree only where the Raider's simultaneous locomotion/aim requires it. Do not map every FSM state to a second state machine or set up motion matching, IK or root-motion extraction.

### Death is a pipeline gate

The current static-mesh copy would show an undeformed/bind-pose skinned Raider. Fix this explicitly during the Raider pilot, not after four models are produced.

Extend the existing tumble component with an optional **visual-only death-instance factory**. Before the actor is hidden/freed, create a clean visual subtree from its visual resource, apply appearance/pose, and play the bounded terminal clip inside the existing cosmetic body. The new subtree contains only meshes, skeleton/animation and presentation data: no actor script, Health, input, navigation, weapon executor, ledger or loot callbacks. It must survive independently of the freed actor. Do not blindly duplicate the entire gameplay node or rely on the live actor lasting until animation completion.

Preserve the one cosmetic body, layer/mask, lifetime, force policy and loot/death event order. Keep the current static-copy fallback for existing primitive targets. Blend the short death pose with accepted tumble motion; if this combination is visually excessive, reduce only the new clip's local motion after review rather than silently change physics tuning. Stop locomotion/fire processing before terminal playback. No bone physics, ragdoll, new corpse persistence or animation-completion-driven gameplay cleanup.

Player hiding and machine/Raider `queue_free()` must not race the copy. Test direct lethal damage, destruction during a fire/locomotion blend, hidden optional accessories, source deletion and restart. The death visual should read an explicit appearance/pose snapshot, not depend on unrelated health-signal connection order or `is_visible_in_tree()` after the parent has been hidden.

## Asset organization and pipeline extension

```text
assets/characters/
  source/.gdignore
  source/{player,raider,ground_machine,flying_scout}/*.blend
  exports/{player,raider,ground_machine,flying_scout}/*.glb[.import]
  textures/                              only if existing shared maps are insufficient
  actor_manifest.json                    dimensions, source/export hashes, rigs, clips, sockets
scenes/characters/visuals/                four reusable wrappers + appearance resources
scenes/characters/actor_inspection.tscn   visual showcase; not a new gameplay mission
resources/characters/materials/          shared fabric/polymer/lens additions and palette
resources/characters/animations/         Godot-authored mechanical clips/blend resources if needed
scripts/presentation/                    visual adapters
tools/art_pipeline/                      extend existing export/import/audit tools
docs/art_pipeline/                       actor-specific conventions and verified workflow
```

Use Blender **4.5.10 LTS**, Godot **4.7.2 Standard / Forward+**. One unit = one metre; Blender +Y front exports to Godot −Z, Godot +Y up. Floor-centre origins for bipeds/ground platform; scout origin stays the existing route-root convention, with its model centre y0.6. Keep gameplay roots unit scale and identity model-root transforms. Apply mesh transforms before binding; never apply transforms to an already animated rig as an automatic fix.

V's exporter currently selects mesh objects only and sets `export_animations=False`; its import tool also disables animation, and its audit requires a static single-mesh asset. Those are **verified limitations**, not an already working rig pipeline. Extend the same tools with an explicit actor mode/manifest schema for armatures, skins, node pivots, named actions/clips and sockets. Keep static V mode/output/import settings unchanged; compare original environment assets after tool changes. Avoid a second unrelated exporter.

For the Raider, export one GLB with the deform skeleton, skinned geometry, sockets and explicitly named actions. Do not depend on arbitrary active-action/NLA state. For mechanical actors, GLB supplies stable named parts/pivots; Godot wrapper resources may own transform animation so artists can reimport geometry without overwriting authored gameplay integration. Document which source owns each clip and prohibit conflicting duplicate tracks. A source edit/export must not rebuild away artist work or reset external material bindings.

Pilot evidence must cover: actual bones/skins and named clips imported, two instances animate independently, body/weapon alignment, source edit/re-export, retained wrapper/material/socket references, and clean import in an isolated ignored project without Blender or the main cache. No “import succeeded” claim based solely on static GLB bounds.

### Materials and deterministic variation

Reuse V's metal/paint/rubber foundations where suitable. Add only shared cloth, protective polymer and opaque sensor-lens response needed for actors. No transparent visor, complex skin shader, unique 4K texture set per Raider or cinematic emissive treatment. Start with shared 1K maps and per-appearance palette choices. Skin/face detail is not required for the masked initial Raider.

Choose one of three authored Raider appearances from a **separate deterministic visual seed derived from mission seed + actor ID + fixed visual salt**. Never consume the gameplay RNG stream or derive appearance from personality/relationships. Reuse resources where possible; copy only genuinely mutable per-instance material state. Appearance choices do not affect actor counts, spawn positions, damage or any ledger allocation. This is a bounded preset choice, not procedural character generation.

## Delivery sequence after approval

1. **Protect V and measure:** snapshot collision, navigation, camera, aim/muzzle, lifecycle and resource allocation contracts; fresh 33-suite regression, original actor screenshots and matched performance windows with isolated saves. Preserve current user work.
2. **Raider pilot:** original base model/rig, minimal clips, stable weapon/pack sockets, external materials and import/reimport. Resolve death-copy compatibility and independent instances before making variants or machines.
3. **Integrate Raider presentation:** map observable state/events, align shots, preserve unsupported/unarmed primitive scenarios through a documented compatibility path, add three bounded appearance choices. Prove decisions/relations/accounting remain independent of appearance.
4. **Mechanical models:** player first at the real shoulder camera, then compact ground support and unarmed scout. Integrate simple gait/track/rotor/sensor transforms and accepted destruction through the same presentation contracts.
5. **Integrated validation:** normal Asset Recovery plus explicit expanded art mission; maximum accepted live population, deaths/cosmetic copies, contacts/cover, ramps, shadows, Recall, post-death follow, extraction and restart. Preserve diagnostic P/Q/R presets and initial single-Raider behavior.
6. **Checkpoint W:** sources/exports/imports, asset/rig/clip/socket inventory, guide, in-game screenshots/clips, regression evidence, before/after metrics, known limitations and director checklist. Stop before Stage X or any Git action.

## Performance expectations and evidence

Use V's measured **5.7 ms local p95** and archived counters as historical context, not a fresh W baseline. Record fresh comparisons at identical seed, actors, camera, 1600×900, Forward+, optional-metrics setting and duration; run sequentially without competing validation. Include normal-schedule observation and an explicit bounded five-Raider/two-support-machine stress fixture plus player. Add a death burst to measure temporary cosmetic rigs/copies and cleanup.

Initial authoring guides: Raider **6–10k triangles**, player **5–9k**, ground **3–6k**, scout **2–4k**; roughly **2–4 shared surfaces per actor**, one main skinned Raider body where practical, and no additional skin rigs per clothing variant. Track accessories and shadows in totals. These are review guides, not evidence that a complex model is necessary. Existing V environment geometry/materials are unchanged by W.

Review triggers: sustained >20% matched p95 increase, repeated >33 ms intervals, roughly >80 additional actor-related draw calls at the configured peak, or >24 MiB incremental imported texture memory. Measure bone/skin counts, animated-instance count, visible/total triangles and surfaces, render-pass draw calls, frame median/p95/max, physics/process monitors, load/reimport time and post-death cleanup. Report unavailable GPU counters explicitly. Check redundant material surfaces, shadow passes, offscreen/terminal evaluation and texture reuse before adding LOD infrastructure. No performance acceptance based on triangle count alone or one empty inspection scene.

## Affected files, risks and regression plan

Expected changes are limited to new actor assets/wrappers/materials/adapters; existing art-tool actor modes; `robot.tscn`/`raider.tscn` presentation composition; the visual-construction block in `support_machine.gd`; `death_tumble.gd`; and the Raider presentation calls in `raider.gd`, `raider_combat.gd`, `raider_feedback.gd` as required by compatibility. New clips must not alter input, AI policies, weapons, collision, target selection, missions, persistence or accounting. Any broader need is a proposal, not implicit scope.

| Concrete risk | Required evidence |
| --- | --- |
| Imported rig moves actor or changes shots | Root transform/velocity, collider, aim point and fixed muzzle snapshots unchanged through every clip; actual blocked/clear shot and ramp/contact movement tests |
| Bind-pose/death failure or duplicate loot | One cosmetic body with valid posed skin/attachments, terminal playback after source removal, no gameplay components; exactly one finite material/equipment release and one settlement |
| Presentation paths fail or old tints override materials | Armed/unarmed actors, loaded/empty packs, per-instance materials and primitive fallback tested with real actor scenes |
| Appearance changes AI outcomes | Stable appearance across repeated seed/ID, separate RNG, unchanged selected profiles/relations/stock; appearance-on/off scripted state/event comparison without requiring natural winners |
| Signals/animation duplicate firing or delay damage | Only accepted `fired` triggers recoil; cooldown/occlusion/damage remain ShotExecutor-owned; no animation gameplay tracks |
| Freeze/restart leaves running visual state or leaks | Briefing/Deploy, world stop, extraction, player death/follow cycling, repeated replay and source cleanup tests; bounded cosmetic lifetime |
| Bigger shapes obscure camera/cover | Shoulder/aim/orbit/follow views, shade, close doors/corners, ramps, occluded targets, weapon silhouette and muzzle convergence |
| Reimport breaks existing assets | Raider edit/reimport and fresh isolated actor import; static V export/import regression and unchanged environment resources |

Preserve all **33** existing suites. Add focused resource/import and actor-presentation integration suites using actual scene movement, shots, damage, death and teardown. Verify clip availability, time advancing, visible pose/transform changes, sockets, skin bounds and independently animated instances; do not assert private animation-graph node layouts.

Two existing assertions need deliberate maintenance rather than silent weakening: `destruction_test.gd` expects exactly three primitive Raider mesh copies, and `awareness_test.gd` accesses the primitive pack material. Retain their primitive-fixture checks, and add equivalent production-model behavior checks rather than simply delete assertions. `asset_pipeline_test.gd` currently requires every protected U gameplay/test file except the level reference to remain byte-identical; W legitimately changes a few presentation-bearing files. Replace that broad historical immutability check with an explicit reviewed W presentation-change allowlist plus preserved gameplay contract checks, while retaining V asset/source integrity. Archive the original manifests unchanged. Do not move any active tests to the unused-test archive.

After implementation: Godot editor parsing/import; all accepted/new suites at ordinary timing; bounded headless deployed simulations; Forward+ startup/active GUI in normal and expanded scenes; physical navigation/combat, observer permissions and clean reimport; matched local performance. Inspect combined logs and warnings as well as exits. Planning inspection is not a fresh test pass; no new runtime validation is claimed in this proposal.

## Director acceptance checks and original approval boundary (satisfied)

Manual review should establish recognizability at ordinary play distance, visible human locomotion and aim, industrial player gait and weapon alignment, grounded track/sensor action, readable unarmed scout propulsion/facing, restrained hit/destruction feedback, appearance variety independent of personality, correct cameras, source-edit/reimport and stable full-population performance. Exact combat outcomes remain autonomous. The first Raider pilot should be visually inspected before expanding geometry/animation complexity across all four models.

Approval requested for **these four original design directions, one shared Raider rig/three bounded appearances, mechanical articulated hierarchies, minimal animation sets, fixed gameplay shot/collision/camera contracts, reuse of V tools and the visual-only death-copy extension**.

The [Stage W ledger](../ledgers/phase_7_stage_w_character_machine_visuals.md), section 21, explicitly requires: **“Stop for director approval before producing actor models.”** The director subsequently approved this proposal and implementation is delivered for Checkpoint W review. The original requirement is preserved as scope history. Stage X, commit and publication remain outside authorization.
