# Phase 5, Stage P - Dynamic encounter generation plan

Prepared: **2026-10-19**. **Approved, implemented and accepted at Checkpoint P on 2026-10-20**, including subsequent combat corrections. The original proposal below is retained as the approved plan. See the [Stage P delivery report](../reports/stage_p_dynamic_encounters.md) for actual behavior, validation and limits. The [supplied Stage P ledger](../ledgers/phase_5_stage_p_dynamic_encounter_generation.md) is unchanged. Stage O functionality has been confirmed by the director.

## Goal and minimum change

Create varied, seeded world conditions using the existing mission framework and independent actors. Add one optional encounter-layout resource to MissionConfig, a bounded population setting, and a dedicated development preset. Resolve the layout before constructing the material ledger and actors. Reuse the current scheduler, navigation checks, AI, social rules, combat, flares, loot, extraction and spectator lifecycle.

No runtime director chooses who fights, cooperates, betrays or extracts. Layout selection establishes locations and schedules; AI remains responsible for outcomes. Existing presets opt out and retain their configuration and behavior.

## Repository review

| Existing capability | Actual ownership/behavior | Stage P action |
| --- | --- | --- |
| Mission scheduling | MissionConfig owns definition; MissionArena schedules identified entries, seeded marker order, retries and pending-entry state | Reuse; stagger five finite initial arrivals and preserve blocked-entry retry/deadline behavior |
| Spawn validation | Capsule clearance against geometry/actors, floor support, navigation proximity and reachable salvage/exit checks | Reuse for all initial/responder entries; validate new layout locations/routes before gameplay |
| Personalities | Three existing resources, currently assigned by Raider ID modulo the profile list | Allow optional layout-authored per-ID profile order without editing shared resources |
| Relationships/cooperation | Explicit symmetric pair attitudes, independent of squads; local three-second allied observations | Reuse authored distribution; no automatic hostility from contention or dynamic alliance formation |
| Betrayal | One opt-in opportunist, continuous visible cargo/range/health assessment and existing threat/combat/retreat guards | Reuse unchanged; never require a betrayal to demonstrate the preset |
| Salvage | Three fixed point nodes, uniform materials-per-point; reachable value/contention scoring already exists | Resolve optional per-point positions and finite quantities before MaterialLedger initialization |
| Machine patrols | Independent scout/guard controllers; ecosystem currently reads fixed ScoutRoute/GuardRoute groups | Allow layout-selected authored route groups, retaining controllers and two preallocated component sources |
| Extraction | Two existing reachable exits, independent Raider selection and ordinary extraction accounting | Retain both; intersect travel through placement rather than reservations or artificial denial |
| Flares/population | One accepted flare per death, two total responders, living-Raider cap in FlareConfig; initial admission checks that cap when flares exist | Share the optional scenario population ceiling across initial admissions and responders, even without flares |
| Spectators/lifecycle | Shared camera rig, developer free flight, restricted post-death follow, permanent player failure and independent world lifetime | Preserve; pending scheduled entries/responses must keep a post-death world alive |
| Diagnostics | Existing seed/F3 output, target/relationship inspector, actor state-transition logs | Extend with resolved layout and bounded event history; normal spectator UI stays unchanged |

Most desired interactions are already possible. Current limitations must stay explicit: original salvage is globally available to objective scoring, unlike observed death drops; neutral competition alone does not create hostility; alliances do not form dynamically; Raiders loot material cargo, not equipment cases; existing armed combat behavior limits personality-specific threat avoidance. Stage P does not silently add these Stage Q behavior candidates.

## 1. Optional, data-driven encounter layout

Add a small `EncounterLayout` resource used only by scenarios that supply a layout pool. Its data describes a stable layout ID, three salvage marker assignments/quantities, per-ID entry-marker assignments, optional existing profile order, and authored scout/guard route-group references. Do not add nested encounter controllers or actor commands. Continue using MissionConfig for count, entry times, seed, exits, social rules, traversal, recall, flares and post-death spectating.

Provide at least two validated layouts using the current graybox. Each supports reusable opportunities: a contested stock location, a patrol intersection, and overlapping travel toward existing exits. Named areas/markers identify the opportunities for diagnostics; they are not combat triggers or private actor objectives. No exclusive claims or forced participation are created.

