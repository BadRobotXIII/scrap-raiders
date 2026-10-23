# Stage T: full gameplay integration and systems verification

Delivered **2026-10-21**; **Checkpoint T accepted by the director on 2026-10-21**, including the decision-stability follow-up. The director approved the [audit and remediation plan](../plans/phase_7_stage_t_remediation_plan.md) before implementation. This report retains the original implementation and automated evidence. The director subsequently stated "Stage T is approved"; Stage U architecture/layout planning is now requested, with construction awaiting separate plan approval. The [original audit matrix](stage_t_integration_audit.md) remains the historical S baseline; the matrix below updates its gaps with delivered evidence.

Director follow-up: integration was broadly functional, but play-testing exposed rapid Raider turning and multi-threat decision paralysis. The [decision-stability follow-up](stage_t_raider_decision_followup.md) records subsequent reproductions, corrections and validation. Counts and seeded observations below describe the original T delivery; they are not overwritten with later AI outcomes. The director subsequently accepted Stage T and the follow-up.

The normal Asset Recovery mission now has a demonstrated natural social-conflict opportunity in its north layout. A local eligibility correction prevents allied reports from retaining or reintroducing a destroyed target. The new normal-scene integration suite covers social combat, finite cargo, machines, player intervention, extraction, post-death responses and replay together. Existing actor, ledger, mission, persistence and camera ownership remain in place.

## Actual changes and tuning

| File | Change / reason |
| --- | --- |
| `scripts/gameplay/social_encounter.gd` | At the existing target-eligibility authority, reject queued targets, missing Health and nonliving target Health. The cached-report regression failed before this change and passed afterward. A live unseen target retains its original position snapshot and normal expiry. |
| `resources/missions/asset_recovery.tres` | Use an S-specific north layout and permit the already-existing `BetrayalEntry3` marker. South layout, authored relationships, all scheduling and finite allocations remain unchanged. |
| `resources/missions/s_encounter_north.tres` | Copy the Q north definition, changing only ID1 entry **EncounterNorthEntry → Spawn5** and ID2 entry **Spawn1 → BetrayalEntry3**. The existing East stock is now close enough for the allied carrier to collect before the underfilled opportunist approaches. Actors still choose their own stock, danger response, assessment, fight and exit. |
| `tests/gameplay_integration_test.gd` and `.uid` | Normal S scene/resources, physical integration fixtures, accepted-transfer conservation checks and lifecycle regressions. Tests deliberately arrange conditions; they do not change production decision policies or claim those arrangements are natural deployments. |
| Development records / README | Archive validation, compare seeds and document current checkpoint and remaining manual review. |

No weapon damage, spread, health, awareness radius, personality policy, movement speed or AI timing was tuned. Entry times remain **[0, 0, 35, 70, 105]**, deadline **180 s**, salvage **6/3/3 plus two installed components = 14 materials**, live Raider cap **5**, response budget **2**, and machine population **2**. Banking and objective requirements are unchanged. P/Q/R resources, layouts, profiles and reference scenes remain byte-identical to the audit manifest. The new definition is specific to normal S/T startup; it does not alter Q's comparison preset.

Health is checked on the **target**, not by requiring the attacking/source Raider to be alive during every eligibility query. This preserves S's deliberate lethal-hit attribution ordering: the dying victim's accepted-defeat callback still captures player-relative eligibility before ledger defeat, then emits accepted credit afterward. Ledgers retain exclusive quantity/transfer ownership, Recall retains settlement/persistence coordination, and mission rules retain deployment/world outcome policy.

No new system, central AI planner, alliance generator, machine role, weapon/equipment system, map, production asset, progression or networking was introduced. No Git staging, commit or publication was performed; existing accepted working-tree changes were preserved.

## Controlled opportunity comparison

The pre-T audit found no Raider-on-Raider damage, richer-ally qualification or assessment across five passive seeds. Initial allies left before their authored rivals arrived, and the opportunist usually filled its cargo first. A controlled S fixture already proved Q betrayal code worked; it did not establish ordinary opportunities.

