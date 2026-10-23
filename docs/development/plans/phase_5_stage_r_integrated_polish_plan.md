# Stage R implementation proposal

Prepared: **2026-10-20**. Status: **implemented, validated and accepted at Checkpoint R on 2026-10-20**. Checkpoint Q is accepted. See the [R delivery report](../reports/stage_r_integrated_polish.md) for results; the approved proposal is retained below. The [supplied R ledger](../ledgers/phase_5_stage_r_encounter_polish.md) is archived unchanged; the [baseline evaluation](../reports/stage_r_baseline_evaluation.md) records code inspection, 25 passing suites, eighteen observation cases and a reproduced feedback defect.

## Recommended scope and order

Deliver one refined integrated deployment using the existing framework. Preserve the accepted N, P and Q presets as controls. Make no blanket navigation, weapon, accuracy, health, machine or economy changes: the baseline does not justify them.

| Order | Evidence / problem | Proposed correction | Expected effect and main risk |
| --- | --- | --- | --- |
| R1: measurement | N lacks P/Q's event history; current logs cannot reliably count accepted transfer deltas or exact navigation recoveries. | Add a small optional mission-local metrics observer using authoritative events and detached snapshots. | Comparable deployments without a second inventory or decision system. Risks: duplicate events, censored durations and observer side effects. |
| R2: reliable feedback | A successful three-material recovery is immediately overwritten by a machine report. Normal HUD exposes raw accounting/debug fields with F3 off. | Fix notification priority, then use existing HUD/labels for player cargo, time and recall state. Keep detailed world diagnostics behind F3 in the refined mission. | Recovery and extraction become readable; interaction/settlement rules stay unchanged. Risk: hiding essential warnings or changing shared-E priority. |
| R3: integrate accepted mechanics | Startup is still Intercept. Integrated N uses baseline policy and all initial entries at time zero; Q already combines the accepted encounter and personality systems in an opt-in comparison. | Create one R integrated definition inheriting the existing Q-composed scene/configuration. Initially preserve Q's complete data unchanged, then expose it as the primary R acceptance environment. | One coherent deployment, without rewriting actors or mission rules. Risk: accidental mutation of reference resources or surprise launch routing. |
| R4: timing comparison | In observed Q runs, the original allied pair extracted before hostile arrivals at 70/105 seconds; no human died. | Trial entry timing as one related parameter group, leaving policy, placement, stock, counts and combat values fixed. | More opportunities for rivals to coexist while retaining quiet/travel time and autonomous choices. Risk: compressed openings, excessive interference or losing late opportunities. |
| R5: conditional corrections | No stable moving task stalled for three seconds in the sampled natural runs; short repaths resolved. Machine lethality attribution and active-player fairness are not established. | Keep existing steering/watchdog/cover behavior. Correct a local defect only after a reproducible physical case or manual observation demonstrates it. | Avoid regressions from speculative AI/navigation changes. No replacement planner or controller. |

### R1: bounded diagnostics, before tuning

Use a small `scripts/debug/deployment_metrics.gd` observer composed by the existing mission coordinator when explicit capture is enabled. Reuse existing actor-entry hooks, state/health/shot signals and debug presentation. Keep P/Q's accepted 64-entry diagnostic history functional; do not add a parallel mission service or global singleton.

- Record seed, configuration fingerprint and profile distribution; actor admission/death/extraction; machine death; player damage/death; actual responder admission separately from ticket commitment; combat episodes and significant unresolved objectives.
- Timestamp in mission simulation time. Define combat episodes exactly as the baseline and mark unfinished durations as censored at stop/Return/deadline. A deployment with no shots is valid, not an error.
- Add minimal read-only notifications at authoritative material/equipment transfer owners **after accepted mutation and invariant verification**, if coordinator events cannot report the accepted amount unambiguously. Do not sum cumulative cargo notices or reconstruct an independent inventory. Rejected/duplicate transfers emit no accepted-transfer event.
- Add an explicit notification from Raider's existing navigation recovery path, including goal, reason and result. It observes the existing decision; it must not choose a destination or reset a timer.
- Keep aggregates bounded by finite actors and use a capped detailed event ring (proposed 256 entries). If truncated, export that fact; do not imply a complete detailed trace. Sample unresolved/position diagnostics at 0.5 seconds at most while capture is enabled, not continuously per frame.
- Ordinary play leaves capture disabled or has only negligible event aggregation. Explicit debug export writes a detached JSON snapshot locally; no networking/telemetry. No change to developer versus player-spectator permissions.

Test capture enabled/disabled and duplicate callback protection against the same deterministic actor/transfer cases. Confirm that sampling/export cannot modify relations, goals, health, velocity, ledgers or persistence. Measure observer overhead separately; the baseline does not provide a performance benchmark.