Use one seeded setup resolver with stable input ordering. Select from the small authored layout pool and produce a mission-local resolved record. Never mutate preloaded/shared MissionConfig, layout, personality, combat or social resources. Apply selected placements/stock before MaterialLedger construction and routes before machine creation. All stock and installed components are allocated once upfront; changing an opportunity's value cannot create materials during simulation.

Validate array lengths, IDs, positive finite stock, unique salvage identity/location, marker existence, traversable salvage positions and ground-machine routes, supported entry positions, and reachability to the relevant enabled objectives/exits. Check flying patrol points against geometry without requiring them to lie on ground navigation. Reject malformed layout setup clearly; temporarily blocked actor entry waits through existing retries rather than teleporting or relocating an entered actor.

## 2. Development preset and bounded pacing

Add **Emergent Encounters - Development Preset** as a separate inherited scene/config. Proposed starting setup, subject to navigation validation:

- Five finite initial Raider IDs, arriving at **0, 0, 35, 70 and 105 seconds** during the existing 180-second deployment. Entry times are conditions, not a wave-completion dependency.
- Mixed existing Greedy/Cowardly/Aggressive profiles; one explicitly allied pair, one independent neutral competitor, and later explicitly authored rivals. One member of the allied pair is betrayal-capable. Relationships remain independent from profiles, ownership and squads.
- Three salvage allocations of **6, 3 and 3 units**, with the valuable point and route intersections varying by selected layout. Scout and guard each retain one installed component: **14 total material units**, equipment separate.
- Two autonomous machines with authored intersecting patrols, both existing Raider exits, player recall/stash, jump/boost, developer observation and Stage O post-death following.
- At most **five living Raiders**, including both initial actors and responders, plus at most two support machines. This is seven autonomous live actors, eight including the robot. Five scheduled initial Raiders plus at most two reinforcement admissions give a finite lifetime budget of seven human actors.
- Existing flare delays, low responder equipment value and two-ticket reinforcement budget. Initial arrivals and responders both respect the shared live cap. If pressure occupies capacity, later scheduled entries wait; no extra material or response budget is generated.

Reuse current entry and flare processing intervals. No new per-frame actor-pair scan, navigation planner, time-varying difficulty, random spawning loop or replenishing stock. Pending schedules/tickets expire at world termination and reset on restart. Ground loot alone does not prolong a dead player's empty world.

### Input and reproducibility

F1-F12 already have assignments in the current project; F5 also currently matches modified F5 events. Propose an explicit **Shift+F5** branch for the new debug preset before the existing plain-F5 dispatch. Plain F5 remains Integrated Extraction. **Ctrl+Shift+F5** starts the encounter preset with the next seed; normal restart repeats the current seed. Provide a direct scene launch as well.

Expose the active seed, chosen layout ID, resolved stock/markers/profile order and entry schedule in F3. Persist only the selected runtime seed across restart of this preset; switching older scenarios restores their own definitions. Test equal-seed setup equality, multiple-seed variation and stable tie/order behavior. Do not claim bitwise deterministic navigation/physics or guarantee a different layout for every adjacent seed.

## 3. Reuse outcomes and add read-only diagnostics

Existing AI chooses salvage, machine/human targets, reports, cover, retreat, loot and exits. Do not introduce a behavioral selector, automatic hostility on shared stock, forced betrayal/cooperation, kill reward, guaranteed victory or scripted extraction interruption.

Extend developer F3/inspection with layout/opportunity origin, remaining finite stock, actors physically near each opportunity and their actual objectives/relations. Track a small bounded event buffer (for example 64 entries) from existing entry, state-change, accepted collection, death and extraction events. Include actor IDs/time and relation reasons where relevant. Sample area membership only at a bounded interval; avoid per-frame logs and duplicating authoritative state. Opportunity availability/resolution is derived from world/ledger state, not a new authority.

Keep this information out of normal player post-death UI. Spawn/layout/seed selection never reads camera position. All setup, pending arrivals, responses and AI continue under the existing world-running policy after player death, with no change to failed deployment, exactly-once forfeiture or persistence.

## 4. Implementation sequence after plan approval

