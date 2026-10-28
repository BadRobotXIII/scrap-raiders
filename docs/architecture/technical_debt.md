# Measured limitations and future work

Updated for the Stage AA handoff, **2026-10-27**. The [delivery report](../development/reports/stage_aa_sanctuary_gameplay_loop.md) records validation and acceptance status.

| Area | Evidence / practical limit | Follow-up boundary |
| --- | --- | --- |
| Synchronous profile commits | Five final ordinary metadata writes took 31.24–44.10 ms. With 1,000 available equipment records, writes took 179.87–191.34 ms and cold reload took 323.85 ms on this machine. | Visible hitch risk at larger stash sizes. Batch intents as now; propose journal compaction/background-save design with crash-consistency tests before changing authority. |
| Journal growth | Each durable operation stores a full verified snapshot; startup validates the chain. Large-profile measurement covers a short chain, not years of history. | Retention/compaction is future work; do not delete old receipts without a recovery design. |
| WAV shutdown cleanup | Existing combat/environment test shutdowns leak only AudioStreamWAV / AudioStreamPlaybackWAV instances in verbose logs. Adding quiet Sanctuary ventilation exposes the same warning in home tests. Native graphical teardown is clean. | Investigate audio resource lifecycle independently; do not hide warnings or treat exit zero as sufficient evidence. |
| Profile ownership | One application process is the intended writer; no cross-process file locking or cloud conflict resolution. | Multi-process/cloud concurrency needs explicit scope. No new networking is implied. |
| Resume | Committed-but-unstarted kits refund; running attempts recover as failed and forfeit carried gear. | No mid-raid resume. A resumable world requires separate authoritative snapshot design. |
| Placement | Eight existing props, bounded marked area and conservative reserved corridors. Fixed stations/display cannot move. | Dense furnishing and free-room placement need navigation review; furniture never grants upgrade effects. |
| Display | One reserved item/stack, presented with the accepted item icon on a plinth. | Detailed weapon/module display meshes are future presentation work; preserve identity ownership. |
| Fabrication | Four explicit recipes, one permanent capacity upgrade. One-level missing-item preview; no recursive/automatic kit fabrication. | Recipe tuning and additional approved resources are natural next work; avoid reversible value/resource loops. |
| Modules | Existing armor/power/mobility/utility items retain their documented effects or data-only status. AA adds capacity, not new combat-stat module behavior. | Implement effects individually with controlled comparisons. |
| Validation coverage | Automated/graphical lifecycle checks and four natural seeded runs establish integration. Passive runs all ended with player destruction and Raider extractions. | Director play-testing remains necessary for fun, camera feel, UI clarity and balancing. Exact outcomes must remain emergent. |

The pre-AA spectator fixture's fixed-frame admission assumption was corrected at AA-5 with a bounded wait and explicit failure. It is retained in the historical audit as a resolved test defect, not an outstanding runtime issue.

Multiple reserved kits, richer home art, broader contract progression, recursive crafting, new maps and module effects are preferences/future proposals, not incomplete hidden implementations. No active tests or assets were archived merely because they were inconvenient to validate.
