# SCRAP Raiders

Internal working title for an original comedic third-person PvE game. The player controls a machine protecting its technology from human scavengers.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript, Forward+ renderer.
- Vulkan-capable graphics device; no external assets, frameworks, services, or networking.
- Blender is installed according to the director; detailed models and animations remain outside this phase.

Open with `godot --editor --path .`, then F5. Standalone: `godot --path .`.

The default `scenes/levels/mission_arena.tscn` runs **Intercept** in the expanded 48 m graybox. Use F6/F7/F8 for the accepted unarmed Intercept, Swarm, and Recovery scenarios; **F9 deploys armed Survival**. Movement, shoulder camera, hitscan combat, practice targets, audio, hit effects, cargo cues, destruction tumbles, and deployment presentation remain shared.

The original 32 m three-Raider arena remains available at `scenes/levels/test_arena.tscn` for Stage A/B regression checks.

For the original one-Raider/three-material regression scenario:

```powershell
godot --path . res://scenes/levels/single_raider_arena.tscn
```

The arenas share the same simulation code. The inherited single-Raider scene overrides Raider count and salvage-point count to one and sets `dynamic_ai = false`, preserving the original behavior and original exit. Stage A tests also explicitly disable dynamic AI. Restart preserves the selected scene/scenario and creates fresh runtime state.

| Control | Action |
| --- | --- |
| Physical WASD | Camera-relative movement |
| Mouse | Camera orbit |
| Hold RMB | Aim-facing |
| Hold LMB | Fire |
| E | Recover nearest eligible cargo |
| Escape / click | Release / capture mouse |
| R or Restart button | Restart after mission completion |
| F3 | Toggle developer diagnostics independently of gameplay prompts |
| F6 / F7 / F8 | Deploy Intercept / Swarm / Recovery in the expanded arena |
| F9 | Deploy armed Survival (Stage E) |

Escape releases controls without pausing simulation. Losing application focus also releases the cursor.

## Stage A scope and configuration

Stage A implements multiple independent Raiders, finite shared salvage, aggregate accounting, and multiple recoverable drops. Stage B adds dynamic AI. Stage C adds the expanded arena, scheduled entries, and mission presets below. Stage E adds armed combat in a separate Survival preset; multiplayer remains outside scope.

Arena Inspector parameters:

- `raider_count`: 1–5, default 3.
- `salvage_point_count`: 1–3, default 3.
- `materials_per_point`: default 3; total material stock is derived from enabled points.
- `mission_duration`: default 180 seconds.
- `pickup_distance`: default 1.8 m.
- `dynamic_ai`: true by default; false retains Stage A selection/behavior and the original exit.
- `debug_seed`: default 4711; controls deterministic local score tie-breaks, without changing global random state or spawning.

Five authored spawn markers live under `RaiderSpawns`. All configured Raiders enter immediately. Spawns are checked against geometry, actors, and already selected positions. Invalid deployment stops with an explicit setup error. No automatic teleport is used.

With dynamic AI disabled, salvage assignment is stable and cyclic by Raider ID and each Raider collects once. A point is not reserved: the first validated collection request transfers available stock atomically. A competing Raider cannot duplicate it; it selects another available point or heads for extraction if none remain. Dynamic AI instead uses scored selection and a profile cargo target; repeated collections debit finite stock only up to the remaining target capacity.

## Stage B dynamic AI

Three shared resources in `resources/enemies/` parameterize one common FSM:

| Profile | Visible threat range / flee distance | Cargo target | Behavior |
| --- | --- | --- | --- |
| Greedy (gold body) | 8 m / 3 m | 6 | Tolerates distant danger and seeks additional finite salvage |
| Cowardly (blue body) | 12 m / 12 m | 3 | Retreats early and strongly penalizes dangerous routes |
| Aggressive (red body) | 10 m / 3 m | 3 | Investigates a last-seen position for up to two seconds before resuming objectives |

In the unarmed scenarios, damage interrupts the current task and causes flight; lethal damage remains terminal. An empty/under-target fleeing Raider can resume scavenging after three seconds without visible danger (damage adds two seconds of memory). Raiders at their cargo target continue extraction. Threats still use line of sight; only observed or damage-revealed threat positions influence route risk. Armed Survival uses the combat behavior below.

