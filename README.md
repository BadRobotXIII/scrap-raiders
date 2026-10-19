# SCRAP Raiders

Internal working title for an original comedic third-person PvE game. The player controls a machine protecting its technology from human scavengers.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript, Forward+ renderer.
- Vulkan-capable graphics device; no external assets, frameworks, services, or networking.
- Blender is installed according to the director; its model/animation pipeline remains unvalidated and is outside Stage A.

Open with `godot --editor --path .`, then F5. Standalone: `godot --path .`.

The default `scenes/levels/test_arena.tscn` now runs **three Raiders, three salvage points, nine materials**, and one shared exit. The existing 32 m primitive arena, obstacles, shoulder camera, hitscan weapon, target practice objects, audio, hit effects, cargo cues, destruction tumbles, and deployment effect remain.

For the original one-Raider/three-material regression scenario:

```powershell
godot --path . res://scenes/levels/single_raider_arena.tscn
```

Both scenes use the same code. The inherited regression scene overrides Raider count and salvage-point count to one. Restart reloads the scene you launched.

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

Stage A implements multiple independent Raiders, finite shared salvage, aggregate accounting, and multiple recoverable drops. It does not add personalities, advanced planning, armed Raiders, random/delayed spawns, multiple exits, a larger map, mission presets, or multiplayer. Those belong to later approved stages.

Arena Inspector parameters:

- `raider_count`: 1–5, default 3.
- `salvage_point_count`: 1–3, default 3.
- `materials_per_point`: default 3; total material stock is derived from enabled points.
- `mission_duration`: default 180 seconds.
- `pickup_distance`: default 1.8 m.

Five authored spawn markers live under `RaiderSpawns`. All configured Raiders enter immediately. Spawns are checked against geometry, actors, and already selected positions. Invalid deployment stops with an explicit setup error. No automatic teleport is used.

Salvage assignment is stable and cyclic by Raider ID. Raiders initially target different points where possible. A point is not reserved: the first validated collection request transfers available stock atomically. A competing Raider cannot duplicate it; it selects the next available point or heads for extraction if none remain. Each Raider collects once, up to the configured per-point amount, then extracts. Selection scoring and personality behavior are deferred.

A Raider detects the robot within 8 m with line of sight, or reacts to damage, and commits to fleeing toward the exit. Scavenging/extraction dwell times remain three seconds. State, navigation, velocity, health, task timer, and objective are independent per Raider. Instance IDs appear in labels and transition logs. F3 shows state, selected salvage, destination, cargo, and conservation diagnostics.

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

Navigation bakes synchronously once from the small arena's tagged collision geometry, including practice targets. Agent path height offset remains 0.5 m for this bake. Destroyed targets leave conservative footprints until restart. There is no dynamic avoidance or advanced blocked-path recovery yet. Crowding and player obstruction remain manual testing priorities, especially with five Raiders. Repath targets change only when destinations change; perception decisions remain on a 0.15 s interval.

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
godot --headless --path . --quit-after 180
godot --path . --quit-after 180
```

The five original suites use the inherited single-Raider scene to preserve movement, combat, scavenging, extraction, loot, mission outcomes, restart, and cosmetic cleanup coverage. Accounting unit checks now address the separate ledger and policy.

Stage A coverage includes contested/partial salvage, accepted-transfer invariants, duplicate events, same-frame deaths, independent actor state, identified overlapping drops, deterministic selection, recovery during active interception, recovery-only controls, mixed losses, deadline categories, sealing, untouched protected stock, and multi-actor restart. Natural bounded navigation runs exercise three and five Raiders without teleporting them; these runs accelerate simulation time for test duration. Other setup-specific interaction tests place actors near objectives to isolate transitions.

Automated tests and graphical startup do not establish gameplay feel, visual readability, or performance on typical gaming PCs. Manual Stage A review should cover competing interception choices, crowding at salvage/exit, multiple kills and pickups, nearest-stack prompts around cover, F3 readability, deadline summary distinctions, and restart.

Stage A validation on 2026-10-18: all five adapted regression suites and the new multi-Raider suite passed, including actual independent hitscan kills and bounded three/five-Raider navigation runs. Godot 4.7.2 editor import/parsing, bounded headless startup, and Vulkan Forward+ graphical startup passed without reported errors. Manual Stage A play-testing is pending.

## Review checkpoints and Git

The accepted primitive prototype was preserved in baseline commit `d51acfd` before this refactor. Stage A is committed separately after validation. Work remains on the existing `master` branch; no remote is configured or changed. Generated `.godot/` state and builds are ignored; script `.uid` files are tracked.

Stop at **Checkpoint A** for director review. Do not advance automatically.

- Stage B: objective scoring, extraction choices, personalities, threat behavior, navigation recovery.
- Stage C: expanded graybox, dynamic/configurable entries, three mission presets, scenario selection.
- Stage D: gunfire awareness and additional gameplay feedback.

Keep networking, progression, detailed Blender models, and final art outside this stage.
