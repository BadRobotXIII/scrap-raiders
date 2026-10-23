# Stage Q: personality-aware combat decisions

Prepared: **2026-10-20**. Status: approved, implemented and **accepted at Checkpoint Q on 2026-10-20**. This is a repository-based plan following acceptance of Stage P, not a director-supplied Stage Q ledger. The approved proposal below is retained for scope reference. See the [delivery report](../reports/stage_q_personality_combat.md) for implemented behavior, tuning, validation and ongoing regression checks.

## Objective and current behavior

Make the existing Greedy, Cowardly and Aggressive profiles visibly different in armed encounters without reintroducing rapid task switching or guard contact stalls.

The accepted Stage P baseline supplies seeded opportunities, independent relationships, bounded arrivals, finite loot and continuous simulation. Its combat follow-ups preserve engagement/cover work, react to visible attackers, steer around blocking bodies, create close-range spacing and allow sustained return fire. Twenty-three suites passed before director acceptance.

Inspection shows `RaiderCombat.decide()` handles armed engagement before the remaining profile-specific flee/investigate decisions in `Raider.decide()`. Most armed Raiders consequently share the same engagement and critical-health retreat policy. Merely changing existing unarmed profile values will not reliably produce distinct armed behavior. The next change should address that decision ordering, rather than add encounters or another AI controller.

## Proposed behavior scope

| Existing personality | Armed behavior to establish |
| --- | --- |
| Greedy | Prefer profitable salvage and preserving carried cargo. Defend against an observed immediate attacker; disengage through a reachable route when the danger outweighs the objective. Do not switch back to scrap on each perception tick. |
| Cowardly | Avoid initiating optional fights and favor an early escape when threatened. Retain an escape decision through brief visibility changes; use the existing defensive fire/cover behavior when escape is obstructed. |
| Aggressive | Commit to eligible observed enemies and follow a bounded last-known-position investigation after losing sight. Resume independent objectives after target resolution, expired knowledge or a necessary retreat. |

Do not add a new personality, change attitude merely because actors contest salvage, or make cooperation imply a permanent squad. An eligible visible attacker can still interrupt a lower-priority objective. Critical survival decisions retain priority over commitment timers.

## Ownership and implementation approach

1. Extend existing profile data with only the fields needed for initiation, disengagement and bounded commitment. Use explicitly opted-in profile/configuration copies for the Q comparison preset; defaults preserve accepted P and older scenarios. Keep rifle damage, accuracy, range, health and population limits unchanged for the initial comparison.
2. Reconcile armed decision ordering in the current Raider/Combat composition. Raider remains the sole FSM and physical-movement owner. Combat owns aim, cover and local combat timing. A profile policy supplies a decision to the existing transition path; it does not run another FSM or write actor velocity.
3. Give commitment and threat knowledge explicit expiration and release conditions: death/extraction, changed eligibility, expired observation, critical damage, blocked escape and terminal mission state. A remembered position is a snapshot, not access to an unseen actor's live movement. Never fire without current visibility and a physically valid shot.
4. Reuse existing reachable exit selection, navigation watchdog, cover reservations, spacing and local steering. Do not replace navigation or introduce a strategic planner.
5. Add concise developer inspection explaining the current decision and why it was retained or released. This reads authoritative state and stays out of normal gameplay UI.
6. Provide one opt-in comparison mission using the existing layouts, stock, patrols and scheduling. Review personality decisions under equivalent conditions rather than force a scripted outcome. Preserve the accepted Stage P preset for comparison.

MaterialLedger and EquipmentLedger retain exclusive transfer authority. Mission policy, persistence, post-death continuation, spectator permissions and camera ownership are outside the change. Personality decisions cannot create materials, equipment or reinforcement tickets.

## Delivery sequence and risks

First establish deterministic policy cases and the opt-in comparison configuration. Implement the smallest profile decision changes, then exercise actual movement, shots, collection and extraction before adjusting default values. Record the initial tuning in the implementation report. Stop at Checkpoint Q for review before expanding scope.

| Risk | Required evidence |
| --- | --- |
| Combat overrides every personality again | Equivalent visible-threat cases produce the intended profile-specific decisions through the actual armed FSM. |
| Objective/combat oscillation returns | Repeated perception ticks, intermittent visibility and noncritical hits preserve commitment until a documented release condition. |
| Flight or pursuit never ends | Reachable escape, last-known-position expiry, blocked routes, low health and resolved targets release or complete the decision. |
| Defensive fire starves escape, or cover prevents all shots | Physical corridor/contact runs and sustained incoming-fire checks retain movement progress and bounded return-fire windows. |
| Knowledge leaks through walls or spectators | Occlusion, unseen target movement, no line-of-sight shots, developer camera and post-death follow tests. |
| Existing scenarios or accounting change | Opt-in configuration, full prior suite run, contested pickup/extraction and conservation checks after accepted transfers. |

## Validation and acceptance

Extend meaningful automated coverage for armed profile initiation, cargo-sensitive disengagement, persistent retreat, observed-attacker defense, bounded pursuit, target resolution, occlusion, blocked routes and decision diagnostics. Include physical movement/shots; policy-only tests are insufficient. Retain both combat follow-up suites as regressions.

Run all twenty-three current suites plus new Q coverage, Godot 4.7.2 editor parsing/import, bounded headless simulation and Forward+ graphical startup. Use isolated ignored saves. Inspect output as well as exit status; report the existing audio test-cleanup warning separately if it recurs.

Manual review must establish that the three personalities are recognizable without diagnostic labels, fights remain fluid, fleeing actors are neither helpless nor omniscient, and the player can interrupt or ignore encounters. Exact winners, betrayals and loot outcomes must remain autonomous rather than test-mandated.

Acceptance is a stable, observable difference in the existing personalities' armed choices while all accepted mechanics remain functional. Stop at **Checkpoint Q** for feedback.

## Explicit exclusions

No dynamic alliance formation, neutral-to-hostile escalation over salvage, equipment equipping, new weapons, machine roles, random spawns, reinforcements, progression, networking, art/animation production or mission-accounting changes. These require their own scope. No Git commit or publication is included in this proposal without an instruction to do so.
