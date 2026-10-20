# Phase 3 — Hostile world, survival and extraction

Recorded: 2026-10-19. Consolidated completion report created for this archive from repository validation records and director approvals.

**Status: approved Stages E–I complete and accepted.**

The phase added dangerous armed encounters, bounded pressure around loot, player recall and persistent rewards, autonomous support machines, and an isolated traversal experiment. The accepted scope is narrower than all future possibilities in the original development ledger.

## Delivery and commits

| Stage | Delivered | Commit |
| --- | --- | --- |
| E — Hostile combat | Shared physical shot execution; armed Raider engagement, cover and retreat; player hull, damage feedback, destruction and terminal shutdown | `c8d6686` |
| F — Death flares and loot pressure | One flare per accepted Raider death; delayed local response; finite reinforcement budget and active cap; identified equipment and hold-to-recover interaction | `9cf9be1` |
| G — Extraction and persistence | Five-second Recall Dock channel; extraction while hostiles remain; separate banking/forfeiture; versioned local stash, receipts, backup recovery and failed-save retry | `78e8004` |
| H — Machine ecosystem | Independent flying scout and ground guard; expiring threat snapshots; player warnings; Raider machine targeting; preallocated recoverable components | `c1abc5d` |
| I — Traversal experiment | Grounded jump, short camera-relative boost, cooldown feedback and collision-safe movement in a separate preset | `ac0bace` |

The director requested player-controlled risk during recall. Commit `6c9dcfd` allows nonlethal hits without resetting recall. Destruction and the deadline still prevent unfinished extraction; movement, firing, release and loss of eligibility still interrupt it.

## Playable presets

| Key | Scenario | Main purpose |
| --- | --- | --- |
| F9 | Survival | Armed Raider combat and player survival |
| F10 | Loot Pressure | Flares, response timing, equipment recovery and finite reinforcements |
| F12 | Recall Deployment | Risking deployment cargo and banking persistent rewards |
| F4 | Machine Ecosystem | Scout/guard autonomy, shared information and component recovery |
| F2 | Traversal Experiment | Space jump and Shift boost with combat and recall |

Prior F6–F8 unarmed scenarios and the single-Raider regression scenario remain available. Experimental traversal is disabled in every previous preset. Its initial tuning is approximately 1.5 m jump height, 16 m/s boost for 0.25 seconds, then a 1.5-second cooldown.

## Ownership and accounting

Health owns accepted damage; the shared ShotExecutor owns firing cadence and physical hit resolution. Each actor owns its own FSM and movement. Shared awareness distributes expiring snapshots without controlling another machine's movement.

MaterialLedger remains the sole material authority:

```text
Protected + Carried + Ground + Recovered + Lost + Banked + Forfeited = Total
```

EquipmentLedger separately owns equipment identities and locations. PersistentStash owns saved inventory; deployment settlement records banking or forfeiture without overwriting actual Raider extraction losses or unrecovered ground categories. Reinforcements add no materials. The ecosystem allocates its two installed components upfront, giving 11 total materials rather than creating quantities on machine death.

## Validation

| Checkpoint | Passing automated suites |
| --- | ---: |
| E | 10 |
| F | 11 |
| G | 12 |
| H | 13 |
| I | 14 |

Each stage recorded Godot 4.7.2 editor import/parsing, bounded headless startup and Forward+ graphical startup validation. The final Stage I run passed all fourteen suites, including earlier regression coverage. Save tests use isolated ignored `.godot/` directories and do not alter the player's stash.

Intermittent two-instance ObjectDB cleanup warnings occurred in some parallel flare/recall test runs; affected separate reruns passed without those warnings. This does not establish a permanent cleanup fix. No gameplay assertion or startup errors remained in the recorded final checks.

## Acceptance and deferred review

The director accepted each checkpoint. Latest Stage I feedback confirms jump and boost work and jump height is good. The jump feels floaty; refinement was explicitly deferred.

Ongoing manual review includes encounter difficulty, aim-warning fairness, cover/path congestion, flare and threat-warning readability, guard usefulness, component pickup placement after aerial deaths, recall risk, jump/boost feel, and real-session stash retention. Automated checks do not replace broad player testing or cross-hardware performance measurement.

Not delivered or authorized by this completion: complex crafting, spending saved inventory, loadout progression, additional chassis, movement attacks, advanced squad tactics, final Blender art/animations, networking or a campaign. A further stage requires an agreed scope. Traversal acceptance does not automatically promote experimental abilities into the baseline controller.
