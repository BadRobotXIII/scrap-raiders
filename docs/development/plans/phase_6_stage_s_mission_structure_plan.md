# Stage S: mission structure, objectives and deployment flow

Prepared: **2026-10-20**. Status: **implemented, validated and accepted at Checkpoint S on 2026-10-21**. See the [delivery report](../reports/stage_s_mission_structure.md). Checkpoint R is accepted. The [supplied Stage S ledger](../ledgers/phase_6_stage_s_mission_structure.md) is archived unchanged. This proposal is based on the current repository, not assumed delivery of future ledger features.

## Recommended delivery

Build **Operation: Asset Recovery** on the accepted R composition. Add a small briefing, explicit objective definitions, one mission-local objective evaluator and a settled player result. Reuse the existing arena coordinator, MissionRules, RecallController, ledgers, stash and spectator composition. Do not replace the mission controller or add a second deployment FSM.

Proposed mission settings:

| Setting | Initial definition |
| --- | --- |
| Mission identifier | `asset_recovery` (definition identity, not the unique stash receipt) |
| Premise | Intercept independent Raiders and secure assets from the automated salvage facility. |
| Required primary | **Bank at least 3 material units through successful recall.** |
| Required extraction | Survive and extract; mission success always requires successful player extraction. |
| Optional recovery | **Bank at least 1 eligible equipment item.** The existing recovery action can collect a two-item loadout; count actual ledger items, not bundles. |
| Optional combat | **Personally defeat 1 eligible hostile Raider.** Other actors' kills and practice targets give no credit. |
| Existing environment | Both Q/R layouts, Q profiles/relations, five scheduled Raiders, two machines, 12 salvage units plus 2 allocated machine components. |
| Existing limits | 180 seconds; arrivals `[0, 0, 35, 70, 105]`; at most five live Raiders and two committed responder tickets. |
| Existing extraction | Recall Dock, five seconds, nearby-loot priority and accepted cancellation rules; nonlethal damage does not interrupt recall. |

Materials currently have unit quantities, not individual prices. Use **three units**, not an invented material value or currency. Three is a modest initial threshold within the fourteen-unit pool and exceeds the two machine components alone: a player generally must intercept loaded Raiders or recover their dropped cargo. Original salvage stock cannot currently be picked up directly by the player. The briefing must explain interception/recovery rather than imply a new salvage interaction. Success is not guaranteed by a seed, and late or empty Raider deaths may provide no materials. The target is an initial mission definition for review, not a new balance claim.

## Repository findings

| Existing owner/path | Verified current behavior and implication |
| --- | --- |
| `scenes/levels/mission_arena.tscn` | Inherits `test_arena.tscn`, installs `mission_arena.gd` and expands the arena geometry. It is still the project startup scene and defaults to Intercept. |
| R scene/config | `refined_extraction_arena.tscn` inherits the existing encounter scene chain. Scenario index 15 selects `refined_extraction.tres`; R is explicit-launch and has no briefing or objective definitions. |
| `mission_arena.gd::_ready()` | Resolves config/seed/layout before base initialization. The base constructs ledgers, recall, machines, relations and spectator support; the existing observer hook runs before deployment/admission. No preparation gate currently exists. |
| Scheduled start | `deploy_raiders()` queues finite IDs; `process_entries()` admits them after navigation/clearance/cap checks. Arena physics advances the deployment clock immediately. Preparation must gate the whole mission, not just this clock. |
| `MissionRules` | Owns HUNTING/RECOVERING/SUCCEEDED/FAILED and a separate RUNNING/FINISHED world state. Currently any successful player recall sets SUCCEEDED; it has no objective policy. |
| `RecallController.complete()` | Rechecks eligibility, writes/verifies the stash receipt first, settles both ledgers, calls `MissionRules.complete_extraction()`, then finishes the mission. Save failure cancels recall for retry while retaining deployment cargo. |
| Player death | `_on_player_destroyed()` fails the deployment; `finish_mission()` invokes `terminate_player()` once. Recall settles forfeiture, disables player controls and offers Spectate/Return while the world may continue. |
| World shutdown | Separate from player termination. Return, deadline or no surviving/pending actors ends observation, stops/seals world systems and presents the summary. |
| Ledgers | Material/equipment transfers validate invariants and emit accepted operation metadata with serials. Player settlement is one-shot; rejected/duplicate operations do not emit accepted transfers. Recovered, banked, forfeited, ground and Raider-extracted categories remain distinct. |
| `PersistentStash` | Sole persistent writer; verified atomic writes and deployment receipts provide idempotent banking. It does not currently store objective progression, and does not need to. |
| Existing summary | Uses mission phase for the title and live world totals. During post-death observation later AI activity can change those world totals. S needs an immutable **player deployment result** alongside any explicitly labeled later world report. |
| Restart | Existing scene replacement preserves scenario, seed override, stash path and capture selection, while rebuilding runtime owners. All existing presets auto-start and must retain that behavior. |
| Kill eligibility | Raiders regard the robot as an eligible opponent independently of their attitudes toward other Raiders. Current support machines ally with the robot and attack Raiders; no hostile machine role is present. |