One experiment moved the first two entries to the existing east positions **in both layouts**, without changing profiles or schedules. North produced a real assessment, betrayal, six damaging rival hits and a loaded Cowardly escape. South produced interrupted assessments, no rival damage, and substantially less allied-report activity. The south change was **not retained**: its established machine/cooperation opportunity did not need displacement. Only the north entry placement was retained. The [trial traces](../baselines/stage_t_delivery/east_entries_87018.json) and [south trial](../baselines/stage_t_delivery/east_entries_87017.json) are archived; the trial modified resources in its own process, never shared reference files on disk.

This is an opportunity correction rather than forced betrayal. It gives an existing underfilled opportunist and a richer visible ally a chance to meet. Current threat, health, range, visibility, uninterrupted assessment and actor policy still govern the outcome. Damage, player movement, machine interference or another actor can interrupt it. Neither an AI kill nor a specific winner is required. R's rejected compressed arrival schedule was not reintroduced.

## Completed integration matrix

“Normal observation” below means the unchanged final normal scene, live simulation clock and no AI/player intervention. “S fixture” means deliberately arranged normal-scene conditions and real production callbacks. Existing diagnostic suites continue to verify their own presets. Human acceptance remains a separate final column/checklist; a passing fixture is not a natural-frequency claim.

| System / authoritative owner | Enabled and initialized in normal mission | Exercised / verified evidence at delivery | Remaining limit |
| --- | --- | --- | --- |
| Input, movement, camera, jump/boost / player components | Shared robot after explicit Deploy; permissions gate death/observation | Existing controller/traversal tests, including S, plus graphical Deploy flow | Feel and previously deferred floaty jump remain manual. |
| Q personalities / Raider FSM + Combat composition | All three scheduled in each layout; no baseline armed-policy fallback for initial actors | Both layouts observed; new S fixture admits all five and asserts three policies; Q physical suites preserved | Two Greedy, one Cowardly, two Aggressive remain authored totals; early exits need not coexist with every later entry. |
| Allied, neutral, hostile relations / RaiderRelations | Existing pair template, responder relations and bounded betrayal mutation | S fixtures: hostile pair exchanges real damage under live cadence, ceasefire releases eligibility, neutral stock contest causes no hostility | Fixed templates are not dynamic alliance formation. Pair history is retained; active eligibility is invalidated. |
| Shared threat cooperation / RaiderSocial + Raider decision path | Per-admission component, direct local reports, 3 s expiry, independent movement | S fixture: one ally sees/fires on a guard while cover hides it from another; recipient physically investigates its snapshot without a squad. Expiry and target death are asserted | Natural south caches valid reports; successful cooperation does not require both actors firing simultaneously. |
| Betrayal / RaiderBetrayal | Existing ID1 component, Q profile, richer-ally/range/health/threat gates | Natural north assessment and pair hostility in four seeds plus repeated 87018; S fixture verifies interruption and ordinary combat/independent victim defense | Events are not mandatory; passive sample is small. No automatic cargo transfer. |
| Hostile combat, aim, LOS, damage / Combat + ShotExecutor + Health | Existing weapon predicate, muzzle ray, ordinary physical geometry | Natural north recorded 5–7 Raider-inflicted damage events; S rival fixture verifies reciprocal instigators and live movement/cover/cadence. All prior physical combat suites retained | No invented accuracy or lethality change; moving cover/airborne-target readability still needs director observation. |
| Navigation, cover, congestion / Raider physical owner + watchdog | Existing navigation map, reservations, steering, spacing and recovery | Every natural initial Raider resolves; S fixture starts five Raiders/two machines in a shared combat area and verifies multiple actors move within population caps | This does not certify every narrow passage or production map. Existing physical corridor suites remain relevant. |
| Contested salvage / MaterialLedger | Original finite stock and actor capacities; neutral actors choose independently | S fixture preloads two real units into a capacity-three Cowardly actor, then contests three units: it takes one, Greedy takes two, repeats cannot duplicate | Fixture positions/dwell are explicit, not a natural contest count. |
| Post-conflict cargo recovery / ledger + drop view + Social | Accepted death allocation, visible remembered drops, normal objective selector | S social conflict releases three units; survivor physically approaches/scavenges through unchanged selection, travels to an actual exit and completes dwell before extraction loss is recorded | Exit intent is arranged in the fixture after real pickup; do not call the entire chain an untouched natural outcome. |
| Equipment / EquipmentLedger + FlareDirector | Loadout on admission, death drop and timed player recovery | Actual S conflict/crowd produces finite gear, hold interaction recovers it, player death forfeits it once; full S recall flow banks gear once | Raider equipment equipping/weapon looting remains outside accepted scope. |
| Ground and flying machines / ecosystem + SupportMachine + awareness | Existing armed guard and unarmed flying scout, routes and expiring reports | Both operate in natural runs; both die in final samples, releasing finite components. S fixture verifies guard combat and target cleanup, existing ecosystem suites retained | Flying machine is a scout/spotter, not a missing armed role. No player-proximity activation requirement. |
| Encounters / EncounterSetup + arena | Seed resolves bounded authored layout before finite ledger/admission setup | Seven seeds plus one repeat; setup reproducible, five timed admissions, all initial actors resolve | Two arrangements, fixed schedule and fixed relation template remain the intended bounded variation. |
| Flares and reinforcement bounds / FlareDirector | Accepted Raider death, delayed response, finite ticket/shared live cap | S fixtures admit ID6/7 after real accepted deaths, preserve Q fallback/relations, reach five live actors after player death, and prove responder death cannot replenish budget | Passive runs had no Raider deaths or responses; constructed evidence is explicitly separate. |
| Player intervention / robot weapon + accepted defeat/objective events | Same physical weapon, hearing and mission callbacks | S fixture player intervenes in betrayal fight with actual lethal shots, receives personal credit and recovers cargo; existing S physical kill attribution test retained | Passive observation cannot establish active target difficulty or fairness. |
| Objectives, full/early recall and persistence / Objectives + Recall + stash | Briefing → Deploy, accepted owner observations, receipt-backed banking | S graphical flow and preserved S suites: completed/incomplete recall, actual recovery, save failure/retry, bank/forfeit, frozen results | Some controlled fixture screenshots show zero deployment seconds because coordinator time is held. Natural runs exercise the clock. |
| Deployment failure/world continuation / MissionRules + arena | Destruction settles player once while autonomous world can continue | New S crowd fixture checks both owners settle exactly once, subsequent real response activity and frozen result; natural north/south worlds continue after death | No speculative multiplayer death handling. |
| Developer and player spectating / shared camera + separate permissions | Existing debug flight vs restricted post-death follow | New S fixture verifies killer preference, cycling, no camera target/transfer, developer-flight rejection after death, target death/extraction and deadline. Existing spectator suites retained | Natural observation is not an exact deterministic camera-on/off outcome comparison. |
| Replay, Return and termination / arena + owners | Existing release, sealing, new deployment identity and retained banked stash | New S replay resets briefing, relations and budgets without banking forfeited loot; existing S/post-death suites verify Return, abandonment, save/restart and preset routing | Director should repeat the whole normal flow after extended observation. |
| HUD/audio/hit/death/recovery presentation / shared presentation components | Existing concise S HUD, F3 diagnostics, effects and feedback | Fresh Forward+ actual GUI Deploy→active→results flow; active and result captures visually inspected; earlier accepted presentation retained | Primitive models, overlapping in-world labels and combat readability remain refinement work; no new HUD/art pass. |
| Metrics/accounting / read-only observer + authoritative ledgers | Optional existing capture, no second economy or gameplay scheduler | Natural frame checks, accepted-transfer assertions in new suite, existing metrics tests; hashes and logs archived | Performance observations are local bounded checks, not production/export certification. |

