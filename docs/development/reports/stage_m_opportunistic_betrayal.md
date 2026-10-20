# Stage M — Bounded opportunistic betrayal

Recorded: 2026-10-19. **Implemented, validated and accepted. Changes are uncommitted.** The director accepted L with “All functional approved. proceed”, then confirmed Stage M is functionally great and requested the display/HUD refinement below.

## Delivered

- Alt+F11 selects Opportunistic Betrayal; direct scene: `res://scenes/levels/social_betrayal_arena.tscn`. All three Raiders begin explicitly allied, with empty squad IDs. Only R1 is an opportunist. There are three original salvage points, nine total materials, seed 84017 and a 180-second deadline. Jump/boost remain enabled. The distant robot remains vulnerable; flares, support machines and persistence are disabled.
- Optional per-ID preferred entry markers provide repeatable roles through the existing collision/navigation/support checks. A blocked authored entry waits and retries. R2 starts at salvage and naturally collects before R1 arrives; no initial cargo, scripted transfer or forced kill is supplied. Existing presets retain their previous entry selection.
- A separate resource configures the visible ally's minimum cargo (three), range (8 m), source health threshold (strictly above 50%) and continuous assessment time (two seconds). The source must have less cargo and available capacity. Visible machine/rival threats, combat, retreat, damage reactions, lost visibility, range loss, invalid/resolved victims or relation changes prevent/cancel assessment.
- RaiderBetrayal owns eligibility and assessment timing; Raider owns the assessment FSM state and physical movement. Presentation displays an orange EYEING Rxx CARGO countdown. The existing rifle aim warning follows successful hostility acceptance. F3/spectator inspection includes reason, timer and spent status.
- At most one accepted initiation per opportunist/deployment. Relation authority records the affected pair's hostility, reason and timestamp. Third-party alliances do not change; membership supplies no inferred response. Cancelled assessments can retry with a fresh timer. There is no trust oscillation or automatic reconciliation.
- Combat, target acquisition, retaliation, cover, retreat, damage attribution, death drops and cargo collection use accepted systems. Hostility itself grants no materials or rewards. Only ledger-validated transfers change quantities; existing conservation checks still run after every accepted transfer. Restart reconstructs fresh relationships, stock and an unspent opportunity. Mission completion stops pending assessment.

## Validation

All **eighteen automated suites** passed: the seventeen existing regressions and `tests/betrayal_test.gd`. The new suite covers opt-in registration, finite initial stock, visible warning before hostility, continuous timing/reset, blocked sight, range loss, nearby machine threat, health/damage and retreat priority, combat exclusion, neutral competition, extraction invalidation, candidate changes, malformed configuration, one accepted transition, third-party independence, ordinary rifle warning/damage/attribution, retaliation, lethal physical shots, normal timed/ranged cargo pickup, deadline sealing and restart.

Isolated transition tests freeze simulation and place actors deliberately; fixture cargo is transferred from real stock through MaterialLedger. The final integration case runs the authored scene with no cargo grants, teleports or forced states, observes normal scavenging, the warning and accepted betrayal, and checks conservation and unchanged observer relationships. The initial opportunity reproduced across separate natural launches and test runs; identical setup is not a claim of bitwise deterministic physics or identical combat winners.

Godot **4.7.2** editor import/parsing, bounded headless startup and Vulkan **Forward+** graphical startup passed with no reported errors. All eighteen suites completed without reported failures or shutdown warnings in this run. Earlier intermittent audio/ObjectDB cleanup warnings remain documented in previous reports; this does not establish that their underlying cause is fixed. Generated `.godot/` test data and builds remain excluded; generated script `.uid` files are retained. No new tests use the player's persistent stash.

## Manual review and limits

Use Alt+F11, then F1 and Tab/F to observe R1/R2 without alerting them with the robot. Review the orange hesitation countdown, the following rifle warning, whether the cargo motive is clear, retaliation/cover/retreat pacing, and ordinary cargo recovery after a loaded Raider dies. Approaching with the robot can legitimately cancel the opportunity. Review restart and repeat observations; warning readability and encounter entertainment require human play-testing.

This is one authored three-Raider experiment. No random betrayal probabilities, dynamic alliances, third-party witnessed retaliation, permanent squad coordination, equipment looting, progression or new art are included. Five-Raider navigation remains covered by prior regressions; larger social encounter balance and cross-hardware performance are not established. The accepted floaty jump tuning remains deferred.

## Accepted display follow-up

The director confirmed Stage M works and requested a larger window and less HUD clutter. Default window/viewport size is now 1600×900. F3 controls the developer diagnostics, control banner and detailed spectator inspector together, hidden by default. Mission information, combat feedback and interaction prompts stay visible; spectator mode retains a compact active-mode indicator. This changes presentation only. Godot parsing and bounded headless/Forward+ launches passed; spectator, rivalry and Raider regressions validate the related UI and camera/combat behavior.

Stage M is accepted. No further gameplay stage is introduced by this refinement.
