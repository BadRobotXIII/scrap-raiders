# Stage R baseline evaluation

Recorded: **2026-10-20**. Stage Q was explicitly accepted by the director during this evaluation. Stage R is **planning only**; no gameplay implementation or balancing change has been made. Read this with the [supplied R ledger](../ledgers/phase_5_stage_r_encounter_polish.md) and [implementation proposal](../plans/phase_5_stage_r_integrated_polish_plan.md).

## Baseline identity and method

The baseline is the current working tree, including accepted but uncommitted P combat follow-ups and Q implementation. Git HEAD remains `32cdde3`; it does not alone identify this baseline. The archived [source manifest](../baselines/stage_r_2026_10_20/source_manifest.json) records SHA-256 hashes of scripts, scenes, resources and tests. Rechecking that manifest after evaluation found **zero changed gameplay source files**. A local ignored source snapshot at `.godot/stage_r_baseline/source_snapshot.zip` preserves those source folders plus `project.godot` for later controlled comparisons without authorizing a commit. Existing user work was preserved; no commit or publication was performed.

Inspection confirms three distinct configurations:

| Reference | Actual configuration |
| --- | --- |
| Integrated Extraction / N | Three baseline-policy Raiders, entries 0/0/0, nine salvage units plus two installed components, authored alliances/rivalry/betrayal, scout/guard patrols, two possible responders, recall and post-death continuation. Runtime seed normally comes from its resource. |
| Emergent Encounters / P | Five baseline-policy Raiders, entries 0/0/35/70/105, two authored seed-selected layouts, 6/3/3 salvage plus two installed components. R1/R2 allied; R3 neutral; R4/R5 allied and hostile to R1/R2. |
| Personality Encounters / Q | Same world conditions as P, copied personality-aware profiles including fallback responders. Q is opt-in; its accepted policies are not used by normal N. |

The application still starts **Intercept**, not the integrated mission; in-game F5 selects N and Alt+Shift+F5 selects Q. All use the existing mission/actor composition, authoritative ledgers and bounded scheduling. Raiders recover material cargo/components, not equipment cases or equipped weapons. The player recovers drops and equipment and banks them through recall; direct salvage harvesting and a spend/progression economy are not implemented. These distinctions prevent proposed capabilities being mistaken for delivered ones.

The temporary [observation harness](../baselines/stage_r_2026_10_20/baseline_probe.gd.txt) ran in an ignored directory. It warms navigation, observes existing signals/state, uses isolated ignored stash files and enables the ordinary developer spectator. The robot stays physically present at its configured Recall Dock, vulnerable and stationary. After its death the harness chooses the existing follow view and allows normal world completion. It never creates cargo, changes weapon/health/policy values, commands an AI decision or relocates an actor. For N only, it changes the cached resource's **seed in RAM before scene initialization**, since N lacks Q's seed override; no resource file is saved. Each deployment has an isolated Godot process.

Eighteen observation runs were completed: six full normal-speed cases (three N, three Q), two 60-second normal-speed checks, eight accelerated N/P/Q reference cases and two accelerated same-seed repeats. Full cases run until the 180-second deadline or legitimate post-death world completion. The two 60-second cases are censored observations, not failed deployments. At 8x speed the simulated physics step differs from 1x, so accelerated outcomes are screening evidence, not normal-speed balance targets.

## Normal-speed results

The following are passive observations, **not win-rate estimates or manual gameplay acceptance**. World-end time can be shorter than the deadline after the stationary robot dies and all autonomous actors/pending work resolve. Extra responders account for human deaths plus extractions exceeding the three initial N actors.

| Preset/seed | Observed end (s) | Autonomous shots | Human deaths / extractions | Empty extractions | Machine deaths | Last shot (s) | Longest no-shot interval (s) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| N 85017 | 90.05 | 95 | 1 / 3 | 1 | 2 | 52.02 | 38.03 |
| N 85018 | 124.93 | 127 | 2 / 3 | 0 | 2 | 95.70 | 29.23 |
| N 85019 | 80.50 | 62 | 1 / 3 | 0 | 2 | 34.45 | 46.05 |
| Q 87017, south | 111.18 | 30 | 0 / 5 | 1 | 2 | 78.47 | 58.38 |
| Q 87018, north | 180.00 | 44 | 0 / 5 | 3 | 1 | 129.97 | 50.03 |
| Q 87019, south | 111.18 | 30 | 0 / 5 | 1 | 2 | 78.47 | 58.38 |

Autonomous firing began at **0.50 seconds in all three N cases**; these were independent actor fights, not immediate player hits. First damage to the stationary robot occurred at 18.75–36.08 seconds in N. Q first-shot times ranged 0.50–5.03 seconds and first player damage 9.68–38.97 seconds. Five of the six stationary robots eventually died; Q north survived to the deadline after taking 30 damage. These passive deaths do not establish unfairness or justify health/accuracy changes.

No case violated conservation or population limits. Normal-speed N peaked at three live Raiders, Q at two; these observations therefore do not establish graphical performance at the configured five-Raider/two-machine ceiling. Existing automated suites cover admission at that cap. N admitted one or two finite responders in the normal cases; Q admitted none because no human died. No evidence of runaway reinforcement escalation appeared.

Final material categories remained distinct: N lost 10/10/11 of 11 units, leaving 1/1/0 ground units. Q south lost 13 of 14, leaving one ground component; Q north lost nine, leaving one ground unit and four protected units. Player recovery/banking was zero because the observer never attempted pickup/recall. This is expected, not evidence that recovery is impossible. Empty extractions are sometimes intentional survival outcomes and should not be eliminated categorically.

