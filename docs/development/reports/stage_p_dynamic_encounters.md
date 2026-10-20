# Phase 5, Stage P - Dynamic encounter generation

Recorded: **2026-10-19**. **Implemented and validated; awaiting Checkpoint P manual review.** The director approved the [implementation plan](../plans/phase_5_stage_p_dynamic_encounter_plan.md). The [supplied ledger](../ledgers/phase_5_stage_p_dynamic_encounter_generation.md) is preserved unchanged.

## Delivery and scope

Stage P adds conditions for autonomous encounters through optional scenario data. It does not add a director that commands actors, new social decisions, combat, loot or extraction rules. The existing integrated mission and earlier presets remain available with their prior definitions.

| Item | Delivered |
| --- | --- |
| Development preset | Emergent Encounters - Development Preset; Shift+F5 or `res://scenes/levels/emergent_encounters_arena.tscn` |
| Replay | Default seed 87017; Ctrl+Shift+F5 advances seed; restart preserves the active runtime seed; plain F5 stays Integrated Extraction |
| Layout pool | `north_contest` and `south_patrol`, selected from stable text-ID ordering using a seed-derived RNG |
| Salvage | Three supported reachable locations, allocated as 6/3/3 finite units before ledger construction |
| Machines | Existing scout/guard, selected authored routes and one installed component each; fourteen material units in total |
| Initial arrivals | Five finite IDs scheduled at 0/0/35/70/105 seconds, with existing profiles and layout-authored entries |
| Relations | R1/R2 allied; R3 neutral competitor; R4/R5 allied and hostile to R1/R2; other pairs neutral; no squads inferred |
| Betrayal | Only R1 may initiate under its existing assessment/health/cargo/threat guards; no event is required or forced |
| Population | Shared ceiling of five live Raiders across initial and reinforcement admission, also respecting current flare cap; at most two support machines |
| Pressure | Existing one-flare-per-death behavior, local response, delays, two total reinforcement tickets and low-value responder equipment |
| Endings | Existing player recall/persistence, destruction forfeiture, post-death observation, deadline/Return and final sealing |
| Diagnostics | Resolved seed/layout/stock/routes/entries, participant membership, actual actor objectives/targets/relations and a 64-entry recent-event buffer |

The five live human actors plus two machines form a maximum of seven autonomous actors, eight including the robot. There are at most seven lifetime human admissions: five initial actors plus two responders. Deaths and responder deaths cannot replenish the budget or material stock.

## Architecture and validation rules

`EncounterLayout` is resource data for initial conditions. MissionConfig optionally supplies a layout pool and a live-Raider ceiling. `EncounterSetup` resolves setup before material/actor construction, validates layout surfaces/routes and observes events. It never commands combat, cooperation, betrayal, movement or extraction, and never writes live inventory quantities.

Selected per-point stock is allocated once through MaterialLedger. Scene point placement and machine route selection occur before ledger/machine initialization. Runtime state remains mission-local; preloaded config/layout/personality resources are read-only. Existing objective value/contention scoring, independent actor FSMs, relation eligibility, perception, navigation recovery, combat and transfer validation remain unchanged.

Validation rejects missing/duplicate/non-finite or off-map placements, bad finite stock, malformed profile/route definitions, unsupported ground routes and geometry obstruction. Flying route endpoints are checked for geometry clearance without requiring ground navigation. Validated ground locations connect to enabled extraction; existing entry validation separately checks collision, support, navigation and reachable salvage/exit. Temporarily blocked entries wait rather than teleporting or moving another actor. A setup failure stops the deployment clearly.

Initial admission and flare admission consult the same live capacity check, including the flare director's current rule resource. This preserves its runtime/test overrides. Actor instances and finite tickets remain under their existing owners. Later arrivals remain pending work for Stage O world lifetime after player death; camera position does not affect layout, admission or perception.

Area membership and diagnostics are sampled at 0.5-second intervals. The event buffer is capped at 64; events come from setup, entry, activity/objective transitions, collection and extraction. Detailed F3 information is presentation-only and hidden from normal post-death follow UI. There is no new continuous actor-pair decision scan, navigation planner or unbounded scheduler.

## Automated and engine validation

