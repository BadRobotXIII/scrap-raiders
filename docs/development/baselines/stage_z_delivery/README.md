# Stage Z delivery evidence — 2026-10-26

The director-approved hybrid inventory implementation is delivered for **Checkpoint Z manual review**. See the [delivery report and A–L checklist](../../reports/stage_z_hybrid_inventory.md), [approved plan](../../plans/phase_7_stage_z_hybrid_inventory_plan.md) and unchanged [director ledger](../../ledgers/phase_7_stage_z_hybrid_inventory.md). The [pre-Z audit evidence](../stage_z_architecture_audit/README.md) remains untouched.

## Final checks

| Check | Result |
| --- | --- |
| Godot 4.7.2 Standard editor/import | Exit 0; clean inspected output |
| All accepted + new suites | **47 / 47 pass**, native exit 0; no script errors or failed assertions |
| Accelerated cleanup | 34 suites report retained shutdown-only audio diagnostics; verbose leaked types are exclusively AudioStreamWAV / AudioStreamPlaybackWAV |
| Native Forward+ graphical lifecycle | Exit 0; clean output, real I/Escape/Deploy input, inventory/source/Recall/restart/post-death captures |
| Complete seeded normal simulations | Four cases plus moving-camera repeat, exit 0; conservation, finite admissions and world completion valid |
| Matched-view performance | Both native runs exit 0, fixed assigned camera throughout, population bounds and accounting valid |
| Isolated large stash | 1,024 stacks / 10,240 legacy material units migrate and remain valid |
| Original ledger | SHA-256 `1f7a363443dacd9e1ea13baa78c0abce7293046d9ccd5b2a2cd7a1946304bc75` |
| Director save | Never read, migrated or written by development/validation |

[final_checks.json](final_checks.json) and [validation.json](data/validation.json) record the final results. [Regression logs](logs/regression/) include all 47 verbose transcripts. [Editor](logs/editor_integration.log.txt), [graphical](logs/graphical.log.txt), [natural simulation](logs/natural.log.txt) and [large-stash](logs/benchmark.log.txt) transcripts are separate. Transcripts are normalized to UTF-8 where PowerShell originally redirected UTF-16; their content is retained.

## Rendering and operation measurements

Hardware: NVIDIA RTX 4060 Laptop GPU, Intel i7-14700HX, Godot 4.7.2 Standard / Vulkan Forward+, 1600 × 900. Each graphical sample runs approximately 30 seconds after warm-up and deliberately overlaps five regular Raiders with both existing machines. That constructed population fixture exercises the cap; it does not alter normal scheduling.

| Fixed view | Maximum draws | Maximum primitives | Frame median | Frame p95 | Maximum frame |
| --- | ---: | ---: | ---: | ---: | ---: |
| Processing bay | 437 | 159,490 | 4.183 ms | 5.686 ms | 43.953 ms |
| Overview | 325 | 122,918 | 4.194 ms | 5.742 ms | 49.404 ms |

The Y review guides remain 487 draws / 188,020 primitives and approximately 6.4 ms p95 (accepted Y about 5.4 ms + 1 ms). Both captures stay inside those guides. These are local frame-interval measurements, not GPU-only times or universal guarantees; occasional longer frames are shown explicitly.

The probe now holds its assigned camera through the normal player-death camera restoration, recording one read-only camera restoration in each run. This corrects mixed-view measurements in earlier development probes. Lower draw/primitive counts are **not claimed as an art optimization or an exact before/after comparison** with an older mixed-camera probe. Actor health, decisions, damage and inventory are unchanged by the benchmark camera. [Bay data](data/performance_z_bay.json), [overview data](data/performance_z_overview.json) and their [logs](logs/) retain startup samples, physics/process monitors, overlap counts and camera checks.

| Isolated 1,024-stack case | Measurement |
| --- | ---: |
| V1 migration | 516.808 ms |
| Expanded scene initialization with that profile | 651.952 ms |
| Inventory open | 12.278 ms |
| Inventory refresh, 20 repetitions | 9.472 ms mean |
| Source/actor fit query, 100 repetitions | 0.467 ms mean |
| Durable preparation transfer, four operations | 171.060 ms mean |
| Inventory Controls/nodes | 76; source/stash page capped at 24 buttons |
| Five committed journal snapshots | 1,006,010 bytes |

See [benchmark.json](data/benchmark.json). Large safe-stash writes remain synchronous; journal compaction is outside Z. No polling builds a 1,024-button panel each frame. UI refresh is driven by accepted changes.

## Seeded observations and reproducibility

[natural.json](data/natural.json) records complete compact/expanded deployments for 87017 and 87018, plus expanded 87017 with a moving developer camera. All five finite regular IDs extracted in each final observation; both machines were destroyed, no natural Raider deaths/flares occurred, and living Raider count peaked at two. World completion ranged from 126.23 to 137.48 simulated seconds. Those observed outcomes are not acceptance requirements for a deployment.

The camera comparison preserves sampled states, health, acquired loot, counters, final ownership and actor outcomes. Its recorded maximum position difference is 0 m; the probe declares a 0.02 m positional tolerance for separate physical runs. This tests seeded configuration and simulation non-interference rather than promising cross-platform bit-identical physics.

## Screenshots

- [Briefing](screenshots/briefing.png), [safe preparation](screenshots/prepared.png).
- [Registered source panel](screenshots/source.png), [Take All result](screenshots/looted.png).
- [Durable Recall result](screenshots/result.png), [post-death follow](screenshots/post_death.png).
- [Bay](screenshots/overview_z_bay.png), [overview](screenshots/overview_z_overview.png).

## Source and reproduction records

[sources_after.json](data/sources_after.json) and [source_changes.json](data/source_changes.json) compare the tree with the 345 pre-Z pinned source files, including pre-existing uncommitted W–Y work. No baseline file was removed. [reviewed_sources.json](reviewed_sources.json) pins exactly 22 existing caller/config/fixture changes for the historical source guard; new inventory components and six suites are listed separately by the source comparison. Generated script `.uid` files are present. No commit or publication is included.

The [probes](probes/) are archived as `.txt` to avoid Godot importing evidence as production scripts. To reproduce developer runs, copy the relevant scripts back to an ignored `.godot/stage_z_build/` directory, removing the final `.txt`. They use isolated randomized save directories and the existing normal scenes. Run the regression harness with Python or the test-index top-level loop; use the graphical/natural/performance wrappers for their respective probes. The wrappers retain process status and combine stdout/stderr for inspection. The paths in those probes intentionally target ignored artifacts, never the director's real stash.

Automated checks and graphical captures establish implementation evidence. Director manual acceptance and any later stage remain pending.
