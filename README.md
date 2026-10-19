# SCRAP Raiders

Internal working title for an original, comedic third-person PvE prototype. The player will control a machine intercepting human scavengers and recovering stolen technology.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript.
- No external dependencies, assets, or services.
- Blender is installed for future modeling/animation work (director reported); it is not required to run this primitive prototype and its asset pipeline has not yet been validated.
- From this directory, run `godot --editor --path .` to open the project. Press F6 with the test arena open or F5 to run the configured main scene.
- Run `godot --path .` for a standalone launch.

The project uses the Forward+ renderer and a 1280 × 720 reference viewport. A Vulkan-capable graphics device is required. All arena geometry and materials are built-in primitives.

## Current scope: Milestone 6 — interaction and combat feedback

Each deployment/restart now plays a brief low-opacity dust burst and expanding cyan ground ring at the robot's initial position. The effect is self-contained in `scenes/effects/deployment_effect.tscn`, cleans itself up after 1.3 seconds, and has no collision or effect on controls, AI, or the mission clock. It uses built-in CPU particles and primitive meshes; the dust remains at the spawn location if the robot moves immediately. Visual timing/readability require manual review.

Milestone 5 pickup, material totals, mission outcomes, and restart have been manually accepted. Recoverable cargo now displays a gold ring, an overhead `[E]` label, and a prompt beneath the crosshair when within pickup range with clear access and captured mouse controls. The cue disappears when leaving range, moving behind cover, releasing the mouse, recovering cargo, or ending the mission. The arena computes availability from the same rule used by pickup; the drop only renders the cue.

Pickup cues have also been manually accepted. Combat feedback now adds a short muzzle flash/light, a synthesized blaster sound per shot, and a distinct confirmation tone only when damage is applied. Original mono PCM audio is generated once on scene startup; there are no external sound assets or licenses. Shot/hit volume can be tuned on `Robot/CombatHUD/Feedback`. Audio currently uses non-spatial playback for the player's weapon and hit confirmation. Manual listening and flash readability review are pending.

The Raider flashes briefly and visually squashes on nonlethal hits, recovering its normal scale/appearance over 0.12 seconds. `HitReaction` owns visual scale and material overlays only; the Raider controller still owns facing, velocity, and state. Shots retain their accepted damage, range, cadence, and aiming.

Raider intent labels now distinguish seeking salvage, scavenging progress, fleeing empty, fleeing with cargo, and travelling to the exit. The extraction dwell displays remaining seconds. Colors reinforce these labels: gold for scavenging, orange for danger/stolen cargo, green for an empty retreat. The text reads the existing authoritative task timer and never changes behavior. Salvage has a gold ring/crate marker; extraction has a green ring marking the existing 0.8 m arrival radius. Marker meshes are visual guides without collision or navigation effects. Review readability and timing in play.

Muzzle flash, audio, and nonlethal reactions were manually accepted. Destruction now spawns a cosmetic RigidBody3D mesh copy of the Raider or practice target, with a small fixed upward launch and spin. It tumbles against the environment and disappears after four seconds. `DeathTumble` listens to health death events and copies only meshes/collision shape, never actor scripts, health, labels, navigation, or cargo. Its collision layer is zero, so movement, hitscan, perception, and pickup queries ignore it. Cargo remains a separate stationary pickup at the death position. Restart removes all tumble bodies. This is a single-body placeholder reaction, not a skeletal ragdoll; launch velocity/lifetime can be tuned on each actor's DeathTumble component. Visual comedy and cleanup still require manual review.

The arena contains the robot, three destructible practice targets, and one AI human scavenger. The Raider travels to SALVAGE, spends three seconds collecting three materials, then heads to RAIDER EXIT and takes three seconds to extract. Approach within 8 m with clear line of sight or damage it to trigger fleeing toward the exit. It does not fight back. Killing it after scavenging leaves a cyan cargo drop; killing it before scavenging drops no materials. Recover cargo with E within 1.8 m and with no cover blocking access. The mission tracks protected, carried, dropped, recovered, and lost materials and ends with a summary and restart. Player damage/death, persistent progression, and multiplayer are not implemented.

Mission rules for this short one-Raider slice:

- Stop an empty Raider: success, three materials protected, no pickup required.
- Raider flees/extracts empty: success, three materials protected.
- Kill a loaded Raider: mission continues until its dropped cargo is recovered.
- Recover the three dropped materials: success, three materials credited to mission inventory.
- Loaded Raider extracts: failure, three materials lost.
- The 180-second deployment limit expires: failure; summary retains exact material locations/counts.

Press R or click Restart on the summary to reset the entire scene, Raider, targets, inventory, and timer. Mission completion disables movement, firing, and orbit input, hides the combat reticle, and releases the cursor. No global pause is used. The limit and pickup distance are Inspector properties on the arena. Missions are deliberately shorter than the eventual 10–15 minute target; there is no base-return step or persistent save yet.

The mouse is captured on startup. Escape releases it and clears movement/aim intent; click inside the game to recapture. Losing application focus also releases it. Escape does not pause the simulation.