The accepted R report records 27 passing suites and N/P/Q/R startup checks. During this architecture review, **editor parsing/import, `mission_test.gd` and `refined_extraction_test.gd` were rerun successfully**, with clean logs. These are current focused checks, not a fresh full-suite, graphical or Stage S validation claim. Logs are local ignored `.godot/stage_s_review_*.log` files.

Git contains substantial accepted, uncommitted P/Q/R work. Preserve it. This proposal does not stage, commit, reset, publish or overwrite that work.

## Ownership and minimal additions

| Concern | Owner / proposed change |
| --- | --- |
| Deployment start, scene replacement, event orchestration | Existing arena/coordinator. Add one explicit preparation/start gate for S, not another controller. |
| Terminal outcome policy | Existing `MissionRules`; accept required-objective satisfaction as an opt-in policy input on the existing extraction completion path. Legacy calls/defaults retain current behavior. |
| Objective definitions | Small typed Resource, proposed `MissionObjectiveDefinition`, referenced by `MissionConfig`. Data only; stable ID, description, kind, target and required/optional designation. |
| Runtime objective status | One `MissionObjectives` instance owned by the arena, preferably RefCounted/event-driven. Stores objective status, accepted kill identities and a frozen result; never owns materials, equipment, health, movement or persistence. |
| Materials/equipment | Existing ledgers exclusively. Queries and accepted notifications are used to refresh derived progress. No shadow inventory or objective-specific loot. |
| Banked inventory | Existing `PersistentStash` exclusively. Keep the current schema, receipt identity and reward amounts. Objective success does not grant a second reward or undo banking. |
| Briefing, HUD, debrief | One small presentation component under the existing Overlay. Reads detached objective/result snapshots and requests actions from the coordinator; no outcome, transfer or start flags owned by widgets. |
| Observation | Existing developer/post-death spectator systems. Objective state is independent of HUD visibility, metrics capture and camera position. |

Initial objective kinds should be only what this mission uses: **bank materials, bank equipment, successfully extract, defeat eligible hostile Raiders**. Material/equipment kind names explicitly establish banked completion semantics. Do not prebuild alternate material-price systems, dependency graphs, arbitrary scripting conditions or a generic machine-objective pipeline. A hostile-machine objective can be added only when an existing eligible hostile machine role actually warrants it; killing an allied guard/scout must not satisfy S's combat objective.

## Material meaning and objective status

Keep these distinct in code and UI:

| Meaning | Authoritative source / use |
| --- | --- |
| Picked up in this deployment | Current recovered + banked + forfeited player material categories. These mutually exclusive locations describe previously recovered units; do not add another collection counter. Equipment uses the equivalent item locations. |
| Currently carried by player | Material `recovered_materials` and equipment RECOVERED items, as in R. Useful for immediate extraction readiness. |
| Successfully banked this deployment | Material `banked_materials` and equipment BANKED items, after a successful receipt/settlement. These complete S's recovery objectives. Do not use the lifetime stash total. |

