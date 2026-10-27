# Stage Y: world population and environmental storytelling

Delivered **2026-10-25**; **Checkpoint Y, including the subsequent refinement, accepted by the director on 2026-10-26**. The director approved the [base proposal](../plans/phase_7_stage_y_world_population_plan.md) after accepting Stage X. The [supplied ledger](../ledgers/phase_7_stage_y_world_population.md) remains unchanged. The optional roof-support geometry amendment was excluded and has not been implemented. No Stage Z work, commit or publication is included.

## Delivered environment

The existing expanded mission now presents **RIVET RECLAMATION WORKS / SITE 07**: receiving, sorting, shipping and isolated services. Static evidence suggests interrupted maintenance and stripped components; autonomous encounters still determine actual events and outcomes.

| Zone | Composition and story | Preserved physical contract |
| --- | --- | --- |
| YD-01 receiving yard | Reinforced bulk retainers, pressed scrap surfaces, secured pallet loads and receiving identification | Filled equivalents of the existing bays, low crates and north screen; no loose blocking debris |
| PF-02 processing | Guarded sorting equipment, feed/sort/output marking, a recessed stripped maintenance panel, reused wall modules and equipment/site signs | Existing sorting-machine box remains opaque solid cover; maintenance recess changes only the visible surface |
| WH-03 shipping | Closed freight skins, sealed/held shipment identification, loading deck and muted solid ramp barriers | Original containers, both ramps, deck and tall barrier volumes remain intact |
| UT-04 services | Backed cabinet/vent banks, supported utility runs, junctions and isolation notices | All details stay within existing solid screens; no free-standing pipe or new obstruction |

All six alternative salvage sites receive restrained surface staging outlines. These are static context, independent of the selected finite stock. Existing stock rings/labels retain authority and visibility. Decorative scrap and secured loads have no interaction prompts, loot groups, transfers or gameplay scripts. Four floating area labels are hidden in production and restored in the explicit graybox.

The compact default, P/Q/R references, 180-second deployment, initial five-Raider schedule, two machines, two response tickets and fourteen materials are unchanged. The four original geometry modules, all 33 collision boxes, masks, navigation inputs, cover/peek points, entries, exits, patrols and Recall marker retain their accepted identities or exact runtime values. AI, combat, input, spectator permissions, objectives, persistence and both accounting authorities were not modified.

## Original source-backed assets

Eight new editable Blender sources and matching GLBs extend the eight-asset library to **16 exports / 8,140 triangles**. The new exports contribute **2,728 triangles** before instancing. All use the same six material foundations and two original 1024 px maps; no reference image was incorporated into a texture or mesh.

| New asset | Category | Nominal Godot envelope, metres | Triangles |
| --- | --- | --- | ---: |
| `processor_guard_2m` | machinery | 2 × 1.2 × .15 | 660 |
| `maintenance_panel_1m` | machinery | .8 × 1.6 × .35 | 688 |
| `vent_panel_2m` | machinery | 2 × 2 × .2 | 140 |
| `scrap_bunker_panel_2m` | props | 2 × 3 × .2 | 128 |
| `scrap_infill_1m` | props | 1 × .15 × .8 | 284 |
| `pallet_load_1m` | props | 1 × 1.2 × 2 | 440 |
| `utility_junction_0p4m` | props | .4 × .4 × .18 | 200 |
| `freight_panel_2m` | structures | 2 × 3 × .12 | 188 |

Sources live under `assets/environment/source/<category>/`, exports under the matching `exports/` directory, with included import settings and thin `scenes/environment/` wrappers. The [manifest](../../../assets/environment/asset_manifest.json) supplies actual imported bounds, UV/material slots, provenance and source/export hashes. The original eight sources/exports/import settings, shared materials/textures and actor assets remain byte-identical to the pre-Y snapshot.

The existing asset-inspection scene now frames and labels all sixteen models, with service faces toward its orthographic camera. It remains a static visual display.

## Implementation and iteration

Three inherited art wrappers extend the existing processing wrapper; `salvage_complex_dressing.tscn` supplies surface markings. `environment_art_view.gd` continues to own production/graybox selection. Structural bodies and the original shadow silhouettes remain in their accepted volumes. New solid meshes and every authored batch instance pass the existing **12 mm surface-detail tolerance**, including rotated ramp bodies. Floor markings do not add collision.