| Action | Binding |
| --- | --- |
| move_forward / move_backward | Physical W / S |
| move_left / move_right | Physical A / D |
| Camera orbit | Mouse movement |
| aim | Hold right mouse button |
| fire | Hold left mouse button |
| pause | Escape (currently releases mouse) |
| recover | E, when close to the dropped cargo |
| restart | R, on the mission summary |

## Organization and ownership

- `scenes/levels/`: level composition, currently `test_arena.tscn`.
- `scenes/player/robot.tscn`: robot composition, primitive mesh, and camera rig.
- `scripts/player/`: input adapter, character controller, and camera control.
- `tests/robot_controller_test.gd`: physics integration checks in the arena.
- `scripts/components/health.gd`: authoritative target health and damage/death signals.
- `scripts/gameplay/`: hitscan weapon, weapon definition, and target behavior.
- `resources/weapons/prototype_blaster.tres`: damage, cadence, and range tuning.
- `scenes/targets/practice_target.tscn`: destructible target composition.
- `tests/combat_test.gd`: combat and health integration checks.
- `scripts/ai/raider.gd`: authoritative Raider state, cargo, and physical movement.
- `scenes/raiders/raider.tscn`: placeholder human, health, and navigation agent.
- `scripts/gameplay/raider_arena.gd`: startup navigation bake, mission wiring, pickup validation, and HUD/summary.
- `scripts/gameplay/mission_rules.gd`: explicit mission phases and authoritative material ledger.
- `scenes/loot/material_drop.tscn`: world cargo stack, consumed once on recovery.
- `tests/raider_test.gd`: navigation, state, cargo, and camera-framing checks.
- `tests/mission_test.gd`: isolated accounting/outcome checks plus scene pickup, timeout, and restart integration.
- `AGENTS.md`: development conventions.
- `project.godot`: application settings and logical input map.

Add other directories when they contain an implemented system.

`RobotInput` samples physical actions before the controller's physics step and emits raw mouse look deltas. `RobotController` alone owns velocity and calls `move_and_slide()`. Movement follows camera yaw, with bounded acceleration/braking (7 m/s top speed, 45 m/s² acceleration, 60 m/s² braking). Movement faces its travel direction; holding aim faces camera yaw, including while strafing or reversing. Only the visual pivot rotates, keeping the body and camera independent.

`RobotCamera` owns yaw and pitch, with immediate mouse response and pitch limits of -60 to +25 degrees. Its pivot follows the body through parenting; robot visual turns do not change orbit. The camera now sits 1 m over the right shoulder at a 1.8 m pivot height, initially pitched down 8 degrees, clearing the robot from the center reticle. A lateral ray shortens shoulder offset near walls; a 5 m SpringArm3D with a sphere sweep handles rear obstruction, excluding the robot. Body facing uses camera yaw while aiming or firing; the weapon uses the full camera ray including pitch. Inspector exports expose shoulder offset, sensitivity, pitch limits, and controller tuning. Camera arm length and FOV are scene properties. No jump or zoom is implemented.

`HitscanWeapon` owns firing cadence and shot resolution, running after character movement. A center-screen camera ray selects the aim point; a second ray from the visible muzzle checks intervening cover and applies damage. Shots exclude the shooter and stop at the first environment/target body. The blaster deals 25 damage every 0.2 seconds with an 80 m range; targets have 100 health. Firing works with or without RMB, without spread, ammunition, reload, or recoil. Target health labels update on damage; lethal hits remove the target. Restart the scene (F8 then F5 in the editor) to restore targets.

`Health` alone changes current health and emits damage/death signals, rejecting invalid damage and repeated damage after death. Target presentation listens to those signals. Combat feedback listens to weapon signals for short-lived tracers and hit markers; it does not apply damage. No player health UI is present because there are no incoming attacks yet.

Collision layer 1 is environment; layer 2 is the robot. Robot movement and the spring arm query layer 1.

`Raider` owns one enum-based state machine: SCAVENGING, FLEEING, EXTRACTING, DEAD, EXTRACTED. All transitions go through `transition()`; terminal states cannot be exited. Threat decisions run every 0.15 s, with distance and physics line-of-sight checks. Damage causes fleeing; death cancels active behavior. Fleeing commits to the exit rather than resuming looting. EXTRACTING includes travel to the exit and the extraction dwell. Health remains a separate component. NavigationAgent3D supplies waypoints; the Raider CharacterBody3D owns velocity and collision movement. Labels show state, goal, health, and cargo; transitions print to the Godot output. The Raider emits cargo/death/extraction events; the arena passes these into the mission rules and displays the resulting state.

The small arena's NavigationRegion3D bakes synchronously once at startup from collision geometry in the `navigation_geometry` group, including practice targets. The agent path height offset (0.5 m) matches the default bake voxel elevation above the floor. This is a primitive-arena setup, not a production level pipeline. Destroyed targets leave conservative navigation footprints until restart; moving geometry is not supported by this bake. The robot can physically block the Raider. There are no attacks, perception personalities, dynamic avoidance, or generative AI dependencies.

