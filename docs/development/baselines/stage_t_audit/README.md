# Stage T audit evidence — 2026-10-21

Read the [audit](../../reports/stage_t_integration_audit.md) for interpretation and the [proposal](../../plans/phase_7_stage_t_remediation_plan.md) for pending implementation. These captures predate any Stage T gameplay changes.

- `source_manifest.json` hashes the 216 files recorded by the accepted S delivery; `source_changes_from_s.json` is empty. This does not claim the Git working tree is clean.
- `validation.json` records all 29 existing suite exit codes. Each suite has a normalized UTF-8 `.log.txt` copy. Inspect the assertions and errors as well as the codes. `flare_loot_test` contains the known two-ObjectDB exit warning; PowerShell repeats part of that warning in its error-record wrapper.
- `editor.log.txt` and `graphical.log.txt` record Godot 4.7.2 parsing/import and default Forward+ briefing startup. These are not a new active-player graphical acceptance run.
- `seed_87017.json` through `seed_87021.json` and their logs are untouched normal-scene observations at 1× simulation speed, with existing metrics enabled. `summary.json` extracts comparison fields. Independent processes ran concurrently; do not interpret wall-clock execution as a performance benchmark.
- `observe.gd.txt` is the observation source. It starts the normal scene, retains the stationary vulnerable robot and uses existing spectator permissions. It does not arrange AI positions, manufacture loot or change relationships. Sample counts are repeated state occupancy, not unique social events. Raider damage instigators are actual Health events. Rifle target names are intended targets, not proof of the struck body. The 512-entry audit event limit was not reached; existing metrics report zero discarded events.
- `fixtures.gd.txt`, `fixtures.json` and `fixtures.log.txt` deliberately arrange normal-scene actors and transfer finite existing stock through the ledger. They demonstrate Q-profile betrayal compatibility and reproduce a dead-player report defect. They are not natural encounter evidence, new regression tests or evidence of a resolved defect. The fixture advances the assessment explicitly; it does not test physical post-betrayal combat/loot/extraction.

To reproduce, copy the `.gd.txt` probes into the ignored `.godot/stage_t_audit/` directory with `.gd` extensions. That directory must exist first. The fixture inherits the existing integration test's helper class. Use isolated ignored saves as supplied by the probes:

```powershell
godot --headless --path . --script res://.godot/stage_t_audit/observe.gd -- 87017
godot --headless --path . --script res://.godot/stage_t_audit/fixtures.gd
```

The observer stops at world completion or 180 simulation seconds, bounded by 12,000 frame iterations. Use 87018–87021 similarly. No user stash is copied or archived. Probes, saves and their generated files remain ignored under `.godot/`; archived source uses `.txt` and sits below the existing baselines `.gdignore`.
