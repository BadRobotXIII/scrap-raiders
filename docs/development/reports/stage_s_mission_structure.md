# Stage S - mission structure, objectives and deployment flow

Delivered: **2026-10-21**. Status: **Checkpoint S accepted by the director on 2026-10-21**, following the delivery. The director confirmed acceptance with "Approved". This records overall stage acceptance; it does not claim additional unrecorded test sessions or cross-hardware results. The director approved the [Stage S proposal](../plans/phase_6_stage_s_mission_structure_plan.md). Stage R remains accepted. No Stage T work, Git commit or publication is included.

## Playable mission

Normal project startup now opens **Operation: Asset Recovery** at its briefing. Run `godot --path .` or use the editor's project Run command, then click **Deploy**.

- Required: bank **3 material units** and survive a successful player recall.
- Optional: bank at least **1 equipment item** and personally defeat **1 hostile Raider**.
- Fourteen finite material units, five scheduled Raiders, two allied support machines, the accepted Q personalities/relationships/layouts, the accepted R arrival schedule, the shared five-Raider live limit and two-responder budget remain unchanged.
- Recall still requires five seconds at the dock. Nonlethal hits do not cancel it. Existing movement/fire/traversal, nearby-loot priority and save-failure rules remain authoritative.

The player recovers dropped cargo; original salvage stock is not directly collectable by the robot. Three material units exceed the two machine components alone, encouraging interception of loaded Raiders without inventing loot or directing AI. No seed guarantees success. The mission can be left early: extraction below target banks the actual inventory and reports **EXTRACTED - PRIMARY INCOMPLETE**. Optional objectives never block recall.

The new briefing is a local preparation gate, not a SceneTree pause or another mission FSM. It permits only briefing input while the world subtree is disabled. Clock, admissions, responses, actor movement, shots, recovery and recall cannot advance before Deploy. The graphical regression clicks the actual button while world processing is disabled; repeated start calls are rejected. Existing presets bypass preparation and retain immediate start.

S's HUD shows mission/time, carry-to-bank readiness, required extraction and optional progress. Carried materials do not get a banked-completion checkmark. Accepted recovery notices, hull/hit/damage feedback, traversal and interaction remain shared. Briefing/results panels are opaque for readability; traversal feedback now respects inherited processing state during preparation. F3 retains developer diagnostics separately from normal objective presentation.

At the end, the result shows mission outcome, required/optional statuses, picked-up/banked/forfeited materials and equipment, and player deployment duration. **Prepare next deployment** or R recreates S at the briefing with a fresh receipt/model/ledgers and the same seed/save path. Banked stash inventory persists.

## Ownership and event flow

| Concern | Implemented owner |
| --- | --- |
| Mission definition | Existing `MissionConfig`, extended with mission ID, description/risk, preparation/concise-HUD flags and typed objective Resources. Legacy definitions default to empty objectives and existing behavior. |
| Objective data/status | `MissionObjectiveDefinition` defines bank-materials, bank-equipment, extract and hostile-Raider defeat goals. One arena-owned `MissionObjectives` derives progress and owns frozen objective/result state. |
| Deployment lifecycle and outcome policy | Existing arena coordinator and `MissionRules`. A single started gate covers preparation; successful extraction accepts required-objective satisfaction, defaulting to legacy success when no objective model exists. |
| Inventory/persistence | Existing MaterialLedger, EquipmentLedger, RecallController and PersistentStash. No ledger, stash schema, receipt key or reward amount was changed. |
| Presentation | `MissionObjectivesView` reads detached snapshots and requests Deploy. The coordinator owns player input/weapon enablement and lifecycle changes. |
| Independent simulation/observation | Existing actor FSMs, combat/navigation, machines and both spectator systems. Developer flight now also rejects entry before deployment starts. |

A dedicated gameplay-objective setup hook runs before admissions, independently of the existing optional debug-observer hook. Objective progress listens to accepted ledger notifications with per-owner serial protection, but reads quantities directly from ledger locations. Picked-up material is recovered + banked + forfeited player material; equipment uses the equivalent item locations. Pickup and later banking are not counted as separate acquisitions. Lifetime stash totals never satisfy a new mission.

