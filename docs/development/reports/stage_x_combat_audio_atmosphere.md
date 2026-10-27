# Stage X: combat feedback, audio and atmosphere

Delivered **2026-10-23**. **Checkpoint X accepted by the director on 2026-10-25.** The director approved the [proposal](../plans/phase_7_stage_x_combat_audio_atmosphere_plan.md), including its recommended correction for the existing flinch/muzzle bug. The [original ledger](../ledgers/phase_7_stage_x_combat_audio_atmosphere.md) remains unchanged. No Stage Y work, Git commit or publication was performed.

## Delivered behavior

Player, Raider and ground-guard fire share one discharge adapter per actual weapon: a brief directional muzzle mesh, capped unshadowed lights, captured-endpoint traces and distinct positional sounds with restrained local variation. Existing ActorVisual retains recoil ownership. The flying scout remains unarmed.

ShotExecutor retains its original permission, physical ray, cooldown, damage and fired-event ordering. An additive observation snapshots impact position, normal, incoming direction, explicit surface tag and actual-damage result before death callbacks. Rejected shots present nothing; sky misses have no invented impact; walls still block damage. The hit marker continues to mean actual accepted damage.

Explicit collision-body metadata selects metal, concrete, industrial equipment, machine armor, Raider gear or generic hard-surface feedback. Short colored chip/spark ribbons and impact sounds use captured world values. Machine Health drives flash, critical smoke and destruction without creating damage. Existing DeathTumble still creates the single cosmetic corpse. Terminal effects outlive the source independently. Imported Raiders flash; only static cosmetic fixtures deform.

One mission-local MissionPresentation owns capped world effects, reusable sound slots and a listener following the existing active camera. It cannot select cameras or command simulation. Actors register through existing visual setup, including scheduled arrivals. Player death preserves surviving world presentation where mission rules permit. Shutdown/restart stops loops, clears stream references and removes the old owner, listener and transients.

Twenty-nine original, offline-generated mono WAVs replace duplicated runtime synthesis: two discharge variants per armed role, six surfaces, damage/destruction, machine motors, environment beds, flare and small interface confirmations. Shared resources preload before deployment. Category buses send to Master; Music remains reserved and silent. Playback never calls AI hearing. Motor pitch/gain reads real speed; recovery/objective/result cues read authoritative edges with deduplication. Existing hull/direction warnings, hit markers, recovery notices and Recall text remain. No camera-shake controller was added.

Compact Asset Recovery and the expanded complex have explicit daylight resources, restrained distance haze, warm bay task lights, cool fill, two localized dust emitters and three quiet spatial environment beds. Geometry, collision, cover, navigation and mission configuration remain unchanged. P/Q/R lighting resources retain their settings. The expanded graybox remains a geometry/art comparison and inherits X's expanded environment; the preserved corrected-W snapshot supplies the original lighting/performance baseline.

Inspection retains six W previews and 0–6/arrow/Space controls. Fire, Metal, Concrete, Armor, Damage, Destroy/Reset, Motor and Repeat audition the shared components without gameplay Health, ShotExecutor, AI or ledgers. Scout Fire is disabled. Reset/selection removes one retained terminal copy and stops audition audio. Motor loops until Reset/selection. See the [presentation guide](../../presentation/README.md) and [audio provenance](../../../assets/audio/README.md).

## Approved muzzle correction

The pre-X probe measured **0.130939 m** of world muzzle movement after one damage point: HitReaction scaled Visuals, which also contains RifleMuzzle. The approved correction never scales that parent. Static cosmetic body fixtures deform, while imported/animated geometry flashes. The physical regression verifies that the entire reaction/restoration cycle leaves the real muzzle and collider transforms unchanged.

Accepted W was copied before edits; a second snapshot contains only this fix. Identical autonomous probes ran on accepted W, corrected W and delivered X:

