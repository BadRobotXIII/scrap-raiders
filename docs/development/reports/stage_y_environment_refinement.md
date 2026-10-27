# Stage Y refinement: ground, connections and staged loads

Delivered **2026-10-26**; **Checkpoint Y accepted by the director on 2026-10-26** after director approval of the [refinement plan](../plans/phase_7_stage_y_environment_refinement_plan.md), including its three physical footprints and rendering-budget amendment. This extends the [original Y delivery](stage_y_world_population.md); its measurements and the Site 07 follow-up remain historical evidence. Stage Z implementation has not begun. No commit or publication was performed.

The expanded mission now has concrete slab seams, surface wear, paired vehicle tracks, localized staining and flush service channels. Two vertical conduit drops join existing utility banks to their trunks, with two reused junctions. Three pairs of secured pallet loads add density at receiving, shipping and maintenance while preserving open routes.

## Implementation and ownership

| Files | Delivered change |
| --- | --- |
| `resources/presentation/industrial_ground.gdshader`, `.gdshader.uid`, `industrial_ground.tres` | One static world-space material, applied to the large floor and processing floor overlay; no textures, time dependence, displacement, physics or gameplay RNG |
| `scenes/levels/environment/service_perimeter_art.tscn` | Separate ground surface with graybox switching; utility batch extended from 17 to 19 instances; two buried junctions relocated to drop/trunk connections |
| `scenes/levels/environment/processing_facility_art.tscn` | Existing bay floor uses the same ground material/coordinates, preserving the visible transition into processing |
| `scenes/levels/environment/staging_clusters.tscn` | Common eleven-instance pallet batch, three matching static boxes, cheap shadow silhouettes and explicit graybox meshes |
| `scenes/levels/environment/salvage_yard_art.tscn` | Original five pallet instances moved out of the LowCrates body into the common batch, retaining their world positions and original collider/shadow |
| `scenes/levels/expanded_salvage_complex.tscn`, `expanded_salvage_complex_graybox.tscn` | Staging layer under the existing navigation geometry source; graybox displays all three new blockers |
| `tests/world_population_test.gd`, `tests/environment_refinement_test.gd`, `.gd.uid` | Exact approved physical exceptions, explicit per-instance containment, visible/physical extent checks and actual route/contact/shot regressions |

Ground slabs are **8 m** wide. Six authored vehicle routes receive paired wear approximately **1.36 m** apart. Nine service-channel segments use flush plates with **0.5 m** joints. These are visual surface features; their configuration cannot change contact, friction or pathfinding. The original six shared materials, two image maps, sixteen GLBs, Blender sources and import settings remain unchanged.

The only physical additions are:

| Cluster | Ground origin | Collider centre | Size |
| --- | --- | --- | --- |
| Receiving | `(5, 0, -24)` | `(5, 0.6, -24)` | `(2, 1.2, 2)` |
| Shipping | `(30, 0, 15)` | `(30, 0.6, 15)` | `(2, 1.2, 2)` |
| Maintenance | `(-32, 0, 14)` | `(-32, 0.6, 14)` | `(2, 1.2, 2)` |

All **33 original boxes**, their transforms/masks, authored markers and navigation parameters remain exact; there are **36 boxes** in both art and graybox. The navigation bake changes from 258 vertices / 265 polygons to **287 / 294**, as expected for three new obstacles. Active stock, all six alternate stock sites, entries, cover/peek points, patrols, both exits and Recall retain supported navigation. Added solids can legitimately change route and cover choices.

No AI, mission configuration, accounting, persistence, input or spectator implementation changed. Of the **388 pinned pre-refinement paths**, 381 remain byte-identical; the seven changed existing paths are precisely the five scene files, population test and updated test index. The static batch and visibility helpers are reused without edits. Decorative loads never register stock, equipment or interactions.

## Validation and simulation evidence

Godot **4.7.2 Standard**, Forward+, isolated ignored saves. [Archived logs, probes, source hashes and screenshots](../baselines/stage_y_refinement_delivery/README.md) distinguish these checks from director play-testing.

| Check | Result |
| --- | --- |
| Editor parsing/import and final editor check | Passed, no reported warnings/errors |
| Full top-level regression | All **41 suites** passed: forty retained suites plus the new physical refinement suite; every completion marker checked |
| Extended physical refinement checks | Passed after adding visible-envelope/ray comparisons; repeated at native timing with clean shutdown |
| Actual Raider movement | Both directions around each of the three clusters; real FSM movement, navigation, steering, gravity and recovery; no penetration or persistent stall in these fixtures |
| Player and combat contact | Walking/boost blocked by visible loads; usable shoulder camera; nearby grounded jump/landing; blocked and clear physical rifle shots |
| Existing expanded-world coverage | Both ramps, distant collection/extraction, alternate retreat, entries/sites/cover, cooperation/betrayal, banking/forfeiture/restart and post-death following passed |
| Bounded headless startup | Expanded and default scenes launched cleanly; default remains compact Asset Recovery |
| Forward+ art and graybox | Both seeds inspected at fixed cameras; all three graybox loads visible; corrected Site 07 boundary regression retained |
| Graphical mission lifecycle | Actual shots, Raider death, finite recovery, three-material Recall banking, results, restart, player death and follow cycling passed cleanly |
| Seven-discharge / eight-death stress | Eight cosmetic bodies, bounded effects, one settlement, expiry and restart cleanup; conservation passed cleanly |

Before adding the new physical props, the **surface-only** integration exactly matched the pre-refinement 40-second replay for seeds **87017 and 87018**: actor timeline, shots, transfers, metrics/events, navigation, geometry, objectives, equipment and stash. After adding the props, final replay with developer spectating/camera movement exactly matched final replay without it for both seeds.