For combat credit, the coordinator captures the registered victim, lethal Health instigator and player-relative eligibility **before** accepting ledger defeat, then emits one accepted-defeat event only after that mutation succeeds. This matters because an eligibility query after defeat would reject the now-resolved Raider. The objective owner credits the deployment robot's lethal hit once per victim, rejecting duplicate/old-deployment events and other instigators. Unknown-origin damage, allied-machine kills, other Raiders' kills and practice targets do not grant this objective. There is no new hostility rule: Raider-to-Raider neutrality/competition remains separate from hostility toward the robot. No hostile-machine goal was added because current machines support the player.

Successful recall preserves ordering: revalidate channel, commit/verify the stash receipt, settle both ledgers, explicitly reconcile required goals against the two settled owners and confirmed extraction, then complete MissionRules and freeze the result. Save failure leaves the model open and deployment cargo intact for retry. Early incomplete extraction sets `player_extracted` but fails the primary mission verdict; it never runs forfeiture on banked loot or rewrites the receipt.

Death/deadline use the accepted failure/settlement path. A one-time player-result hook runs after settlement and before post-death choice/observation. The result is frozen there, even if the world continues. Later loot, actor deaths, reinforcements, extraction, spectator selection and observation duration cannot change objectives, player duration or rewards. Return stops observation and presents that same result. Replacing an active S deployment with a development preset records abandonment and forfeiture once; opening a report never settles anything. Signal/HUD ordering and deferred debug-metrics finalization are not responsible for closing the objective model.

Definition validation covers identity, target/kind validity, duplicate IDs, required primary/extraction goals, compatible recall/equipment features and material targets within each configured layout's finite pool. Objective snapshots/results are deep detached copies. Scene teardown disconnects ledger observers.

## Routing and compatibility

- `project.godot` now starts `scenes/levels/asset_recovery_arena.tscn` (scenario 16). This was the explicit S startup promotion in the approved plan, performed after explicit-scene flow tests passed.
- `mission_arena.tscn` still defaults to Intercept when launched directly. N/P/Q/R scenes, configs, layouts and profiles remain unchanged as references.
- **In-game F5** still selects N. The editor's project Run/F5 now starts S through the configured main scene; these are different contexts.
- Existing development preset keys remain available after Deploy. While actively in S, **Ctrl+Shift+F5** prepares S with the next seed. Existing P/Q key behavior is unchanged. Normal restart keeps the current seed.
- Leaving active S for a debug preset ends that S deployment and forfeits unbanked cargo; it does not clear the persistent stash. Debug references retain their existing policy and immediate-start behavior.

## Validation results

**All 29 suites pass:** the 27 accepted suites plus `mission_objectives_test.gd` and `deployment_flow_test.gd`. The full runner initially reported one traversal failure because its all-config loop now included S without pressing Deploy. Its setup now starts a preparation-gated scenario first, preserving every physical jump/boost assertion; the focused rerun passed for S and all references. Initial and final results are retained in the [evidence directory](../baselines/stage_s_delivery/validation.json). Final focused deployment/R regression reruns also passed after setup-hook/presentation cleanup.

New coverage includes config parsing/invalid targets, objective initialization/reset, carry versus bank semantics, duplicate transfer/kill protection, detached inspection, required versus optional goals, physical cargo pickup, timed equipment recovery, actual player hitscan attribution, no automatic mission completion on a kill, early recall, save failure/retry, success and exact banking, death/deadline forfeiture, frozen post-death results, continuing arrivals and physical machine movement, Return, restart, abandonment, same/different seed configuration, S next-seed routing and unchanged in-game F5/N routing. The existing tests continue to cover physical combat/navigation, reinforcement bounds, social AI, accounting, save/retry and camera ownership.

Godot **4.7.2** editor parsing/import passed. Bounded default S headless startup (600 frames), default Forward+ briefing startup (180 frames), the full scripted Forward+ briefing-to-results flow, and explicit Forward+ R reference startup passed. The graphical flow used the actual Deploy mouse interaction and captured the [briefing](../baselines/stage_s_delivery/briefing.png), [active HUD](../baselines/stage_s_delivery/active.png), [early extraction](../baselines/stage_s_delivery/early_result.png), [success](../baselines/stage_s_delivery/success_result.png) and [failed result](../baselines/stage_s_delivery/failed_result.png); these images were visually inspected. They are controlled fixtures, not human gameplay acceptance. Some fixture screenshots show zero deployment seconds because the coordinator clock is deliberately held while interaction boundaries are advanced; natural runs below exercise the live clock.