## Seeded observations

Final configuration, **1×**, stationary vulnerable robot at Recall Dock, existing developer observation and restricted follow after death. No teleporting actors, granting cargo, changing relations or forcing states in these runs. Seven seeds **87017–87023**, plus repeat **87018**. [Summary](../baselines/stage_t_delivery/seeded_summary.json) and individual JSON/logs preserve actual events.

| Seed | Layout | Player death / world end (s) | Betrayals / Raider damage by Raiders | Shots / nav recoveries | Extracted / ground / original materials |
| --- | --- | --- | --- | --- | --- |
| 87017 | south | 17.32 / 111.18 | 0 / 0 | 30 / 2 | 13 / 1 / 0 |
| 87018 | north | 45.10 / 146.83 | 1 / 6 | 57 / 3 | 14 / 0 / 0 |
| 87019 | south | 17.32 / 111.18 | 0 / 0 | 30 / 2 | 13 / 1 / 0 |
| 87020 | north | 44.30 / 135.17 | 1 / 7 | 52 / 2 | 12 / 2 / 0 |
| 87021 | north | 43.50 / 138.63 | 1 / 6 | 52 / 2 | 14 / 0 / 0 |
| 87022 | south | 17.32 / 111.18 | 0 / 0 | 30 / 2 | 13 / 1 / 0 |
| 87023 | north | 44.30 / 138.63 | 1 / 5 | 46 / 2 | 13 / 1 / 0 |
| 87018 repeat | north | 45.10 / 146.83 | 1 / 6 | 57 / 3 | 14 / 0 / 0 |

