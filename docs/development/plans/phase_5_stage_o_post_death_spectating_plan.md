# Phase 5, Stage O - Post-death spectating implementation plan

Prepared: **2026-10-19**. **Approved by the director; implemented and validated for Checkpoint O manual review.** Stage N is accepted. Source requirements: [Stage O ledger](../ledgers/phase_5_stage_o_post_death_spectating.md). Delivered behavior and validation are recorded in the [Stage O report](../reports/stage_o_post_death_spectating.md); the proposed design below is retained as the approved plan.

## Proposed behavior and scope

Enable post-death spectating in the F5 Integrated Extraction mission through an explicit mission configuration option. Keep it disabled by default in older presets and original regression arenas, preserving their immediate terminal shutdown. The shared implementation can later be enabled elsewhere without copying camera or mission logic.

On destruction, immediately fail the player's deployment, stop all player actions and settle carried loot as forfeited once. Show **Spectate** and **Return** while the world continues running. Spectate follows a living Raider or support machine. Return leaves the observation view and shows the existing failed-deployment summary with its restart option. There is no hub scene yet, so Return does not invent a new menu or quit the application. Returning ends/disposes this local world through the normal world-stop path; no rewards or revival occur.

Pending approval, proposed player controls are **Tab / Shift+Tab** for next/previous target, mouse orbit around the followed actor with bounded pitch and camera collision, and **Escape / Return button** to return to the failure summary. Selection is immediate; no actor control, free translation, AI inspection or gameplay interactions are available. A compact target name and cycling/Return controls replace gameplay prompts during observation.

## Repository findings

| Area | Current behavior | Required separation |
| --- | --- | --- |
| `MissionRules` | `fail_player_destroyed()` sets terminal FAILED; `is_finished()` prevents further outcome evaluation | Retain permanent player failure, add explicit independent world-running/world-finished state and a reason for world termination |
| `raider_arena.gd` | `_on_player_destroyed()` calls `finish_mission()`; this settles recall, seals materials/relations/equipment, stops actors and shows summary | Split player termination/settlement, summary presentation and final world shutdown; summary visibility must not be a shutdown guard |
| Arena/mission scheduling | `is_finished()` gates arena time, scheduled entries and events | World scheduling must use world state, while player interactions continue to use player terminal state |
| `MaterialLedger` | `_player_settled` blocks future player recovery; settlement is idempotent. AI collect, collect-ground, defeat, extraction, component release and registration remain possible until `seal()` | Settle the player at death; delay global sealing until the world stops. Keep this ledger as the sole material writer |
| `EquipmentLedger` | Player settlement blocks recovery but loadout assignment and owner resolution continue until sealing | Preserve exactly-once forfeiture; allow subsequent AI deaths/extractions and finite responder equipment |
| `RecallController` | Failure settlement cancels recall; successful recall persists rewards before settlement; terminal eligibility prevents late extraction | Reuse failure settlement without shutting down the world; never save rewards after player death |
| Social/flare/ecosystem code | Several `mission.is_finished()` guards suppress target eligibility, reports, betrayal, responses and component release | Audit each guard by ownership: autonomous operations use world state, player pickup/recall use deployment state |
| `DeveloperSpectator` | Owns a private Camera3D, free motion and Raider-only selection; debug-only creation; entry rejects dead/finished player; exit can restore player controls | Extract common camera/follow behavior and use separate developer/player permission controllers; dead-player exit must never restore gameplay |
| Health/damage | Health records the last accepted instigator instance ID before emitting death | Prefer that exact registered, live Raider if still eligible; unknown, removed or invalid instigators fall back safely |

Dead actor eligibility and camera non-interference must remain based on actor health/registration/ledger outcome, never camera position. Existing cosmetic robot destruction remains unchanged; no spectator physics body, collision layer, threat proxy or corpse gameplay system is added.

## 1. Separate player outcome from world lifetime