One small technical addition was necessary beyond the anticipated scene-only placement: **`EnvironmentMeshBatch`**, an independent static presentation adapter. It holds a GLB `PackedScene` and an authored transform array, then constructs a shared `MultiMesh` at readiness or source-change notification. It has no frame loop, input, physics, mission access or RNG. Embedding imported mesh arrays would have duplicated geometry and broken source reimport; importer-generated mesh subresource paths also proved unsuitable as durable external references. The adapter preserves the GLB as mesh authority. Service details share one batch per source asset; no gameplay state is duplicated.

The validated processing pilot preceded the other zones. A protected source edit/export/reimport changed the guard's geometry fingerprint, retained shared material bindings and mesh sharing, and restored its original export bytes. Final targeted tests also exercise idempotent batch rebuilds, GLB mesh identity and source-change notifications. A fresh isolated Godot project imported the runtime art without Blender sources or the main import cache and initialized all 19 model batches cleanly.

The first complete placement exceeded the agreed rendering budget: 493 maximum draws and 237,900 primitives. It was rejected. The retained version reduces facade repetition and bulk detail, groups service instances, and removes subpixel trim bevels from four newly authored Y assets. Accepted V assets were not regenerated. Storage barriers were changed from an overly dominant yellow to muted painted steel. Final review covered each bulk-retainer top with two shared pressed-scrap instances and removed two redundant signs after a repeat run exceeded the draw allowance by one call. The final budget check is enforced by the validation probe. The existing vent ambience emitter moved from `(24, 2, -9)` to `(16, 2, 18.6)`, beside an actual service vent; ambient voice/light counts and all sound behavior remain unchanged.

Eleven baseline files changed relative to the preserved pre-Y snapshot: the asset inventory, asset inspection, processing wrapper, expanded art/graybox scenes, atmosphere placement, two inventory tests, the test index and two authoring/audit tools. New files are the eight source/export/import/wrapper sets, three art wrappers, signs/markings, static batch adapter plus UID, world-population suite plus UID, and development evidence/documentation. The [source comparison](../baselines/stage_y_delivery/source_comparison.json) records **416 of 427 baseline files unchanged, none missing**. This comparison preserves prior uncommitted W/X work; it is not a Git clean-tree claim.

## Validation

Godot **4.7.2 Standard**, Blender **4.5.10 LTS**, Forward+, isolated ignored saves. [Raw evidence and probes](../baselines/stage_y_delivery/README.md) distinguish parsing, assertions, bounded simulation, graphical checks and remaining human review.

| Check | Result |
| --- | --- |
| Editor parsing/import | Clean final import; no errors/warnings |
| Full automated regression | **40/40 suites** completed with zero assertion failures and successful exits; all 39 prior suites retained |
| Static asset audit | 16 exports, 8,140 triangles, six materials, two maps; source/export identities and limits pass |
| Targeted Y physical/source suite | Original eight identities; shared/rebuildable GLB batches; no RNG use; both layout contracts; all-zone instance containment and retainer-top coverage; clear stock sites; graybox restoration; actual blocked/clear rifle shots; accounting and teardown pass |
| Existing movement/combat integration | Expanded physical travel across the service route/ramps, finite collection/extraction, cover/peek firing, player traversal, social conflicts, settlement and spectators remain covered and pass |
| Protected X/Y replay and repeat | Exact match for both seeds across all recorded fields, including baked navigation, targets, trajectories, health/cargo, physical shot endpoints, transfers, objective state and stash state |
| Forward+ mission flow | Expanded briefing, loaded Raider defeated with actual shots, cargo recovery, Recall banking, result, fresh restart, player death, post-death following and target cycling pass |
| Forward+ views/startup | Both layouts/all four zones, sixteen-model inspection and unchanged default startup clean |
| Seven discharges/eight deaths | Expected cosmetic bodies, bounded effects/audio, expiration, conservation and restart pass; no resettlement |
| Clean runtime import | GLBs/materials alone initialize the populated wrappers and all 19 source batches |

The historical actor-import test originally pinned the entire eight-entry environment manifest. Y necessarily extends it. Its correction authenticates the original manifest hash and compares its exact entries/metadata within the extension; every original environment file still receives its original byte check. This is not a relaxed asset-preservation assertion.

The before/after replays each observe **40 seconds at fixed 60 Hz**, with the player parked by the test fixture. Seed **87017 west** exercised scavenging and six recorded post-start transfers, with no shots in this window; seed **87018 east** exercised nineteen actual shots and nine transfers. Both have **258 navigation vertices / 265 polygons**, identical before/after. Repeated Y runs match exactly. This evidence demonstrates non-interference in those windows; it does not mandate winners or prove every possible long deployment outcome.

