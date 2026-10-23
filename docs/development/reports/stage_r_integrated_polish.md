# Stage R - integrated mission polish delivery

Delivered and accepted: **2026-10-20**. Status: **Checkpoint R accepted by the director**. The director confirmed: "All works well for this stage" and approved the delivery, noting that further refinement will be needed as the project grows. This records overall stage acceptance, not additional unrecorded test sessions or cross-hardware performance guarantees. Q and the [R implementation plan](../plans/phase_5_stage_r_integrated_polish_plan.md) were previously approved. No commit or publication was made; startup/F5 routing remains unchanged.

The evidence and review checklist below preserve the implementation-time observations. Future pacing, navigation, presentation and performance refinements should address concrete observations in separately scoped work. No next stage is started by this acceptance record.

## Delivered behavior

Launch the review environment explicitly:

```powershell
godot --path . res://scenes/levels/refined_extraction_arena.tscn
```

The inherited R scene composes accepted Q personalities, both seeded layouts, five finite scheduled Raiders, 12 salvage units plus two machine components, relationships/cooperation/betrayal, machines, bounded flares, jump/boost, player recall, developer spectating and post-death follow. The shared five-Raider live cap and two-responder budget are unchanged. N/P/Q configuration, layout and profile files are unchanged from the reviewed Q snapshot. Default startup remains Intercept; F5 remains N and the existing P/Q comparison keys remain available.

Normal R presentation shows the objective, time, **player deployment cargo**, hull, hit/damage feedback and the current interaction. F3 restores global material/equipment totals, pending entries, response budget, machine coordinates, actor labels and diagnostics. Detailed Raider/personality/state/cargo, machine and test-target labels are hidden normally; threat/aim cues remain. The dock has one world name and one screen action prompt. Stored stash detail stays in F3 except actionable save errors. A [Forward+ capture](../baselines/stage_r_delivery/refined_hud.png) records the reviewed normal HUD.

Recovery success now takes presentation priority for **two simulation seconds**, including when a machine report arrives synchronously. Both material and equipment recovery use that notice. The material regression failed before the fix (`Recovered 3 materials` was immediately replaced by a raw machine report), then passed after it. It also verifies notice retention, expiration, routine-report restoration and unchanged transfer count. No pickup range, E priority, channel duration, persistence or recall interruption rule changed. Nonlethal damage still permits player recall.

## Optional deployment measurement

Append `-- --capture-metrics` to the launch command, or enable the debug scene's `capture_metrics` property. Capture is absent by default and restricted to debug builds. Ctrl+F3 explicitly exports a local `user://deployment_<seed>_<ticks>.json` snapshot; the action notice prints its path. F3 in R shows that capture is active. No network or telemetry service exists. Snapshot/export also remains available to developer tools after world termination; no automatic export is required.

`DeploymentMetrics` is a mission-local observer, not an inventory, AI controller or mission authority. It attaches before admission/loadout allocation and observes:

- Seed, resolved setup, profile distribution, config/profile hashes and a setup fingerprint.
- Actual admissions, responder admissions separately from committed tickets, shot/hit counts, player applied damage/death and machine death instigator.
- Accepted material and equipment operations, exact delta quantities/item counts and monotonically increasing notification serials. Empty extraction is counted as an event with zero material units. Rejected or duplicate transfers do not emit accepted events; repeated serial callbacks are ignored.
- Raider deaths/extractions through accepted ledger events; death metadata also records the actual instigator when available. No camera position is used.
- Combat episodes: consecutive ENGAGING/TAKING_COVER/REPOSITIONING states, matching the baseline definition. These are actor episodes, not distinct world battles. Completed duration totals are bounded aggregates; open episodes are censored once at world stop, Return, replacement or scene closure. Player death alone does not stop observation. World-stop finalization is deferred until the terminal signal finishes dispatching, so a final machine death is counted before capture closes.
- Exact navigation recovery notifications from the existing watchdog, with attempted goal, reason and resulting status/state. This adds no recovery decision or timer reset.
- Current unresolved actor objectives/positions at most every 0.5 seconds, plus finite admission and peak-population records.

Detailed history retains **256 events** with an explicit discarded count. Aggregates remain available after history truncation; a truncated trace is not a complete event log. Ledger snapshots are read directly from authoritative owners, and exported dictionaries are detached. The fingerprint identifies configuration/setup; the delivery source manifest separately identifies implementation files. Restart creates fresh metrics while preserving the selected R scene, seed and capture setting.

## Controlled timing result: candidate rejected

The initial R resource matched Q byte-for-byte after normalizing only its display name; [control equivalence](../baselines/stage_r_delivery/control_equivalence.json) records that check. An initial 1x R control at seed 87017 reproduced Q's baseline summary: 111.18 seconds, 30 shots, five extractions, zero Raider deaths and conserved ownership.