Before recall, show **“Carry 3/3 — extract to secure”**, not a completion checkmark for a banked-material objective. The actual banked objective remains pending. After accepted banking, show completed banked progress. Optional player-kill progress can complete during play and stays visibly completed; a later failed deployment still fails overall and grants no objective reward.

Use a small set of objective statuses: pending/in progress, completed, and unmet at terminal failure/expiration, with readiness derived separately from current cargo. Required objectives gate mission success, optional objectives never block recall. Completed statuses are idempotent. Frozen terminal results distinguish unmet-at-extraction, death failure and deadline expiry; no speculative early failure because Raiders took some loot. No post-settlement progress or retroactive credit from the continuing world.

Objective configuration validation rejects duplicate/empty IDs, unsupported kinds, invalid/nonpositive targets, missing primary/extraction requirements, and incompatible feature flags (for example banking without player extraction/equipment support). Validate material targets against the configured finite pool for each supported layout, without promising the player can always obtain that stock. Empty objective arrays keep every existing preset on its legacy policy and UI.

## Preparation and lifecycle mapping

Preparation is the only new lifecycle gate needed. It belongs to the existing coordinator and defaults to already started for legacy presets. S requires an explicit Deploy action, with repeated requests ignored.

Construct and validate the mission while its inherited world subtree has processing disabled; keep only the briefing controls able to receive input. Navigation initialization and stash reads may occur, but no deployment clock, Raider/machine AI, entry/reinforcement scheduler, shots, player movement, recall or actor-driven transfers may advance while briefing is open. Do not merely stop arena physics and leave children running. Use local process/input gating rather than pausing the whole SceneTree, with authoritative action/admission checks also rejecting pre-start requests. Configure this before children can simulate. Clear buffered player actions, consume the Deploy action and restore mouse capture cleanly when enabling simulation.

| Ledger concept | Existing state to use |
| --- | --- |
| Preparation | S coordinator's not-started gate and briefing; legacy presets bypass it. |
| Deploying | Existing initialization, navigation validation, arrival effect and admission checks; no separate timed state required. |
| Active | Existing mission/world state and elapsed clock, after explicit start. |
| Extracting | `RecallController.channeling`; interruption returns to ordinary active play. |
| Settled | Existing player termination/extraction plus ledger settlement guards; objective/result closure is idempotent. |
| Spectating | Existing PostDeathSpectator permissions while world state remains running. |
| Returning | Existing world-stop/summary path. “Prepare next deployment” uses current scene replacement and returns S to its briefing with fresh owners. |

The briefing includes the mission name/premise, required and optional targets, the three-minute deadline, five-second recall, forfeiture risk, and permission to extract early with incomplete objectives. One Deploy button is sufficient. The existing post-death Return still means end observation and show the settled result; it does not write a new result or reopen the deployment. Restart/R recreates S at preparation, with the same seed and stash path; earlier presets continue their accepted immediate-restart behavior. No hub, inventory menu or mission-selection framework is needed.

## Accepted events and settlement ordering

Initialize the objective owner before admissions and player actions. Reuse ledger accepted notifications as invalidation/progress inputs, keyed by each ledger's serial, without depending on the optional debug metrics observer. Query the ledger categories for recovery progress; do not sum cargo announcements or count the same recovered units again when they are banked.

For optional combat, add one minimal structured accepted-defeat notification from the existing coordinator:

1. Validate the registered Raider, dead health/FSM and pending ledger outcome as today.
2. Capture the lethal instigator and eligibility **before** `ledger.defeat()` changes active status. Calling today's `SocialEncounter.eligible()` afterward would reject the now-resolved actor.
3. Only after the ledger accepts defeat, report the deployment identity, victim ID, instigator and captured eligibility. Rejected/duplicate defeat callbacks emit no accepted event.
4. Credit only a registered eligible hostile Raider whose lethal `Health.last_damage_instigator_id` identifies this deployment's robot. No proximity credit, assists, unknown-origin damage, machine/Raider kills, practice-target credit or post-death credit. Retain a finite set of credited victim IDs to reject repeated events.

