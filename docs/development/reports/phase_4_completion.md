# Phase 4 - Developer observation and social Raider AI

Recorded: **2026-10-19**. Consolidated completion report based on the stage reports, recorded validation and director approvals.

**Status: approved Stages J-M complete and accepted, including traversal availability and the window/HUD refinement.**

Raiders can now fight rivals, share local observations with allies, compete for and recover finite cargo, and initiate a bounded opportunistic betrayal. Developer spectator tooling allows these encounters to be observed without the camera affecting AI behavior.

This report covers the [Stage J amendment](../ledgers/phase_4_stage_j_spectator_amendment.md) and the approved [K-M social AI plan](../plans/phase_4_social_ai_plan.md). A separate full Phase 4 ledger was not supplied. Completion refers to this approved scope.

## Delivered scope

| Stage | Delivered | Acceptance |
| --- | --- | --- |
| J - Developer spectator | Independent debug free camera, no collision or gravity, configurable flight, one active camera, player input separation, inspect/follow, clean exit/restart/destruction handling | Director confirmed it works perfectly and approved |
| K - Social rivalry | Explicit symmetric allied/neutral/hostile pair attitudes, hostile human targeting and damage, accepted-hit attribution, ordinary combat/retreat/death and relationship diagnostics | New mechanics confirmed functional; traversal availability issue corrected and accepted |
| L - Cooperation and contested cargo | Local expiring allied reports, independent responses, observed drop memory, validated partial/contested material recovery and opt-in finite flare responders with authored relations | Director confirmed all functional and approved proceeding |
| M - Opportunistic betrayal | One authored opportunist, continuous eligibility assessment, visible warning, one accepted pair hostility initiation per deployment and ordinary combat/loot afterward | Director confirmed functionally great |
| Display follow-up | 1600 x 900 default resizable window; F3 hides/shows developer diagnostics, control banner and detailed spectator inspection; hidden by default | Director confirmed perfect and approved |

Jump and boost now default to enabled across all test scenes. Their accepted tuning remains unchanged; the floaty jump feel was explicitly deferred.

## Architectural decisions retained

- **Relationships, resource competition and squad membership are independent.** Neutral Raiders can compete for salvage. Allies can cooperate without a permanent squad; current authored social encounters use no squad assignments.
- Mission-local `RaiderRelations` owns pair attitudes and records accepted changes with reasons and timestamps. A betrayal changes only the affected pair. Third parties do not acquire automatic hostility or knowledge.
- Raider's common FSM and CharacterBody3D retain activity, velocity and movement ownership. Social and betrayal components supply observations and decisions through that FSM; they do not add a second movement controller.
- Shared shot execution and Health handle physical hits, eligibility, damage and instigator attribution. Allied/neutral bodies block shots without taking human friendly damage. Fresh visibility and normal aim warnings remain required.
- `MaterialLedger` remains the sole owner of material quantities and transfers, checking conservation after each accepted transfer. World drops and Raiders are views of those allocations. Relations, reports, betrayal and responder admission cannot create material stock.
- Mission outcome policy remains separate from accounting. Untouched salvage, recoverable ground cargo, carried cargo and actual Raider extraction losses retain their distinct meanings. Existing recovery-only/deadline/recall rules remain in place.
- Spectator position is never used for perception, targeting, navigation or interaction. AI, physics, mission time and loot continue while observing. The robot stays physically present and vulnerable, with gameplay input disabled until normal control resumes.

## Playable controls and scenarios

| Control | Purpose |
| --- | --- |
| F1 | Toggle debug spectator camera |
| WASD / mouse in spectator | Horizontal flight / unrestricted rotation |
| Space / Ctrl / Shift in spectator | Ascend / descend / accelerated movement |
| Tab / F in spectator | Select next living Raider / toggle following it |
| F3 | Toggle developer HUD, control banner and detailed inspector |
| F11 | Social Rivalry: R1/R2 allied, R3 hostile to both |
| Shift+F11 | Social Cooperation: allied observations and material looting |
| Ctrl+F11 | Social Pressure: cooperation with existing finite flare responses |
| Alt+F11 | Opportunistic Betrayal: initially allied Raiders, only R1 may initiate betrayal |

Social scenario shortcuts and spectator activation are debug-only. Existing scenario shortcuts remain available, including F9 Survival. Direct social scene files are under `scenes/levels/`; the [project README](../../../README.md) contains launch commands and controls.