Aggressive investigates once per observed threat position, then resumes objectives while the robot remains stationary. Investigation re-arms after the robot moves at least 2 m from that position, or after lost visibility outlasts threat memory. Its investigation standoff includes an arrival margin outside the close-threat flee distance; close approaches and damage still cause retreat.

The common FSM adds SELECTING, INVESTIGATING, and STRANDED to the existing states. Raider-specific state, timers, failed objectives, and sensor memory remain per instance. Profile resources are shared read-only definitions. `HitReaction`, death tumbles, weapon damage/cooldown, recovery, and mission outcome policy retain their existing ownership.

Objective scoring uses actual reachable navigation paths, path length, remaining stock, other Raiders targeting the location, known route danger, and a small seeded tie-break. Exit scoring uses reachable path length and known danger weighted by profile. Off-map/disconnected destinations are rejected. Decisions wait for usable navigation geometry, not merely a nonzero map iteration. Seeded scores reproduce choices for the same state; this does not promise bitwise deterministic physics.

Navigation watches physical progress at 1.5-second intervals while travelling. No progress first requests a repath; a repeated stall excludes that objective and selects an alternate salvage point or exit. If no exit is available, the Raider enters STRANDED with an explicit label and retries after two seconds. Failed-route exclusions are cleared on that retry so temporary obstructions can recover. The Raider remains unresolved with its exact cargo allocation until it escapes, dies, or the mission deadline ends deployment. There is no teleport or artificial extraction. The watchdog interval is configurable per Raider; these are simple recovery rules, not dynamic crowd avoidance.

F3 diagnostics include seed, personality, state, salvage, destination, cargo, threat source/visibility/memory, navigation status, and material conservation. Gameplay labels show profile names and brief actions separately. Stage D adds the gunfire reactions below.

Legacy behavior detects the robot within 8 m with line of sight and commits to the original exit when threatened. Both modes retain three-second scavenging/extraction dwell times and independent state, navigation, velocity, health, task timer, and objective per Raider. IDs appear in labels and transition logs.

## Stage C arena and mission variety

`mission_arena.tscn` inherits the existing arena and adds a 48 m floor/boundary, separated routes around tall sight blockers, low cover near an open central/southern area, a narrower west-central passage, and a raised east-side lookout reached by a shallow ramp. Ramp guards prevent navigation shortcuts up edges that CharacterBody movement cannot step over. All enabled salvage, spawn and exit locations are connected by the baked navigation mesh. The original arenas retain their geometry and immediate-entry behavior.

Three shared `MissionConfig` resources under `resources/missions/` define quantities, duration, ordered entry times, allowed spawn marker names, available exits, seed, and starting ground cargo:

| Scenario / key | Raiders / entry times (seconds) | Protected / initial ground | Deadline | Exits |
| --- | --- | --- | --- | --- |
| Intercept / F6 | 3 / 0, 4, 8 | 9 / 0 | 180 s | Both |
| Swarm / F7 | 5 / 0, 0, 2, 4, 6 | 15 / 0 | 180 s | Both |
| Recovery / F8 | 2 / 8, 16 | 6 / 6 (three stacks of two) | 150 s | B only |

F6/F7/F8 replace the current deployment immediately, including after its summary. This is a debug selector: switching discards that run, and R restarts the selected scenario. There is no saved progression or menu framework. The scene's `scenario_index` Inspector property chooses its initial preset; edit the mission resource to tune that preset. All presets use the same Raider profiles and mission outcome rules.

The mission arena owns pending entry IDs and the schedule. Every scheduled Raider is registered in the ledger at setup, so unresolved counts include pending entries and early kills cannot complete the deployment before later entries. F3 shows pending IDs and entry/retry status; the gameplay HUD shows pending count separately. The deadline stops entry, preserves all material categories, and reports Raiders that never entered.