No sampled stable moving task had three seconds of persistent low progress. The longest such segment was **2.13 seconds** in Q north; short repath/status changes appeared and the actor later extracted. This is not proof that all congestion is solved: sampling is coarser than the FSM, task changes reset the low-progress segment, and no human-created blockade was imposed.

## Findings and limits on their interpretation

1. **Integration is incomplete at the experience level.** Normal N does not use Q's accepted personality policies or P/Q's staggered encounter setup. This is verified configuration behavior, not an AI defect. Reuse the accepted Q composition for the refined integrated experience, preserving N/P/Q as references.
2. **Timing limits rival opportunities in the Q samples.** In the observed Q cases, both initial allied actors had extracted before the first hostile-group arrival at 70 seconds. No human deaths occurred. Temporal separation is directly observable, but this does not prove that changing timing alone will produce fights; route intersection, visibility and personality remain independent requirements. Tune opportunities rather than force rivalry or betrayal.
3. **Quiet intervals already exist.** N's 29–46 second and Q's 50–58 second no-shot intervals include post-combat travel, scavenging, extraction or waiting. No-shot time is not equivalent to safe exploration or inactivity. Do not add scripted quiet windows or force constant combat to fill the deadline.
4. **Two layout choices are coarse variation.** Q seeds 87017 and 87019 select the same authored arrangement and produced matching summary outcomes in these samples. Repeated accelerated seeds also reproduced setup. This is a reason to compare multiple arrangements and holdout seeds, not a reason to add procedural maps or unbounded randomness.
5. **There is a reproduced recovery notification defect.** In a separate controlled fixture, the ledger accepted recovery of three finite materials and remained conserved, but the status immediately read `Machine report: R02 last seen near (-19, 3)`. `try_recover()` writes success text, then `after_event()` calls `refresh_hud()`, whose machine-report branch overwrites it. See the [reproduction result](../baselines/stage_r_2026_10_20/recovery_feedback_reproduction.json) and [fixture source](../baselines/stage_r_2026_10_20/recovery_feedback_probe.gd.txt). This case is separate from the passive outcome table and does not assert a new gameplay transfer rule.
6. **Normal presentation exposes diagnostic detail.** The [Forward+ HUD capture](../baselines/stage_r_2026_10_20/normal_hud.png), taken with F3 off, shows global protected/carried/ground/lost counts, pending admissions, response budget and raw Raider IDs/coordinates. World labels expose personality/state/cargo; the dock has overlapping world/screen prompt text. This supports presentation cleanup using existing controls, not a large HUD or art project. Existing damage flash, directional bearing, health display, hit marker and audio already exist; do not duplicate them before active play-testing.
7. **The current metrics are incomplete.** P/Q have a 64-entry event buffer, but N has no equivalent deployment summary. Actor collection notices report current cargo, not an accepted-transfer delta, so summing them would miscount. Navigation status sampling can miss or double-count attempts. Exact accepted-transfer and navigation notifications are a justified small diagnostic addition; counters must not become an inventory authority.

N and Q differ in counts, schedules, relations, stock and placement as well as policy. Their outcomes cannot be used to attribute improvements to a single personality parameter. The next controlled tuning comparison must keep one configuration fixed while changing one related group.

## Validation, artifacts and reproduction

All **25 existing suites passed in a fresh run**, including physical combat/movement, policy, encounter generation, persistence, post-death and spectator cases. The [validation manifest](../baselines/stage_r_2026_10_20/validation.json) records suite completion lines. Editor parsing/import passed. Bounded Forward+ N and Q launches (600 frames each) and a separate graphical UI capture passed; see the [engine-check manifest](../baselines/stage_r_2026_10_20/engine_checks.json). The recall suite and bounded N graphical launch reported the known two-instance audio ObjectDB cleanup warning; Q startup, observation runs and the recovery reproduction reported no errors. This warning remains an investigation item, not a claim of a corrected defect.

Archived evidence:

- [Per-run summaries](../baselines/stage_r_2026_10_20/summary.json): all eighteen cases, material/equipment categories, shot/episode counts and unresolved objectives.
- [Raw observations](../baselines/stage_r_2026_10_20/observations.json): bounded event records and setup data, not a second accounting database.
- [Source hashes](../baselines/stage_r_2026_10_20/source_manifest.json): the actual uncommitted baseline.
- [Normal HUD](../baselines/stage_r_2026_10_20/normal_hud.png) and the separate recovery reproduction above.

To reproduce, copy the archived probe text to `.godot/stage_r_baseline/probe.gd` and run, for example:

```powershell
godot --headless --path . --script .godot/stage_r_baseline/probe.gd -- n 85017 1 180 n_85017_recheck
godot --headless --path . --script .godot/stage_r_baseline/probe.gd -- q 87018 1 180 q_87018_recheck
```

Arguments are preset (`n`, `p`, `q`), seed, time scale, maximum simulated seconds and output label. Use 1x for balance comparisons. The harness stores output and fresh isolated saves under ignored `.godot/stage_r_baseline/`. Game source/resource files stay unchanged. Live case logs remain there; archived JSON retains durable observations.

Combat episodes mean consecutive Raider ENGAGING/TAKING_COVER/REPOSITIONING states, not a unique world encounter; pursuit can split an episode. Late actors are discovered on a roughly 0.25-second observation cadence. Low progress means less than 0.05 m displacement per sample while over 1 m from the same moving goal in the same state. These definitions are screening measurements, not clinical assertions about AI quality. The event limit was not reached. Normal runs were concurrent, so wall-clock durations are not performance benchmarks.

Human active intervention, recovery-window usability, fairness, actor recognition without labels and full-cap graphical frame pacing remain **manual/unmeasured**. No new tests or production instrumentation were introduced during planning. See the proposal for controlled implementation and acceptance gates.