All runs admitted five initial Raiders and ended with five extractions, no Raider deaths, two machine deaths, zero response tickets and observed peak two live Raiders. Thus the natural data demonstrate betrayal, damage, escape, machine combat and finite extraction, **not** a natural Raider kill/flare chain or maximum-load safety. The S fixtures deliberately cover those paths. No final unresolved Raider objectives remain. Every frame checked conservation, equipment validity, cap/budget and immutable player result; all passed. Audit buffers never reached 512 records and existing metrics discarded no events.

Compared with the five-seed pre-T baseline, south's shots, extraction totals and world duration remain the same; invalid post-death report intent no longer appears. North changes from no rival hits/assessment and a passive deadline at 180 s to natural social damage and autonomous world resolution at 135–147 s. This does not establish better subjective pacing: all material can still leave with Raiders if the player does nothing. Recovery is an active intervention opportunity, not a guaranteed free reward. The loaded Cowardly actor survives and extracts in these observations; no health or weapon tuning was added to force a kill.

The repeated 87018 reproduces setup and reported outcome here. Seed identity guarantees seeded configuration, not cross-hardware/frame-perfect physics or mandatory identical combat. Concurrent headless runs are not wall-clock performance benchmarks. Scout pursuit can alternate engagement/investigation through changing visibility; no indefinite unresolved Raider was observed, but the director should judge whether those airborne engagements remain fluid.

## Automated and graphical validation

Final result: **all 30 suites pass**, comprising the 29 accepted suites and `gameplay_integration_test.gd`. The first full run found two assertions caused by the new contested fixture incorrectly assuming Cowardly capacity was one. The unchanged profile actually holds three. The corrected fixture preloads two finite units through the ledger, then repeats the new complete suite successfully. The original full results and corrected focused result are retained separately; final validation records that correction rather than hiding it. No production tuning was introduced to make the test pass.

The dead-player regression failed on the old eligibility code, then passed on the corrected code, preserving living-target snapshots/expiry and frozen accounting. All accepted transfers during the new integration fixtures check both authoritative owners. Existing physical combat, traversal, social K/L/M, P/Q/R, objectives, persistence and spectator suites remain intact.