Each mission seed shuffles the authored marker order with a local RNG. Each due Raider tries that stable order with an ID offset; blocked markers fall back to another valid candidate. Entry validation checks the capsule against geometry/actors, same-tick actor positions, supported ground, navigation proximity, and paths to enabled salvage and an enabled exit. A completely blocked entry stays pending and retries every 0.5 s until clear or the deadline. Entries never teleport, mint materials, or silently count as extracted. Identical seeds and world state reproduce entry choices; player obstruction and physics can change actual admission timing.

Recovery's initial ground allocations are part of the ledger's initial total, with source ID zero (mission stock). Physical cubes are only views of those allocations. Later death drops receive IDs beyond the initial stacks. Existing E eligibility, prompts, accounting, recovery-only phase, and deadline distinctions apply unchanged.

## Stage D awareness and readability

The arena forwards the existing weapon `fired` event to entered, living Raiders while deployment is active. Accepted hits and misses both produce gunfire awareness; cooldown-rejected triggers produce no event. Weapon damage, cadence, health, and material accounting retain their original owners.

Hearing uses distance to the shot's muzzle origin: Greedy 12 m, Cowardly 18 m, Aggressive 16 m. This deliberately simple radius rule allows hearing through cover without sound propagation or impact/near-miss simulation. An unseen shot records a last-known source and refreshes three-second threat memory; it never grants sight or tracks subsequent unseen player movement.

Cowardly retreats from audible shots, Greedy continues scavenging unless the source is within its close-threat distance, and under-target Aggressive can investigate the heard source. Existing close-range and damage retreat take priority. Stationary repeated shots retain the investigation re-arm guard; they refresh memory without restarting an active retreat or extraction task. Empty fleeing Raiders can resume scavenging after memory expires. Loaded Raiders continue toward extraction, and unreachable investigation routes retain the existing watchdog fallback. The inherited single-Raider regression mode keeps its original behavior.

World feedback reads simulation state: `?` marks investigation and `!` marks alertness; `GUNFIRE` identifies an audible source. Indicators clear with threat memory and stop at mission completion. Loaded backpacks become gold with a subtle emission; empty packs stay dark. Depleted salvage hides its crate and displays `DEPLETED`. Existing nearest-drop highlight and E eligibility remain shared. `raider_feedback.gd` owns presentation only and cannot advance task clocks, change health, or transfer cargo. Detailed state and threat diagnostics remain behind F3.

## Phase 3, Stage E hostile combat

Launch with F9, or directly with `godot --path . res://scenes/levels/survival_arena.tscn`. Survival uses three armed scavengers entering at 0/5/10 seconds, nine materials, both exits, a 180-second deadline, and seed 32017. The three original presets remain unarmed. This checkpoint uses their existing mission completion policy; player extraction and persistent rewards are Stage G work.

Player hull starts at 100. `Health` remains the sole writer of current health and records the accepted impact origin. A separate player HUD shows hull, a brief red border and directional indicator, and an original synthesized impact tone. Destruction creates a cosmetic tumble, hides the robot visuals, and reports explicit deployment failure. Controls, player and enemy weapons, pending entry, and transfers stop. Restart resets health, outcomes, cover reservations, random streams, and the ledger while preserving scenario selection.

`ShotExecutor` owns cooldown, range clamping, muzzle obstruction, accepted damage, and the existing shot event for both sides. `HitscanWeapon` adapts the player's camera aim/input to it. Enemy intent comes from `RaiderCombat`, with no camera or player-input dependency. Environment and other Raiders block hostile shots; friendly Raiders take no damage from those shots. Cosmetic tracers and rifle audio live in `RaiderFeedback`.

The initial combat resource uses 10 damage, 0.8-second shot interval, 24 m physical range, 18 m engagement range, 2-degree seeded aim spread, and a 0.65-second visible aim warning. Each actor has its own RNG and shot cooldown. Visibility and engagement range are checked again immediately before firing. Losing sight or changing combat state resets the warning. Armed scavengers engage visible threats, return to salvage when danger is forgotten, seek cover after damage, and retreat at or below 30% health. Their existing personality resource still controls noncombat decisions.

