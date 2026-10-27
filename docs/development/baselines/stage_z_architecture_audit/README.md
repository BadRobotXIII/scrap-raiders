# Stage Z architecture baseline

Recorded **2026-10-26**, after director acceptance of Stage Y, for the [inventory audit](../../reports/stage_z_inventory_architecture_audit.md) and [architecture proposal](../../plans/phase_7_stage_z_hybrid_inventory_plan.md). This evidence contains accepted behavior before any Stage Z inventory implementation.

- `data/sources_before.json` and `final_checks.json`: **345** script/resource/scene/test/tool/project/bus/manifest file identities; all unchanged. The unchanged supplied Stage Z ledger SHA-256 is recorded too. Documentation acceptance/proposal additions are separate from runtime changes.
- `logs/regression/validation.json` and suite logs: clean editor parsing/import, **41 passing suites**, all actual completion markers and timeouts checked. Thirty-two accelerated suites retain the existing WAV cleanup warning. Verbose classification found only `AudioStreamWAV` / `AudioStreamPlaybackWAV`, with no additional assertion/script failures.
- `data/replay_final.json`, `logs/baseline_seeded.log.txt`: both 40-second autonomous observations, seeds **87017 / 87018**. The complete serialized baseline exactly matches `stage_y_refinement_delivery/data/replay_final.json`; the known WAV warning remains at accelerated shutdown.
- `data/runtime_validation.json`, `logs/baseline_graphical.log.txt`: clean Forward+ physical fire, death, recovery, three-material Recall banking, results, restart, player death and follow cycling. Every test save is isolated under ignored `.godot` paths.
- `screenshots/`: current accepted briefing, results and post-death following; they are baseline captures, not proposed inventory UI screenshots.
- `probes/`: `.txt` copies of the ignored audit scripts. Restore them under `.godot/stage_z_audit/` to reproduce; the full-suite runner discovers only top-level active tests. The replay/graphical probes reuse accepted test helpers and the current expanded scene, not a new gameplay controller.

The director's real stash was not inspected, migrated or modified. No inventory code or art was generated. The Stage Z ledger remains byte-for-byte archived at [phase_7_stage_z_hybrid_inventory.md](../../ledgers/phase_7_stage_z_hybrid_inventory.md). Manual acceptance of the future inventory loop is not claimed by these baseline checks.
