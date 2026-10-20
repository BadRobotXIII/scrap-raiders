# Phase 4 Ledger Amendment — Developer Free Camera / No-Clip Spectator Mode

**Priority:** High\
**Implementation:** Stage J, before Raider-versus-Raider interaction play-testing\
**Scope:** Developer/debug tooling only

## Objective

Introduce a developer-only free camera that can move independently throughout the world, allowing observation of autonomous Raider behavior without approaching or alerting them with the player robot.

This is intended for testing Raider cooperation, betrayal, combat, looting, navigation, and other emergent encounters.

## Requirements

### Camera controls

- Toggle spectator mode using F9, unless already assigned.
- WASD for horizontal movement relative to camera orientation.
- Mouse movement for unrestricted camera rotation.
- Space to ascend.
- Ctrl to descend.
- Shift for accelerated movement.
- Camera passes freely through walls, terrain, actors, and other geometry.
- No collision, gravity, or physical movement restrictions.
- Camera movement speed should be configurable.

### Player separation

- Entering spectator mode must not move or teleport the player robot.
- The player robot remains at its existing world position.
- Spectator camera position must not be used for AI perception, combat targeting, navigation, or interaction.
- Raiders must not detect or react to the spectator camera.
- Disable player movement, firing, and interactions while spectator mode is active.
- Restore the normal player camera and controls when exiting.

### Simulation behavior

- Raider AI, navigation, combat, physics, loot, and mission systems continue running normally.
- Do not pause the simulation when entering spectator mode.
- Preserve the current mission state.
- Spectator mode must not directly alter mission accounting or actor state.
- The existing player robot remains vulnerable to attacks unless a separate developer invulnerability option is explicitly enabled.

### Debugging integration

- Show a small indicator when spectator mode is active.
- Preserve the existing developer HUD.
- Allow inspection of Raider state, current targets, relationships, and objectives while observing.
- Avoid adding permanent gameplay UI elements.
- If practical, support selecting or following a Raider without controlling it.

### Architecture

- Implement spectator camera control independently of the player movement controller.
- Use the existing camera and input architecture where practical.
- Maintain one authoritative active camera.
- Avoid duplicating gameplay input or actor movement logic.
- Restore mouse capture and camera state cleanly when toggling modes.
- Keep all functionality isolated from release gameplay behavior.

### Validation

Test:

- Entering and exiting spectator mode repeatedly.
- Free movement in all directions.
- Passing through collision geometry.
- Normal simulation continuing while spectating.
- No Raider aggression caused by spectator camera proximity.
- Player position remaining unchanged.
- Player controls restoring correctly.
- No impact on mission accounting.
- Correct behavior after mission restart and player destruction.

## Acceptance criteria

The developer can activate spectator mode, fly freely through the arena, and observe Raiders interacting with one another without the spectator camera affecting AI behavior.

The player robot remains physically present in the world, and all normal gameplay systems continue functioning.

Implement and validate this feature during Stage J before proceeding to social AI testing.