1. Preserve the accepted pre-P working state as a separate local baseline checkpoint, then add the opt-in layout definition/resolver and validations. Existing J-O implementation and documentation are currently uncommitted; do not fold them invisibly into a Stage P change or discard them.
2. Integrate per-point stock/placement, profile order and selected machine route groups using existing construction hooks. Apply the shared population ceiling to initial and responder admission.
3. Author two reusable layouts and the staggered development preset. Add the explicit shortcut/seed-replay controls and bounded read-only diagnostics.
4. Add focused configuration/lifecycle tests and natural simulation cases, run all checks and inspect graphical startup. Document the actual results and limits.
5. Create the ledger-requested focused Stage P commit after successful validation, separate from the accepted baseline. Stop at Checkpoint P for manual review; do not start Q.

The ledger requests a post-validation Stage P commit. Approval of this plan should cover the separate baseline checkpoint and focused P commit sequence; neither commit is performed during this planning turn. No remote publication is proposed.

## Risks and tests

| Risk | Validation |
| --- | --- |
| Existing presets changed by shared resources | Snapshot old configuration/stock/profile/route behavior; opt-in defaults; full prior twenty-suite regression run |
| Unsupported or unreachable layout | Invalid/missing marker, duplicate/negative stock, blocked entry, overlapping actors, route geometry/support/navigation and both enabled exits |
| Cap exceeded by same-tick admission | Simultaneous initial/responder due times, full-cap wait/retry, capacity reopening, finite ticket/lifetime budgets and no replenishment from responder death |
| Setup not reproducible | Equal-seed resolved record/restart equality, varied seed corpus, explicit stable ordering and seed controls |
| Everything fights immediately or later arrivals have nothing useful to do | Natural bounded runs across layouts/seeds, multiple opportunity areas and later entries; manual review of quiet periods, loot contention and pacing |
| Material duplication or incorrect loss | Contested/partial stock, ordinary rival death, ground loot competition, loaded survivor extraction, component release, equipment identity and conservation after accepted transfers |
| Invalid post-death completion | Pending later entries and tickets keep world alive; no camera influence; no reward after death; deadline/Return seal and restart clears resolved setup and diagnostics |
| Excess work or misleading logs | Bounded history/membership sampling, event deduplication, finite pending work, current actor objectives derived rather than assigned |

Add `tests/encounter_generation_test.gd`, preserving all twenty current suites. New coverage includes seeded setup, placements, scheduling/caps, multiple independent opportunity regions, neutral contention without forced hostility, explicit rival combat, machine participation, ordinary flare escalation, finite responders, contested/stolen cargo extraction, restart, post-death continuation, camera non-interference and both accounting invariants.

Use controlled actor conditions to test a specific hostile shot, loot transfer or betrayal guard. Natural simulation cases must not depend on a particular betrayal, cooperation event or winner. They should establish autonomous activity in separate regions/times and valid accounting, while recording observed outcomes. Existing personality/social logic remains unchanged.

Run Godot 4.7.2 editor parsing/import, **all twenty-one automated suites**, bounded headless runtime, Forward+ graphical startup and affected spectator checks. Use isolated saves and ignored test artifacts. Record timings, live counts and any navigation/performance concern discovered; do not infer cross-hardware performance from this machine. No new tests were run during documentation-only planning.

## Manual Checkpoint P procedure

1. **Passive:** Shift+F5, then F1. Observe early and late opportunities without moving the robot into them. Look for independent scavenging, machine crossings, neutral competition, rival fights, loot pickup and extraction when conditions permit.
2. **Active:** Intervene in one area, leave another alone, recover material/equipment and attempt recall. Assess whether the untouched area continues independently and whether later arrivals add pressure without global constant combat.
3. **Post-death:** Die while later entries/responses remain pending. Follow humans/machines, watch later arrivals and accounting, then Return or wait for the deadline. No rewards may be earned after death.
4. **Reproduction:** Restart the same seed, compare setup and readable event history, then use Ctrl+Shift+F5 to try other seeds. Compare opportunities rather than demanding identical combat winners.
5. **Population:** Observe the five-Raider/two-machine ceiling, blocked-entry retries, cover congestion, late entry usefulness, patrol intersections and frame pacing.

Manual review must establish believable variety and pacing before P acceptance. Existing AI limitations are reported as such; substantial behavioral changes remain Stage Q proposals, requiring separate approval.