**Retained warning:** 30 accelerated suites report shutdown-only `AudioStreamWAV` / `AudioStreamPlaybackWAV` retention. Verbose classification found no other leaked object type. The new Y suite passes cleanly at native timing; Forward+ checks are clean. These warnings already occurred before Y and remain unresolved, separate from passing logic assertions.

## Measured rendering cost

Matched 1600 × 900 bay/overview cameras, seed 87018, the same bounded five-Raider/two-machine fixture and 30-second measurement windows. RTX 4060 Laptop / i7-14700HX. These are local observations, not minimum-system guarantees.

| Metric | Accepted X bay / overview | Final Y bay / overview |
| --- | ---: | ---: |
| Median interval | 4.179 / 4.182 ms | 4.183 / 4.187 ms |
| p95 interval | 5.437 / 5.538 ms | 5.493 / 5.497 ms |
| Worst measured interval | 32.612 / 20.016 ms | 20.955 / 21.635 ms |
| Maximum draws | 387 / 387 | 463 / 463 |
| Maximum rendered primitives | 143,020 / 143,020 | 174,428 / 174,428 |
| Maximum reported texture memory | 120,538,624 B | 122,766,848 B |
| Static memory sample | 80,701,739 / 80,723,131 B | 84,906,136 / 84,932,716 B |
| Scene-ready sample | 440.645 / 451.682 ms | 450.861 / 485.407 ms |

The final **+76 draws / +31,408 primitives** meets the unchanged +80/+35,000 limits; p95 remains within +1 ms. The pilot was +15 draws / +.055 ms p95. Full-scene static memory grows about 4.0 MiB, below the 16 MiB review trigger. The earlier full-scene ready samples were 439.681/474.393 ms; no repeated >100 ms increase was observed. Neither final 30-second sample contains a >33 ms frame interval. Cached CPU process/physics monitors still cannot be interpreted as independently measured per-frame CPU timings.

Reported global texture memory increased about **2.125 MiB** despite unchanged environment maps/remaps and no embedded GLB textures. That renderer allocation is not attributed to individual resources by the available script API; do not describe total texture memory as unchanged. No new environment image files were introduced.

The separate simultaneous death fixture peaks at **552 draws / 270,950 primitives**, p95 **4.466 ms**, worst **4.773 ms** during its burst observation. It presents seven shots/eight deaths, then expires all eight cosmetic bodies; remaining voices are the three existing ambient beds. Its transient peak is reported separately from the matched normal-population budget.

Runtime geometry contains 67 visible-flag mesh nodes (including shadow-only proxies), 19 model batches/105 instances, 14 signs and one 27-instance floor-marking batch. Relative to the 41-node baseline, this adds **46 mesh/batch nodes**, below 120; signs plus marking group total 15, below 24. The six material foundations are reused; remaining distinct geometry materials are existing roof/floor/local presentation materials.

## Matched visual comparison

| View, seed 87017 | Accepted X | Delivered Y |
| --- | --- | --- |
| Overview | [Before](../baselines/stage_y_environment_audit/screenshots/87017_overview.png) | [After](../baselines/stage_y_delivery/screenshots/full_87017_overview.png) |
| Processing | [Before](../baselines/stage_y_environment_audit/screenshots/87017_processing.png) | [After](../baselines/stage_y_delivery/screenshots/full_87017_processing.png) |
| Yard | [Before](../baselines/stage_y_environment_audit/screenshots/87017_yard.png) | [After](../baselines/stage_y_delivery/screenshots/full_87017_yard.png) |
| Storage | [Before](../baselines/stage_y_environment_audit/screenshots/87017_storage.png) | [After](../baselines/stage_y_delivery/screenshots/full_87017_storage.png) |
| Services | [Before](../baselines/stage_y_environment_audit/screenshots/87017_service.png) | [After](../baselines/stage_y_delivery/screenshots/full_87017_service.png) |

Additional views: [filled retainer tops](../baselines/stage_y_delivery/screenshots/full_87017_yard_top.png), [sixteen-model inspection](../baselines/stage_y_delivery/screenshots/asset_inspection.png). Both seeds and the expanded mission workflow are archived in the evidence.

## Checkpoint Y director review

Launch the expanded mission explicitly; normal startup still opens compact Asset Recovery:

```powershell
godot --path . res://scenes/levels/expanded_salvage_complex.tscn
```

