# SCRAP Raiders

Internal working title for an original comedic third-person PvE game. The player controls a machine protecting its technology from human scavengers.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript, Forward+ renderer.
- Vulkan-capable graphics device; no external assets, frameworks, services, or networking.
- Blender is installed according to the director; its model/animation pipeline remains unvalidated and is outside Stage A.

Open with `godot --editor --path .`, then F5. Standalone: `godot --path .`.

The default `scenes/levels/test_arena.tscn` now runs **three profiled Raiders, three salvage points, nine materials**, and two extraction choices. The existing 32 m primitive arena, obstacles, shoulder camera, hitscan weapon, target practice objects, audio, hit effects, cargo cues, destruction tumbles, and deployment effect remain.

For the original one-Raider/three-material regression scenario:

```powershell
godot --path . res://scenes/levels/single_raider_arena.tscn
```

Both scenes use the same code. The inherited regression scene overrides Raider count and salvage-point count to one and sets `dynamic_ai = false`, preserving the original behavior and original exit. Stage A tests also explicitly disable dynamic AI. Restart reloads the scene you launched.

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

Escape releases controls without pausing simulation. Losing application focus also releases the cursor.

## Stage A scope and configuration

Stage A implements multiple independent Raiders, finite shared salvage, aggregate accounting, and multiple recoverable drops. Stage B adds the dynamic AI described below. Armed Raiders, random/delayed spawns, a larger map, mission presets, and multiplayer remain outside this checkpoint.

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

No Raider weapons are implemented. Damage always interrupts the current task and causes flight; lethal damage remains terminal. An empty/under-target fleeing Raider can resume scavenging after three seconds without visible danger (damage adds two seconds of memory). Raiders at their cargo target continue extraction. Threats still use line of sight; only observed or damage-revealed threat positions influence route risk.

Aggressive investigates once per observed threat position, then resumes objectives while the robot remains stationary. Investigation re-arms after the robot moves at least 2 m from that position, or after lost visibility outlasts threat memory. Its investigation standoff includes an arrival margin outside the close-threat flee distance; close approaches and damage still cause retreat.

The common FSM adds SELECTING, INVESTIGATING, and STRANDED to the existing states. Raider-specific state, timers, failed objectives, and sensor memory remain per instance. Profile resources are shared read-only definitions. `HitReaction`, death tumbles, weapon damage/cooldown, recovery, and mission outcome policy retain their existing ownership.

Objective scoring uses actual reachable navigation paths, path length, remaining stock, other Raiders targeting the location, known route danger, and a small seeded tie-break. Exit scoring uses reachable path length and known danger weighted by profile. Off-map/disconnected destinations are rejected. Decisions wait for usable navigation geometry, not merely a nonzero map iteration. Seeded scores reproduce choices for the same state; this does not promise bitwise deterministic physics.

Navigation watches physical progress at 1.5-second intervals while travelling. No progress first requests a repath; a repeated stall excludes that objective and selects an alternate salvage point or exit. If no exit is available, the Raider enters STRANDED with an explicit label and retries after two seconds. Failed-route exclusions are cleared on that retry so temporary obstructions can recover. The Raider remains unresolved with its exact cargo allocation until it escapes, dies, or the mission deadline ends deployment. There is no teleport or artificial extraction. The watchdog interval is configurable per Raider; these are simple recovery rules, not dynamic crowd avoidance.

F3 diagnostics include seed, personality, state, salvage, destination, cargo, threat visibility/memory, navigation status, and material conservation. Gameplay labels show profile names and brief actions separately. Gunfire/death awareness remains Stage D work. Arena expansion, delayed/random entries, and mission presets remain Stage C work.

Legacy behavior detects the robot within 8 m with line of sight and commits to the original exit when threatened. Both modes retain three-second scavenging/extraction dwell times and independent state, navigation, velocity, health, task timer, and objective per Raider. IDs appear in labels and transition logs.

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
- `scripts/ai/raider.gd`: common per-instance state machine and physical movement using NavigationAgent3D.
- `scripts/gameplay/material_drop.gd`: ledger-backed world presentation.
- `scripts/player/`: input, CharacterBody3D movement, independent camera orbit, combat presentation.
- `scripts/gameplay/hitscan_weapon.gd`, `resources/weapons/`: weapon cadence/resolution and tuning.
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

Stop at **Checkpoint B** for director review. Do not advance automatically.

- Stage B: objective scoring, extraction choices, personalities, threat behavior, navigation recovery.
- Stage C: expanded graybox, dynamic/configurable entries, three mission presets, scenario selection.
- Stage D: gunfire awareness and additional gameplay feedback.

Keep networking, progression, detailed Blender models, and final art outside this stage.
