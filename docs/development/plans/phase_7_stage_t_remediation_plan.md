# Stage T: focused integration remediation proposal

Prepared **2026-10-21**. **Approved by the director on 2026-10-21; implemented and validated for Checkpoint T manual review.** See the [delivery report](../reports/stage_t_full_gameplay_integration.md) for actual corrections, retained/rejected placement experiments, tests and remaining acceptance. The proposed sequence below is preserved as approved scope. Scope follows the [complete director ledger](../ledgers/phase_7_stage_t_integration_audit.md). The [repository audit and integration matrix](../reports/stage_t_integration_audit.md) and [five-seed evidence](../baselines/stage_t_audit/summary.json) remain the historical baseline. S is accepted; T manual acceptance remains pending.

## Proposed result

Keep the current mission architecture and make its social/combat/loot paths demonstrably work together in **normal Asset Recovery**. Correct one reproduced dead-target lifecycle defect. Add the integration evidence missing from otherwise passing isolated suites. Change normal scenario opportunities only when traceable configuration evidence warrants it; no scripted winner, betrayal or kill quota.

## Corrections, evidence and affected systems

| Order | Evidence / correction | Files and ownership | Expected result / risk |
| --- | --- | --- | --- |
| 1 | A destroyed robot remains eligible for a fresh allied report during post-death world continuation. Require a valid living target at the existing eligibility boundary; retain current registration/relationship checks. | `scripts/gameplay/social_encounter.gd`; regression in a normal-scene integration suite, with existing social/post-death suites retained. Modify `raider_social.gd` only if the death test demonstrates a stale retained report intent still needs release through the existing FSM path. | Dead target cannot be accepted or retained as an eligible report. Risk: over-clearing valid unseen living targets. Test stored-position pursuit and normal expiry explicitly; do not grant live target tracking. |
| 2 | Existing K/L/M/Q tests largely instantiate diagnostic presets; normal S flow does not prove their combined chains. Extend coverage through actual S scene, resources, callbacks and physical actors. | New `tests/gameplay_integration_test.gd` and generated `.uid`, plus narrowly relevant existing suites if needed. Use ignored, isolated saves. No new production test hook or global state. | Reproduce physical shots, movement, pickup and extraction across real integrations rather than only calling policy functions. Risk: artificial fixtures hiding normal gating; retain separate untouched seeded observations and record every arranged condition. |
| 3 | Initial allied pair exits before later authored hostile pair arrives in all five passive baselines; no richer-ally betrayal opportunity sampled. Investigate eligibility/opportunity traces, then try one normal-only arrangement group if warranted. | `resources/missions/asset_recovery.tres`; if necessary new S-specific `EncounterLayout` resource copies using existing arena markers/routes. Do **not** mutate shared `q_encounter_*.tres`, Q profiles, reference presets or add a new map/director. | Permit ordinary eligible actors to coexist and make autonomous decisions. Risk: continuous firefight, lost recovery window, broken personality roles. Compare identical seeds, leave actor damage/accuracy/health/policies/budgets unchanged, reject regressions. |
| 4 | Natural samples never reached configured population cap or triggered flares; Stage T graphical active-player validation is missing. Exercise those existing paths deliberately and repeat complete regression. | Same integration suite; bounded validation harness and evidence archive, report/checklist. Reuse current metrics and finite budgets. | Demonstrate safe peak interactions, responder allocation, player intervention and cleanup without inventing accounting or production telemetry. No performance claim from concurrently launched headless probes. |

Step 3 is a constrained experiment, not a predetermined tuning change. First determine whether existing ordinary player intervention and normal configured opportunities already satisfy reachability. Test retained neutral competition, allied shared threats and loaded-victim opportunity without calling betrayal commit or spawning test cargo in ordinary runs. If a correction is justified, prefer existing marker/profile placement and stock-access geometry so compatible actors overlap naturally. Adjust admission timing only if that addresses the measured cause without repeating R's rejected global compression. Preserve finite totals, all three Q personalities, neutral competitors, the five-live cap and two-ticket response budget.

Do not retain a scenario candidate merely because it produces one desired betrayal. Require valid opportunity traces across both layouts and multiple seeds, conservation and physical progress, then director observation of actual behavior. If only an excluded new system could satisfy a requested result, document it and return for scope review instead of expanding T.

## Normal-scene integration coverage

Tests may arrange positions, occlusion, damage or **ledger-backed** finite cargo to create valid conditions. They must state those changes. They must not replace the normal config with K/L/M data and then claim ordinary integration. Actual actor movement and physical firing are required for physical claims. Avoid assertions that a particular personality must win.