The Raider owns cargo until extraction or death. Extraction emits the amount and removes the Raider; death transfers the exact amount into one world drop, then removes the Raider. Empty Raiders produce no drop. `MissionRules` owns HUNTING, RECOVERING, SUCCEEDED, and FAILED phases plus a conserved three-material ledger. Gameplay events request transfers; invalid amounts, duplicate events, and transfers after completion are rejected. `MaterialDrop.consume()` zeroes its stack synchronously before queuing removal. The arena validates phase, amount, range, and line of sight before consuming the drop and crediting recovered inventory. This is per-mission inventory; restarting clears it.

For a cargo-drop test, stay away until the HUD says "Raider carrying 3 materials", then intercept it. Approaching or shooting before it finishes scavenging causes it to flee empty. The HUD explicitly reports empty deaths or the amount dropped. Regression coverage includes default spawn-to-scavenging behavior followed by four actual blaster hits, verifying the cargo amount, world position, and persistent visible mesh. The muzzle ray extends 5 cm beyond the camera's surface hit (within weapon range) to avoid floating-point misses on the Raider's capsule.

## Validation

Run from the project root:

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/robot_controller_test.gd
godot --headless --path . --script res://tests/combat_test.gd
godot --headless --path . --script res://tests/raider_test.gd
godot --headless --path . --script res://tests/mission_test.gd
godot --headless --path . --script res://tests/destruction_test.gd
```

The editor command validates imports, scripts, and resources; the runtime command checks a bounded main-scene launch. The integration script exercises floor contact, camera-relative movement, braking, pitch limits, aim facing, camera independence, obstacle/boundary collision, and spring-arm retraction/recovery using logical intent. It does not emulate physical keyboard/mouse input.

Manual review is still required: movement and turning feel, diagonal/strafe response, mouse sensitivity, pitch limits, camera framing and wall/corner obstruction, visible rendering, focus loss and mouse recapture. Try holding RMB while moving in every direction. Verify the robot cannot pass through walls or orange blocks. Close using normal window controls. Parsing, automated physics checks, and startup are separate from manual play-testing.

Milestone 2: movement and camera manually accepted by the director. Milestone 3 automated checks cover invalid damage, health clamping, single death emission, hits, misses, cadence, muzzle-side cover obstruction, target destruction, and fire intent clearing. The 14 controller checks remain regression coverage. Manual combat review must confirm reticle alignment at different pitches/ranges, aiming and firing while moving, close-wall obstruction, readable hit flashes/markers/tracers, and target destruction after four hits. These checks do not establish weapon feel or verify physical input.

## Roadmap

1. Foundation: project, arena, input, conventions, import and launch validation.
2. Robot controller: camera-relative movement, orbit camera, aiming orientation, collisions; manual feel review.
3. Combat: one hitscan weapon, health, damage, destruction, and feedback.
4. Raider: navigation, scavenging, threat detection, fleeing, extraction, death, and loot.
5. Mission loop: material accounting, explicit success/failure conditions, restart, and summary.
6. Refinement after core play-testing: feedback, reactions, and physics comedy.

Milestone 3 hitscan, damage, and markers were manually accepted, with camera framing corrected in Milestone 4. The Raider test checks actual obstacle-crossing navigation/extraction, detection and cover, fleeing, scavenged cargo, death/drop ownership, terminal states, and reticle clearance against the robot capsule across four pitches. Automated clearance is not a visual framing acceptance test. Manually review shoulder aim alignment and close-wall behavior, Raider route/readability, interruption while looting, escape timing, and cyan drops after killing a loaded Raider.

Milestone 4 cargo drops were manually confirmed after scavenging. Milestone 5 checks cover conserved accounting, invalid/duplicate events, early interception, empty and loaded extraction, timeout, blocked/distant pickup, exactly-once credit, summary presentation state, disabled controls at completion, and clean scene reload through both restart paths. Manual review remains necessary for the physical E/R keys, button interaction, HUD readability, pickup distance/feedback, and end-to-end mission pacing.

Milestone 6 pickup cues, combat sound/flash, placeholder tumble feel, and Raider progress/objective markers have been manually accepted. Deployment presentation is the latest addition awaiting visual review. The original six-milestone primitive prototype is implemented; this is a short test loop, not the eventual 10–15 minute vertical slice or a production art pass.

Recommended next stage (design approval before implementation): retain this arena for regression testing and build one separate industrial blockout map with the existing robot, one Raider, one salvage location, and one exit. Use a few cover routes to test interception and camera clearance before introducing extra Raiders, combat AI, or final models. Validate a single Blender-to-Godot asset pipeline separately once the map proportions and visual direction are agreed. Keep further changes incremental and discuss substantial gameplay/architecture changes. Multiplayer and progression remain deferred. Git is local; commits require director authorization and no remote is configured. Dropbox synchronization should not be used for simultaneous editing across machines.