### R2: player-facing clarity using existing presentation

First turn the recovery overwrite reproduction into a failing regression, then fix it. Use a short presentation-only player-action notice that has priority over routine machine reports. A proposed two-second success notice may expire back to the latest report; it never changes simulation timing, eligibility or ownership. Verify that identical recovery transfers happen with and without visible notices.

For the refined integrated mission, keep the existing normal HUD focused on the objective, time, **player deployment cargo** (ledger recovered materials and recovered equipment), hull and current interaction. Move global protected/carried/ground/lost counts, pending entries, response budget and raw actor IDs/coordinates into F3 diagnostics. Keep actual banking/forfeiture distinctions in the end report; do not describe recovered loot as banked before recall commits.

Reduce duplicate dock instructions and detailed actor/test-target labels in the normal view. Retain necessary aim/danger cues and existing hit/damage feedback; F3 restores inspection details. Use the existing controls/nodes rather than build a new HUD framework or add permanent debug UI. Judge this in the refined integrated mission with diagnostics hidden.

If recall interruption remains unclear in active review, add a short reason derived from RecallController's actual cancellation path. Preserve the accepted rule: **nonlethal damage does not interrupt player recall**. Movement, fire, jump/boost, E release, range/eligibility and save failure retain their existing rules. Material pickup takes priority over equipment; nearby loot takes priority over recall. Do not add generic interaction failures that fight these priorities or reveal unseen loot.

### R3: one integrated acceptance environment, preserved controls

Use a single inherited scene such as `scenes/levels/refined_extraction_arena.tscn` and a copied `resources/missions/refined_extraction.tres`, selected through the existing MissionConfig/mission-arena path. Start from accepted Q conditions: five finite initial IDs, 6/3/3 salvage plus two components, the same two layouts/patrols, Q profiles, relationships, betrayal guards, recall, traversal and both spectator modes. No new maps, actors, material sources, budgets or AI capability are required.

This is integration/configuration reuse, **not evidence that Q individually fixes N's pacing**. The initial R record must match its Q control for the same seed before tuning. Keep all other Q data fixed during the timing trial; never modify preloaded P/Q profile/layout/configuration resources in place.

During implementation review, launch the R scene explicitly and use it for all active acceptance sessions; retain N/P/Q scene paths and existing comparison controls. After Checkpoint R manual acceptance, the proposed final promotion is to make the refined integrated scene the normal startup/integrated entry, with older scenarios still available as diagnostic references. Do not silently change startup/F5 routing during baseline collection or early experiments. Routing promotion and its explicit regression expectations should be reviewed with the final R result, rather than deleting legacy tests to accommodate it.

### R4: one timing group at a time

Control: `[0, 0, 35, 70, 105]`. Initial proposed trial: **`[0, 0, 15, 25, 70]`**, preserving ID order and moving the first rival-group opportunity into a period when earlier actors may still be active. This is a test candidate, not a promised final tuning value. Keep finite counts, profiles, stock, exits, spawn markers, patrols, weapon values and flare rules identical to the control.

Compare R versus Q at **1x** with seeds 87017/87018/87019, then fixed holdouts 87020/87021. Keep P and N smoke/regression checks. Retain equivalent repeated-seed setup records and active-player sessions; do not infer normal-speed balance from 8x outcomes. Baseline data already shows that different seeds can share the same layout/outcomes.

Evaluate temporal/spatial opportunity, independent objective completion, quiet/travel intervals, player intervention and recovery windows. Earlier hostile co-presence is an opportunity metric; a rival fight, human death, cooperation or betrayal is never required. Do not impose target death rates, force a quiet opening, guarantee rewards or use the player's health/camera to alter difficulty. If the candidate compresses activity or provides no meaningful improvement, revert it and record why before another trial.

Placement, awareness, policy, cargo targets and machine/weapon numbers stay unchanged initially. Consider a later single-group change only with a named failing seed/case, measured evidence and a clear comparison. Do not vary health, accuracy, damage and policy together. If earlier arrival alone does not improve opportunities, report route/visibility/personality reasons rather than force AI engagement.

### R5: conditional navigation, loot and machine work

Re-run accepted guard-contact, cover-route, pursuit, blocked-exit and finite-extraction cases in the refined configuration. Add a physical regression only for a demonstrated gap, for example repeated recovery to the same unreachable goal or permanent body blocking in a particular passage. The test must fail for the observed behavior before its correction; avoid generic rewrites or collision bypasses.

Empty extraction can be a valid survival choice, and original uncollected salvage must not block mission resolution. Preserve the distinction between Raider extraction loss, unrecovered ground loot and forfeited player cargo. Treat ignored equipment as a player opportunity: Raiders do not currently collect/equip it, and equipment equipping is explicitly excluded. Recovered loot already banks to a stash; adding a use/spend economy is outside R. Improve truthful reporting, not progression systems.

