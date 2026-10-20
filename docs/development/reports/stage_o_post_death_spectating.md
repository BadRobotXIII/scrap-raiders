# Phase 5, Stage O - Post-death spectating

Recorded: **2026-10-19**. **Implemented, validated and functionally accepted. Changes are uncommitted.** The director approved the implementation plan, then confirmed "Great functionally it works well" and authorized Stage P scope. The [Stage P implementation plan](../plans/phase_5_stage_p_dynamic_encounter_plan.md) awaits the review required by its ledger. The [Stage O ledger](../ledgers/phase_5_stage_o_post_death_spectating.md) remains unchanged.

## Delivered behavior

- Enabled through `MissionConfig.post_death_spectating` in the F5 Integrated Extraction preset. Default is false; earlier presets and original test arenas retain immediate terminal death behavior.
- Player destruction immediately and irreversibly fails the deployment, disables player movement/input/fire/interaction/traversal/recall, settles recovered material and equipment cargo as forfeited once, and offers Spectate or Return. Prior persistent stash contents remain unchanged.
- Spectate follows registered living Raiders and support machines, preferring the eligible Raider recorded as the lethal hit's instigator. Unknown, invalid or dead instigators fall back to stable Raider-ID order, then machine source-ID order.
- Tab/Shift+Tab cycles targets. Hold RMB and move the mouse to orbit with bounded pitch; mouse capture lasts only while RMB is held, and focus loss releases it. The shared follow rig uses SpringArm3D for geometry collision and excludes the followed actor. No physics body or gameplay proxy is added.
- Normal follow mode offers target name and Return controls, without free translation, AI inspection, actor control or gameplay interactions. The dead robot's HUD and stash display are hidden while following. F1 developer entry remains disallowed after player termination.
- Target death/extraction/removal switches to another eligible actor. No current targets with pending arrivals produces a passive waiting view; a new eligible responder can be acquired automatically.
- The world continues both while the death choice is open and while following. Existing Raiders, machines, combat, observations, social decisions, scavenging, loot, component release, responses and Raider extraction remain active.
- Return/Escape ends this local world and shows the existing failure summary/restart option. Observation also ends at the original deployment deadline or when no live actors or pending entries/responses remain. Living patrol machines remain observable even with no Raiders; ground loot alone does not keep an empty world running.
- Restart/scenario replacement clears observation references, preserves the selected scenario and stash path, and reconstructs normal player camera/control state. No Stage P systems, respawn, hub/menu scene, networking or multiplayer infrastructure were added.

## Ownership and termination

`MissionRules.is_finished()` still means player deployment termination. FAILED remains permanent after death; later AI outcomes and the world deadline cannot turn it into success or change death into a timeout failure. `MissionRules` separately owns world lifetime and its stop reason. Legacy terminal outcomes still stop the world immediately; only opted-in player destruction allows continued simulation.

The arena separates one-time player termination, final world shutdown and summary presentation. Explicit cleanup guards replace summary visibility as a shutdown guard. At player death, existing ledger settlement flags reject later player recovery and repeated settlement. Ledgers and relations remain unsealed until final world stop so autonomous transfers can continue. MaterialLedger and EquipmentLedger retain exclusive ownership, conservation/identity validation and existing transfer paths.

The terminal-guard audit separates player eligibility from autonomous operations across scheduled entry, material collection, social targeting/reports/betrayal, finite flare responses and machine component release. Recall/pickup still reject a terminal player. Successful living-player recall and its existing reward receipts are unchanged.

`SpectatorCamera` extracts shared camera construction, orientation, translation and follow behavior from DeveloperSpectator. The developer adapter retains living-player debug free flight/inspection and its accepted public camera behavior. PostDeathSpectator independently owns player permissions, candidate selection and death-choice UI, using the same camera rig. Arena composition and guarded entry/exit keep only one camera current. No camera coordinates enter AI or ledger queries.

Failure reporting preserves the death time and fixed player forfeiture. The final summary identifies later world observation time and labels aggregate totals as including subsequent AI activity. Actual Raider extraction may increase Lost after the player dies; previously forfeited cargo remains forfeited. Spectator actions do not save rewards or create cargo.

## Validation

All **twenty automated headless suites passed**, comprising the nineteen existing suites and `tests/post_death_spectator_test.gd`. This includes original scenarios, living-player integrated extraction, finite pressure, persistence, traversal, developer spectator, social rivalry/cooperation and betrayal regressions. After the final player-HUD/mouse presentation changes, the focused Stage O suite was rerun headlessly and graphically.

New coverage includes independent world/deployment policy, permanent failure, one-time material/equipment forfeiture, repeated death/finish rejection, prior stash preservation, death from developer view, killer preference, fallback without a developer adapter, single active camera, every eligible Raider/machine in forward/reverse cycles, RMB pitch limits, blocked player/free-flight actions, camera proximity without perception, follow collision without actor movement, normal post-death rival damage, component release, finite responder admission and relations, Raider scavenging/extraction, target death/extraction fallback, temporary no-target waiting, automatic reacquisition, no-survivor completion, deadline, Return/button wiring, final sealing, late recall rejection and restart.

A natural case resumes actor physics, patrols, combat, scavenging, flare processing and mission time after player destruction, first leaving the choice open and then observing. The world advances and accepts legitimate transfers with conserved material/equipment ownership while the player cannot bank rewards. Isolated cases deliberately freeze/place actors and use ledger-backed fixture transfers to exercise specific transitions. Camera screenshots are presentation artifacts, not proof of encounter balance.

Godot **4.7.2 Standard** editor import/parsing, bounded headless integrated startup and Vulkan **Forward+** graphical startup passed. The developer spectator suite and Stage O suite also passed graphically. Stage O graphical captures of the death choice, follow view and summary were inspected; final follow presentation removes dead-player HUD clutter. Output was inspected alongside exit status. The completed full regression run reported no failures or shutdown warnings. Previous intermittent audio/ObjectDB cleanup warnings remain documented and are not claimed fixed.

The post-death controller is composed outside debug-only guards and works in a fixture with the developer adapter removed. This verifies separation in the current runtime, not a packaged release export; release packaging has not been exercised. Test saves/screenshots use unique ignored paths under `.godot/stage_o_tests/` and do not modify the real player stash. Generated script `.uid` files are retained.

## Manual Checkpoint O review

1. Use F5, recover some loot, then allow the robot to be destroyed. Check Spectate/Return, forfeiture, the surviving killer preference and continued encounters while choosing.
2. Cycle Raiders, scout and guard with Tab/Shift+Tab. Hold RMB to orbit near walls and cover; assess distance, pitch limits, transitions and cursor capture/release.
3. Watch followed targets die or extract and verify understandable fallback. Observe pending responders and a temporary empty target list where practical.
4. Continue to the deadline, or Return/Escape. Verify the failed summary distinguishes death time, forfeiture and subsequent AI losses, and that restart restores normal controls with the prior stash intact.
5. Check living F1/F3 behavior and earlier scenes retain their accepted controls and terminal behavior.

Camera comfort, encounter pacing and cross-hardware behavior still require human review. Post-death observation deliberately lasts only for the remaining deployment time and cannot earn new rewards. Stop at **Checkpoint O**; no Stage P work or Git commit is authorized by this completion report.
