# Stage Q: personality-aware combat decisions

Recorded: **2026-10-20**. **Checkpoint Q accepted by the director on 2026-10-20.** Scope follows the [approved plan](../plans/phase_5_stage_q_personality_combat_plan.md). Subsequent Stage R baseline evaluation and planning are recorded [separately](stage_r_baseline_evaluation.md). No commit or publication is included.

## Delivered behavior

The new comparison mission uses copied profile/configuration resources. Accepted Stage P and earlier scenarios retain the baseline combat policy. Layout IDs, seed selection, profile order, patrol routes, stock, entry timing, population/response budgets, weapons, health and mission rules are unchanged. Q fallback profiles also apply to finite flare responders.

| Profile | Implemented armed decision |
| --- | --- |
| Greedy | Empty and healthy, prioritize salvage over an optional opponent more than 6 m away. Engage nearby danger. Carrying cargo, or at/below 65% health, favor a reachable escape. An observed attacker can trigger four seconds of defense before reconsidering cargo; repeated hits do not extend that window. Complete selected cover work through occlusion unless survival/cargo escape takes priority. |
| Cowardly | Avoid optional fights and start a five-second escape commitment on a visible threat or remembered damage/gunfire. Keep moving through brief sight loss. If all exits are unavailable, defend while retrying every two seconds, then resume escape when a route opens. An empty, noncritical Raider can resume objectives once its commitment and threat observation expire. |
| Aggressive | Commit to eligible visible opponents using the existing combat/cover flow. On losing sight, investigate the saved observed position for at most four seconds, stopping about two metres from that position on the navigation map. Unseen target movement, gunfire, allied reports and flares cannot relocate that committed snapshot. Release on expiry, searched/blocked pursuit, death, extraction or changed eligibility. |

All profiles retain critical-health retreat at the shared 30% threshold. Loaded escaping Raiders continue toward timed extraction; a safe empty Raider may return to its independent objective after observed and audible danger expire. New sounds/hits may retain escape without restarting its commitment timer. Failed exit retries preserve active defensive cover work. Completed cover routes still use the accepted warning and return-fire window. Actual firing requires fresh visibility, range, cooldown and an unobstructed physical shot. No attitude is inferred from personality or competition for stock.

Raider remains the sole FSM and movement/velocity owner. RaiderCombat evaluates the opted-in profile before baseline armed decisions and owns its combat commitment/escape/observation metadata; it does not move the body or transfer loot. The existing actor navigation watchdog, exits, cover reservations, close spacing and local steering remain in use. Mission policy, player/world lifetime separation, cameras, material/equipment ledgers and stash settlement are reused unchanged.

F3 diagnostics and the developer inspector show the policy, current reason and commitment/escape/observation time remaining. These fields are read-only presentation and are absent from normal post-death spectator UI.

## Running and comparison

- **Alt+Shift+F5** in a debug build opens Q. From an encounter preset it preserves the chosen seed.
- **Shift+F5** returns to accepted P; from Q it preserves the chosen seed for comparison.
- **Ctrl+Shift+F5** advances the seed and keeps the current P/Q mode. Restart repeats the selected mode and seed.
- Standalone: `godot --path . res://scenes/levels/personality_encounters_arena.tscn`.
- F1 developer spectating and F3 inspection remain available. Post-death Spectate/Return and target cycling retain their existing restrictions.

The default seed is 87017 (south); 87018 selects north. Matching seeds reproduce initial conditions, not identical physics/combat outcomes. The initial north pair includes Greedy/Cowardly; south includes Greedy/Aggressive. Additional profiles arrive through the unchanged schedule.

## Validation

All **25 automated suites** passed: the existing 23 plus `personality_combat_test.gd` and `personality_integration_test.gd`. The final affected-suite reruns include the comparison controls and preserving Greedy cover progress through lost visibility.

Coverage includes equivalent-threat decisions, actual escape movement, bounded defense and unchanged timers under repeated damage, blocked-route defensive hits/retry/reopening, real finite scavenging and timed extraction, saved-position pursuit, expiry despite unrelated gunfire, report priority, pursuit navigation failure, critical retreat, relationship eligibility, destroyed/extracted targets, configured responders, same-seed restart and P/Q switching. Integration checks cover developer camera non-interference, irreversible player failure, one-time loot forfeiture, restricted follow cycling, deadline shutdown and conservation. Saves are isolated under ignored `.godot/stage_q_tests/` and `.godot/stage_q_integration/` paths.

Natural accelerated cases exercised both Q layouts beyond the final 105-second initial entry, with five scheduled Raiders admitted in each observed case. Actual movement and policy activity occurred while live caps, finite material totals and equipment ownership remained valid. No exact winner, betrayal or loot total was required. Scenarios warm up navigation before accelerated observation, as in the existing encounter test; an initial test without that synchronization failed setup during scene replacement and was corrected in the fixture.

Godot **4.7.2 Standard** editor parsing/import, bounded **900-frame headless** Q startup and **600-frame Vulkan Forward+** graphical startup passed without reported errors. Exit status and output were inspected. The existing recall suite passed its assertions but reported its known two-instance audio ObjectDB cleanup warning. The new Q suites and startup checks reported no such warning. No packaged export was performed. Generated engine/test state remains ignored; generated script `.uid` files are retained.

## Manual Checkpoint Q

1. Compare P and Q using the same seed. Observe the north opening and later arrivals; verify Cowardly's avoidance and Greedy's choice of scrap/cargo over optional fights.
2. Use the south opening to assess Greedy/Aggressive guard combat, completed cover/peek routes and sustained return fire. Check close guard contact and crowded passages for regression.
3. Intervene against loaded Greedy and fleeing Cowardly. Assess whether defense, disengagement and escape are readable and responsive without repeated short task switches.
4. Break sight with Aggressive behind cover. Verify a bounded search of the observed area rather than tracking through walls, followed by independent objectives when the search resolves.
5. Recover cargo/equipment and recall; then test death, follow cycling, later arrivals, deadline and restart. Review F3 reasons, then hide diagnostics and judge whether the personalities remain recognizable.

The director accepted Q and authorized preparation for R. Personality readability, commitment durations, escape fairness, cover rhythm and congestion remain useful ongoing regression/play-test checks. The first Q tuning is deliberately small: no new alliance formation, neutral hostility, equipping, weapons, progression, spawning framework, art or networking. Original salvage remains globally available to the existing scorer; this stage does not introduce observed-only salvage discovery.

Existing uncommitted P follow-up work has been preserved. Stage Q and documentation changes remain uncommitted, as required by the approved scope and repository conventions.