Machine deaths/shot counts alone do not identify kill attribution or establish dominance. Collect actual instigators before recommending machine tuning. Keep the existing two machine roles, one allocated component each, shared observations, finite responder budget of two and shared live cap of five Raiders. Investigate the known audio shutdown warning separately; apply only a localized owned-resource cleanup if reproduced in actual restart/Return/quit. Do not replace audio or mask unrelated warnings.

## Affected systems and regression risks

| Area / likely files | Permitted work | Guardrail |
| --- | --- | --- |
| `mission_arena.gd`, `mission_config.gd`, optional `deployment_metrics.gd` | Observer lifecycle, detached snapshots, integrated definition/selection | No decisions, spawns or transfers driven by metrics; preserve N/P/Q setup and source resources. |
| `material_ledger.gd`, `equipment_ledger.gd` | Accepted-event notification metadata only where needed | Retain exclusive writers, transfer validation and every existing invariant; no rejected-event counting. |
| `raider.gd` recovery path | Exact diagnostic notification; localized correction only for a reproduced physical failure | CharacterBody3D stays movement owner; no new controller, teleport, disabled collision or unbounded retry. |
| `raider_arena.gd`, `mission_arena.gd`, `recall_controller.gd`, existing presentation scripts | Notification priority, R normal HUD and clear action/debrief state | Presentation does not change timers, input, camera permissions, reward receipt or settlement. |
| New R config/scene using existing resources | Baseline composition, then one timing trial | No new map/art; baseline N/P/Q files remain reference scenarios. |
| Relevant tests and development reports | Targeted regressions, before/after data and source/tuning records | Keep all 25 suites; change a legacy expectation only for an explicitly approved interface change, never to hide a failure. |
| `project.godot` / integrated-entry routing | Possible final promotion after manual acceptance | Deferred during experiments; retain explicit legacy scenarios and validate restart/default launch. |

## Validation and acceptance gates

1. **Diagnostics gate:** event correctness, rejection/duplicate handling, censored durations, actor lifecycle cleanup, export immutability and metrics-on/off non-interference. Preserve authoritative accounting after every accepted transfer.
2. **Feedback gate:** real recovery with simultaneous machine report retains success notification, expires correctly and displays the same ledger result. Exercise shared-E priority, overlapping prompts, recall cancellation reasons, successful bank receipt, failed deployment and save-error retry. Low-impact visual layout edits need visual inspection rather than tests that mirror labels.
3. **Integration/timing gate:** equal-seed R/Q setup equality before tuning; finite admission/response bounds; normal-speed controlled comparisons and holdouts, including real movement, shots, pickup and timed extraction. Physical cases are mandatory for movement defects; no outcome-specific assertions in natural runs.
4. **Integrity gate:** player death and one-time material/equipment settlement, continued pending arrivals/AI/loot/extraction, restricted follow target resolution, developer camera independence, Return/deadline shutdown, isolated persistence and restart in the selected R mode/seed.
5. **Engine/performance gate:** full 25-suite regression plus focused additions, Godot 4.7.2 parsing/import, bounded headless runtime, Forward+ startup and relevant N/P/Q/R smoke checks. Inspect warnings. Profile representative and peak-population graphical runs with metrics off/on; do not treat concurrent headless wall time as a frame-time benchmark.
6. **Manual gate:** use the full ledger's acceptance matrix, primarily in the integrated R mission with diagnostics hidden. Judge personality readability, combat continuity, credible escape, intervention/recovery opportunities, machine contribution and pacing across seeds. Record player actions and subjective findings separately from automated observations.

For each trial retain configuration fingerprint, exact changed values, seed, outcome metrics, physical failures, human feedback and a retain/revert decision. Manual play-testing is required to establish improved enjoyment and fairness. No automated metric is a substitute for that decision.

## Approval boundary and deliverables

Approval authorizes the ordered, bounded R work above, starting with diagnostics and the reproduced feedback defect. It does not authorize new social mechanics, equipment equipping, new weapons/machines, progression, art/maps, multiplayer, an AI/mission replacement or forced outcomes. Conditional corrections must remain localized and evidence-backed.

At Checkpoint R provide changed-file/tuning records, N/P/Q compatibility results, before/after normal-speed observations, all validation outcomes and remaining manual issues. Stop for feedback. Commits/publication require separate authorization.

**Historical planning boundary:** no gameplay source, configuration, scene, weapon value, policy or scheduling change was made when this proposal was prepared. The current changes are archival records, baseline evidence and this proposal. The supplied ledger's instruction applies: **“Stop for director approval before modifying gameplay behavior.”**