**Warnings:** the legacy extraction suite's known **two ObjectDB instances leaked at exit** warning recurred in the full runner while all its assertions passed. No Stage S error/warning appeared in final focused or graphical logs. No audio resource/controller was changed; this existing test-cleanup warning remains separate from gameplay/test failures. During test development, log inspection caught and corrected a wrong aim-method reference despite its process returning zero. Headless tests invoke the Deploy button's signal because headless mouse-coordinate routing is not graphical GUI acceptance; the separate Forward+ flow tests actual GUI mouse delivery. Final focused logs are clean. No packaged export or cross-hardware performance claim is made.

### Natural simulation observations

Two additional **1x**, bounded, stationary-player deployments used debug observation without intervening in AI decisions or inventory. The robot remained physically present/vulnerable; after death the harness entered existing restricted follow.

| Seed / layout | Player deployment end | World end | Shots | Accounting/cap checks | Player result after later simulation |
| --- | --- | --- | --- | --- | --- |
| 87017 / south_patrol | Destroyed at 17.32s | 111.18s, autonomous actors resolved | 30 | Passed; peak 2 Raiders | Frozen failed result, no new objective credit/reward |
| 87018 / north_contest | Deadline at 180.00s | 180.00s | 44 | Passed; peak 2 Raiders | Expired result, no invented recovery/banking |

Both configurations admitted their independent actors, preserved material/equipment invariants and reinforcement/live-population bounds, and retained immutable player results. These passive runs do not establish active-player target difficulty, good pacing, mandatory combat winners or mission enjoyment. No balance tuning was introduced to improve their outcomes. [Raw observations and the bounded harness](../baselines/stage_s_delivery/natural_observations.json) preserve the evidence.

## Files changed

New runtime files: `scripts/gameplay/mission_objective_definition.gd`, `scripts/gameplay/mission_objectives.gd`, `scripts/presentation/mission_objectives_view.gd`, `resources/missions/asset_recovery.tres`, `scenes/levels/asset_recovery_arena.tscn`. New suites: `tests/mission_objectives_test.gd`, `tests/deployment_flow_test.gd`; generated script UIDs are included.

Existing changes relative to accepted R: `mission_config.gd`, `mission_rules.gd`, `mission_arena.gd`, `raider_arena.gd`, `recall_controller.gd`, `flare_director.gd`, `developer_spectator.gd`, `traversal_feedback.gd`, `tests/traversal_test.gd` and `project.godot`. README, development index, checkpoint register and approved-plan status describe the delivered flow. See the [source change list](../baselines/stage_s_delivery/source_changes.json) and [source hashes](../baselines/stage_s_delivery/source_manifest.json).

Accepted uncommitted P/Q/R work was preserved. Ledgers, stash, AI/combat/profile resources and reference scenes were not overwritten. `.godot/` and builds remain ignored; evidence is outside the game import pipeline under the existing `.gdignore`. No Git staging, commit or publication was performed.

## Checkpoint S manual review

1. Start the project normally. Read the briefing, confirm the world waits, click Deploy, then verify movement/jump/boost and the concise goals with F3 hidden.
2. Intercept a loaded Raider, recover cargo with E, and confirm carry readiness stays pending until recall. Recover equipment using the existing hold-E interaction; verify its optional progress. A direct player lethal hit should grant one Raider credit; an AI kill should not.
3. Recall with fewer than three materials. Confirm inventory banks but the primary is incomplete. Prepare again, bank at least three and confirm mission success; optional goals must not prevent either recall.
4. Test destruction and deadline with cargo. Confirm forfeiture once and preserved stash. Spectate survivors, cycle targets, wait for later deaths/extractions/arrivals, then Return: the player result and deployment duration must remain unchanged.
5. Repeat with the same seed; use active S Ctrl+Shift+F5 for another seed. Check fresh goals/receipt/cargo and preserved banked inventory. Verify reference presets, in-game F5/N, developer camera and return/restart behavior.
6. Judge briefing/HUD/debrief clarity, interception opportunities and whether three units is an appropriate first mission target during actual play. Note seed/time/actions for difficulties; no outcome is guaranteed or forced.

The ledger's full manual acceptance matrix remains applicable. The checklist above is retained for future regression and refinement. Overall stage functionality is accepted; mission target balance, unusual resize/accessibility conditions and long-session performance remain areas for future observation. No rewards for optional goals, progression, equipping, crafting, new enemies/weapons, maps, frontend framework or networking were added. **Checkpoint S is accepted.** No Stage T scope or implementation is started; commits/publication remain separately authorized actions.