Keep the existing deployment outcome API terminal and irreversible: after death, `mission.is_finished()` remains true, `player_destroyed` remains true and phase remains FAILED. Later AI results or a deadline cannot change that to success, enable recall or re-bank cargo.

Add a small world lifetime state owned by MissionRules, with explicit RUNNING/FINISHED transitions and a separate world-stop reason. Avoid an unrelated global manager. Normal completion, timeout and setup failure still stop both lifetimes in existing presets. Only an opted-in player destruction allows FAILED deployment plus RUNNING world.

Refactor the arena's current `finish_mission()` responsibilities into idempotent operations: terminate player/settle once, present the appropriate summary/choice, and stop/seal the world. Use explicit state guards rather than whether a panel is visible. Capture player settlement and death elapsed time for stable failure reporting; label later world totals/time as observation results so subsequent AI extraction is not confused with player rewards.

While the post-death world runs, continue time, already scheduled entries, finite flare responses, AI FSMs, reports, betrayal assessments, combat, navigation, scavenging, ground collection, machine component release and Raider extraction. Stop player movement, weapon, camera input, traversal, pickup and recall immediately. Refresh post-death UI without re-exposing pickup, equipment or recall prompts.

Proposed world-stop conditions after player death:

- Original deployment deadline, using its remaining time rather than starting a new timer.
- No living eligible Raiders or support machines, with no pending scheduled entries or reinforcement tickets. Ground loot alone cannot be recovered by a dead player and does not keep an empty simulation running.
- Return, restart, scenario replacement or scene teardown.

Living patrol machines may therefore remain observable after every Raider resolves, until the deadline or Return. A temporary absence of targets with pending entries/responses shows a waiting message rather than ending the world prematurely. At world stop, seal ledgers/relations and stop all actors once, return to the failure summary and retain the original player failure/forfeiture.

## 2. Settle loot without sealing autonomous transfers

At accepted player destruction, cancel interaction channels and invoke existing player-failure settlement exactly once. Both ledgers already reject a second settlement and future player recovery. Do not reset those flags, invent spectator inventories, duplicate ledger state or transfer forfeited cargo back into the world.

Delay material, equipment and relation sealing until final world shutdown. AI transfers continue through the same validated paths and conservation checks. Future Raider extraction increases actual Lost; new ground loot remains ground; forfeited player cargo stays forfeited. The pre-existing persistent stash is untouched by death, observation, switching targets, Return or world timeout. Successful living-player recall retains its existing persistence/receipt behavior and ends the world normally.

## 3. Reuse camera mechanics with separate permissions

Extract a shared spectator camera rig from `DeveloperSpectator` for Camera3D ownership, safe target references, follow translation, orientation and clean activation/deactivation. Keep it presentation-only. The arena coordinates mutually exclusive player-camera, developer-spectator and post-death-follow modes; there is only one current camera. Preserve existing developer-facing camera access where regression tests use it.

Retain DeveloperSpectator as the debug-only input/inspection adapter. It keeps F1, free flight, unrestricted rotation and existing developer diagnostics for a living player. A separate post-death controller uses the same rig's follow/orbit behavior and explicit actor eligibility, available in normal gameplay builds when the mission enables it. Developer free flight/inspection are not inherited by normal spectating. Reject F1 mode takeover while in the post-death flow; if the player dies while using the developer camera, leave that mode without restoring controls, then offer the normal death choices.

Player follow uses a target-relative anchor and SpringArm3D collision handling, with configurable distance and bounded pitch. Geometry shortens the camera arm rather than moving the target or imposing physics on it. Developer free flight bypasses the arm and retains existing no-clip behavior. Shared follow/camera calculations are reused; developer and player input permissions stay in their respective adapters. No networking, authority replication, team visibility rules or future PvP policy is implemented.

## 4. Target eligibility and lifecycle