The common Raider FSM adds ENGAGING, TAKING_COVER, and REPOSITIONING. `RaiderCombat` supplies decisions and aim timing through that FSM; CharacterBody3D retains movement/velocity. Authored cover slots include a protected position and peek position. The arena validates cover against the last-known threat, clear peek sightlines, navigation reachability, and exclusive actor reservations. Cover dwell is one second, followed by physical movement to the peek position and a fresh warning. Fighters also attempt repositioning after three seconds of engagement. Reservations are released on disengagement, retreat, death, extraction, or mission shutdown. No valid cover falls back to investigation or retreat; stalled cover routes use the existing navigation watchdog. This is basic squad coordination through cover allocation, with no shared movement controller or tactical squad framework.

Player destruction is a distinct mission reason, separate from deadline expiration and Raider material outcomes. At this temporary Stage E boundary, **all material categories are preserved exactly and sealed**: protected, carried, ground, recovered, and extracted/lost. Death does not relabel cargo as extracted loss or create persistent inventory consequences. Flare response, equipment loot, player extraction, and persistence remain outside Stage E.

## Ownership and material conservation

`MaterialLedger` is the sole writer of all material quantities and locations:

```text
Protected + Carried + Ground + Recovered + Lost = Total Mission Materials
```

- Protected: remaining stock indexed by salvage location ID.
- Carried: stock indexed by registered Raider ID.
- Ground: stacks indexed by unique mission-local drop ID, retaining their source Raider ID.
- Recovered: mission inventory credited by accepted recovery transfers.
- Lost: materials that actually left through Raider extraction.

The ledger derives aggregate totals from its records and validates nonnegative quantities and conservation after **every accepted transfer**, including empty death/extraction resolution. Validation executes in release builds too; debug assertions add diagnostics. Unknown IDs, duplicate resolutions/recovery, depleted stock, and transfers after the ledger is sealed are rejected without mutation.

Raiders request collection and report death/extraction. They read cargo from the ledger; they cannot mint cargo. The arena validates the requesting actor, state, timing, and location before requesting a collection transfer. On death it asks the ledger to move that Raider's cargo into a new drop allocation, then creates its physical representation. Empty deaths create no drop.

`MaterialDrop` only exposes its ledger stack and renders its highlight/label. It cannot independently consume, create, or credit materials. Recovery credits the ledger once and removes that physical stack. Duplicate/stale drop IDs retain no recoverable quantity.

The same eligibility function drives candidate selection, highlight, prompt, and pickup: active mission, registered drop identity, positive ledger allocation, distance, and unobstructed access. Choose the nearest eligible stack; equal distances within a small numerical tolerance break by lower drop ID. Only that stack highlights. Mouse capture governs physical input; eligibility remains a spatial/gameplay rule. Recovering cargo is allowed while other Raiders are active.

## Mission outcome policy

`MissionRules` is separate from the ledger. It reads material totals and the number of unresolved Raiders; it never transfers materials.

| Condition | Outcome |
| --- | --- |
| Any Raider remains active | HUNTING: intercept and recover simultaneously |
| All Raiders resolved, ground cargo remains | RECOVERING: player retains controls until recovery or deadline |
| All Raiders resolved, no ground cargo, no extraction loss | SUCCEEDED |
| All Raiders resolved, no ground cargo, extraction loss exists | FAILED |
| Deployment deadline expires | FAILED; preserve every material category as it stands |

Materials still protected at their original salvage points **do not block completion**. One death/extraction cannot end the other Raiders' simulation. An early extraction loss is recorded immediately, but the mission remains playable while other Raiders or ground cargo remain.

At the deadline, ground cargo remains **unrecovered**, not extracted/lost. Still-carried cargo also remains carried. The summary reports protected, recovered, extracted/lost, unrecovered ground, carried, total, and elapsed time separately. Terminal completion seals transfers, stops all live actors and player combat/movement input, releases the cursor, and shows the restart control. Cosmetic tumble/particle cleanup can continue. Restart creates a fresh ledger, actors, drops, timer, and outcomes; there is no persistent progression or global mission singleton.

## Code boundaries