Only entry timing changed for the experiment: control **[0, 0, 35, 70, 105]**, trial **[0, 0, 15, 25, 70]**. Profiles, layouts, routes, relations, weapons, accuracy, health, stock, counts and limits stayed fixed. Q's original 1x seeds 87017/18/19 were reused from the baseline archive; Q holdouts 87020/21 were freshly run. All five R candidates ran at 1x. These stationary-player/developer-camera observations deliberately continued through post-death follow; they are not active-player balance or enjoyment tests.

| Seed | Q control elapsed / shots | Trial elapsed / shots | Q extracted material / trial | Q / trial peak Raiders |
| --- | --- | --- | --- | --- |
| 87017 | 111.18s / 30 | 76.05s / 30 | 13 / 14 | 2 / 3 |
| 87018 | 180.00s / 44 | 94.15s / 38 | 9 / 13 | 2 / 2 |
| 87019 | 111.18s / 30 | 76.05s / 30 | 13 / 14 | 2 / 3 |
| 87020 | 180.00s / 43 | 94.15s / 38 | 9 / 13 | 2 / 2 |
| 87021 | 180.00s / 43 | 94.15s / 33 | 9 / 14 | 2 / 2 |

Every case admitted five initial Raiders and recorded five extractions, no Raider death and no responder commitment. Every material/equipment/cap check passed. No stable moving task reached the probe's three-second low-progress threshold; that sampled heuristic is not proof that all congestion is absent. Short north-layout repaths resolved. Different seeds sometimes select the same coarse authored layout and can share outcomes.

Earlier hostile-group admission created temporal co-presence in the south, but did not establish richer interactions in either layout. It compressed world activity and moved more material into autonomous extraction, reducing the observed remaining recovery stock. The stationary robot also died in all candidates, whereas it survived north controls; that observation alone does not prove active-player unfairness. The evidence did not justify retaining the candidate. **Final R restores Q's accepted [0, 0, 35, 70, 105] schedule.** No replacement timing or policy experiment was invented.

A final 180-second 1x R seed 87018 was run with capture enabled and disabled. Setup, actor records, all sampled gameplay events, episodes, shots/hits, deaths, damage, population, unresolved goals, material/equipment outcomes and elapsed time were identical. Both recorded 44 shots, five extractions, a surviving player, nine extracted materials, one ground unit and four protected units. This demonstrates observer non-interference for that case, not determinism of every possible session.

Evidence: [comparison summary](../baselines/stage_r_delivery/comparison.json), [eight new control/trial observations](../baselines/stage_r_delivery/observations.json), [final capture on/off comparison](../baselines/stage_r_delivery/non_interference.json), and the [original Q baseline](stage_r_baseline_evaluation.md). Reproducible observation/performance harnesses are retained as `.gd.txt` documents beside the results. Temporary execution files and isolated saves remain under ignored `.godot/`; `.gdignore` also keeps documentation evidence out of the game asset import pipeline.

## Workstream decisions

| Ledger area | Result / limit |
| --- | --- |
| Pacing | Measured five seeds, rejected the earlier-arrival group; no mandatory quiet/combat periods or forced outcome. Active-player pacing remains manual. |
| Personality/combat | Accepted Q policy and physical P/Q regressions preserved. No health, accuracy, damage, initiation or commitment retuning. Behavioral readability needs player review. |
| Navigation/congestion | Added exact recovery observation; existing guard/contact, spacing, cover, pursuit and blocked-route physical suites pass. No reproduced new stall justified a movement rewrite. |
| Loot/extraction | Truthful player cargo HUD and recovery notice; finite ledgers, banking, forfeiture and ground/extracted distinctions retained. No equipment equipping or economy expansion. |
| Player feedback | Fixed the reproduced overwritten success message and removed routine diagnostic clutter in R. Existing hit, bearing, audio and hull feedback retained. |
| Machines | Roles, components, patrols and threat sharing unchanged; kill attribution is now observable. No unsupported lethality or reward tuning. |
| Spectators/lifecycle | Existing camera ownership/permissions retained; capture continues after irreversible deployment death and ends with world lifetime. |

## Validation

**27 automated suites passed:** all 25 accepted suites plus `recovery_feedback_test.gd` and `refined_extraction_test.gd`. [Recorded suite results](../baselines/stage_r_delivery/validation.json) list each exit status. Logs were inspected for script errors, warnings and failed checks as well as process status.

The new R integration coverage includes enabled/disabled capture, early loadout/admission observation, duplicate admissions/transfer callbacks, exact deltas, snapshot detachment, bounded history, censored episodes, local export, authoritative totals, terminal-machine event ordering, actual watchdog notification, physical drop/range recovery, timed recall with nonlethal damage, banking, one-time death forfeiture, restricted follow selection, camera non-interference, post-death scheduled admission, physical machine movement, Return shutdown and restart preserving R seed/capture with fresh ledgers. Existing suites retain target death/extraction handling, save failures/retry, traversal, reinforcement bounds, social behavior, physical firing and cover/contact cases. The new tests extend concrete behavior; no outcome-specific winner assertions were added to natural trials.