In the final 40-second observations, 87017 had three arrivals, three collected material units, two Raider extraction events carrying three units in total, and no shots. Seed 87018 had three arrivals, nineteen damaging shots, two machine deaths, eight units collected from stock plus one recovered from a drop, and two Raider extraction events carrying nine units. Both conserved materials/equipment. These bounded observations demonstrate different activity, not guaranteed complete-mission outcomes or proof that stalls can never occur.

**Retained shutdown warning:** 31 accelerated suites reported the existing `AudioStreamWAV` / `AudioStreamPlaybackWAV` retention. Verbose classification found no other leaked object type. Assertions and completion markers passed; this is not a claim of warning-free accelerated teardown. Native population/refinement tests, graphical lifecycle, graybox, performance and stress runs were clean. Audio ownership was not changed in this pass.

## Rendering cost and startup

Matched 30-second five-Raider/two-machine observations, **1600 x 900**, RTX 4060 Laptop / i7-14700HX. The before values below are the immediate pre-refinement proposal control, rather than the earlier original-Y delivery measurement.

| Metric | Before bay / overview | Integrated bay / overview |
| --- | ---: | ---: |
| Maximum draws | 463 / 463 | **480 / 480** |
| Maximum rendered primitives | 174,428 / 174,428 | **182,340 / 182,340** |
| Median frame interval | 4.189 / 4.186 ms | 4.195 / 4.190 ms |
| p95 interval | 5.487 / 5.429 ms | 5.463 / 5.429 ms |
| Worst interval | 22.489 / 21.495 ms | 21.249 / 22.632 ms |
| Maximum texture bytes | 122,766,848 / 122,766,848 | 122,766,848 / 122,766,848 |
| Static-memory sample | 86,432,645 / 86,459,685 B | 86,514,085 / 86,511,849 B |

The integrated cost is **+17 draws / +7,912 primitives**, within the approved **487 / 188,020** limits, with seven draws of headroom. Frame p95 remains within the accepted-X +1 ms guide; texture allocation is unchanged and the static sample increase is below 0.1 MiB, under the 16 MiB review trigger. Local samples are not a general hardware guarantee; cached CPU monitor values are retained in the raw files and are not independent per-frame CPU timings.

The separate transient death fixture reached **557 draws / 274,322 primitives**, p95 **4.589 ms**, worst **5.232 ms**. Its temporary effects/corpses are reported separately from the matched normal-population budget; sixteen bursts / 176 particles / four lights / twenty-two voices remained bounded and expired.

Integrated scene-ready samples were **481.263 / 482.722 ms**, now including the new resources. Initial observed frame intervals were **33.353 / 51.346 ms** in the first run, then **29.547 / 30.354 ms** in the second; later matched gameplay windows peaked at the values above. This checks startup separately and records a visible initial loading hitch. It does not isolate shader compilation from other first-frame setup or prove behavior on an empty driver cache. Startup occurs at the briefing before autonomous deployment begins.

## Views and director review

Compare the [earlier before-images](../baselines/stage_y_refinement_proposal/README.md) with the integrated [ground](../baselines/stage_y_refinement_delivery/screenshots/full_87017_ground.png), [overview](../baselines/stage_y_refinement_delivery/screenshots/full_87017_overview.png), [utility connection](../baselines/stage_y_refinement_delivery/screenshots/full_87017_connections.png), [processing](../baselines/stage_y_refinement_delivery/screenshots/full_87017_processing.png) and [maintenance load](../baselines/stage_y_refinement_delivery/screenshots/full_87017_maintenance_cluster.png). The [matching graybox load](../baselines/stage_y_refinement_delivery/screenshots/gray_87017_maintenance_cluster.png) shows the same physical footprint.

```powershell
godot --path . res://scenes/levels/expanded_salvage_complex.tscn
```

Click **Deploy**. **F1** toggles developer spectating; **F3** toggles diagnostics. **Ctrl+Shift+F5**, then Deploy, advances the expanded seed; **R** repeats it. Compare `res://scenes/levels/expanded_salvage_complex_graybox.tscn` explicitly.

- Walk from Recall through yard, shipping and processing. Judge slab scale, tyre-track repetition, stain strength and visibility of real drops/targets against the new floor.
- Follow the cabinet conduit into its trunk and the flush channels toward equipment. Check the processing overlay transition from normal camera height.
- Pass both sides of all three loads, especially the western maintenance lane. Try boost, jump, shoulder-camera orbit and shots around their ends. Their decorative contents remain nonrecoverable.
- Observe both seeds and intervene in an encounter. Complete recovery/Recall; die, follow a survivor, cycle, return and replay.
- Compare graybox, including the three matching blockers. Judge whether these first clusters add enough density before any further placement is proposed.

The **1.35 m roof-support gap** and simple boundary/roof/ramp forms remain recorded limitations. More physical clutter, roof supports, additional asset production or new gameplay need their own scope and performance review. Subjective density, target visibility and route comfort remain director acceptance items. Stop at **Checkpoint Y**.

## Director acceptance

The director explicitly approved **Stage Y on 2026-10-26**, including the delivered ground, connection and staged-load refinement. Earlier manual-review language and measurements above describe the delivery checkpoint; acceptance adds no further gameplay changes. Documented limitations remain future refinement items. The subsequent [Stage Z audit](stage_z_inventory_architecture_audit.md) and [architecture proposal](../plans/phase_7_stage_z_hybrid_inventory_plan.md) are separate, with implementation pending approval.