Social encounters begin with three Raiders and nine finite materials. The betrayal preset uses authored per-ID entry markers and seed 84017 so R2 naturally scavenges before R1 reaches it. No cargo grant or forced kill creates the opportunity.

Allied hostile reports use a 15 m communication radius and three-second lifetime. Only direct sightings publish; recipients cannot relay unseen reports or gain firing visibility through them. Visible loot discovery uses a 12 m radius and three-second memory. Normal capacity, distance, reach and scavenging time still gate collection.

Betrayal requires a visible ally carrying at least three materials and more cargo than the opportunist, within 8 m for two continuous seconds. The opportunist needs more than 50% health, available cargo capacity and no visible machine/rival threat or active combat/retreat. Interruption resets assessment. The orange cargo countdown precedes hostility and the ordinary rifle warning. The opportunist can lose or retreat; no winner or reward is guaranteed.

## Validation record

The completed Stage M validation passed **all eighteen automated suites**, comprising the original controller, combat, Raider, mission, destruction, multi-Raider, dynamic AI, mission variety, awareness, hostile combat, flare/loot, extraction, machine ecosystem and traversal suites, plus spectator, social rivalry, social cooperation and betrayal suites.

Focused coverage includes:

- Repeated spectator entry/exit, collision-free flight, single camera, unchanged player position, blocked player actions, simulation continuity, camera proximity without aggression, inspect/follow, restored controls, restart and lethal player damage.
- Relation validation/sealing, independent neutral salvage competition, no-squad alliances, physical rival shots, protected allied/neutral blockers, target changes, normal death/accounting and naturally occurring rival combat.
- Report radius/expiry, source/target invalidation, detached snapshots, no relay or live tracking, repeated-observation task preservation, observed loot discovery, partial/raced collection, forged-drop rejection, natural cargo approach/scavenging/extraction and finite authored responder relations.
- Continuous betrayal timing and interruption by obstruction, range, threats, damage, retreat and victim resolution; one accepted pair change; ordinary warning, shots, retaliation, death and pickup; conservation, deadline, restart and a natural authored opportunity without fixture cargo.

Godot **4.7.2 Standard** editor import/parsing, bounded headless runtime and Vulkan **Forward+** graphical startup passed at the stage checkpoints. Stage J also passed its spectator suite graphically for real mouse capture/restoration. After the display refinement, parsing, bounded headless/Forward+ launches and the spectator, social rivalry and Raider suites passed. The full eighteen-suite run predates that presentation-only refinement.

These are recorded results from implementation, not new test runs performed while writing this report. Isolated tests deliberately position/freeze actors where needed; natural integration cases exercise actual movement, navigation and combat. Repeatable initial setup does not imply bitwise deterministic physics or identical combat winners.

Earlier parallel flare/recall runs intermittently reported two-instance audio/ObjectDB cleanup warnings. The final Stage M full run reported no shutdown warnings; the underlying cause is not claimed fixed. No new social preset or suite uses the player's persistent stash.

## Acceptance and remaining limits

The director accepted J-M functionality and the subsequent display refinement. Further tuning can still improve warning readability, combat/retreat pacing, shared-cover congestion, pickup routes and social encounter balance. These are ongoing play-test concerns rather than unaccepted implementation checkpoints.

Release exclusion uses debug guards; a packaged release export has not been independently exercised. Existing five-Raider navigation regressions pass, but larger social encounter balance and cross-hardware performance are not established. Detailed Blender assets and animations remain deferred.

The approved scope does not include asymmetric attitudes, dynamic alliance formation, permanent squad coordination, third-party witnessed retaliation, random betrayal probabilities, persistent social memory, equipment looting/re-equipping, cargo trading/sharing, progression, multiplayer or final art.

## Repository status and next boundary

The latest committed gameplay checkpoint remains **`ac0bace` (Stage I)**. Stages J-M, documentation, traversal availability and the display refinement remain **uncommitted**. This report does not create a Git checkpoint or authorize a commit.

Approved work through Stage M is complete. No subsequent gameplay milestone has been agreed or implemented. Preserve this accepted state and agree on the next scope before adding further systems.

## Supporting reports

- [Stage J spectator](stage_j_spectator.md)
- [Stage K social rivalry](stage_k_social_rivalry.md)
- [Traversal availability follow-up](traversal_availability_followup.md)
- [Stage L social cooperation](stage_l_social_cooperation.md)
- [Stage M betrayal and display follow-up](stage_m_opportunistic_betrayal.md)
- [Checkpoint register](checkpoints.md)
