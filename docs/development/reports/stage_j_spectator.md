# Stage J — Developer free camera / no-clip spectator

Recorded: 2026-10-19. **Implemented, validated and accepted by the director. Changes are uncommitted.** Director feedback: “Works perfectly. Approved.” This is debug tooling under the [Phase 4 amendment](../ledgers/phase_4_stage_j_spectator_amendment.md), not social AI implementation.

## Delivered

- Debug-build-only spectator camera, independent from the robot controller and its shoulder camera.
- F1 toggle because F9 already selects Survival. WASD horizontal flight, unrestricted mouse yaw/pitch, Space up, Ctrl down and Shift fast movement.
- No collision, physics body, gravity or world-boundary restrictions. Default speed 10 m/s and fast multiplier 4x are exported/configurable, as is mouse sensitivity.
- Robot position held unchanged, gameplay input blocked and weapon disabled while observing. Robot health/collision remain active and Raiders can attack it. No invulnerability was added.
- One current camera at a time; exiting restores the player view, orbit and previous mouse mode. Escape, click-to-capture and focus-loss handling work in spectator mode.
- Mission time, pending entry, AI, navigation, scavenging, damage, destruction, loot and accounting continue normally. The spectator never supplies its position to gameplay queries.
- Temporary indicator and Tab Raider inspection with F follow. Inspector reads state, profile, target, salvage, exit, cargo and navigation. Follow translates only the camera and clears on target death/extraction/removal. Existing F3 diagnostics remain usable.
- Relationships are explicitly marked not implemented. No cooperation, betrayal, Raider-versus-Raider combat, actor commands or social AI was added.
- Terminal mission policy exits spectator without restoring dead/finished player controls. Restart/scenario replacement creates a normal fresh player view.

## Ownership and behavior details

`DeveloperSpectator` owns its Camera3D and debug input/selection/follow. Arena composition only creates it when `OS.is_debug_build()` is true; the tool also guards activation and input. `RobotInput.gameplay_enabled` gates gameplay intent, and the robot controller owns its physical velocity and movement hold. The original camera rig's physics update is temporarily held, preserving its transform for restoration.

Entering clears gameplay intent and cancels an active boost through the existing input-clear behavior. The robot's own movement and traversal timers are held while observing; airborne entry holds the avatar at that exact point until normal gravity resumes on exit. Existing interaction channels stop through cleared intent. The tool does not write ledger quantities, Raider FSM state or health.

## Validation

- **All fifteen automated suites passed**: the fourteen prior suites plus `spectator_test.gd`.
- Godot 4.7.2 editor import/parsing and bounded default headless startup passed without reported errors.
- The spectator suite also passed in a bounded Forward+ graphical run, verifying real mouse capture/release and reset behavior. Headless display always reports a visible mouse, so capture-specific assertions are conditional there and checked graphically.
- Coverage includes repeated entry/exit, single active camera, configurable free translation, pitch beyond player limits, flight through walls/terrain, robot immobility, blocked gameplay actions and direct firing, preserved normal camera transform, cursor release/recapture/focus loss, camera proximity without AI perception, inspection/follow, F3 coexistence, natural mission time/scavenging, ordinary cargo drops, follow-target death, restored player movement, restart, real Raider damage/lethal shots and terminal shutdown.
- Accounting is checked on entry and after natural simulation. The spectator test uses presets without persistent rewards and does not write the player's stash.

An early spectator-test exit emitted audio playback cleanup warnings; verbose output identified AudioStreamWAV/AudioStreamPlaybackWAV instances. Waiting for normal audio cleanup before test exit removed the warning in the final headless and graphical spectator runs. A pre-existing two-instance warning still appeared in the parallel extraction regression run; this checkpoint does not claim a general engine/audio cleanup fix.

Release exclusion is implemented through debug-build guards and code review. An exported release build has not been separately exercised.

## Manual review and stopping point

Check flight speed/sensitivity, unrestricted rotation comfort, indicator/inspector readability, follow behavior around moving Raiders, return to the normal shoulder view and scenario switching during observation. The robot remains a valid threat when physically near Raiders; moving only the camera cannot hide or protect it. Position the robot somewhere suitable before entering spectator mode when testing undisturbed encounters.

The director accepted Stage J after play-testing. Social AI play-testing and further implementation require their own scoped work; Stage J supplies observation tooling only.