All **twenty-one automated suites passed**, retaining the twenty prior regressions and adding `tests/encounter_generation_test.gd`. A regression initially identified that the shared cap read the original flare resource rather than the director's current rules; this was corrected and the affected flare suite passed again. Focused Stage P checks were rerun after final diagnostics/test refinements.

New coverage includes seeded layout choice, stable order independent of resource insertion, same-seed snapshot equality/restart, multiple-seed variation, runtime seed controls, source-resource immutability, plain-F5/earlier-preset compatibility, all stock/components allocated once, rejected malformed quantities/IDs/caps, supported salvage/navigation, invalid off-map objectives and patrol points inside geometry.

Admission coverage includes scheduled delay, blocked preferred-marker retry, same-tick initial/response contention, full-cap waiting and reopening, five live initial Raiders with two machines, finite response chains and no equipment/material duplication. Controlled opportunities exercise competing allied stock claims, ordinary machine targeting/damage, hostile human shots/death/flare, physical timed recovery of fallen cargo and its later timed extraction loss. Player recall may complete while future initial entries remain pending.

Post-death coverage verifies permanent player failure, continuing late entries, camera-independent spawn selection, no internal configuration in normal follow UI, deadline sealing and unchanged previously banked stash contents. Test saves use unique ignored directories under `.godot/stage_p_tests/`; the real stash is not modified.

Natural runs across both authored arrangements resume normal actor physics, patrols, combat, scavenging and finite response processing. All five scheduled initial actors enter over time and actors are observed around multiple separate opportunity regions. Accounting and live limits remain valid. These cases do not require betrayal, a particular winner or an alliance change. Other isolated checks intentionally place actors and transfer fixture stock through the ledger to verify a specific accepted transition.

Godot **4.7.2 Standard** editor parsing/import, bounded headless runtime and Vulkan **Forward+** graphical startup passed. The Stage P suite and both developer/post-death spectator suites were also exercised graphically. Output was checked alongside exit status. No packaged release export was performed. Generated `.godot/` test data/builds remain excluded; script `.uid` files are retained.

## Performance observations and limits

Representative accelerated natural cases reached roughly 142-147 simulated seconds in about 18.3 wall-clock seconds per layout at 8x time scale, with five autonomous actors observed at peak in those cases. Separate controlled coverage fills five Raiders plus two machines. These are bounded integration timings on the development machine, not frame-time benchmarks or cross-hardware guarantees. Setup/path validation is performed before first admission; recurring diagnostic work is sampled and bounded.

Existing AI can repeatedly switch between cover/engagement or flight/extraction under continuing threats. Such transitions appeared in accelerated logs; assess their readability and pacing manually rather than treating test success as proof of balanced behavior. Stage P does not change that behavior framework. Original salvage is globally available to the existing objective scorer; only death-drop knowledge is observation-limited. Neutral competition alone does not produce hostility, alliances do not form dynamically, and Raiders do not loot equipment cases or equip stolen weapons. Substantial behavioral changes remain Stage Q candidates.

## Manual Checkpoint P procedure

1. **Passive:** Shift+F5, then F1. Observe the opening, arrivals at 35/70/105 seconds, stock competition, patrol crossings and independent exits. Look for useful quiet periods as well as encounters, without approaching actors with the robot.
2. **Active:** Intervene in one area, leave another alone, recover cargo/equipment and return to the Recall Dock. Check that independent objectives continue elsewhere and that flares create bounded pressure.
3. **Post-death:** Die before all scheduled arrivals, choose Spectate, cycle Raiders/machines, and watch later arrivals. Confirm that Return/deadline preserve the failed deployment and prior stash.
4. **Reproduction:** Restart the same seed and compare layout, profiles, stock, entry markers and schedule. Ctrl+Shift+F5 advances the seed; seeds 87017 and 87018 select different authored layouts in this engine version. Compare setup, not identical physics winners.
5. **Population/pacing:** Assess five-Raider congestion, cover/exit interference, capacity-delayed arrivals, patrol usefulness, frame pacing and late-arrival loot availability. Betrayal is optional and must not be forced for acceptance.

Manual believable-variety acceptance remains outstanding. Stop at **Checkpoint P** for feedback; no Stage Q implementation is authorized.

## Git checkpoints

The accepted pre-P project, including previously uncommitted J-O work and development records, is preserved in **`bac0f6d`**. Stage P is committed separately after validation; this report is included in that focused change. Use `git log` for its final commit ID. No remote publication is performed.