Godot **4.7.2** editor parsing/import passed. Bounded 600-frame R headless startup with capture passed. Forward+ 600-frame graphical startup passed separately for N, P, Q and R; R's normal HUD was captured and visually inspected on the RTX 4060 Laptop GPU. Final suite, parsing and startup logs were clean; the [focused final regression log](../baselines/stage_r_delivery/refined_final.log.txt) also records the terminal-machine ordering regression passing after its observed failure and correction. The previously documented two-instance audio cleanup warning did not recur; no audio subsystem change was justified. PowerShell briefly could not rewrite a cumulative result file while it was being read; the completed 27-entry result file is intact and all test process results were zero. This was a reporting-file lock, not a Godot test failure. A temporary `--log-file res://...` argument was also corrected to a native relative path; the final focused/parser/graphical logs contain no errors.

Generated `.godot/` probes, imports, logs and saves and `builds/` remain ignored. New script `.uid` files are present. Git whitespace validation passed (existing LF/CRLF advisory messages remain). Existing uncommitted P/Q work was preserved; no Git commit or publication was performed.

### Performance limits

[Performance observations](../baselines/stage_r_delivery/performance.json) contain four short sequential Forward+ samples at 1600x900/120 FPS cap, followed by a peak pair repeated after the regression runner finished. Each records 300 process samples after warmup. The peak fixture admits all five finite IDs against the same two machines by advancing its deployment clock before entry; it is a load probe, not a natural pacing trial. Both peak runs actually contained five Raiders and two machines.

Initial normal off/on physics p95 was 2.45/2.21ms; initial peak off/on was 2.99/3.64ms. The repeated peak off/on physics p95 was 3.47/3.28ms, with process p50 1.89/1.77ms. There was **no consistent capture overhead** in these short noisy samples. Process p95 nevertheless reached approximately 20-28ms in both modes. These probes do not isolate GPU/OS costs or establish sustained frame pacing on other hardware. Inspect hitches during manual deployment and use a longer dedicated profiler session if persistent. Natural headless trials ran concurrently for observation, not performance benchmarking.

## Files and ownership

New runtime files: `scripts/debug/deployment_metrics.gd` (and UID), `resources/missions/refined_extraction.tres`, `scenes/levels/refined_extraction_arena.tscn`. New test files: `tests/recovery_feedback_test.gd`, `tests/refined_extraction_test.gd` (and UIDs).

Existing runtime changes relative to the reviewed Q snapshot are limited to seven files: `material_ledger.gd` and `equipment_ledger.gd` add post-verification notification metadata; `raider.gd` adds watchdog observation; `raider_arena.gd` adds the observer setup hook and action notice; `mission_arena.gd` owns optional capture, R selection/lifecycle and R presentation; `flare_director.gd` presents equipment success; `recall_controller.gd` removes duplicated R world instructions. See [source delta](../baselines/stage_r_delivery/changed_existing_sources.json) and [delivery hashes](../baselines/stage_r_delivery/source_manifest.json). README, plan status, development index, checkpoint register and this evidence/report document the delivery. Original supplied ledgers remain unchanged.

MaterialLedger and EquipmentLedger retain exclusive transfer authority and invariant checks. Raider still owns physical movement/FSM, Combat retains aim/cover/timing, mission rules retain outcome policy, RecallController retains persistence/settlement, and shared spectator camera/permission composition is unchanged.

## Checkpoint R manual review

1. Launch R explicitly with F3 hidden; explore, scavenge, avoid/intercept fights and recall. Confirm objective/cargo/hull/hit feedback and recovery notices are useful without developer labels. Test failed deployment and successful banking.
2. Observe Greedy cargo defense/disengagement, Cowardly escape/return fire and Aggressive bounded pursuit. Exercise multi-actor fights, guard contact, cover congestion, narrow passages and blocked/inaccessible loot. Report seed, actor, location and approximate time for stalls or oscillation.
3. Compare ordinary play and passive observation across 87017-87021. Evaluate recovery windows, machine pressure, quiet/travel time and missed interception opportunities; no specific winner or betrayal is required. This was an implementation-time review item; the director subsequently accepted overall stage functionality. Specific sessions beyond that feedback are not claimed.
4. Test F1 developer flight, player death, restricted target cycling, actor extraction/death, Return, deadline and restart. Confirm simulation continues without observer-triggered aggression and stash settlement remains truthful.
5. Enable capture for a comparison, use Ctrl+F3, inspect truncation/setup/accepted-transfer records, then restart and repeat with capture off. Watch real frame pacing at peak activity.

The director has accepted Checkpoint R. Retain the ledger's review matrix for future regressions and refinement; further observations should record seeds and player actions. Startup/F5 promotion, next-stage implementation and commits/publication remain separate work. Any further balance or localized movement change should address a reproduced issue rather than target predetermined encounter outcomes.
