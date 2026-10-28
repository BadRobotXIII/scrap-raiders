# Stage AA playable checkpoint evidence

Captured **2026-10-27** for AA-1 through AA-5. Director play-testing is pending; AA-6 onward remains gated. See the [delivery and manual checklist](../../reports/stage_aa_playable_loop.md). The separate [architecture-audit baseline](../stage_aa_architecture_audit/README.md) remains the immutable pre-implementation record.

- `summary.json`: machine-readable final results, seeded observations, warning types and rendering/write samples.
- `regression/validation.json` and 50 adjacent logs: final results from the full batch with focused reruns replacing corrected suites. Every final suite completed; script errors and assertion failures are rejected even when Godot exits zero. The audit's spectator-fixture failure was corrected with a bounded admission wait.
- `editor_import.log.txt`: clean Godot 4.7.2 editor parsing/import output.
- `graphical.log.txt`, `graphical_metrics.json`, `screenshots/`: native Forward+ interaction, actual UI confirmation/cancel, extraction/return, and 13 captures. Rendering counts are single-scene samples, not frame-rate guarantees.
- `natural.json` and `natural.log.txt`: both contracts at seeds 87017 and 87018, bounded passive deployments through the actual application root. All four continued after destruction, conserved inventory and returned home. Outcomes were observed, not prescribed.
- `reviewed_sources.json`: exact hashes for the 14 pre-existing runtime/config/test files changed from the audit manifest. Other previously recorded runtime sources remain unchanged.
- `source_manifest.json`: current scripts/scenes/resources/tests and tracked-style UID identities, plus project configuration. Generated `.godot` files and screenshots are excluded from this source manifest.
- `working_tree_status.txt`: working-tree inventory; includes accepted pre-AA scroll work and documentation. No commit was made.
- `*.gd.txt` / `*.py.txt`: diagnostic probe and runner source retained as text, outside the active test/import set.

The regression batch uses `godot --headless --verbose --path . --fixed-fps 60 --script res://tests/<suite>.gd --quit-after 20000`. The native probe uses `--script res://.godot/stage_aa_build/graphical.gd`; the natural probe uses `--headless --verbose --fixed-fps 60 --script res://.godot/stage_aa_build/natural.gd --quit-after 50000`. To reproduce these helpers, copy their text sources back to the indicated ignored `.godot/stage_aa_build` paths. Python runners use this machine's `C:/Users/kzulf/bin/godot.cmd`; adjust that executable for another environment.

All application/arena probes assign randomized ignored test profile paths before scene startup. The real `user://stash.json` was not opened or migrated. A normal interactive application launch uses the actual profile and offers the documented version-3 upgrade path.

Thirty-seven regression suites and the natural probe report known WAV shutdown cleanup warnings. Verbose leaked-instance types are exclusively `AudioStreamWAV` and `AudioStreamPlaybackWAV`; these are retained in evidence rather than counted as clean shutdowns. Editor and native graphical logs are clean. Tests establish functional behavior; they do not substitute for the mandatory director review of usability and gameplay feel.