Click **Deploy**. **F1** toggles developer spectating, **F3** shows diagnostics. **Ctrl+Shift+F5**, then Deploy, advances the expanded seed; **R** replays the current one. In-game F5 selects a reference scenario. Compare `expanded_salvage_complex_graybox.tscn` or inspect `scenes/environment/asset_inspection.tscn` separately.

- Walk both ramps and all four zones; use jump/boost and the shoulder camera near dressed cover. Look for false gaps, clipping, repeated patterns, z-fighting and confusing silhouettes.
- Review processing guards and the stripped maintenance recess, yard retainers/secured loads, shipping faces/barriers and utility banks. Confirm their functions read at normal player distance.
- Distinguish static industrial bulk and empty staging pads from the authoritative stock/drop presentation. Recover a real drop, bank it and replay.
- Observe autonomous Raiders/machines with both seeds; follow a survivor after player death, cycle targets, return and restart. Check targets against daylight/shade and new surface detail.
- Judge material scale, subdued signage, utility sound placement and whether the interrupted-maintenance story reads without diagnostics.

The existing **1.35 m processing roof-support gap** remains visible and documented. The separately proposed colliding support amendment was not approved by base-plan approval. World-boundary walls, floor, roof and some loading geometry retain simple forms; no new map, large crane, operating conveyor, hazard, dynamic prop or extra machine role was added. Visual quality, route comfort and target readability still need director play-testing. Additional population would require a fresh performance review: the draw allowance has only four calls of measured headroom.

Stop at **Checkpoint Y**, awaiting director acceptance before Stage Z. No Git commit or publication was performed.

## Director follow-up: Site 07 visible collision

The director reported that Site 07 blocks movement beyond its visible surface. Inspection confirmed that `ServicePerimeter/RecallScreen` retained its accepted **1 ? 3 ? 6 m** collision box, while the Y dressing incorrectly applied the other service screens' **0.65 m** recessed depth to this wall, whose long axis runs along Z. Its visible footprint was only 1 ? .65 m. Earlier containment checks verified that art stayed inside collision, but did not establish that this wall's visible footprint filled the blocker.

The visible opaque box now matches the unchanged 1 ? 3 ? 6 m collider at the same centre. The sign faces the Recall Dock from the long side. No collision, navigation, actor, input or accounting changes were required; mesh/material/node counts remain unchanged. The archived placement authoring recipe is corrected as well.

A new regression compares actual physics ray hits with the visible box from both ends and multiple side positions. It fails on the original scene and passes after correction. Godot editor parsing, native world-population tests, asset-pipeline tests, expanded physical travel/extraction tests and Forward+ matched views pass. The two accelerated suites retain the previously documented WAV shutdown warnings; native and graphical follow-up runs are clean. These are focused checks after the original forty-suite delivery, not a newly claimed full-suite run. Checkpoint Y remains pending director acceptance.

[Follow-up evidence](../baselines/stage_y_site_07_followup/README.md) contains the failing reproduction, passing checks, corrected source identities and matched [before](../baselines/stage_y_site_07_followup/before_side.png) / [after](../baselines/stage_y_site_07_followup/after_side.png) views. The earlier delivery measurements and snapshots above remain historical evidence of the reviewed Y build.
## Approved ground, connection and density refinement

The director approved the subsequent [refinement plan](../plans/phase_7_stage_y_environment_refinement_plan.md), including exactly three matching prop colliders and the measured budget amendment. Its [delivery report](stage_y_environment_refinement.md) supersedes the current-build measurements and physical-count statements above: the 33 original boxes remain exact, with three new boxes, a shared eleven-instance load batch, connected services and expanded-only procedural ground. All 41 suites pass, with known accelerated WAV warnings reported separately; native and graphical checks are clean. Final matched views measure 480 draws / 182,340 primitives within the approved 487 / 188,020 limits. Original delivery and Site 07 evidence remain unchanged. Checkpoint Y is still pending director manual acceptance.

## Director acceptance

The director explicitly approved **Stage Y on 2026-10-26**, including the delivered ground, connection and staged-load refinement. Earlier manual-review language and measurements above describe the delivery checkpoint; acceptance adds no further gameplay changes. Documented limitations remain future refinement items. The subsequent [Stage Z audit](stage_z_inventory_architecture_audit.md) and [architecture proposal](../plans/phase_7_stage_z_hybrid_inventory_plan.md) are separate, with implementation pending approval.