No new combat authority or threat rule is introduced. The existing Health/ShotExecutor instigator remains the source of attribution. Player-relative eligibility is separate from relationships between Raiders; neutral salvage competition is not a kill-credit hostility rule.

At successful recall, preserve the authoritative order:

1. Recheck actual recall eligibility and settlement guards.
2. Commit and verify the existing stash receipt. On save failure, keep objectives open and cargo intact for retry.
3. Settle both existing ledgers as extracted and verify their invariants.
4. The existing coordinator explicitly reconciles objectives using settled ledger state and the confirmed extraction on this path. Pass required satisfaction into MissionRules' existing completion policy. The extract objective is evaluated with that confirmed outcome, not with an earlier false `player_extracted` flag.
5. Record `player_extracted = true` regardless of primary completion. Required objectives satisfied means mission success; otherwise report **“Extracted — primary objective incomplete”** with the same successfully banked inventory. This is a terminal deployment, not a reason to call failure forfeiture or undo the receipt. Legacy configurations still treat accepted recall as success.
6. Freeze the objective/result snapshot exactly once, then use existing termination/world shutdown and presentation.

On death/deadline, keep the existing outcome decision and one-time forfeiture first, explicitly reconcile/freeze player objectives before observation or terminal UI, then allow the existing world policy to continue or stop simulation. Use the same closure hook for invalid setup and any supported deployment replacement/abandonment, without performing an additional settlement. Snapshot deployment duration at the player's end; later world observation duration is a separate value.

Accepted-transfer/death signals refresh active progress, but **signals do not decide finalization order**. The coordinator must explicitly flush the objective view from both ledgers at the settlement boundary, even if HUD callbacks run earlier or later. This avoids relying on scene-tree callback order, deferred debug finalization, widgets or a first ledger's notification arriving before the second ledger settles.

A settled result contains only detached data: mission identity/name, extracted/destroyed/expired outcome, MissionRules verdict, required/optional objective rows, deployment duration, picked-up/banked/forfeited material/item counts and existing receipt outcome. Results presentation never calls settlement or stash commit. Later Raider deaths, extraction and reinforcement admission can update world diagnostics but not the player result.

## Configuration, routing and UI changes

Extend `MissionConfig` with mission ID, short description/risk text, objective definitions and opt-in briefing. Leave existing scenario resources with defaults/empty objectives so their state, summary and seed behavior remain unchanged. Use a copied `asset_recovery.tres`, inheriting the same encounter resources as R, and `asset_recovery_arena.tscn` through the current arena script/config selection (next index 16). Reuse the concise R presentation through the opted-in configuration rather than adding more scattered index-only HUD checks.

Keep the S HUD compact: mission name, primary carry/bank readiness and extraction requirement, small optional progress, deadline, hull and interaction. Keep global quantities, seed/layout, AI relationships and private objectives in developer diagnostics. The existing success notice, damage bearings, hits, traversal and recall prompts remain in use. On settlement show the frozen player result; after spectating label any later world totals separately.

Propose making **the new S briefing scene the default project startup only after explicit-scene integration tests pass**, as part of the approved S implementation. This is an explicit routing change for review, not a hidden R promotion. Preserve `mission_arena.tscn` as Intercept and every accepted N/P/Q/R scene/config. Plain F5 remains N, satisfying its existing regression; other developer preset keys remain separate from the normal mission. If adding S-specific next-seed inspection, keep it debug-only and scoped to S (for example Ctrl+Shift+F5 advances S while existing P/Q behavior remains intact). Ordinary restart preserves the current seed; no random seed selection or new encounter scheduling is needed.

## Implementation sequence and likely files