- `scripts/gameplay/material_ledger.gd`: authoritative material transfers, identity, actor resolution, invariants.
- `scripts/gameplay/mission_rules.gd`: mission phase and outcome policy.
- `scripts/gameplay/raider_arena.gd`: composition, registration, event validation, spawn validation, interaction, and HUD/summary wiring.
- `scripts/gameplay/mission_arena.gd`: Stage C entry scheduling, admission validation, and debug scenario selection using shared arena composition.
- `scripts/gameplay/mission_config.gd`, `resources/missions/`: mission definitions, with no mutable runtime mission state.
- `scripts/ai/raider.gd`: common per-instance state machine and physical movement using NavigationAgent3D.
- `scripts/gameplay/material_drop.gd`: ledger-backed world presentation.
- `scripts/player/`: input, CharacterBody3D movement, independent camera orbit, combat presentation.
- `scripts/gameplay/hitscan_weapon.gd`, `resources/weapons/`: weapon cadence/resolution and tuning.
- `scripts/gameplay/shot_executor.gd`: shared shot execution, cooldown, physical obstruction and damage.
- `scripts/ai/raider_combat.gd`, `raider_combat_profile.gd`: armed decision/aim intent and combat tuning, using the common Raider FSM.
- `scripts/player/player_damage_feedback.gd`: hull, incoming damage, directional feedback and destruction presentation.
- `scripts/components/`: health, visual hit reaction, cosmetic death tumble.
- `scripts/presentation/`, `scenes/effects/`: self-contained deployment presentation.

Health, weapon damage/cadence, movement, camera ownership, and physics presentation retain their existing boundaries. The blaster deals 25 damage at 0.2 s intervals over 80 m. The center camera ray chooses aim; the muzzle ray checks cover, extending 5 cm past the surface hit to avoid curved-collider rounding misses.

Navigation bakes synchronously once from the small arena's tagged collision geometry, including practice targets. Agent path height offset remains 0.5 m for this bake. Destroyed targets leave conservative footprints until restart. There is no dynamic crowd avoidance. Crowding and player obstruction remain manual testing priorities, especially with five Raiders. Path targets change when destinations change or the watchdog explicitly retries; perception decisions remain on a 0.15 s interval. Path scoring runs during objective/exit selection, not every render frame.

All visual/audio assets are engine primitives or original generated PCM. Cosmetic tumble bodies have collision layer zero: gameplay shots, movement, perception, and pickup queries ignore them. Cargo stays stationary and recoverable after the tumble expires.

## Validation

