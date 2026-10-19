# SCRAP Raiders

Internal working title for an original, comedic third-person PvE prototype. The player will control a machine intercepting human scavengers and recovering stolen technology.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript.
- No external dependencies, assets, or services.
- From this directory, run `godot --editor --path .` to open the project. Press F6 with the test arena open or F5 to run the configured main scene.
- Run `godot --path .` for a standalone launch.

The project uses the Forward+ renderer and a 1280 × 720 reference viewport. A Vulkan-capable graphics device is required. All arena geometry and materials are built-in primitives.

## Current scope: Milestone 2

The lit arena contains a controllable placeholder robot, collision floor and boundaries, three collision obstacles, a third-person orbit camera, and a controls overlay. The yellow visor marks the robot's front. Weapons, health, Raider AI, and multiplayer are not implemented.

The mouse is captured on startup. Escape releases it and clears movement/aim intent; click inside the game to recapture. Losing application focus also releases it. Escape does not pause the simulation.

| Action | Binding |
| --- | --- |
| move_forward / move_backward | Physical W / S |
| move_left / move_right | Physical A / D |
| Camera orbit | Mouse movement |
| aim | Hold right mouse button |
| fire | Left mouse button (reserved; no weapon) |
| pause | Escape (currently releases mouse) |

## Organization and ownership

- `scenes/levels/`: level composition, currently `test_arena.tscn`.
- `scenes/player/robot.tscn`: robot composition, primitive mesh, and camera rig.
- `scripts/player/`: input adapter, character controller, and camera control.
- `tests/robot_controller_test.gd`: physics integration checks in the arena.
- `AGENTS.md`: development conventions.
- `project.godot`: application settings and logical input map.

Add other directories when they contain an implemented system.

`RobotInput` samples physical actions before the controller's physics step and emits raw mouse look deltas. `RobotController` alone owns velocity and calls `move_and_slide()`. Movement follows camera yaw, with bounded acceleration/braking (7 m/s top speed, 45 m/s² acceleration, 60 m/s² braking). Movement faces its travel direction; holding aim faces camera yaw, including while strafing or reversing. Only the visual pivot rotates, keeping the body and camera independent.

`RobotCamera` owns yaw and pitch, with immediate mouse response and pitch limits of -60 to +25 degrees. Its pivot follows the body through parenting; robot visual turns do not change orbit. A 5 m SpringArm3D with a sphere sweep retracts against arena geometry, excluding the robot. Aim direction is camera forward projected onto the ground plane; vertical weapon aiming is deferred to combat. Inspector exports on the controller and camera script expose tuning values. Camera arm length and FOV are scene properties. No jump or zoom is implemented.

Collision layer 1 is environment; layer 2 is the robot. Robot movement and the spring arm query layer 1.

Planned Raider: one controller owns an enum-based state machine and target selection, NavigationAgent3D supplies route guidance, and the character controller owns movement. Health and mission accounting retain separate authoritative owners. These are design directions, not implemented systems.

## Validation

Run from the project root:

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/robot_controller_test.gd
```

The editor command validates imports, scripts, and resources; the runtime command checks a bounded main-scene launch. The integration script exercises floor contact, camera-relative movement, braking, pitch limits, aim facing, camera independence, obstacle/boundary collision, and spring-arm retraction/recovery using logical intent. It does not emulate physical keyboard/mouse input.

Manual review is still required: movement and turning feel, diagonal/strafe response, mouse sensitivity, pitch limits, camera framing and wall/corner obstruction, visible rendering, focus loss and mouse recapture. Try holding RMB while moving in every direction. Verify the robot cannot pass through walls or orange blocks. Close using normal window controls. Parsing, automated physics checks, and startup are separate from manual play-testing.

Milestone 2 validation (2026-10-18): Godot 4.7.2 editor import and parsing passed; bounded headless and graphical launches passed without reported errors. Graphical startup used Vulkan Forward+ on an NVIDIA RTX 4060 Laptop GPU. All 14 controller integration checks passed. Manual play-testing and movement/camera feel acceptance are pending.

## Roadmap

1. Foundation: project, arena, input, conventions, import and launch validation.
2. Robot controller: camera-relative movement, orbit camera, aiming orientation, collisions; manual feel review.
3. Combat: one hitscan weapon, health, damage, destruction, and feedback.
4. Raider: navigation, scavenging, threat detection, fleeing, extraction, death, and loot.
5. Mission loop: material accounting, explicit success/failure conditions, restart, and summary.
6. Refinement after core play-testing: feedback, reactions, and physics comedy.

Milestone 2 is the current approved scope. Stop for movement/camera feel review before combat. Multiplayer and progression remain deferred. Git is local; commits require director authorization and no remote is configured. Dropbox synchronization should not be used for simultaneous editing across machines.