1. **Definitions and policy tests:** add `mission_objective_definition.gd` and `mission_objectives.gd`; extend `mission_config.gd` and opt-in completion policy in `mission_rules.gd`. Establish recovery basis, readiness, optionality, duplicate credit and terminal snapshots before connecting UI.
2. **Coordinator integration:** update `raider_arena.gd`/`mission_arena.gd` with preparation, accepted-defeat metadata and explicit one-time objective closure. Adjust `recall_controller.gd` only at the existing successful settlement boundary. Preserve ledger/stash ownership and their accepted notifications; no stash schema or reward changes planned.
3. **One S definition/scene and presentation:** add `resources/missions/asset_recovery.tres`, objective resources if separate `.tres` definitions improve editing, `scenes/levels/asset_recovery_arena.tscn` and a small `scripts/presentation/mission_objectives_view.gd` (or equivalent existing-Overlay scene). Briefing, HUD and debrief all consume the same read-only model.
4. **Integration/regression validation:** add focused objective and deployment-flow tests alongside all 27 existing suites. Exercise real pickup, recall, attributed physical shots, save-error retry, post-death continuation and restart.
5. **Startup/routing and records:** after explicit S validation, update only `project.godot`'s main scene and associated startup expectations; preserve developer entry routes. Document launch commands, policy, results and remaining manual review. Run final engine/graphical checks and stop at Checkpoint S.

## Risks and required evidence

| Risk | Evidence before delivery |
| --- | --- |
| Briefing hides UI but AI or time advances | Hold preparation across physics frames: no admissions, movement, shots, clock/recall/response progression or transfers; one Deploy action enables the existing simulation. |
| Early extraction is mislabeled or forfeits loot | Real below-target recall banks actual cargo once, records extracted/incomplete, stops world normally and leaves optional objectives nonblocking. No extra reward or save mutation from opening results. |
| Bank objective completes on temporary possession | Pickup shows readiness only; save failure retains pending status; receipt plus settlement completes it; death forfeits and fails bank requirements. |
| Event ordering produces partial settlement results | Repeated and differently ordered progress callbacks, explicit terminal reconciliation and the terminal-machine regression leave the same frozen player result. |
| AI kills grant player credit, or kills count twice | Physical player shots, AI lethal shots, unknown sources, friendly machines, practice targets and repeated accepted-defeat notifications exercise explicit eligibility/instigator rules. |
| Spectator actions or later AI rewrite results | Compare frozen result before/after follow cycling, later deaths/extractions, pending arrivals, Return and deadline; no bank or objective reopening. |
| Shared resources/presets change | Compare N/P/Q/R setup/resources, scenario routing, initial stock, profile decisions and accounting; no in-place edits to preloaded reference definitions. |
| Restart leaks state, listeners, seeds or receipt IDs | New scene/model/ledgers and receipt, cleared credited IDs and progress, same selected seed/save path, preserved stash and no previous-deployment events affecting the new result. |
| Targets become impossible in some sessions | Validate against the finite configured pool; communicate incomplete extraction honestly. Never grant synthetic loot, change AI goals or force kills to rescue a mission. |

## Validation and Checkpoint S

Run **all 27 accepted suites plus meaningful new objective/mission-flow suites**, Godot 4.7.2 editor parsing/import, bounded headless S startup and simulation, and Forward+ graphical briefing-to-debrief checks. Inspect logs and report warnings independently of failures. Use isolated ignored saves, not the real stash. Preserve tracked script UIDs and ignored generated imports/exports.

New coverage must include definition validation/reset, read-only snapshots, authoritative material/equipment progress, duplicate transfer/kill events, required versus optional policy, carrying versus banking, completion before recall, deliberate early recall, full success, save failure/retry, death/deadline one-time settlement, post-death simulation with frozen results, Return/restart, same/different seed setup, startup briefing and all old developer presets. Physical interaction and firing integration tests are required where attribution, collision or recall eligibility matters; policy-only tests are insufficient.

Manual Checkpoint S should exercise the ledger's complete matrix, primarily with diagnostics hidden: understandable briefing, interception/cargo recovery, optional equipment/combat credit, early and objective-complete extraction, death and spectating, repeated deployment and different seeds. Confirm autonomous activity and player agency remain intact, objectives do not obscure combat, and mission success/inventory banking/failure reasons are distinct. Exact combat winners or loot outcomes are never acceptance assertions.

Deliver the implementation report, changed files, policy/ownership decisions, full validation results, graphical evidence, known limitations and manual procedure. No Stage T work, commit or publication is included. **Historical planning boundary:** implementation had not begun when this proposal was prepared. The director subsequently approved it; the linked delivery report records the result.
