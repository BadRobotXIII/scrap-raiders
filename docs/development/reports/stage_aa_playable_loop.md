# Stage AA: early playable Sanctuary loop

Prepared **2026-10-27**. **AA-1 through AA-5 accepted by the director, who authorized continuation.** This report preserves the early checkpoint; see the [final AA delivery](stage_aa_sanctuary_gameplay_loop.md) for later implementation. This is the approved early checkpoint, not completion of Stage AA. The [approved plan](../plans/stage_aa_sanctuary_gameplay_loop_plan.md) and unchanged [director ledger](../ledgers/stage_aa_sanctuary_gameplay_loop.md) define the boundary. AA-6 onward remains gated. No commit or publication was performed.

## Playable behavior

Run `godot --path .`, or F5 in the editor, to open the title screen. Enter Sanctuary opens a safe workshop with a walking player machine; Quick Deploy reaches the same preparation services directly. Settings provides saved master volume and fullscreen preferences. Existing explicit arena launches and diagnostic presets remain available.

In Sanctuary, use **WASD**, mouse and wheel for movement/camera, **E** at a station, **Tab** for quick station navigation and **I** for storage. The six stations expose storage, maintenance/loadouts, fabrication, disassembly, contracts and deployment. Fabrication and disassembly clearly report that they are unavailable at this checkpoint. The room contains no hostile simulation, mission deadline or resource income. Damage and weapon input are disabled there. Quick navigation checks a standing destination and route before moving the robot.

Storage and loadout preparation reuse the accepted item view, icons, shortcuts, quantities and scroll retention. Named templates describe desired equipment and cargo; saving or previewing them reserves nothing. One prepared kit holds actual reserved identities. Readiness distinguishes ready, partially available and unavailable requests, including missing definitions, quantities, mount compatibility, weight and slot limits. Exact preparation is atomic; partial preparation requires explicit confirmation. Recovered human rifles remain cargo for the robot and cannot be mounted.

Both existing contracts are selectable with a reproducible seed: compact Asset Recovery and expanded Salvage Complex. Deployment confirms equipment/readiness, stages the existing scene, checks navigation and physical floor readiness, commits the kit, marks the attempt running and enables simulation. An activation failure before running refunds the original kit and mount identities. Preparation is locked during this handoff.

Recall uses existing mission/objective rules: completed-objective extraction succeeds, early extraction banks carried items while reporting incomplete objectives, and destruction/abandonment forfeits carried deployment cargo. Results and inventory settlement share one durable receipt. Return reconstructs Sanctuary from the persistent projection; another deployment does not require restarting the application. After destruction, the existing spectator behavior can continue until Return.

During active gameplay, **Escape** or **Abandon / Return to Sanctuary** opens a cargo-loss confirmation. Cancel restores gameplay without forfeiture; simulation continues during the dialog. After settlement the button becomes Return to Sanctuary. Application-managed restart returns through the session; debug preset requests cannot silently replace an active deployment. Standalone diagnostic scenes retain their own routing.

## Authority and persistence

| Responsibility | Owner |
| --- | --- |
| Application phase, scene replacement and preparation lock | `GameSession` under the application root; no autoload |
| Item identities, locations, transfers and capacity | Existing `InventoryLedger` |
| Profile writes, journal and deployment receipts | Existing `PersistentStash` |
| Template requests and safe preparation commands | `PreparationService`, through the same persistent transaction path |
| World simulation, actor FSMs and combat | Existing arena and actor composition |
| Outcome and objective evaluation | Existing `MissionRules` and `MissionObjectives` |
| Physical/quick station access | Sanctuary mode and `StationRegistry` |
| Shared inventory presentation | `InventoryContext` and `InventoryView` |

The session opens one profile and binds one command-enabled inventory at a time. Candidate ledgers are transaction previews. Outgoing bindings are sealed before the next scene publishes its inventory. No second spendable stash or item balance was introduced.

Application startup upgrades valid version-2 profiles to version 3 with an original-byte `.v2.bak`. Existing version-1 migration remains supported. Home metadata stores templates, contract/seed, settings and station availability; later upgrade/layout/display fields remain empty. Migration issues no replacement equipment. Unsupported future versions fail visibly rather than silently resetting the profile.

The durable `committed` and `running` attempt phases distinguish an unstarted refunded kit from a running deployment that must forfeit on recovery. Settlement and retries are idempotent. No mid-deployment resume is offered. **Development validation used isolated ignored profile paths; the real user profile was not opened or migrated.**

Concrete reliability corrections include canonical JSON normalization for fractional result durations, retaining live inventory when a settlement save fails, recomputing an uncommitted success preview if the player subsequently dies, rejecting inventory access during scene staging and preventing deferred UI callbacks after teardown. Loadout forms now fit smaller windows and typing an `i` in a template name does not close the panel. The spectator regression fixture now waits for bounded actor admission before inspecting its target.

## Files and scope