Run the editor import before the script tests:

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/robot_controller_test.gd
godot --headless --path . --script res://tests/combat_test.gd
godot --headless --path . --script res://tests/raider_test.gd
godot --headless --path . --script res://tests/mission_test.gd
godot --headless --path . --script res://tests/destruction_test.gd
godot --headless --path . --script res://tests/multi_raider_test.gd
godot --headless --path . --script res://tests/dynamic_ai_test.gd
godot --headless --path . --script res://tests/mission_variety_test.gd
godot --headless --path . --script res://tests/awareness_test.gd
godot --headless --path . --script res://tests/hostile_combat_test.gd
godot --headless --path . --quit-after 180
godot --path . --quit-after 180
```

The five original suites use the inherited single-Raider scene to preserve movement, combat, scavenging, extraction, loot, mission outcomes, restart, and cosmetic cleanup coverage. Accounting unit checks now address the separate ledger and policy.

Stage A coverage includes contested/partial salvage, accepted-transfer invariants, duplicate events, same-frame deaths, independent actor state, identified overlapping drops, deterministic selection, recovery during active interception, recovery-only controls, mixed losses, deadline categories, sealing, untouched protected stock, and multi-actor restart. Natural bounded navigation runs exercise three and five Raiders without teleporting them; these runs accelerate simulation time for test duration. Other setup-specific interaction tests place actors near objectives to isolate transitions.

Automated tests and graphical startup do not establish gameplay feel, visual readability, or performance on typical gaming PCs. Manual Stage A review should cover competing interception choices, crowding at salvage/exit, multiple kills and pickups, nearest-stack prompts around cover, F3 readability, deadline summary distinctions, and restart.

Stage A validation on 2026-10-18: all five adapted regression suites and the new multi-Raider suite passed, including actual independent hitscan kills and bounded three/five-Raider navigation runs. Godot 4.7.2 editor import/parsing, bounded headless startup, and Vulkan Forward+ graphical startup passed without reported errors. Manual Stage A play-testing is pending.

## Review checkpoints and Git

The accepted primitive prototype was preserved in baseline commit `d51acfd` before this refactor. Stage A is committed separately after validation. Work remains on the existing `master` branch; no remote is configured or changed. Generated `.godot/` state and builds are ignored; script `.uid` files are tracked.

Stage A was accepted in commit `49cf442`. Stage B tests cover profile-specific reactions, investigation interruption, resuming scavenging, seeded scoring, reachable/safe exit choice, finite two-location cargo accumulation, repath/alternate/stranded transitions, a physical no-progress watchdog, and natural three/five-Raider resolution. Manual Stage B review remains necessary for personality differences, investigation readability, retreat/resume pacing, route choices, and congestion recovery.

Stage B validation (2026-10-18): the five original regression suites, Stage A suite, and new Stage B suite passed. Godot 4.7.2 import/parsing and bounded Forward+ startup passed without reported errors. Simulation checks are automated; profile feel and navigation recovery in player-created congestion still require manual play-testing.

Stage B, including the stationary-threat investigation fix (`ee3159b`), has been accepted by the director.

Stage C coverage includes configuration validation, initial ground stock and unique IDs, timed entries, pending-entry completion guards, collision/support/navigation checks, blocked-entry retry, same-tick separation, seeded replay, restricted exits, normal recovery, deadline accounting, scenario switching, restart, reachable map locations, physical ramp traversal, and natural resolution of all three presets. Manual review should cover interception distances and timing, five-Raider congestion, camera behavior in passages/on the ramp, cover readability, and Recovery pickup routes.

Stage C validation (2026-10-18): all eight automated suites passed, including the seven existing regression suites and `mission_variety_test.gd`. Godot 4.7.2 import/parsing, bounded headless startup, and Vulkan Forward+ graphical startup passed without reported errors. Manual Stage C play-testing remains pending; automated runs establish simulation behavior rather than encounter feel or typical-PC performance.

Stage C (`e9d6e48`) has been accepted by the director.

Stage D automated coverage includes actual missed-shot dispatch, cooldown suppression, independent profile reactions, hearing through cover, out-of-range rejection, last-known-position memory, investigation re-arming, damage priority, repeated-shot task preservation, return to scavenging, feedback ownership/cleanup, depleted salvage, terminal events, and legacy behavior. All nine suites, Godot 4.7.2 import/parsing, bounded headless startup, and Forward+ graphical startup passed on 2026-10-18. Manual review remains necessary for hearing distances, sustained-fire behavior, alert/cargo readability, and clutter with five Raiders.

Stage D (`9f21ae8`) and Phase 2 were accepted by the director. Phase 3 Stage E was approved separately with temporary death accounting that preserves ledger categories.

Stage E coverage includes real hostile hits and a lethal shot, warning/cadence/range, physical cover obstruction, visibility interruption, distinct cover reservations, damage interruption, retreat/extraction, return to scavenging, independent attackers, one-time player death, terminal shutdown, exact material categories, seeded restart, cosmetic destruction, and natural firing/cover/peek physics. All ten automated suites passed on 2026-10-18, including the nine existing regression suites. Godot 4.7.2 import/parsing and bounded headless/Forward+ Survival startup passed without reported errors. Manual survival testing must establish incoming damage readability, warning fairness, accuracy, cover choices/congestion, difficulty against multiple attackers, and restart behavior.

Stop at **Checkpoint E** for director review. Stages F-I remain planned and require separate approval.

- Stage B: objective scoring, extraction choices, personalities, threat behavior, navigation recovery.
- Stage C: expanded graybox, dynamic/configurable entries, three mission presets, scenario selection.
- Stage D: gunfire awareness and additional gameplay feedback.

Keep networking, progression, detailed Blender models, and final art outside this stage.