| Scenario | Assertions to add or reuse |
| --- | --- |
| Three personalities and scheduling | Both S seeded layouts admit their configured Q policies; all three represented over the entry schedule, independent objectives preserved. Do not require simultaneous presence after early exits. |
| Allied cooperation / machine pressure | A current direct sighting can produce an expiring allied report and physical shared-threat response without squad ownership. Occlusion/report expiry/death/attitude changes remove eligibility; no unseen firing or camera target. |
| Hostile rival engagement | Normal hostile pair produces valid aim warning, LOS shot, actual damage instigator and retaliation. Allied/neutral bodies block without illicit damage. Ceasefire/extraction/death releases interest. |
| Betrayal / post-conflict loot / cargo extraction | Normal opportunist with actual ledger-backed richer ally enters/cancels/commits existing assessment under valid/invalid conditions. Only that pair changes attitude. Subsequent real combat can release finite cargo; surviving actor physically discovers, collects and extracts it once. Do not bypass Q policy or prescribe winner. |
| Contested stock and recovery | Multiple actors/player contend for one allocation; capacity-limited partial transfer and later requests cannot duplicate it. Material/equipment views match authoritative ownership. |
| Flare and responders | Real accepted Raider death emits existing flare; local delay, finite response admission, normal Q fallback and authored social attitudes, shared live cap and depleted budget remain correct, including after player death. |
| Player intervention | Actual player weapon can interrupt autonomous combat, credit only an eligible personal lethal hit, recover finite material/equipment and affect existing AI without changing relation policy. |
| Objectives / full and early recall | Reuse S `deployment_flow` physical recovery, save retry, receipt checks and completed/incomplete objectives; add chained encounter recovery where missing. Banking once is independent from required-goal verdict. |
| Destruction / observation / mission completion | Forfeit both owners once, freeze player result, continue physical autonomous combat/pickup/entries/extraction; cycling and target death/extraction cannot alter that result. Deadline/Return ends world and seals late transfers. |
| Restart / conservation / congestion | Fresh identities/reports/relations/owners/budgets on replay, stash unchanged except confirmed receipts. Check invariants after each accepted transfer and during physical five-live/two-machine contact/recovery, not only policy decisions. |

Keep all 29 existing suites. Test names above describe coverage, not an obligation to duplicate assertions that existing S suites already make. One additional focused integration suite plus the small dead-target regression should be sufficient unless concrete failures justify more.

## Validation and controlled comparison

1. Preserve this audit's 216-file source hashes and five untouched seed traces. Implement the T1 failing regression first, then the local correction and living-target/expiry cases.
2. Run the new physical S integration coverage, existing social/Q/combat/spectator/S suites and the complete suite. Inspect log contents as well as exit status. Track the existing two-ObjectDB warning in `flare_loot_test` separately; investigate new runtime warnings rather than dismissing them as legacy.
3. Re-run **87017–87021** at 1× with the same stationary vulnerable robot and observation permissions. Record layout/profile/entry config, actual damage instigators, qualifying opportunities, actor lifetimes, extraction quantities, watchdog recoveries, tickets, accounting and frozen player result. Add at least two seeds and repeat a seed for reproducible setup. No mandatory death/betrayal count.
4. If Step 3 configuration changes are needed, compare one related group at a time against those seeds. Preserve shared P/Q/R reference resources byte-for-byte. Reject increased stalls, oscillation, unavoidable opening combat, excessive response pressure or shortened recovery windows even if the candidate creates more social fights.
5. Run Godot 4.7.2 parsing/import, bounded default startup, actively deployed headless smoke and Forward+ startup **plus active integrated mission**. Validate GUI Deploy, ordinary HUD, actual recovery/recall, death/follow/Return and replay; repeat the diagnostic preset smoke routes. Isolate saves from the director's stash.
6. At configured peak population, record bounded frame-time/actor-count observations on this machine with diagnostics selection stated. Report hardware, duration and limits; do not generalize to export/cross-hardware performance.
7. Deliver Checkpoint T report with completed matrix, exact changes/tuning values, retained/rejected candidates, raw baseline comparison, test/log results, remaining limits and Stage U readiness recommendation. Stop for manual acceptance.

## Director play-test checklist

| Normal Asset Recovery test | Expected evidence |
| --- | --- |
| Briefing → Deploy, F3 hidden | Clear objectives, waiting world before Deploy, normal movement/aim/jump/boost afterward. |
| Observe both layouts and several seeds | Greedy/Cowardly/Aggressive appear over entries, act independently; different seeds can share an authored layout. |
| Passive observation, then active intervention | Machines/Raiders scavenge/fight/extract without player proximity; player can choose to engage, interrupt or recover afterward. |
| Allied shared threat and hostile rivals | Eligible allies can cooperate without a squad; neutral competition does not automatically become hostility; hostile actors can exchange physically valid fire. |
| Valid betrayal opportunity over repeated deployments | Healthy underfilled opportunist can consider a richer nearby ally; threat/damage can cancel. No guarantee every deployment betrays or that a particular actor wins. |
| Loot contest and Raider extraction | Finite drop remains correct through competing pickup, death/recovery and completed or interrupted extraction. |
| Player recovery → full/early recall | Actual recovered material/equipment and optional kill progress match results. Early recall banks without falsely completing the required goal. Nonlethal damage alone does not restart recall. |
| Death → Spectate → cycle/extracted or dead target → Return | Failure/forfeiture happens once, world continues, targets switch safely, camera has no control/perception effect and results stay frozen. |
| Debug flight → exit, restart/next seed | Robot stays physical/vulnerable, controls return when eligible, no stale reports/relationships/budgets, prior stash preserved. |
| Maximum configured crowd / deadline | No persistent body stall, uncontrolled response growth or late accounting transfer; world shuts down cleanly. |

All mechanics must be demonstrably reachable through the normal configuration across runs; constructed tests alone are insufficient for final ordinary-play acceptance. Exact combat winners and event frequency are not scripted acceptance conditions.

## Approval boundary and exclusions

The requested next approval covers the local eligibility correction, focused normal-scene tests and measured normal-only integration corrections described here. No new AI controller, relationship system, personality, weapon, machine role, equipment equipping, progression, map, production asset or multiplayer work. Any broader architecture change needs a concrete reproduced problem and separate discussion.

The ledger explicitly says **“Stop for director approval before modifying code.”** That boundary was honored: the director approved this plan before implementation. The delivered work now stops at Checkpoint T for manual review. **Stage U, Git commits and publication are not authorized.**
