# Stage N - Integrated extraction mission

Recorded: **2026-10-19**. **Implemented, validated and accepted. Changes are uncommitted.** The director approved the integrated mission, then confirmed "Perfect" and supplied the Phase 5 Stage O ledger, identifying N as completed. Stage O implementation requires separate plan approval.

## Purpose and approved scope

Combine the accepted mechanics into one playable deployment-to-stash loop in the existing graybox. Preserve focused regression scenes and use existing state owners. This milestone introduces an authored mission configuration, its scene/shortcut, extraction-oriented introductory text and integration tests. It does not add an AI system, map, weapon, economy or progression layer.

## Delivered

| Setting | Integrated mission |
| --- | --- |
| Launch | F5 in the running game, or `res://scenes/levels/integrated_extraction_arena.tscn` |
| Scene | Existing expanded 48 m graybox, cover, ramp and Recall Dock |
| Player | Starts at Recall Dock; existing shoulder camera, hitscan, hull, jump and boost |
| Initial Raiders | Three simultaneous entries at existing seeded, validated spawn markers; Greedy, Cowardly and Aggressive profiles |
| Relationships | Explicit R1/R2 alliance; R3 hostile to both; no squad assignments |
| Opportunist | R1 only; existing continuous eligibility and warnings, with no guaranteed trigger |
| Cooperation/loot | Local expiring allied observations, observed material drops, timed contested collection and ordinary death/extraction accounting |
| Pressure | Existing death flares, local investigation, two-responder total budget and five-living-Raider cap |
| Responders | Existing authored policy allies with surviving R1/R2 and other responders, opposes surviving R3; does not reconcile a betrayed pair |
| Support | Independent scout and guard, machine reports, combat and preallocated components |
| Materials | Nine original salvage units plus one component per support machine: eleven total |
| Equipment | Existing separate loadout ledger and hold-to-recover rules |
| Seed/deadline | 85017 / 180 seconds |
| Extraction | Existing five-second Recall Dock channel and persistent stash |
| Developer tools | F1 spectator/inspect/follow; F3 optional diagnostics and detailed inspector |

The default main scene remains Intercept. F5 opens this separate integrated preset. All earlier presets and original single-/three-Raider scenes remain available. No existing personality or combat tuning resources were changed.

## Mission loop and ownership

Deploy, intercept scavengers or investigate encounters, recover finite material/equipment drops, choose how much risk to take, return to the dock and extract. Original stock remains a Raider scavenging source; direct player harvesting is outside this milestone.

The accepted `requires_extraction` mission policy already supports this model. After every Raider and response resolves, the mission enters recovery and remains open even if no ground loot remains. Untouched original stock does not prevent recall. Successful player recall, robot destruction or the deadline ends the deployment. Active hostiles, pending responses and zero recovered cargo do not prevent recall.

Incoming nonlethal damage preserves recall progress. Release, movement, firing, traversal or loss of dock eligibility still cancels it; death/deadline prevent completion. Nearby material pickup takes priority over equipment hold, and eligible loot takes priority over recall. These interaction rules are reused unchanged.

MaterialLedger owns all quantities and checks conservation after every accepted transfer. Eleven upfront units include components still installed in living machines. EquipmentLedger owns equipment identities and settlement. Raider death, machine destruction, collection and extraction use existing validated transfer paths. Mission rules determine outcomes separately; recall settles and persists rewards. Destruction/timeout forfeits carried player cargo, preserves previously banked inventory and distinguishes ground cargo from actual Raider extraction losses.

Raider FSM/CharacterBody3D retain activity and movement ownership. Social targeting includes hostile humans, the physical robot and support machines. Allied reports do not grant direct sight; machine and human observation channels remain separate. An opportunist can encounter a valid betrayal opportunity, but visible machine/rival threats, retreat, low health and other existing guards still take priority.

## Validation

All **nineteen automated suites passed**, including the eighteen prior regressions and `tests/integrated_extraction_test.gd`. The traversal regression also exercises jump/boost and the shared HUD across the new preset and existing scenarios.

The integration suite verifies:

- Simultaneous composition, three distinct existing profiles, opt-in opportunist, nine salvage plus two installed components and valid configuration.
- Social target selection choosing nearby machines and then human rivals; relation-aware shots dealing ordinary attributed damage to a support machine while allied protection remains intact.
- A quiet, deliberately isolated betrayal opportunity followed by normal loaded death, material drop, equipment and a bounded response. Responder initialization preserves existing pair hostility and finite budget.
- Physical material eligibility, overlapping material/equipment interaction priority, timed equipment recovery, preallocated component release and recovery into the common ledger.
- Five-second recall through nonlethal damage while living Raiders and an outstanding response remain; exact banking of four materials and two equipment items, no duplicate rewards, terminal shutdown and restart/stash preservation.
- Separate destruction and timeout cases, with recovered cargo forfeited, ground cargo unrecovered, zero fabricated extraction loss and no stash credit or late recall.
- All initial Raiders and finite responders resolving with no remaining ground loot, yet the mission staying open until explicit player recall.
- A natural simultaneous simulation with normal actor physics, support patrol, combat/scavenging, finite transfers, spectator observation and subsequent grounded recall.

Isolated cases deliberately position actors, transfer fixture cargo through the authoritative ledger and freeze selected systems. The natural case resumes real simultaneous simulation without forced cargo or activity transitions; its final recall setup positions the robot at the dock. Full player-controlled routes and encounter pacing remain manual checks. An early test-harness run accessed a freed Raider during freezing and crashed the engine; validity checks corrected the helper, and the completed focused and full-suite runs passed. No runtime workaround was added for that test error.

Godot **4.7.2 Standard** editor import/parsing, bounded headless startup (900 frames) and Vulkan **Forward+** graphical startup (180 frames) of the integrated scene passed. Output was inspected alongside exit status. The completed nineteen-suite run reported no failures or shutdown warnings. Earlier intermittent audio/ObjectDB cleanup warnings remain documented and are not claimed fixed.

All integration saves use unique paths under ignored `.godot/stage_n_tests/`; tests do not write the player's real stash. Real play intentionally uses the existing stash and banking rules. Generated data/builds remain ignored, and script `.uid` files are retained.

## Checkpoint N manual review

1. Press F5 and play a complete deployment: leave the dock, intercept loaded Raiders, recover materials/equipment and return to extract. Check cargo/stash totals after restart and reopening the game.
2. Observe competing human and machine threats with F1/Tab/F. Assess target switching, cover congestion, patrol usefulness, ally cooperation and whether one faction dominates too quickly. Betrayal may not occur when combat pressure keeps its guards active.
3. Check how death flares and finite responders affect pickup windows and the return route. Review combined material/equipment/component prompts and their priority near the dock.
4. Try extracting under fire, retreating from a fight, clearing all Raiders before recall, and continuing recovery until timeout. Confirm clear warnings and summary categories.
5. Review three-minute pacing, route distances, early empty extraction, available cargo value and overall difficulty. This is integration validation, not a finished economy or balanced extraction map.

Existing five-Raider navigation remains covered, but this combined encounter has not been balanced across hardware or larger populations. Detailed art/animations, new layouts, direct salvage harvesting, AI equipment looting, random spawning/probabilities, progression and multiplayer remain outside scope. Floaty jump refinement remains deferred.

**Checkpoint N accepted.** The director supplied the [Stage O ledger](../ledgers/phase_5_stage_o_post_death_spectating.md); its [implementation plan](../plans/phase_5_stage_o_post_death_spectating_plan.md) awaits approval before gameplay changes. No commit is created; the last committed gameplay checkpoint remains Stage I (`ac0bace`).
