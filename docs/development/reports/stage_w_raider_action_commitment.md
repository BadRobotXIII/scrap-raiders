# Stage W review: Raider action commitment and steering

The director reported rapid `ENGAGING / INVESTIGATING` alternation and frequent physical path changes while reviewing the new actor models. This is a focused gameplay correction during Checkpoint W review; it does not advance the stage. No commit or publication is included.

The director subsequently confirmed improved behavior and explicitly accepted completed Stage W in the [Stage X ledger](../ledgers/phase_7_stage_x_combat_audio_atmosphere.md) on 2026-10-23. The original implementation/review evidence below is retained.

## Diagnosis and ownership

Raider already owned one explicit FSM. The model adapter only displayed accepted state and actual movement. Three existing paths made those accepted actions unstable:

- Aggressive combat switched to investigation on a single missed perception sample and immediately resumed combat on the next sighting. A real-wall regression reproduced 14 alternating transitions during brief occlusions.
- Fresh allied reports could replace an unfinished investigation destination without a state transition, repeatedly changing the navigation goal. Flares could also replace that route.
- In the expanded west layout, a Raider approaching cover beside a guard could reverse nearly every physics frame while remaining in `TAKING_COVER`. The detour-retention test used the final destination's corridor while navigation was following a different intermediate segment. This discarded useful local detours repeatedly; the navigation height offset was not the cause.

`RaiderThreatMonitor` now holds observation continuity and an accepted investigation deadline. Its enum ranks reported knowledge, direct sight, observed attacks and critical danger. Raider applies the interruption threshold for its accepted activity; the monitor has no FSM, actor-movement code, own processing loop or ledger access. `RaiderCombat` retains personality policy, aiming, cover and firing. Raider remains the sole state/physical-movement owner.

## Corrections

- Accepted armed defense tolerates **0.65 seconds** of continuous sight loss after personality/survival decisions have run. This protects both Aggressive engagement and loaded Greedy defense. Aggressive then uses its existing bounded last-known-position search. During grace the actor does not track an unseen position or fire through cover. Legacy baseline combat policies retain their decision path.
- Rejoining that same opponent requires **0.25 seconds** of continuous visibility. First engagement with a newly observed eligible opponent remains immediate. Target death/ineligibility, observed incoming attacks and critical survival retain their existing priority.
- Report/flare-level knowledge cannot replace an active investigation route. Accepted reported routes expire on their original profile-memory bound; later reports or gunfire cannot extend that deadline. Arrival, failed navigation and stronger observed danger retain their existing completion/release paths.
- Local detours measure the blocker corridor against the current navigation segment while retaining the final-goal test for having passed the blocker. Cover/reposition recovery checks the best remaining navigation-path distance, so circling cannot continually count as progress. Two failed windows use the existing repath/abandon/defend path. Physical sweeps and the existing short detour bound remain active.
- Existing developer inspection shows interruption threshold, sight continuity and route deadline. No player-facing HUD or new strategic/opportunity planner was added. Weapon, health, personality-resource, population and loot values are unchanged.

## Validation and review

Godot 4.7.2 editor parsing/import passed. All **36 regression suites passed** with completion markers, zero test failures and zero script/runtime errors in the final controlled `--fixed-fps 60` headless run. Existing Q/T pursuit fixtures explicitly advance the new sight-loss grace before their original pursuit assertions; those assertions remain intact. Actual physical occlusion, shots, body collision, route recovery, collection, extraction, restart, spectating and authoritative transfers remain covered.

| Physical reproduction | Before | After |
| --- | ---: | ---: |
| Aggressive brief-occlusion action flips | 14 | 0 |
| Loaded Greedy defense action flips | 12 | 0 |
| Occupied corner: large heading changes in eight seconds | 228 | 19 |
| Occupied corner: bounded recovery events / actual shots | 2 / 4 | 2 / 4 |

The corner case ends in visible engagement after abandoning failed cover travel. It does not claim to reach a waypoint occupied by a living machine. Brief detour changes remain; the per-frame reversals are removed while bounded failure recovery is preserved. The rejected retention-only candidate produced 37 turns but zero recovery events or shots, which is why turning count alone was insufficient.

Matched normal-schedule expanded deployments used the same observer and seed, without forced enemies, winners or loot outcomes:

| Seed/layout | Duration before / after | Large heading changes before / after | Engagement/search flips before / after |
| --- | --- | ---: | ---: |
| 87017 west | 152.35 / 145.00 s | 426 / 37 | 15 / 0 |
| 87018 east | 118.52 / 118.52 s | 21 / 21 | 0 / 0 |

Here a large heading change means more than 0.65 radians between observed physics frames. Counts include legitimate turns and route changes; fewer is not itself a gameplay acceptance criterion. Both final worlds completed, admitted the five scheduled Raiders, stayed below the configured population cap and conserved both ledgers at every sampled frame. Scripted regression callbacks also validate conservation after accepted transfers. These two seeds demonstrate improvement and an unaffected reference, not exhaustive behavioral certification.

Forward+ checks passed for normal/expanded startup, the complete physical action-commitment suite, and a graphical Deploy-button-signal/combat/recovery/Recall smoke run. An earlier synthetic mouse-click probe failed to start deployment, so its downstream missing-actor error is retained as a probe failure; it is not counted as successful GUI evidence. The final smoke uses the real button signal and does not certify operating-system mouse delivery. No visual/model assets or rendering settings changed.

Two rejected attempts are documented: retaining detours alone reduced turning but still stalled; applying the new path-distance watchdog to every activity incorrectly abandoned valid post-conflict loot travel after physical recovery produced a longer route. The final watchdog change is restricted to cover/reposition. The unchanged full-integration and guard-passing tests pass; scavenging, investigation and extraction keep their accepted displacement-based recovery. The art audit initially flagged the intentional AI/test source changes. Its historical check now pins five explicitly reviewed correction files to exact hashes while protecting all other U/V/W sources.

The original [W delivery](stage_w_actor_visual_production.md) retains its visual, asset and rendering baseline. [Follow-up evidence](../baselines/stage_w_action_commitment/) includes failed reproductions, final suite logs, seed observations, reviewed source identities and graphical checks. Cleanup warnings are recorded separately from gameplay failures.

The accelerated final run emitted timing-sensitive ObjectDB cleanup warnings in **20 suites**. All 20 passed verbose reruns; warnings recurred in 17. The leaked classes were exclusively `AudioStreamWAV` and `AudioStreamPlaybackWAV`, with audio bus `Master` as the only orphan StringName. No Raider, threat monitor, node, skeleton or animation player leaked. The initial ordinary-rate run emitted this warning only in extraction/flare suites, consistent with the original W audio-cleanup debt; the final graphical checks were clean. This is a retained test/audio shutdown limitation, not a claim of warning-free validation.

Affected files are `scripts/ai/raider.gd`, `raider_combat.gd`, new `raider_threat_monitor.gd` and its UID; new `tests/action_commitment_test.gd` and UID; Q combat/integration and T decision-stability fixtures; the art source-identity contract; and linked documentation/evidence. No commit or publication was made.

For manual review, launch normal Asset Recovery with `godot --path .`, or the expanded mission with `godot --path . res://scenes/levels/expanded_salvage_complex.tscn`, then Deploy. Use **F1** to observe and **F3** for optional diagnostics. Check brief cover/visibility interruptions, an observed attack during pursuit, critical retreat, allied reports and close guard/body passing. Fights should continue through minor visibility changes, searches should remain bounded, and physical routes should progress without rapid reversals. Emergent winners and loot outcomes remain autonomous. Stop at Checkpoint W for director feedback.