Candidates are registered living active Raiders and registered living active support machines. Exclude the dead robot, camera, drops, cosmetic tumble bodies, queued-for-deletion nodes and extracted Raiders. Inspect registration plus health and ledger activity before following; never use a stale object ID as permission to attach.

On choosing Spectate, prefer the Raider identified by the lethal hit's recorded instigator if still eligible. Otherwise choose a deterministic fallback: eligible Raiders by stable Raider ID, then machines by stable source ID. Rebuild eligibility when cycling and after lifecycle changes; new finite responders can become candidates. No permanent actor mutation is needed for following.

Automatically switch to the next eligible candidate if the current actor dies, extracts or disappears. If none are currently eligible but entries/responses remain, hold a passive camera view and display a waiting message, then acquire an eligible target when available. If the world finishes, deactivate observation and show the failed summary. Restart/scenario replacement clears all references and returns to fresh player camera/control state and the existing stash path.

## Implementation sequence after approval

1. Add opt-in configuration and independent world lifetime policy with focused state/settlement tests. Separate arena player termination from world sealing and presentation.
2. Audit all existing terminal guards and callbacks, including flare response processing, social eligibility/reports/betrayal, component release, scheduled entry and human collection. Preserve earlier preset semantics.
3. Extract common spectator rig behavior, preserve debug tooling, then add restricted follow controls, Raider/machine eligibility and safe camera handoff.
4. Add Spectate/Return UI and stable failed-deployment reporting. Integrate target fallback, waiting, deadline, Return and restart.
5. Run all existing suites plus a new Stage O suite, engine checks and graphical camera/UI validation. Document results and stop at Checkpoint O.

## Risks and validation

| Risk | Focused coverage |
| --- | --- |
| Accidental resurrection or reward after death | FAILED stays terminal through later extraction/death/deadline/Return; one forfeiture; late pickup/recall/save rejected; prior stash unchanged |
| AI still stopped by an old guard | Natural post-death motion, combat, reports, scavenging, loot, extraction, component release and finite responder admission; unchanged caps and invariants |
| Ledgers sealed too early or twice | Accepted AI transfers after player settlement; no spectator-created transfers; final sealing rejects late mutation; preserved ground/Lost/forfeiture distinctions |
| Two cameras or restored dead-player input | Death from normal/developer view; repeated Spectate/Return; restart/scenario switch; one current camera and permanently disabled dead-player gameplay |
| Follow target freed during a frame | Lethal hit, extraction, queued deletion, missing instigator, killer dying before selection, machine destruction, empty target list and delayed responder |
| Player spectating gains developer permissions | Free movement/ascend/boost/fire/interact and AI inspection unavailable; follow orbit/cycle only; same restrictions in normal builds |
| Camera influences autonomous decisions | Camera proximity versus distant/dead robot; actor state/physics/ledger unchanged by switching/orbiting; real simulation remains free to evolve |
| Return or timeout rewrites failure | Separate world-stop reason/time; stable death outcome and forfeiture; correct summary and safe repeated shutdown |
| Regression in older scenes or living gameplay | N before-death extraction, all prior nineteen suites, original arenas, legacy immediate terminal behavior, living F1/F3, traversal and stash restart behavior |

Add `tests/post_death_spectator_test.gd` and meaningful extensions to affected policy, spectator and integrated mission tests. Use isolated saves under ignored `.godot/stage_o_tests/`. Run Godot 4.7.2 editor parsing/import, all twenty suites, bounded headless runtime and Forward+ graphical startup. Run the affected spectator/UI checks graphically for actual capture, cursor release, buttons and camera collision; inspect output as well as exit codes. Release-mode controller availability and developer exclusion must be checked explicitly; distinguish code/build-flag checks from an actual exported release test.

Manual Checkpoint O review will cover following comfort, target labels/cycling, killer preference, choice/Return flow, continued autonomous encounters after death, obstruction handling, no-target waiting, deadline and restart. No Stage P work follows without approval. No Git commit is authorized by this plan.
