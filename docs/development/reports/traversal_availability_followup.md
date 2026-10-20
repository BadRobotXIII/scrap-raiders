# Jump and boost availability — Post-Stage K follow-up

Recorded: 2026-10-19. The director confirmed the new social mechanics work well but reported that jump and boost appeared to have been lost from the test scenes.

## Cause and resulting behavior

The functionality remained in the controller. The earlier Stage I scope intentionally enabled it only in F2; both the controller and mission configuration defaulted traversal to false elsewhere. This restriction no longer matched the director's expectation for testing.

Traversal now defaults to enabled in all nine mission presets and both original arenas. Space jumps and Shift boosts after direct scene launch, preset switching and restart. F2 remains a dedicated test preset, not a requirement for traversal access. A custom scene/resource can still explicitly turn traversal off. No jump height, gravity, speed, burst duration, cooldown, combat, relation or material tuning changed.

The HUD is composed once in the common arena rather than only the mission-specific traversal preset. It is hidden while spectating or after terminal shutdown. Spectator input isolation still prevents player movement/jump/boost; Space and Shift control only the camera while spectating. Recall still requires grounded stationary behavior and cancels on traversal.

## Verification

The traversal integration suite now launches every mission preset plus `single_raider_arena` and `test_arena`, verifies actual grounded jump and boost displacement, and checks exactly one traversal HUD. Existing apex, collision, camera, cooldown, recall, death/restart tests remain. Recall's frozen test fixtures now establish real floor contact before checking a grounded recall channel.

All sixteen automated suites passed after the rollout, including the expanded traversal coverage, grounded recall fixtures, spectator isolation and social rivalry. Godot 4.7.2 parsing/import and bounded headless/Forward+ default startup passed. Known two-instance audio cleanup warnings appeared in flare/extraction regression runs; no gameplay assertions failed. Existing historical ledgers and completion reports retain their original F2-only scope; this follow-up supersedes those availability restrictions without changing their historical test claims.

Manual review should confirm Space/Shift in the preferred scene and after F-key preset switching. Floaty jump feel remains deferred. This follow-up does not authorize Stages L/M or create a Git commit.
