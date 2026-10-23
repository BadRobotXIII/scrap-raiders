# Stage T follow-up: Raider hesitation and rapid turning

Prepared **2026-10-21** in response to director play-testing. Stage T integration was broadly functional, but the director reported apparent decision paralysis and high-speed turning around competing encounters and nearby allied Raiders. **This is a correction within Checkpoint T, subsequently accepted by the director on 2026-10-21 with "Stage T is approved." No Stage U implementation or Git commit is included.**

## Reproduced causes and corrections

| Cause | Evidence before correction | Delivered correction |
| --- | --- | --- |
| Per-frame local avoidance changes | Two allied physical bodies approach independent salvage objectives head-on. One made **19 heading jumps greater than 1 radian in four seconds**. Recomputed tangents and brief sweep clearance repeatedly changed direction. | Raider's existing movement owner retains a collision-checked bypass vector for at most **0.35 s**. It releases on changed goal, invalid/passed/distant blocker, sufficient lateral clearance, expiry or obstructing geometry. A forward component prevents the detour from repeatedly backing away from the objective. No teleport or collision bypass. |
| Pursuit loses target commitment | An Aggressive Raider sees an opponent, loses LOS behind actual cover and starts bounded last-known-position pursuit. The next decision selects another visible enemy, cancels that pursuit and stops making progress. | Existing social target selection retains a valid current target through Combat's existing bounded pursuit, as well as combat states. It uses the existing observation expiry and saved position. Death, extraction, attitude/eligibility changes and expired knowledge still release it. |
| Incoming hits continually restart aim | Two visible eligible attackers alternate noncritical damage callbacks every 0.2 s. The Raider switches targets **20 times and fires zero shots in four seconds** despite valid firing opportunities. | Combat owns a bounded attacker-response timer. The first observed attacker can interrupt; while actually engaging a still-visible eligible target, subsequent alternating hits cannot repeatedly reset aim. Duration derives from existing warning plus two shot intervals (**2.25 s** for the current rifle). Repeated hits on that same target do not extend it. |

The attacker window is not invulnerability and does not force a fight. All incoming damage applies. Loss of visibility/eligibility or target death permits a new visible attacker immediately. Existing cover/repositioning work permits attacker changes without resetting its route. Critical survival still overrides response commitment; Cowardly flight, Greedy cargo defense and Aggressive pursuit remain separate existing policies. Unknown or unseen damage does not reveal an attacker through walls. All firing retains fresh LOS and physical shot validation.

This fixes the underlying movement/decision changes rather than adding rotation smoothing. Legitimate turns are still immediate with primitive meshes; animation polish remains separate scope.

## Scope and ownership

- `scripts/ai/raider.gd`: local bypass state and physical movement remain actor-owned; observed damage redirects consult Combat's response timing.
- `scripts/ai/raider_combat.gd`: response timer and its expiry/stop reset remain part of existing local combat timing; no new FSM or controller.
- `scripts/gameplay/social_encounter.gd`: current target retention now includes valid snapshot pursuit, without changing relationship eligibility.
- `tests/raider_decision_stability_test.gd` and its Godot `.uid`: actual body movement, physical occlusion and competing threats, outgoing rifle shots, damage application, resolution and critical escape.

No mission resources, schedules, populations, relationships, weapon definitions, health values, personality resources, material/equipment accounting, persistence, player controller or spectator ownership were changed in this follow-up. Compare [delivery source hashes](../baselines/stage_t_decisions/source_changes.json) with the original [T implementation manifest](../baselines/stage_t_delivery/source_manifest.json) to distinguish these changes from accepted uncommitted work.

## Validation and development evidence

The new tests failed before the corresponding fixes: allied-contact heading reversal, pursuit retention/progress, and multiple-attacker firing starvation. On the final version:

| Physical case | Result |
| --- | --- |
| Allied passing | **4 / 4** large heading changes, rather than 19 / 2; both actors pass and progress to their separate objectives with alliance and accounting intact. Counts include intentional initial/bypass turns; they are not an animation smoothness score. |
| Pursuit with another visible enemy | Original target/snapshot retained, actual navigation progress, visible incoming attacker can interrupt, resolved/expired interest releases. |
| Competing incoming hits | **2 target switches / 4 outgoing shots**; all 20 incoming damage units still applied. Target death releases focus immediately, critical health still triggers escape. |

An initial bypass candidate held a backward-biased detour too long and failed the existing guard-clearance travel test. That candidate was rejected. The final short, forward-biased bypass passes the original physical guard clearance, contact spacing and sustained-return-fire assertions without weakening those tests.

Full validation and bounded normal-deployment evidence are archived in the [follow-up evidence directory](../baselines/stage_t_decisions/README.md). The new regression runs both headless and under Forward+; the complete suite includes all 30 prior suites plus this one. Parsing/import and normal graphical startup are checked separately. Natural outcomes are reported separately from deliberately arranged regressions; these tests do not force ordinary missions to produce particular winners or betrayals.

**All 31 suites passed in the final full run**, with no engine/script errors or warnings in final logs. This includes original guard clearance, cover/return fire, Q policies, K–M social behavior, normal S integration, accounting, traversal, extraction, persistence and both spectator modes. Godot **4.7.2** editor parsing/import, the full new regression under **Forward+** and bounded normal graphical startup passed. No production export or new performance certification was attempted.

Two final **1×** passive normal deployments, **87017 south** and **87018 north**, both resolved at **111.18 s** with five Raider extractions, two machine deaths, 13 extracted material units and one unit left on the ground. They recorded 30/32 shots and **zero navigation recovery events**. Every frame retained material/equipment conservation, population/response limits and frozen player results; no unresolved Raider objective remained. The robot remained stationary/vulnerable and existing spectator permissions were used. These observations are not a substitute for active player or large-group feel review.

North had a valid betrayal assessment that was interrupted rather than committed in this sample. This differs from the original T delivery's passive outcome: physical paths/arrival timing change when movement is corrected. The assessment gates and mission configuration were not retuned to guarantee a betrayal, kill or winner. Controlled S integration and the preserved natural M regression continue to verify valid betrayal behavior separately. This follow-up does not claim betrayal must occur in each normal deployment.

## Manual recheck

1. Revisit the same normal mission/seeds where spinning was seen. Observe allies crossing or converging on salvage and a moving combatant passing a stationary friendly body. They should pass or use the existing bounded recovery path, rather than rapidly reverse direction in place.
2. Watch a Raider encountering multiple eligible threats. Brief occlusion should retain its remembered pursuit; unseen movement must not update that saved destination. A genuinely visible attacker can still interrupt.
3. Attack a Raider while another opponent also attacks it. It should be able to finish an aim warning and respond, take cover or retreat according to its personality. Incoming damage must remain effective.
4. Check close guard contact, cover travel, retreat and extraction. The correction should not trade spinning for long detours or stuck actors. Keep F3/F1 inspection available to record seed, Raider ID, state and target if another loop appears.

These cases address three measured causes, not every possible crowded-layout failure. The director has accepted this integrated baseline for world-expansion planning. Retain these checks as regression guidance when geography and crowding change.
