# SCRAP Raiders — Phase 5, Stage O: Post-Death Spectating

Stage N — Integrated Gameplay Mission has been completed, combining the previously isolated gameplay mechanics into a unified playable mission.

The next development checkpoint is **Stage O — Post-Death Spectating**.

## Objective

Allow the player to continue watching surviving Raiders and autonomous machines after their robot is destroyed, without influencing the ongoing simulation.

Build upon the existing developer spectator system rather than duplicating camera functionality.

## Requirements

1. After player destruction, offer **Spectate** or **Return**.
2. Allow the spectator to follow surviving Raiders and autonomous machines.
3. Support cycling between eligible spectator targets.
4. Prefer the Raider responsible for the player's destruction when available.
5. Keep developer-only free-camera movement and AI inspection separate from normal player spectating.
6. Preserve irreversible player-deployment failure and settle loot forfeiture exactly once.
7. Allow remaining Raiders, machines, combat, looting, and extraction activities to continue independently.
8. Ensure spectator observation does not influence AI perception, combat, physics, or authoritative material/equipment accounting.
9. Handle target death, extraction, mission completion, and restart gracefully.
10. Preserve the existing integrated mission and all previously accepted test scenarios.
11. Avoid speculative multiplayer infrastructure, but maintain a clear separation between camera behavior and spectator permissions for future PvP use.

## Architecture review

Before implementation, inspect the current repository and determine how player destruction, mission termination, actor shutdown, persistence, and spectator camera ownership interact.

Specifically evaluate how to separate **player deployment termination** from **world simulation termination** without violating existing mission rules or accounting invariants.

## Validation

Extend automated regression coverage for:

- Player death and one-time loot settlement.
- Continued AI simulation after player destruction.
- Spectator target switching.
- Target destruction and extraction.
- Mission completion while spectating.
- Spectator non-interference.
- Existing developer spectator behavior.
- Integrated mission compatibility.

Run existing Godot parsing, headless validation, automated tests, and graphical startup checks.

## Workflow

Prepare a focused Stage O implementation plan identifying architectural changes, risks, and test coverage.

**Do not begin implementation until the plan is approved.**

After implementation and validation, stop at Checkpoint O for manual review. Do not proceed to Stage P without approval.