Godot 4.7.2 editor parsing/import, bounded default headless startup and actively deployed headless integration passed. Ten Forward+ startup checks passed: normal Asset Recovery, base Mission/Intercept, Single Raider, P, Q, R, Rivalry, Cooperation, Betrayal and Ecosystem. The **graphical S flow used the actual GUI mouse Deploy action**, physical pickup/weapon/recall paths and results/replay. [Active](../baselines/stage_t_delivery/active.png) and [success](../baselines/stage_t_delivery/success_result.png) captures were visually inspected; briefing/early/failure captures are also archived. These are automated graphical fixtures, not human acceptance.

Final suite, graphical, simulation and parsing logs contain no script errors, engine errors or warnings. The historical two-ObjectDB exit warning did **not** recur in this full run. Expected failures in the pre-fix regression and the initial new-fixture run are archived separately from final passing evidence.

### Bounded graphical population check

Forward+, **1600×900**, RTX 4060 Laptop GPU / Intel i7-14700HX. A deliberately arranged S fixture admits all five finite initial IDs immediately, preserving real Q decisions, both machine controllers, normal physics and existing stock. It then observes 600 rendered process frames, discarding the first 61 samples as warmup. Tests ran sequentially after the other validation processes finished.

| Existing metrics capture | Retained frames at five Raiders + two machines | Median / p95 / max frame interval (ms) | Simulated observation |
| --- | --- | --- | --- |
| Off | 539 | 4.190 / 5.729 / 6.497 | 2.50 s |
| On | 539 | 4.166 / 5.520 / 6.787 | 2.48 s |

Both checks retained conservation and live/response bounds. The small difference does not establish a speed improvement from metrics; these are short local frame-interval samples, not CPU/GPU profiling or a sustained production benchmark. The separate automated crowd case exercises five Raiders/two machines in close physical combat for five simulation seconds. Neither replaces extended director play-testing or performance checks on a future production map/export.

Final logs and performance JSON/source are recorded in the [evidence directory](../baselines/stage_t_delivery/README.md). No packaged export or cross-hardware certification was attempted.

## Checkpoint T director review

1. Start normally with F3 hidden; confirm briefing, Deploy, objectives and accepted movement/aim/jump/boost. The default **87017 south** setup remains. In active S, **Ctrl+Shift+F5** prepares the next seed; Deploy **87018 north** to review the new social opportunity. Restart repeats the current seed.
2. Observe several seeds with F1/Tab/F. Compare independent personalities, allied reports and machine encounters. In north, watch the early loaded carrier/opportunist opportunity; then intervene or ignore it. Betrayal is conditional, and exact winners are not acceptance requirements.
3. Intercept a loaded carrier, contest/recover finite cargo and hold E for gear. Judge whether the new entry placement leaves a reasonable interception/recovery window and whether pursuit/cover/airborne-target movement looks fluid. Neutral competition must not automatically become hostility.
4. Recall with fewer than three materials, then repeat with at least three. Check banked inventory, incomplete versus successful primary goals and optional personal kill credit. Nonlethal damage alone must not reset recall.
5. Die carrying material/equipment, Spectate, cycle targets, observe deaths/extractions/arrivals and Return. Failure, forfeiture, player duration and reward/objective result must remain fixed. Developer flight must not be available through normal post-death controls.
6. Restart and advance seeds after extended observation. Confirm fresh briefing/actors/relations/budget and intact banked stash. Use prior diagnostic presets for crowded passage and rare condition comparison; record seed and actor IDs for any stall or decision loop.

**Checkpoint T is accepted.** The director stated "Stage T is approved" on 2026-10-21. The accepted baseline includes the subsequent decision-stability correction and its 31-suite validation, rather than only the original delivery outcomes above. The [Stage U proposal](../plans/phase_7_stage_u_world_expansion_plan.md) is prepared for layout/architecture approval; no expanded level has been constructed. Production assets and broader AI/economy changes remain separate scope.