| Mission / seed | Accepted shots | Material transfers | W → corrected → X off → X on |
| --- | ---: | ---: | --- |
| Compact / 87017 | 14 | 5 | Identical recorded replay |
| Compact / 87018 | 11 | 5 | Identical recorded replay |
| Expanded / 87018 | 19 | 7 | Identical recorded replay |

Each comparison covers 40 seconds, actual movement sampled every half-second at 1 mm precision, state/event sequence, shot counters and transfers. Both ledgers remain conserved on every physics tick. No changed shot/outcome appeared in these probes. The approved fix intentionally changes a shot's physical origin during the old erroneous squash; equivalence for every possible W deployment is not claimed. No AI tuning conceals this exception.

## Bounds and performance

Normal maxima are seven weapon voices, twelve reusable spatial one-shots, six machine/environment loops and two interface voices: **27 voices**, below the 32-voice review limit. Four transient lights, sixteen traces, sixteen bursts and 256 transient particles are enforced. Contact bursts expire before terminal smoke under pressure. Each burst batches particles in one mesh. Ambient/critical seeded CPU particles have a separate budget of 24 + up to 24; prior arrival/flare bounds remain.

Matched Forward+ samples use the same 1600 × 900 cameras, seed 87018, five initial Raiders/two machines and 30 seconds of autonomous activity. Hardware: RTX 4060 Laptop / i7-14700HX, Godot 4.7.2. The baseline includes only the approved muzzle fix.

| Measurement | Corrected W | Final X |
| --- | ---: | ---: |
| Bay median / p95 frame interval | 4.179 / 5.525 ms | 4.194 / 5.529 ms |
| Overview median / p95 | 4.171 / 5.528 ms | 4.182 / 5.434 ms |
| Maximum normal draws | 381 | 387 |
| Maximum normal texture memory | 120,534,528 B | 120,538,624 B |
| Eight-death burst p95 / maximum | 4.518 / 5.179 ms | 4.589 / 5.346 ms |
| Eight-death maximum draws | 481 | 475 |

The +1 ms frame-p95 / +80 draw-call review guides were not crossed. Seven simultaneous accepted discharges and eight deaths produced **16 bursts / 176 transient particles / 4 lights / 22 playing voices**, preserving accounting. Eight cosmetic bodies expired and restart removed all previous terminals. A separate 100-impact saturation case exercises admission/eviction limits.

There are performance caveats. Final normal-view maximum intervals reached **20.454 / 21.502 ms**, versus baseline **10.429 / 9.337 ms**. Cached CPU monitor p95 readings were also higher: physics **16.108 / 16.104 ms** and process **4.965 / 29.374 ms** in X. Raw baseline/current monitors are retained in the evidence. Small frame-p95 differences do not establish unchanged CPU cost or hitch behavior. Shared audio now preloads before deployment, avoiding first-use WAV loading in shot callbacks. Director review should include sustained-fire frame comfort; longer profiling is warranted if rare stalls are perceptible. These local samples are not a general hardware guarantee.

## Validation and limitations

