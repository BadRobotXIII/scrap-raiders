# Phase 2 completion report

Archive note: recorded on 2026-10-19. The report below was previously provided in the conversation and is preserved here for reference. Phase 3 capabilities mentioned at the end are deliberately outside its delivery scope.

---

**SCRAP Raiders — Phase 2 Completion Report**  
**Dynamic Gameplay and Replayability — Complete and accepted**

Phase 2 expanded the single-Raider prototype into a configurable sandbox supporting independent Raiders, competing salvage objectives, varied encounters, and reliable mission accounting. All four checkpoints were implemented, validated, committed separately, and approved.

| Stage | Delivered | Commit |
|---|---|---|
| A — Multi-Raider foundation | Independent Raiders, multiple salvage locations, authoritative material ledger, uniquely identified loot drops, recovery-only mission phase | `49cf442` |
| B — Dynamic AI | Shared FSM with Greedy, Cowardly and Aggressive profiles; scored objectives; safer extraction choices; investigation, retreat and navigation recovery | `ae86f4c` |
| C — Arena and mission variety | Expanded 48 m graybox, passages, cover and ramp; validated scheduled entries; seeded configuration; three selectable scenarios | `e9d6e48` |
| D — Gameplay refinement | Gunfire awareness, last-known threat memory, profile-specific reactions, alert indicators, cargo cues and depleted-salvage feedback | `9f21ae8` |

The repeated Aggressive investigation issue reported during play-testing was corrected separately in `ee3159b`.

**Playable scenarios**

| Scenario | Raiders | Materials | Deadline |
|---|---:|---:|---:|
| Intercept — F6 | 3 | 9 salvage | 180 seconds |
| Swarm — F7 | 5 | 15 salvage | 180 seconds |
| Recovery — F8 | 2 | 6 salvage + 6 ground cargo | 150 seconds |

Each uses shared gameplay systems and data resources. Entry schedules, available exits, quantities and seeds are configurable.

**Architecture and accounting**

- Each Raider retains independent state, movement, health, objectives, cargo allocation and timers.
- `MaterialLedger` owns material quantities and transfers; mission rules separately determine outcomes.
- Every accepted transfer checks conservation: **Protected + Carried + Ground + Recovered + Lost = Total**.
- Duplicate collection, death, extraction and recovery events cannot duplicate materials.
- Untouched salvage does not block completion. Remaining ground cargo enables recovery-only play.
- Deadline reporting distinguishes unrecovered cargo from materials lost through Raider extraction.
- The original single-Raider scenario, player movement, shoulder camera and combat remain preserved.

**Validation and acceptance**

At Phase 2 completion, **all nine automated suites passed**, covering concurrent collection, simultaneous outcomes, unique recovery, AI transitions, navigation fallback, seeded selection, spawn validation, mission completion and restart.

Godot **4.7.2** parsing/import, bounded headless runtime and Forward+ graphical startup checks passed. Your incremental play-testing confirmed functionality and supported acceptance of each checkpoint. Subsequent Phase 3 regression runs also retained passing Phase 2 coverage.

Remaining review areas are encounter balance, congestion with five Raiders, HUD readability and performance across typical gaming PCs. Automated checks establish simulation correctness; they do not establish broad player enjoyment or hardware performance.

Armed Raiders, death flares, persistent player extraction, support machines, and jump/boost were delivered later in **Phase 3**, outside this report’s scope.
