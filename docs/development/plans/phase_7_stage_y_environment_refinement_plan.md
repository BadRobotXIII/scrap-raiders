# Stage Y refinement: ground, utility connections and clustered dressing

Prepared **2026-10-25** following the director's three visual references and Site 07 review. **Approved, implemented and validated; Stage Y accepted by the director on 2026-10-26.** The approved scope and original proposal evidence below are retained; see the [refinement delivery report](../reports/stage_y_environment_refinement.md) for final changes, validation and acceptance items. This stays within Checkpoint Y, before Stage Z. No commit/publication is authorized.

## Recommended pass

Give the ground the first share of effort. It occupies most of the image at both player and elevated camera heights. Follow with visible service connections and a small number of deliberately grouped loads at the perimeter. Preserve open circulation space, identifiable stock/drop markers and independent encounter outcomes.

The supplied images guide concrete wear, equipment connections and the organization of salvage. They are not copied into textures or meshes. The existing sixteen original exports remain the asset library for this pass.

| Director feedback | Proposed change | Boundaries |
| --- | --- | --- |
| Uniform ground | One static ground shader/material with eight-metre concrete joints, restrained slab variation, granular wear, paired vehicle tracks and localized oil/dirt around equipment | No image maps, vertex displacement, slippery surfaces, dynamic tracks, input or gameplay RNG |
| Disconnected utilities | Two wall-contained vertical conduit drops, reuse of two presently buried junctions, and flush covered service channels joining the service bank, processing cabinet and sorting-machine base | No floating solid pipes, open floor trenches, power-network simulation or new overhead obstructions |
| Sparse elevated view | Three staged-load clusters using six existing pallet-load instances, two per cluster | Three explicitly defined, matching static collision boxes; no loot allocation, interaction or new cover-point registration |

Apply the same ground coordinates to the main floor and the existing processing-bay floor overlay. Updating only the large floor would leave that opaque overlay hiding the interior treatment. Use an expanded-only presentation material; retain the original six shared material resources and two maps unchanged. Daylight, actor feedback, ambience, flares and mission UI remain as delivered.

Static wear should follow plausible circulation and equipment use without painting every possible route. Keep stains subdued enough that dropped cargo, targets and extraction markers remain readable. The covered service channels are surface details; they create no apparent hole or raised cable for actors to cross.

## Explicit physical amendment

The [approved Y base proposal](phase_7_stage_y_world_population_plan.md) states: **"It does not authorize collision/navigation changes."** Freestanding pallets need matching collision and a navigation rebake. This is the reason for requesting a bounded amendment before integration, rather than placing uncollidable solid-looking clutter in the open yard.

These are ground origins in the existing expanded world; positive Z is south. Each group contains two adjacent original `pallet_load_1m` instances with a solid filled envelope. Each collider centre is 0.6 m above its listed origin.

| Group | Ground origin X, Y, Z | Box size X, Y, Z | Purpose |
| --- | --- | --- | --- |
| Receiving staging | `(5, 0, -24)` | `(2, 1.2, 2)` | A secured load beside the northern receiving circulation |
| Shipping staging | `(30, 0, 15)` | `(2, 1.2, 2)` | A dispatched/staged load south of freight storage |
| Maintenance staging | `(-32, 0, 14)` | `(2, 1.2, 2)` | A service load southwest of processing |

Retain the original 33 collider shapes/transforms/masks and all existing markers. Add exactly these three boxes, giving 36 structural boxes. Preserve existing entry/response volumes, all six alternate salvage sites, both ramps, patrol routes, cover/peek points, both exits and Recall access. The western candidate leaves approximately two metres of passage to the boundary's inside face.

New props can legitimately change physical cover and route choices; exact AI trajectories need not match the earlier world after adding them. They cannot alter attitude policy, actor populations, reinforcement tickets, cargo allocation, loot ownership or mission outcome policy. Neither a navigation pass nor matching endpoints proves that actors will never stall; physical play-tests remain necessary.

The existing roof-support amendment remains excluded. Approval covers only the three listed ground footprints, not additional supports, machinery or future clutter placements.

## Reuse, ownership and integration

- Reuse `EnvironmentMeshBatch`, `environment_art_view.gd`, current GLBs/material foundations and static collider navigation. No additional environmental controller or mission framework.
- Move the existing five-instance pallet batch to a common presentation owner and extend it to eleven instances. Each instance must be checked against its own declared original/new collision volume; do not leave a world-spanning batch notionally owned by the LowCrates collider.
- Add the two vertical drops to the existing utility batch. Reuse the two junction instances now hidden inside the corrected Recall wall at the new drop/trunk connections. Library geometry stays unchanged.
- Retain cheap, matching shadow silhouettes for the three new groups. Explore shared shadow batches if useful, preserving actual silhouettes and visibility.
- In graybox mode, hide the proposed presentation and show full grey meshes for all three new blockers. An invisible physical prop in the comparison scene is unacceptable.
- Keep the same scene identity, mission configurations, seeds, ledgers, player/spectator permissions and lifecycle. New cluster geometry belongs under the existing `Geometry` navigation source group.