- Editor parsing/import passed with clean output. All **39 active suites passed** with completion markers, exit 0 and zero test failures. Thirty-six accepted suites remain, plus combat presentation, audio lifecycle and presentation-integrity coverage.
- Physical cases cover rejected/cooldown fire, real hit/wall/miss, normals/tags, exact damage, hit confirmation, stable muzzle/collider, one-time death, source removal, duplicate registration, invalid geometry, isolated randomness, saturation, expiry and cleanup. Existing movement, personalities, cooperation/betrayal, finite loot, missions, persistence and spectator assertions remain intact.
- Audio checks exercise three restarts, active-camera listening in both spectator modes, no actor/ledger changes from listening, post-death continuation, idempotent settlement and stopped voices after shutdown. Ordinary-rate enabled audio and combat are clean. Dedicated accelerated audio with a **test-only 200 ms mixer drain** is clean. Production teardown never waits or mutes playback.
- The final ordinary accelerated batch retains WAV shutdown diagnostics in **27 of 39 suites**. A separate full verbose batch reproduced them in 30 suites; **only AudioStreamWAV and AudioStreamPlaybackWAV** leaked types appeared, with no actor, node, skeleton or rig type. Incidence is timing-dependent. This inherited backend/test-rate limitation remains open; passing assertions are not described as warning-free shutdown.
- Bounded headless compact/expanded startup logs are clean. Three paired 40-second running deployments test autonomous behavior beyond merely opening a briefing.
- Forward+ inspection/default mission passed actual player firing, loaded Raider death, recovery, successful Recall banking, restart and post-death following. Captures were visually inspected. An initial artificial kill beside the dock left equipment in pickup range, correctly taking priority over Recall; moving that fixture away resolved the smoke check without a gameplay change.
- Source audit: **310 existing entries identical, 15 changed, none missing**, relative to pre-X W runtime/scene/resource/asset/test files. The changed entries are thirteen runtime/scene seams plus test contract/index. Raider FSM/combat/threat/social/navigation, ledgers/rules/configs/stash, project entry, Blender sources, GLBs and rigs retain their hashes. Six additional historical U paths have exact X hashes; prior W AI hashes and physical-geometry tests remain enforced.
- Generated `.godot/` snapshots/imports/probes and isolated saves remain ignored. Source WAV/import sidecars and new script UID files are retained. No existing user work was reset/discarded or committed.

[Delivery evidence](../baselines/stage_x_delivery/README.md) contains raw validation, warning classification, replay observations, source identities, performance, screenshots and probe copies. Automated checks cannot establish sound quality, atmosphere or gameplay readability.

## Changed files and systems

Existing seams: `raider_arena.gd` registration/lifetime; `shot_executor.gd` additive collision snapshot; `hit_reaction.gd` approved fix; player combat/damage feedback and Raider/support/flare presentation migration; ActorVisual preview hooks; actor inspection controls. Compact/expanded scene resources and processing-bay lights/surface metadata changed. Physical actor scenes and authored muzzles were not edited during X.

New components: MissionPresentation, WeaponFeedback, ActorDamageFeedback, FeedbackProfile, FeedbackSurface, EffectBurst and AmbientFeedback; effect/atmosphere scenes and data resources; default bus layout; 29 original WAVs, manifest/import settings and deterministic generator. Three regression scripts/UIDs, pinned contract hashes, updated guides/indexes and evidence complete the delivery. The W source-art pipeline and prior uncommitted work are preserved.

## Checkpoint X review checklist (retained reference)

1. Run `godot --path .`, Deploy and engage one Raider, then several actors. Check firing direction, impact versus real-hit confirmation and incoming direction without reticle/silhouette overload.
2. Run `godot --path . res://scenes/levels/expanded_salvage_complex.tscn`. Compare sunlight, shaded processing bay and alternate routes; check haze/dust, loot contrast, quiet periods and overlapping combat.
3. Run `godot --path . res://scenes/characters/actor_inspection.tscn`. Audition Fire, surfaces, damage, destruction/reset and motors. The scout remains unarmed. Judge placement, character and volume on headphones/speakers. Sounds are synthetic foundations, not final recordings or voice acting.
4. Damage machines through critical health/death; check smoke, one terminal body, finite drops, recovery and Recall/result confirmations.
5. Use F1 developer spectating/F3 diagnostics, then die and use normal post-death following. Check listening follows the view while autonomous encounters continue. Restart repeatedly and listen for lingering loops.
6. At maximum population, judge sustained-fire visibility and frame comfort. Report perceptible rare hitches or masked positional cues.

The director approved **Checkpoint X on 2026-10-25**. The checklist remains available for regression review; documented WAV shutdown and performance caveats remain open refinement items. Stage Y awaits its ledger and director-approved scope. Complex debris/decals, volumetrics, new weapons, AI changes and a larger audio/VFX framework remain outside this stage.
