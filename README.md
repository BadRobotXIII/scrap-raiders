# SCRAP Raiders

Internal working title for an original, comedic third-person PvE prototype. The player will control a machine intercepting human scavengers and recovering stolen technology.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript.
- No external dependencies, assets, or services.
- From this directory, run `godot --editor --path .` to open the project. Press F6 with the test arena open or F5 to run the configured main scene.
- Run `godot --path .` for a standalone launch.

The project uses the Forward+ renderer and a 1280 × 720 reference viewport. A Vulkan-capable graphics device is required. All arena geometry and materials are built-in primitives.

## Current scope: Milestone 1

The foundation contains a lit static arena, collision floor and boundaries, three collision obstacles, a fixed overview camera, and a foundation status overlay. There is no player controller or gameplay yet. The open central area is reserved for movement testing.

Input actions are configured for the next milestones; they do not trigger gameplay yet:

| Action | Binding |
| --- | --- |
| move_forward / move_backward | Physical W / S |
| move_left / move_right | Physical A / D |
| aim | Right mouse button |
| fire | Left mouse button |
| pause | Escape |

## Organization and ownership

- `scenes/levels/`: level composition, currently `test_arena.tscn`.
- `AGENTS.md`: development conventions.
- `project.godot`: application settings and logical input map.

Create player scenes and scripts in Milestone 2. Add other directories when they contain an implemented system.

Planned controller: an input adapter produces intent; a CharacterBody3D controller owns movement; a separate camera rig owns orbit and camera collision. Later, weapon and health components own their respective state.

Planned Raider: one controller owns an enum-based state machine and target selection, NavigationAgent3D supplies route guidance, and the character controller owns movement. Health and mission accounting retain separate authoritative owners. These are design directions, not implemented systems.

## Validation

Run from the project root:

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 120
```

The editor command validates imports and resources; the runtime command checks a bounded main-scene launch. Neither proves visible rendering, collision feel, or playability. For a visual check, launch normally and confirm the floor, four boundary walls, three obstacles, lighting, and legible overlay. Close the window using the normal window controls.

There is no isolated gameplay logic to unit-test in this milestone. Add tests for state transitions, health, loot ownership, and extraction outcomes as those systems are introduced.

## Roadmap

1. Foundation: project, arena, input, conventions, import and launch validation.
2. Robot controller: camera-relative movement, orbit camera, aiming orientation, collisions; manual feel review.
3. Combat: one hitscan weapon, health, damage, destruction, and feedback.
4. Raider: navigation, scavenging, threat detection, fleeing, extraction, death, and loot.
5. Mission loop: material accounting, explicit success/failure conditions, restart, and summary.
6. Refinement after core play-testing: feedback, reactions, and physics comedy.

Approve each milestone before implementation. Multiplayer and progression remain deferred. Git is local; no remote or commits are created automatically. Dropbox synchronization should not be used for simultaneous editing across machines.
