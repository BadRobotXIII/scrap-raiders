# Stage U: world expansion and encounter geography

Delivered and **accepted at Checkpoint U on 2026-10-21**. The director confirmed: "Everthing functioned perfectly, approved." The director accepted Stage T and approved the [U architecture/layout proposal](../plans/phase_7_stage_u_world_expansion_plan.md) before construction. This is a graybox expansion using the existing gameplay controllers. Default startup remains compact Asset Recovery. Stage V, Git commits and publication are not included.

## Play the expanded mission

```powershell
godot --path . res://scenes/levels/expanded_salvage_complex.tscn
```

Read the briefing and click **Deploy**. The mission is **Operation: Salvage Complex**. Recover three material units and hold E at the Recall Dock to bank them; original stock remains Raider-only. Existing combat, jump/boost, optional objectives, equipment recovery and settlement rules apply.

Use **F1** for developer free camera, **Tab / F** to inspect/follow, and **F3** for diagnostics. **Ctrl+Shift+F5**, then Deploy, prepares the next seed in the expanded scene; **R** after termination replays that scene and seed. These operations preserve the selected U mission configuration. Explicit diagnostic scenario selection still leaves U and settles the outgoing deployment normally. Launch `godot --path .` again to return to compact Asset Recovery. Do not use in-game F5 as a U selector; its existing reference routing remains unchanged.

## Delivered environment

The floor is **72 × 64 m**, twice the compact Mission floor area, with a connected activity core rather than uniformly distributed objectives. North is −z.

| Area | Delivered geometry and purpose |
| --- | --- |
| Central yard | Low crates, full occluding bays, north screen, multiple approaches and the six-unit stock opportunity. |
| Processing | Openings to north, south and east, an internal partition and a high roof. Multiple entrances permit retreat when a doorway is blocked. |
| Storage | Offset container cover and a one-metre loading deck with two separate four-metre ramps. Ramp side rails keep navigation approaches physically valid. |
| Service/perimeter | Southern screened traversal, exterior north/east/west alternatives and visible route landmarks. |
| Extraction | Northwest and southeast Raider exits, plus Recall Dock near the south boundary, accessible through more than one approach. |

The route graph and approximate coordinates remain in the approved proposal. The implemented north processing opening, service links and outer lanes supply alternate routes without introducing route-planning policy. Landmark labels were reduced and raised after graphical inspection showed the first version obscuring the player view. All geometry, colors and labels are engine primitives; no third-party assets or detailed art are introduced.

```text
ExpandedSalvageComplex                   mission_arena.gd
  Geometry                              navigation_geometry source group
    SalvageYard                         environment/salvage_yard.tscn
    ProcessingFacility                  environment/processing_facility.tscn
    StorageArea                         environment/storage_area.tscn
    ServicePerimeter                    environment/service_perimeter.tscn
  NavigationRegion3D                    one synchronous static bake
  Robot                                 existing player scene
  Overlay                               shared existing static HUD scene
  Salvage / Salvage2 / Salvage3          ledger-backed views
  RaiderSpawns / EncounterSites          authored markers
  ScoutRoute / GuardRoute               authored patrol markers
  CoverPoints                           cover markers with Peek children
  Extraction / Extraction2 / RecallDock
```

## Implementation and ownership

| Files | Change |
| --- | --- |
| `scenes/levels/expanded_salvage_complex.tscn` and four `environment/*.tscn` files | New root composition, static geometry, root-compatible markers, cover, navigation and patrols. No level controller script. |
| `resources/missions/expanded_asset_recovery.tres`, `u_encounter_west.tres`, `u_encounter_east.tres` | U-only configuration and two seeded authored arrangements. Same finite pool and accepted profiles/social policy. |
| `scenes/presentation/arena_overlay.tscn`, `scenes/levels/test_arena.tscn` | Extract existing static Overlay and instance it in both level families, retaining child paths, properties and compact root-child order. Dynamic presentation remains created by existing systems. |
| `scripts/gameplay/mission_arena.gd` | Optional typed configuration override; replay/next-seed can preserve current scene/config identity. Explicit reference selection clears the override. Default CONFIGS routing is retained. |
| `tests/expanded_world_test.gd` and `.uid` | Physical U geometry, navigation, social/combat and deployment-lifecycle coverage using existing test helpers and isolated saves. |

No Raider FSM, combat policy, steering, machine controller, collision masks, ledger, persistence or spectator-permission code changed. The root preserves the existing controller contract instead of relocating gameplay authority into environment modules. Module geometry exists before the existing parent `_ready()` bakes navigation. The briefing's disabled process mode also prevents active map use until Deploy; tests validate the synchronized map after deployment rather than treating a briefing-time empty map as broken navigation.

