# Stage T delivery evidence — 2026-10-21

Interpretation: [delivery report / integration matrix](../../reports/stage_t_full_gameplay_integration.md). Historical control: [pre-T audit evidence](../stage_t_audit/README.md). Implementation is validated for Checkpoint T manual review, not director-accepted or committed.

## Regression results

`initial_full_validation.json` records the actual sequential run of all 30 suites. All 29 prior suites passed; the new suite initially failed two assertions because its contested fixture assumed Cowardly capacity one rather than three. The profile was never changed. The corrected fixture preloads two finite units through the ledger; its complete rerun passed (actual exit code 0).

`validation.json` records final results, retaining the new suite's initial code and naming its focused final evidence. `gameplay_integration_test.log.txt` and `integration_final.log.txt` contain that complete passing run. `integration_fixture_initial.log.txt` retains the failed fixture run. Do not mistake the latter for a failed final gameplay check or claim the initial full runner was entirely green.

`dead_target_before.log.txt` deliberately demonstrates the original dead-target defect with two failing assertions. `dead_target_after.log.txt` demonstrates the local correction before further integration coverage was added. Final test source is `tests/gameplay_integration_test.gd`; its Godot-generated `.uid` is retained in the project.

Final suite logs have no engine/script errors or warnings. The known historical ObjectDB exit warning did not recur. Individual logs are copied as UTF-8 text, not inferred solely from exit codes.

## Natural deployments and placement trial

`final_87017.json` through `final_87023.json`, `final_repeat_87018.json`, corresponding logs and `seeded_summary.json` record eight final normal deployments at 1×. Existing metrics and developer observation are enabled; the robot stays stationary and vulnerable at Recall Dock, then restricted follow activates after death. No actor teleports, forced relations, manufactured cargo or AI state changes occur in these observations.

The 512-entry audit event buffer was not reached; existing metrics also report zero discarded events. `samples` are 0.5-second occupancy counts, not unique events. `raider_damage` records actual Health instigators. Rifle `shot.target` is intended target, not proof of the struck body. Final summaries therefore use actual Raider damage events to demonstrate social hits. No natural Raider deaths occurred, so flare/reinforcement integration is demonstrated by deliberate S fixtures instead.

`east_entries_87017.json` and `east_entries_87018.json` record the one trial applied to both layouts in memory. The south variant was rejected; only the north copy was retained. These are pre-promotion experiments, not additional final seeds. Arrival timing, weapon/profile values and resource totals were unchanged.

`observe.gd.txt` is the archived harness. Copy to the ignored `.godot/stage_t_delivery/observe.gd` after creating that directory. Final configuration reproduction:

```powershell
godot --headless --path . --script res://.godot/stage_t_delivery/observe.gd -- 87018 final
```

The optional `east_entries` trial mode was used against the pre-T resource setup before promotion; it mutates loaded definitions only inside that test process. To reproduce that historical trial, use the recorded baseline hashes/resources. Do not treat it as an extra normal gameplay mode. The observer stops at world completion/180 simulation seconds, with a 12,000-physics-frame iteration bound; its own shutdown writes the final artifact. A low `--quit-after` process-frame limit can truncate a headless observation before that write and is not equivalent to the physics bound.

## Engine, graphics and performance

`engine_checks.json`, `editor_final.log.txt` and `default_headless.log.txt` record parsing/import and bounded startup. `graphical_startups.json` and ten `startup_*.log.txt` files record Forward+ scene startups. The initial PowerShell loop encountered transient file locking while rewriting intermediate summary JSON; all ten engine processes returned zero and the final summary is complete. This was an evidence-file write issue, not a game runtime error.

`graphical_flow.log.txt` runs the existing S flow through actual graphical mouse Deploy, physical interactions, full/early results, failure and replay. `briefing.png`, `active.png`, `early_result.png`, `success_result.png`, `failed_result.png` are controlled fixture captures. Active/result screenshots were visually inspected. Fixture clocks are deliberately held in some captures; zero displayed deployment duration is not a natural runtime result.

`performance_off.json`, `performance_on.json`, logs and `performance.gd.txt` record sequential short Forward+ observations on this laptop with five Raiders/two machines. The fixture deliberately advances all admissions, arranges valid existing entry positions and runs production AI. It changes no profile/health/weapon policy. It records frame intervals, warmup exclusion, actual peak-population sample count, simulation duration, hardware, metrics choice and conservation/caps. This is a bounded approximately 2.5-second graphical check, not sustained production profiling. Natural observations were run concurrently and must not be used as timing benchmarks.

## Source and isolation

`source_manifest.json` contains final runtime/test/resource hashes; `source_changes.json` identifies precisely two existing files changed and three new files relative to the audit. P/Q/R reference resources/scenes/profiles remain unchanged. Documentation changes are outside this source manifest. Existing accepted uncommitted work is preserved; no staging, commit or publication occurred.

Probe source is archived as `.gd.txt` below the baselines `.gdignore`. Executable probes, transient logs/imports and isolated saves remain under ignored `.godot/` directories. Automated test fixtures, seeded observers and performance probes use isolated stash paths. Plain scene startup smokes may read their configured stash but perform no banking or persistent reward writes. Captures do not constitute human acceptance, guaranteed social outcomes or authorization for Stage U.