Expected implementation files are a new `resources/presentation/industrial_ground.gdshader` plus material resource, the existing processing/service art wrappers, a small static staging-cluster scene, the expanded and graybox scene references, targeted environment tests and documentation. The asset manifest, all Blender/GLB exports, original geometry modules, AI, mission configuration, accounting and persistence need no change.

## Reviewable prototype and measured cost

The prototype lives under ignored `.godot/stage_y_refinement/`. It constructs a temporary fixture from the actual mission, applies the proposed material/connections/clusters and rebakes navigation. It does not save those changes into production scenes. [Evidence and runnable probe copies](../baselines/stage_y_refinement_proposal/README.md) are archived separately from accepted/delivered Y snapshots.

| View | Current | Proposed |
| --- | --- | --- |
| Ground, player height | [Before](../baselines/stage_y_refinement_proposal/screenshots/before_ground.png) | [Preview](../baselines/stage_y_refinement_proposal/screenshots/proposed_ground.png) |
| Elevated density | [Before](../baselines/stage_y_refinement_proposal/screenshots/before_overview.png) | [Preview](../baselines/stage_y_refinement_proposal/screenshots/proposed_overview.png) |
| Service connections | [Before](../baselines/stage_y_refinement_proposal/screenshots/before_connections_detail.png) | [Preview](../baselines/stage_y_refinement_proposal/screenshots/proposed_connections_detail.png) |
| Processing floor/base | [Before](../baselines/stage_y_refinement_proposal/screenshots/before_processing.png) | [Preview](../baselines/stage_y_refinement_proposal/screenshots/proposed_processing.png) |

Godot 4.7.2 Standard / Forward+, 1600 x 900, RTX 4060 Laptop, the existing five-Raider/two-machine fixture and matched 30-second bay/overview windows:

| Metric | Current bay / overview | Prototype bay / overview |
| --- | ---: | ---: |
| Maximum draw calls | 463 / 463 | 480 / 480 |
| Maximum rendered primitives | 174,428 / 174,428 | 182,340 / 182,340 |
| Median interval | 4.189 / 4.186 ms | 4.191 / 4.194 ms |
| p95 interval | 5.487 / 5.429 ms | 5.417 / 5.526 ms |
| Worst observed interval | 22.489 / 21.495 ms | 21.151 / 21.022 ms |
| Maximum texture memory | 122,766,848 B | 122,766,848 B |
| Static memory sample | 86,432,645 / 86,459,685 B | 86,806,820 / 86,818,900 B |

Frame timing is similar in these local samples; it is not a hardware guarantee. The full preview adds **17 draws / 7,912 rendered primitives** over current Y. It exceeds the old Y ceilings of 467 draws / 178,020 primitives. This is measured cost, not permission to silently increase a budget.

For the full pass, request a bounded revision to **487 draws / 188,020 primitives** in these matched views: accepted-X +100 draws / +45,000 primitives, increasing the prior allowances by 20 draws / 10,000 primitives. Retain the existing +1 ms p95 review trigger, texture policy and 16 MiB static-memory trigger. Optimize repeated geometry/shadows during integration and retain the tighter limits if achievable. Do not remove useful shadows merely to pass a counter. First-shader compilation/load hitches need a separate check; the preview applies its additions after the scene-ready timestamp, so those ready timings are not comparable.

## Evidence and implementation sequence

Already checked: clean editor parsing, bounded headless prototype, clean Forward+ preview, both seeds 87017/87018, unchanged original collider/marker/navigation-input contracts, active stock/patrol validation, all six stock positions clear, and four complete performance observations with conserved accounting and bounded actor/response populations. Production source hashes are verified unchanged. These are proposal checks, not a claim that the full regression suite or manual acceptance has been repeated for an integrated refinement.

Approved delivery sequence (completed; see the delivery report):

1. Integrate and tune the ground/flush channels first. Preserve the explicit graybox and compact/reference scenes. Use a deterministic replay to confirm the surface-only step cannot affect actors or ledgers.
2. Add the two conduit drops/junction changes, validating transformed bounds, visible attachment and player/scout clearance. Check the processing overlay and equipment foundations at normal camera height.
3. Add exactly the three reviewed matching prop groups and consolidate shared instances. Pin those three exceptions in physical-contract tests while retaining exact checks for all 33 original boxes and existing markers.
4. Exercise actual movement around each group from both directions, jump/boost/shoulder-camera clearance, valid blocked/clear shots, both ramps, all alternate stock sites, exits and Recall. Preserve the Site 07 visible-versus-physical regression and add equivalent checks for the new loads.
5. Run all forty existing suites plus concrete new coverage; editor import; bounded seeded deployments; bank/forfeit/restart; both spectator modes; matched performance and the seven-discharge/eight-death fixture. Inspect warnings separately from assertions.
6. Deliver revised before/after views, measurements and a director checklist at Checkpoint Y. Judge whether the first three clusters provide enough perceived density before proposing more. Stop before Stage Z.

**Approval record:** the director approved this three-part Stage Y refinement, exactly three new matching prop colliders, one expanded-only procedural ground material, and the bounded rendering-budget amendment above on 2026-10-25. Implementation and validation are complete; the director accepted Stage Y on 2026-10-26. No new GLBs, gameplay systems, roof supports, commit or publication are included.