Initial parameters remain **five Raiders at 0/0/35/70/105 s**, **180 s deadline**, **five live Raiders maximum**, **two machines**, **two finite response tickets**, and **6/3/3 stock plus two installed components = 14 materials**. Health, weapons, awareness, cargo targets, social relationships, Q policies and objective requirements are unchanged. The scout remains an unarmed observer and the guard remains armed. No tuning increased populations or extended the deadline to compensate for scale.

## Physical corrections during construction

Path existence alone initially hid a real defect: a diagonal navigation approach entered the side of a loading ramp, where the capsule stopped. The accepted watchdog retried and selected alternate salvage. Adding side rails, as used by the compact ramp, corrected the geometry; the same test now crosses the level, collects three units on the deck at about y=1 and completes physical extraction. No navigation tolerance or movement test was weakened.

The first west-yard peek clipped the far cover corner and could not hit the machine. Moving the authored peek beyond the corner permits a real rifle hit while the cover position still blocks it. Processing/service peek clearance was adjusted similarly; every cover/peek endpoint has supported connected navigation. This is marker placement, not new cover logic.

## Validation evidence

Evidence is archived in the [U baseline directory](../baselines/stage_u_delivery/README.md), including source hashes, logs, natural observations, graphical captures and performance data. Fresh pre-change validation passed all **31** accepted suites and editor parsing/import. Accepted compact source hashes matched the T follow-up manifest before edits; fresh 87017/87018 compact runs reproduced that baseline.

The expanded suite covers:

- Briefing gating, both seeded configurations, finite pool, supported/collision-clear entries, all alternate stock sites, exits/dock, cover/peek navigation and clear scout legs.
- Actual Raider travel across the level, ramp access to finite stock, extraction travel/dwell and player ascent/deck traversal/descent.
- A physically closed processing north doorway with a rebake in a controlled fixture: a loaded Cowardly Raider leaves through another doorway and extracts. Out-of-bounds objectives return infinite route cost.
- Occluding cover and valid peek shots, actual hostile Raider damage exchange, shared occluded machine reports and physical investigation without permanent squads, conditional richer-ally betrayal and a real shot.
- Cargo recovery, successful objective banking, one-time failure forfeiture, immutable results, normal post-death follow, U replay/seed identity and explicit return to compact configuration.
- Conservation checked after every accepted material/equipment transfer in these fixtures. Existing suites retain contested ownership, flare bounds, post-death world activity, target switching, AI commitment and compact regression coverage.

The complete **32-suite set passed** in accelerated fixed-60-FPS simulation and the ordinary-timing full run. Additional final U fixture extensions were rerun as focused checks, including Forward+ at ordinary timing; see the archived validation register for exact final runs. Accelerated checks emit additional audio cleanup warnings and are retained separately from ordinary timing. Final ordinary-timing logs contain no engine/script errors. The existing two-instance ObjectDB cleanup warning recurred in the legacy extraction suite in both the fresh before and after runs; it is separate from gameplay correctness and also predates U. A verbose U accelerated check identified AudioStreamWAV/AudioStreamPlaybackWAV cleanup references; ordinary final U and GUI logs are clean. Final logs were inspected as well as process exit status.

Graphical checks also exercise the actual U GUI Deploy click, player hitscan defeat of an arranged loaded Raider, physical cargo recovery, five-second recall and successful results. Compact S graphical deployment/results and reference routing are tested after Overlay extraction. These are automated graphical fixtures, not director acceptance or proof of gameplay feel.

## Natural seeded observations

Five U seeds **87017–87021**, a repeat of **87018**, and five matched compact seeds were observed at **1×**. Observers read state and use existing spectator permissions; they do not reposition actors, grant cargo, force kills/relations or change AI decisions. The stationary player remains vulnerable and post-death simulation continues. Concurrent headless observers are not rendering/performance measurements.

| Seed / layout | World resolution (s) | First shot (s) | Shots | Navigation retries | Materials extracted / ground / untouched |
| --- | --- | --- | --- | --- | --- |
| U 87017 west | 152.35 | 8.77 | 87 | 2 | 12 / 1 / 1 |
| U 87018 east | 118.52 | 2.85 | 29 | 0 | 14 / 0 / 0 |
| U 87019 west | 145.62 | 8.77 | 82 | 2 | 12 / 1 / 1 |
| U 87020 east | 118.52 | 2.85 | 29 | 0 | 14 / 0 / 0 |
| U 87021 east | 118.52 | 2.85 | 29 | 0 | 14 / 0 / 0 |
| U 87018 repeat | 118.52 | 2.85 | 29 | 0 | 14 / 0 / 0 |