New code is grouped under `scripts/application`, `scripts/sanctuary`, application/preparation presentation scripts, and four gameplay definitions/services: `contract_definition`, `inventory_context`, `loadout_template` and `preparation_service`. New application and Sanctuary scenes are under `scenes/application` and `scenes/sanctuary`; contract resources are under `resources/contracts`. Three new suites cover the application lifecycle, preparation and physical Sanctuary interaction.

Fourteen existing runtime/config/test sources changed relative to the pre-AA manifest. The [exact reviewed hashes](../baselines/stage_aa_playable/reviewed_sources.json) identify those files. Changes connect session lifecycle, persistence, objectives, Recall, inventory context, home input/camera safeguards and relevant test fixtures. Existing source pins outside this set remain intact. Earlier inventory scroll work is preserved. Accepted environment geometry, actor art, weapon balance and AI policy were not changed by AA.

## Validation

Evidence and reproducible probes are archived in [the AA playable baseline](../baselines/stage_aa_playable/README.md). Parsing, launches, automated checks and director play-testing are separate evidence categories.

| Check | Result |
| --- | --- |
| Godot 4.7.2 editor import/parse | Passed; inspected output contains no errors or warnings |
| Active regression suites | **50 passed**, using the full run plus focused final reruns after corrections; completion output and assertions checked, not exit code alone |
| New application lifecycle coverage | Real scene roots, repeated raids, success, early extraction, death, failed save/retry, unstarted refund and death after failed success save |
| Preparation coverage | Template CRUD, non-reserving previews, shortages, explicit partial preparation, compatibility, weight/slots, identity-preserving recovery and failed-write atomicity |
| Sanctuary coverage | Physical movement/floor, E interaction, camera, home/Quick equivalence, typed names, blocked navigation and damage/fire rejection |
| Forward+ graphical interaction | Passed actual title/home/Quick controls, deployment confirmation, abandonment cancel, loot, Recall, results and return; screenshots include 1280 x 720 layouts |
| Natural app simulations | Both contracts at seeds 87017/87018, bounded to 160 simulation seconds each; autonomous activity, conservation and return verified |
| Manual director play-test | **Pending**; required before AA-6 |

Thirty-seven regression suites retain the previously observed shutdown cleanup warning. Verbose logs identify only `AudioStreamWAV` / `AudioStreamPlaybackWAV` leaked instances. These warnings are recorded separately from successful assertions; they are not a clean-shutdown claim. The native graphical check is clean.

The natural probe leaves the player passive and does not force encounters or actor outcomes. All four observations admitted five Raiders, reached at most two simultaneously active Raiders at the sampling points, continued after player destruction and ended with all five Raiders extracted. Material and equipment checks passed, and each run returned to Sanctuary. These observations verify lifecycle integration; they do not establish combat balance or varied player play styles.

| Contract | Seed | World duration, seconds | Natural player outcome | Raider extractions |
| --- | --- | --- | --- | --- |
| Asset Recovery | 87017 | 130.9 | Destroyed | 5 |
| Asset Recovery | 87018 | 141.1 | Destroyed | 5 |
| Salvage Complex | 87017 | 126.2 | Destroyed | 5 |
| Salvage Complex | 87018 | 137.0 | Destroyed | 5 |

The measured home frame contained 162 draw calls and 24,750 primitives, with 127 nodes. Five ordinary profile commits averaged **17.16 ms** on this machine (16.93–17.55 ms). These are scene/write samples, not an FPS benchmark or a large-profile performance guarantee.

## Director play-test checklist

1. Start normally. Test title Settings, Enter Sanctuary and Quick Deploy.
2. Walk around the safe room, zoom/rotate, use E at stations, Tab quick navigation and I storage. Check camera comfort and station readability.
3. Transfer equipment, equip a compatible robot weapon and verify scroll/selection retention. Keep a recovered Raider rifle as cargo; it should remain incompatible with robot mounts.
4. Create, rename, duplicate and delete templates. Preview shortages, exact preparation and explicitly confirmed partial preparation. Check that previews reserve nothing and actual preparation creates only one kit.
5. Select each contract and a seed. Confirm deployment readiness and verify movement/combat after arrival.
6. Recover finite loot, complete objectives and Recall. Read results, return home, verify banked inventory and deploy again.
7. Extract early with incomplete objectives; confirm cargo is banked while the result remains incomplete.
8. Open abandonment and Cancel; confirm gameplay resumes. Then confirm abandonment and verify carried cargo is forfeited once.
9. Die, continue spectating, switch targets where available and return. Confirm safe stash contents remain intact and the next mission starts fresh.
10. Restart the application between deployments and verify templates, settings, selected contract and persistent inventory. Report confusing controls, unexpected item changes or save errors.

## Remaining boundary

Stop here for director review. AA-6 disassembly/fabrication/upgrades, AA-7 furniture/displays, AA-8 atmosphere polish and AA-9 final handoff have not been implemented. The home is a functional early workshop using existing assets and primitives. Later station functions are visibly unavailable.

Synchronous profile commits and journal growth remain a large-stash performance concern. Current validation assumes one application process owns the profile. Final camera feel, visual quality and usability need director play-testing. None of these observations authorizes progression beyond the AA-5 gate.