All six U runs finished with five Raider extractions, two machine deaths, no unresolved actor objectives, valid conservation/caps and immutable player results. West recorded successful bounded navigation retries during cover/retreat; no persistent stall remained. Its 16–17 combat episodes occupied roughly 74–87 actor-seconds; east had three episodes totalling 18.37 actor-seconds. Actor-seconds can overlap and are not deployment-wide combat duration. The longest intervals between logged shots were 8.5 s west and 22.4 s east; these exclude activity before the first shot and after the last, and do not measure player-perceived danger.

Matched compact runs resolved in 111.18 s except seed 87021 at 138.63 s, with 30–35 shots and no navigation recoveries. Compact first shots ranged 1.03–13.30 s. U changes geography rather than guaranteeing less combat: west creates longer machine pressure and retreat work, while east has a shorter early machine fight and longer gaps. No activity collapse or unresolved long-distance objective required changing counts or timing in this sample.

**Natural observations did not produce a Raider death, committed betrayal or human-to-human damage in U.** Existing social behavior is enabled, shared reports occurred in west, and controlled U fixtures verify cooperation, betrayal and hostile combat under valid conditions. This is reachability evidence, not a claim that all social events occurred naturally. The repeat reproduced east's setup and summary; seed reproducibility does not promise frame-identical combat on other hardware. Only two authored configurations exist; five seeds do not imply five different maps.

## Performance and remaining review

Paired performance results and the exact probe are archived separately from natural observations. The probe admits the five finite initial IDs early as an explicitly arranged load case, uses the same full-world overview camera/settings and records 30 seconds of rendering plus process/physics monitors. It reports the number of frames actually retaining five Raiders/two machines; actors remain free to die/extract. Timing includes a separate repeated-bake measurement, not a claim to isolate every cold-start cost. Results are local Forward+ measurements rather than production export or cross-hardware certification.

On the RTX 4060 Laptop GPU / i7-14700HX, Forward+ at 1600×900, with optional metrics disabled:

| Measurement | Compact | Expanded |
| --- | --- | --- |
| Retained frame samples | 7,143 | 7,143 |
| Median / p95 / max frame interval (ms) | 4.170 / 5.615 / 7.430 | 4.183 / 5.594 / 8.698 |
| Frames with five Raiders and two machines | 1,676 | 1,322 |
| p95 frame interval at that population (ms) | 5.615 | 5.748 |
| Load-to-root-ready including initial setup (ms) | 266.50 | 280.40 |
| Separate repeated navigation bake (ms) | 6.87 | 14.87 |
| Repeated map synchronization wait (ms) | 7.51 | 7.64 |
| Static memory at sample end (MiB) | 69.56 | 71.67 |

Both retain conservation and population bounds. No sustained frame-interval regression or repeated >33 ms frames was observed in these paired samples; full-window p95 differs by less than 1%. The expanded static bake costs more, as expected from the additional surfaces, but remains a one-time operation in ordinary deployment. Engine process/physics monitor samples remain in the JSON; their reported aggregates are not interpreted as exclusive per-render-frame CPU/GPU costs. In particular, the compact process monitor includes a larger reported value than the rendered frame intervals, so it is not used to claim a CPU speed improvement in U. Sustained target-hardware review remains necessary.

Before accepting U, the director should:

1. Traverse processing, yard, service/perimeter and storage; use both ramps and alternate routes. Judge landmark readability, camera clearance and whether travel adds tactical value.
2. Play normally, intercept loaded Raiders, recover materials/gear, and recall. Compare early/complete extraction, incoming damage feedback and the chance to intervene before carriers leave.
3. Observe seeds 87017 and 87018 with F1/F3, then advance seeds. Watch cover/peek transitions, close guard contact, flying-target pursuit, the two west recovery situations and whether personalities remain recognizable.
4. Observe allied/rival opportunities across repeated deployments without requiring betrayal or a specific winner. Natural social conflict frequency may need later geography refinement after human feedback.
5. Die carrying loot, Spectate, cycle targets through death/extraction, Return and replay. Confirm expanded scene retention, fresh mission state and unchanged prior stash.
6. Return to compact Asset Recovery and diagnostic presets; confirm accepted movement/camera/social behavior remains available.

This remains a primitive graybox with one static bake, no streaming, no AI climbing/mantling, no new traversal and no art/animation pass. The high processing roof is not a Raider objective; the scout stays on open outdoor legs above recoverable ground. New machine roles, strategic routing, broader AI tuning, progression and production assets remain outside U.

**Checkpoint U accepted.** The director confirmed successful manual play-testing on 2026-10-21. The checklist above remains regression guidance for future expansion; local performance samples do not establish cross-hardware certification. Stage V requires its own agreed scope and approval. No default-scene promotion, Git commit or publication is included.
