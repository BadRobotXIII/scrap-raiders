# SCRAP Raiders

Internal working title for an original comedic third-person PvE game. The player controls a machine protecting its technology from human scavengers.

Original phase ledgers, completion reports and the current acceptance history are collected in the [development records](docs/development/README.md).

Stages N and O are accepted. Stage P dynamic encounter generation is in [implementation-plan review](docs/development/plans/phase_5_stage_p_dynamic_encounter_plan.md), following the newly supplied ledger; gameplay implementation has not begun.

## Requirements and running

- Windows x64, Godot **4.7.2 Standard**, GDScript, Forward+ renderer.
- Vulkan-capable graphics device; no external assets, frameworks, services, or networking.
- Blender is installed according to the director; detailed models and animations remain outside this phase.

Open with `godot --editor --path .`, then F5. Standalone: `godot --path .`.

The default resizable window is **1600×900**. **F3** shows/hides the developer HUD, control banner and detailed spectator inspector; they start hidden. Mission information, combat feedback and interaction prompts remain visible. Spectator mode retains a small active-mode indicator when debug details are hidden.

The default `scenes/levels/mission_arena.tscn` runs **Intercept** in the expanded 48 m graybox. F6-F8 select the unarmed scenarios, F9 selects armed Survival, F10 selects Loot Pressure, **F12 selects Recall Deployment with extraction and persistent rewards**, **F4 selects Machine Ecosystem**, and **F2 selects Traversal Experiment**. Movement, shoulder camera, combat, flares, and loot presentation remain shared.

The original 32 m three-Raider arena remains available at `scenes/levels/test_arena.tscn` for Stage A/B regression checks.

For the original one-Raider/three-material regression scenario:

```powershell
godot --path . res://scenes/levels/single_raider_arena.tscn
```

The arenas share the same simulation code. The inherited single-Raider scene overrides Raider count and salvage-point count to one and sets `dynamic_ai = false`, preserving the original behavior and original exit. Stage A tests also explicitly disable dynamic AI. Restart preserves the selected scene/scenario and creates fresh runtime state.

| Control | Action |
| --- | --- |
| Physical WASD | Camera-relative movement |
| Space / Shift | Grounded jump / short boost in all test scenes |
| Mouse | Camera orbit |
| Hold RMB | Aim-facing |
| Hold LMB | Fire |
| E | Recover nearest eligible cargo |
| Escape / click | Release / capture mouse |
| R or Restart button | Restart after mission completion |
| F3 | Show/hide developer HUD, control banner and spectator inspection details |
| F1 (debug builds) | Toggle developer spectator camera; Tab inspect, F follow |
| F11 (debug builds) | Deploy Social Rivalry (Stage K) |
| Shift+F11 / Ctrl+F11 (debug builds) | Deploy Social Cooperation / Social Pressure (Stage L) |
| Alt+F11 (debug builds) | Deploy Opportunistic Betrayal (Stage M) |
| F6 / F7 / F8 | Deploy Intercept / Swarm / Recovery in the expanded arena |
| F9 | Deploy armed Survival (Stage E) |
| F10 | Deploy Loot Pressure (Stage F); hold E for equipment |
| F12 | Deploy Recall Deployment (Stage G); hold E at the Recall Dock for five seconds |
| F4 | Deploy Machine Ecosystem (Stage H); scout and guard support with recall |
| F5 | Deploy Integrated Extraction (Stage N); combined mission with persistent recall rewards |
| F2 | Deploy Traversal Experiment (Stage I); Space jumps, Shift boosts |

Escape releases controls without pausing simulation. Losing application focus also releases the cursor.

## Stage N integrated extraction mission

Press **F5** in the running game, or launch:

```powershell
godot --path . res://scenes/levels/integrated_extraction_arena.tscn
```

This separate preset combines the accepted systems in the existing expanded graybox. The default main scene remains Intercept; earlier test scenarios retain their configurations. The robot deploys at the Recall Dock. Three Raiders enter at validated, seeded original spawn markers with Greedy, Cowardly and Aggressive profiles. R1/R2 are explicitly allied; R3 is hostile to both. Only R1 can initiate opportunistic betrayal if existing conditions occur naturally. There is no forced betrayal, guaranteed fight winner or new squad coordination.

Armed combat, local allied reports, contested cargo, Raider material looting, death flares, at most two responders, scout/guard support, jump/boost and persistent recall rewards are enabled together. Responders use the existing authored alliance/rival policy, without resetting a betrayed pair's hostility. There are **nine salvage units plus two installed machine components (eleven total material units)**; equipment is accounted separately. Seed 85017, 180-second deadline, normal five-second recall and existing movement/combat tuning are retained.

Intercept scavengers, recover dropped materials with E and hold E to loot equipment. Support-machine destruction releases its already allocated component. Original salvage remains a Raider scavenging source; direct player harvesting is not introduced. Return to the dock and hold E to extract, banking deployment cargo into the existing local stash. Incoming nonlethal damage does not reset recall; movement, firing, jump/boost, release or loss of eligibility still cancel it. Material pickup takes priority over equipment recovery, and nearby loot takes priority over recall.

Resolving every Raider **does not end this mission**. Continue recovering loot or choose recall until the deadline. Extraction is allowed with hostiles and pending responses, including an empty-cargo extraction. Robot destruction or timeout forfeits deployment cargo while preserving prior stash contents. Ground cargo remains unrecovered, and actual Raider extraction remains Lost. No new mission outcome policy or material authority is added.

F1 spectator and F3 diagnostics remain available in debug builds. The [Stage N report](docs/development/reports/stage_n_integrated_extraction.md) records validation and the Checkpoint N play-test checklist. Real play uses the existing persistent stash; integration tests use isolated saves under ignored `.godot/stage_n_tests/`.

## Stage O post-death spectating

In **F5 Integrated Extraction**, robot destruction immediately fails the player deployment and forfeits carried loot once, but autonomous activity continues. Choose **Spectate** to follow surviving Raiders and machines, or **Return** to end the local world and open the existing failure summary/restart option. The world also continues while the choice is open. Earlier presets retain immediate terminal shutdown.

The follow view prefers the surviving Raider responsible for the lethal hit, otherwise falls back to registered living Raiders and then support machines. **Tab / Shift+Tab** cycles targets. **Hold RMB and move the mouse** to orbit with pitch limits; releasing RMB restores the cursor. A SpringArm3D shortens the camera against geometry. **Escape or Return** ends observation. Target death/extraction automatically selects another eligible actor; a temporary empty list waits for pending arrivals.

Normal post-death spectating has no free-flight controls, AI inspector, firing, pickup, recall or actor control. It reuses the developer spectator's shared camera rig with separate permissions. F1 cannot re-enable developer mode after death. The dead robot's HUD is hidden while following. Restart restores normal player controls and fresh deployment state.

Raiders, machines, social observations, combat, looting, component drops, finite responses and Raider extraction keep using their existing state owners and ledgers. Player forfeiture is irreversible; spectating cannot earn rewards or modify the prior stash. World totals may change through autonomous activity and are labelled separately from the death time in the final failure summary. Observation ends at the original deployment deadline, Return, or when no living actors and no pending entries/responses remain. Surviving patrol machines keep the world observable until the deadline or Return; leftover ground loot alone does not.

See the [Stage O report](docs/development/reports/stage_o_post_death_spectating.md) for validation and manual review items. Post-death follow is composed independently of debug-build guards; an exported release package has not been exercised.

## Stage J developer spectator camera

Available in editor/debug builds only. **F1** toggles the camera; F9 retains its existing Survival preset assignment. WASD moves horizontally relative to camera yaw, mouse rotates freely beyond the player pitch limits, Space ascends, Ctrl descends, and Shift accelerates movement. The camera has no physics body, collision or gravity, so it can pass through walls and terrain. Exported properties on the runtime `DeveloperSpectator` node configure base speed (10 m/s), acceleration multiplier (4x) and mouse sensitivity. Escape releases the cursor; click recaptures it. Exiting restores the previous mouse mode and unchanged player camera orbit. Losing focus releases the cursor.

The robot remains at its existing position, physically targetable and vulnerable. Spectator mode gates gameplay input and firing; its position is never supplied to perception, targeting, navigation or interaction. The robot controller retains velocity ownership and holds movement while spectating. Existing boost is cancelled through normal input clearing, and traversal timers are held while movement is locked. Exiting resumes normal movement; entering while airborne holds the robot there until exit, after which gravity resumes. No invulnerability option is included.

AI, physics, entries, mission time, loot, combat and accounting continue normally. Deadlines and robot destruction leave developer spectator mode, restore the player view, release the cursor and keep gameplay disabled. Stage O adds the separate Spectate/Return flow after destruction in Integrated Extraction; older presets retain immediate terminal shutdown. Restart/scenario replacement creates a fresh inactive spectator and normal controls. Existing held interaction channels cancel through cleared input; no spectator interactions or material transfers are added.

While active, a debug indicator shows controls and warns that the robot remains vulnerable. **Tab** cycles living entered Raiders; **F** follows the selected Raider by translating only the camera. Mouse look and free movement remain available during follow. The inspector shows the selected Raider's profile, state, target, salvage, exit, cargo and navigation status. Follow clears when that Raider dies, extracts or disappears. **F3** retains the existing developer overlay. Stage J itself does not introduce social behavior; Stage K adds relationship inspection in its separate preset below. Presets without a relationship service retain the `not implemented` message.

`scripts/debug/developer_spectator.gd` owns the free camera, selection/follow and debug input routing. Arena composition creates it only when `OS.is_debug_build()` is true, and the tool also guards activation and input. Release gameplay does not instantiate this tool; an exported release build has not been independently validated in this checkpoint.

## Stage K social rivalry

Press **F11** in a debug build, or launch `godot --path . res://scenes/levels/social_rivalry_arena.tscn`. Three armed Raiders enter immediately around the southern open area, with nine total materials, a 180-second deadline and seed 81017. R1 and R2 are explicitly allied; R3 is hostile to both. All have **no squad assignment**. The robot starts at a distant southwest position and remains vulnerable. Flares, support machines and persistence are disabled in this preset. Jump and boost are available, as in the other test scenes. Use F1/Tab/F to observe and inspect the fight, and restart to replay. Every previous preset retains its accepted relationship/damage behavior.

`RaiderRelations` owns symmetric explicit ALLIED/NEUTRAL/HOSTILE pair attitudes, defaulting unspecified pairs to neutral. It validates active IDs, records transition reasons and seals at mission end. Attitude, salvage competition and optional squad metadata are separate: neutral or allied Raiders can target the same finite stock, each carries its own cargo, and no squad is needed to ally against a common machine threat. There is no cargo sharing, exclusive salvage entitlement, permanent squad controller or automatic alliance derived from squad metadata.

Hostile humans become eligible targets through the existing Raider FSM, sensing, aim warning, cover and retreat. Selection uses distance and current-target preference. Ally and neutral bodies block bullets without taking human friendly damage; physical layers alone do not decide social hostility. The shared ShotExecutor uses an optional eligibility callback and records accepted damage's instigator instance ID alongside its origin through Health. Previous callers remain compatible. Destroyed/ineligible targets cannot be fired upon; target changes restart aim timing. Raider death still follows normal ledger-backed cargo drops, and material conservation remains unchanged.

Spectator/F3 inspection shows actual pair attitudes and reasons, separate squad metadata, current target/selection reason and last damage instigator. Stage K does not implement shared allied observations, commanded cooperation, dynamic alliance formation, betrayal or Raider looting of death cargo. Those remain proposed L/M scope. Pair attitudes are symmetric in this first version; asymmetric opinions are not modeled.

## Stage L cooperation and contested cargo

**Shift+F11** selects Social Cooperation, and **Ctrl+F11** selects Social Pressure. Direct scenes are `social_cooperation_arena.tscn` and `social_pressure_arena.tscn` under `scenes/levels/`. Both keep three initial Raiders, nine total materials, the explicit R1/R2 alliance, R3 rivalry, no squad assignments, normal jump/boost and a 180-second deadline. Plain F11 retains Stage K. Every earlier preset retains its accepted settings.

Per-Raider `RaiderSocial` components observe on the existing 0.15-second decision interval. Allies within 15 m receive three-second last-known hostile snapshots. Only a fresh direct sighting can publish; receivers cannot relay unseen reports. Communication uses radius rather than simulated radio obstruction. Each recipient independently decides through the common FSM: active combat, retreat, low health, damage/gunfire response and full cargo retain priority. Reports do not grant line of sight, aim or live target tracking. Repeated stationary reports preserve the current investigation timer, and expired/dead/no-longer-allied sources are discarded. Machine-faction awareness remains separate.

Raiders discover material drops within 12 m and unobstructed sight, remembering stationary drop identity/position for three seconds without renewed sight. Known drops participate in normal reachable objective scoring, contention costs and navigation fallback. Collection requires the registered world view, matching ledger, active live Raider, range below 0.8 m, completed scavenging time, remaining capacity and current unobstructed reach. Partial collections leave the remaining finite allocation; the player and other Raiders can contest it. Only MaterialLedger transfers quantities. Cargo is carried until normal death or extraction; it becomes Lost only on actual Raider extraction. Raiders still do not loot equipment cases, equip weapons, trade or share cargo.

Social Pressure enables existing death flares and their finite two-responder budget, active cap, delays and retry policy. Tickets snapshot explicit authored relations: responders ally with surviving R1/R2, oppose surviving R3 and ally with other responders. These are encounter rules, not inherited squad membership or knowledge of a killer. Blocked entries wait; a responder's death cannot replenish the budget or create materials. Equipment remains under its existing ledger/player-recovery rules.

Use F1/Tab/F and F3 to inspect source, report counts/expiry, remembered drops, relations and objectives. Empty Raiders still drop no material cargo: observe or intercept after scavenging to review contested material recovery. Investigation, source expiry, loot discovery and all transfers are covered by the [Stage L report](docs/development/reports/stage_l_social_cooperation.md).

## Stage M opportunistic betrayal

**Alt+F11** selects Opportunistic Betrayal, or launch `godot --path . res://scenes/levels/social_betrayal_arena.tscn`. Three armed Raiders initially have explicit mutual alliances and no squad assignment. Only R1 is an opportunist. Nine materials remain at the three ordinary salvage points; seed 84017 and authored per-Raider entry markers make the initial opportunity reproducible. R2 naturally scavenges before R1 reaches it. The robot begins away from the encounter, remains vulnerable and supports normal jump/boost. Flares, support machines and persistence are disabled in this preset.

The independent `RaiderBetrayal` component requests an assessment through the common Raider FSM. A visible ally must carry at least three materials and more than the opportunist, remain within 8 m, and stay visible for two continuous seconds. The opportunist needs more than 50% health, available cargo capacity, and no visible machine/rival threat, active combat or retreat. Interruption resets the timer. An orange **EYEING Rxx CARGO** countdown precedes the relation change; the usual rifle aim warning follows it. Movement remains owned by CharacterBody3D. `RaiderBetrayalProfile` configures eligibility separately from existing personality resources.

At most one accepted betrayal may be initiated per opportunist per deployment. Only that pair becomes hostile, with a recorded reason and time; other alliances remain unchanged. Combat, retaliation, cover, retreat, death drops and timed loot collection use existing systems. Changing a relation cannot transfer or create materials, and no winner or reward is guaranteed. Neutral salvage competition alone never triggers betrayal. F1/Tab/F and F3 show the assessment, reason and spent flag. Restart restores the authored alliances and unspent opportunity. See the [Checkpoint M report](docs/development/reports/stage_m_opportunistic_betrayal.md).

Optional `MissionConfig.preferred_entries` pins IDs to validated entry markers for this encounter; a blocked marker retries rather than relocating its actor. `player_start_marker` selects its distant robot start. Existing presets retain their seeded entry selection and settings.

## Stage A scope and configuration

Stage A implements multiple independent Raiders, finite shared salvage, aggregate accounting, and multiple recoverable drops. Stage B adds dynamic AI. Stage C adds the expanded arena, scheduled entries, and mission presets below. Stage E adds armed combat in a separate Survival preset; multiplayer remains outside scope.

Arena Inspector parameters:

- `raider_count`: 1–5, default 3.
- `salvage_point_count`: 1–3, default 3.
- `materials_per_point`: default 3; total material stock is derived from enabled points.
- `mission_duration`: default 180 seconds.
- `pickup_distance`: default 1.8 m.
- `dynamic_ai`: true by default; false retains Stage A selection/behavior and the original exit.
- `debug_seed`: default 4711; controls deterministic local score tie-breaks, without changing global random state or spawning.

Five authored spawn markers live under `RaiderSpawns`. All configured Raiders enter immediately. Spawns are checked against geometry, actors, and already selected positions. Invalid deployment stops with an explicit setup error. No automatic teleport is used.

With dynamic AI disabled, salvage assignment is stable and cyclic by Raider ID and each Raider collects once. A point is not reserved: the first validated collection request transfers available stock atomically. A competing Raider cannot duplicate it; it selects another available point or heads for extraction if none remain. Dynamic AI instead uses scored selection and a profile cargo target; repeated collections debit finite stock only up to the remaining target capacity.

## Stage B dynamic AI

Three shared resources in `resources/enemies/` parameterize one common FSM:

| Profile | Visible threat range / flee distance | Cargo target | Behavior |
| --- | --- | --- | --- |
| Greedy (gold body) | 8 m / 3 m | 6 | Tolerates distant danger and seeks additional finite salvage |
| Cowardly (blue body) | 12 m / 12 m | 3 | Retreats early and strongly penalizes dangerous routes |
| Aggressive (red body) | 10 m / 3 m | 3 | Investigates a last-seen position for up to two seconds before resuming objectives |

In the unarmed scenarios, damage interrupts the current task and causes flight; lethal damage remains terminal. An empty/under-target fleeing Raider can resume scavenging after three seconds without visible danger (damage adds two seconds of memory). Raiders at their cargo target continue extraction. Threats still use line of sight; only observed or damage-revealed threat positions influence route risk. Armed Survival uses the combat behavior below.

Aggressive investigates once per observed threat position, then resumes objectives while the robot remains stationary. Investigation re-arms after the robot moves at least 2 m from that position, or after lost visibility outlasts threat memory. Its investigation standoff includes an arrival margin outside the close-threat flee distance; close approaches and damage still cause retreat.

The common FSM adds SELECTING, INVESTIGATING, and STRANDED to the existing states. Raider-specific state, timers, failed objectives, and sensor memory remain per instance. Profile resources are shared read-only definitions. `HitReaction`, death tumbles, weapon damage/cooldown, recovery, and mission outcome policy retain their existing ownership.

Objective scoring uses actual reachable navigation paths, path length, remaining stock, other Raiders targeting the location, known route danger, and a small seeded tie-break. Exit scoring uses reachable path length and known danger weighted by profile. Off-map/disconnected destinations are rejected. Decisions wait for usable navigation geometry, not merely a nonzero map iteration. Seeded scores reproduce choices for the same state; this does not promise bitwise deterministic physics.

Navigation watches physical progress at 1.5-second intervals while travelling. No progress first requests a repath; a repeated stall excludes that objective and selects an alternate salvage point or exit. If no exit is available, the Raider enters STRANDED with an explicit label and retries after two seconds. Failed-route exclusions are cleared on that retry so temporary obstructions can recover. The Raider remains unresolved with its exact cargo allocation until it escapes, dies, or the mission deadline ends deployment. There is no teleport or artificial extraction. The watchdog interval is configurable per Raider; these are simple recovery rules, not dynamic crowd avoidance.

F3 diagnostics include seed, personality, state, salvage, destination, cargo, threat source/visibility/memory, navigation status, and material conservation. Gameplay labels show profile names and brief actions separately. Stage D adds the gunfire reactions below.

Legacy behavior detects the robot within 8 m with line of sight and commits to the original exit when threatened. Both modes retain three-second scavenging/extraction dwell times and independent state, navigation, velocity, health, task timer, and objective per Raider. IDs appear in labels and transition logs.

## Stage C arena and mission variety

`mission_arena.tscn` inherits the existing arena and adds a 48 m floor/boundary, separated routes around tall sight blockers, low cover near an open central/southern area, a narrower west-central passage, and a raised east-side lookout reached by a shallow ramp. Ramp guards prevent navigation shortcuts up edges that CharacterBody movement cannot step over. All enabled salvage, spawn and exit locations are connected by the baked navigation mesh. The original arenas retain their geometry and immediate-entry behavior.

Three shared `MissionConfig` resources under `resources/missions/` define quantities, duration, ordered entry times, allowed spawn marker names, available exits, seed, and starting ground cargo:

| Scenario / key | Raiders / entry times (seconds) | Protected / initial ground | Deadline | Exits |
| --- | --- | --- | --- | --- |
| Intercept / F6 | 3 / 0, 4, 8 | 9 / 0 | 180 s | Both |
| Swarm / F7 | 5 / 0, 0, 2, 4, 6 | 15 / 0 | 180 s | Both |
| Recovery / F8 | 2 / 8, 16 | 6 / 6 (three stacks of two) | 150 s | B only |

F6/F7/F8 replace the current deployment immediately, including after its summary. This is a debug selector: switching discards that run, and R restarts the selected scenario. There is no saved progression or menu framework. The scene's `scenario_index` Inspector property chooses its initial preset; edit the mission resource to tune that preset. All presets use the same Raider profiles and mission outcome rules.

The mission arena owns pending entry IDs and the schedule. Every scheduled Raider is registered in the ledger at setup, so unresolved counts include pending entries and early kills cannot complete the deployment before later entries. F3 shows pending IDs and entry/retry status; the gameplay HUD shows pending count separately. The deadline stops entry, preserves all material categories, and reports Raiders that never entered.

Each mission seed shuffles the authored marker order with a local RNG. Each due Raider tries that stable order with an ID offset; blocked markers fall back to another valid candidate. Entry validation checks the capsule against geometry/actors, same-tick actor positions, supported ground, navigation proximity, and paths to enabled salvage and an enabled exit. A completely blocked entry stays pending and retries every 0.5 s until clear or the deadline. Entries never teleport, mint materials, or silently count as extracted. Identical seeds and world state reproduce entry choices; player obstruction and physics can change actual admission timing.

Recovery's initial ground allocations are part of the ledger's initial total, with source ID zero (mission stock). Physical cubes are only views of those allocations. Later death drops receive IDs beyond the initial stacks. Existing E eligibility, prompts, accounting, recovery-only phase, and deadline distinctions apply unchanged.

## Stage D awareness and readability

The arena forwards the existing weapon `fired` event to entered, living Raiders while deployment is active. Accepted hits and misses both produce gunfire awareness; cooldown-rejected triggers produce no event. Weapon damage, cadence, health, and material accounting retain their original owners.

Hearing uses distance to the shot's muzzle origin: Greedy 12 m, Cowardly 18 m, Aggressive 16 m. This deliberately simple radius rule allows hearing through cover without sound propagation or impact/near-miss simulation. An unseen shot records a last-known source and refreshes three-second threat memory; it never grants sight or tracks subsequent unseen player movement.

Cowardly retreats from audible shots, Greedy continues scavenging unless the source is within its close-threat distance, and under-target Aggressive can investigate the heard source. Existing close-range and damage retreat take priority. Stationary repeated shots retain the investigation re-arm guard; they refresh memory without restarting an active retreat or extraction task. Empty fleeing Raiders can resume scavenging after memory expires. Loaded Raiders continue toward extraction, and unreachable investigation routes retain the existing watchdog fallback. The inherited single-Raider regression mode keeps its original behavior.

World feedback reads simulation state: `?` marks investigation and `!` marks alertness; `GUNFIRE` identifies an audible source. Indicators clear with threat memory and stop at mission completion. Loaded backpacks become gold with a subtle emission; empty packs stay dark. Depleted salvage hides its crate and displays `DEPLETED`. Existing nearest-drop highlight and E eligibility remain shared. `raider_feedback.gd` owns presentation only and cannot advance task clocks, change health, or transfer cargo. Detailed state and threat diagnostics remain behind F3.

## Phase 3, Stage E hostile combat

Launch with F9, or directly with `godot --path . res://scenes/levels/survival_arena.tscn`. Survival uses three armed scavengers entering at 0/5/10 seconds, nine materials, both exits, a 180-second deadline, and seed 32017. The three original presets remain unarmed. This checkpoint uses their existing mission completion policy; player extraction and persistent rewards are Stage G work.

Player hull starts at 100. `Health` remains the sole writer of current health and records the accepted impact origin. A separate player HUD shows hull, a brief red border and directional indicator, and an original synthesized impact tone. Destruction creates a cosmetic tumble, hides the robot visuals, and reports explicit deployment failure. Controls, player and enemy weapons, pending entry, and transfers stop. Restart resets health, outcomes, cover reservations, random streams, and the ledger while preserving scenario selection.

`ShotExecutor` owns cooldown, range clamping, muzzle obstruction, accepted damage, and the existing shot event for both sides. `HitscanWeapon` adapts the player's camera aim/input to it. Enemy intent comes from `RaiderCombat`, with no camera or player-input dependency. Environment and other Raiders block hostile shots; friendly Raiders take no damage from those shots. Cosmetic tracers and rifle audio live in `RaiderFeedback`.

The initial combat resource uses 10 damage, 0.8-second shot interval, 24 m physical range, 18 m engagement range, 2-degree seeded aim spread, and a 0.65-second visible aim warning. Each actor has its own RNG and shot cooldown. Visibility and engagement range are checked again immediately before firing. Losing sight or changing combat state resets the warning. Armed scavengers engage visible threats, return to salvage when danger is forgotten, seek cover after damage, and retreat at or below 30% health. Their existing personality resource still controls noncombat decisions.

The common Raider FSM adds ENGAGING, TAKING_COVER, and REPOSITIONING. `RaiderCombat` supplies decisions and aim timing through that FSM; CharacterBody3D retains movement/velocity. Authored cover slots include a protected position and peek position. The arena validates cover against the last-known threat, clear peek sightlines, navigation reachability, and exclusive actor reservations. Cover dwell is one second, followed by physical movement to the peek position and a fresh warning. Fighters also attempt repositioning after three seconds of engagement. Reservations are released on disengagement, retreat, death, extraction, or mission shutdown. No valid cover falls back to investigation or retreat; stalled cover routes use the existing navigation watchdog. This is basic squad coordination through cover allocation, with no shared movement controller or tactical squad framework.

Player destruction is a distinct mission reason, separate from deadline expiration and Raider material outcomes. At this temporary Stage E boundary, **all material categories are preserved exactly and sealed**: protected, carried, ground, recovered, and extracted/lost. Death does not relabel cargo as extracted loss or create persistent inventory consequences. Stage F adds flare/equipment pressure in a separate preset below. Player extraction and persistence remain Stage G work.

## Phase 3, Stage F death flares and loot pressure

Use **F10**, or `godot --path . res://scenes/levels/loot_pressure_arena.tscn`. This preset has three armed Raiders entering immediately, nine materials, two exits, seed 41017, and a 180-second deadline. F6-F9 retain their accepted behavior. Restart preserves the selected preset and resets every response, item allocation, world drop, and flare.

Every accepted Raider death in Loot Pressure launches exactly one original primitive flare with a rising tone. It climbs for 0.8 seconds and lingers for 20 seconds. It also drops equipment even when the Raider carried no mission material. Survivors do not launch flares voluntarily. Dead responders still produce flares and low-value loot.

`death_flare_rules.tres` configures a 20 m alert radius, two-second local response delay, eight-second reinforcement delay, two additional Raiders per deployment, five living Raiders maximum, and 1.5-second equipment hold time. Each death snapshots nearby existing actors for delayed notification. Their own FSM can investigate the death location, while active combat, retreat, low health, and loaded extraction retain priority. A flare does not reveal subsequent unseen player movement.

The first two deaths each commit at most one reinforcement ticket. Local notifications are processed before reinforcement admission; reinforcement delay is constrained to exceed local delay. Due tickets use the existing seeded marker order, collision/support checks, and reachable routes to salvage, exits, and the flare. Blocked entries and the active cap defer admission with no teleport. Tickets retry every 0.5 seconds until admitted or deployment ends. Responder deaths cannot replenish the budget, so response chains are finite. F3 shows local jobs, pending tickets, budget use, and ownership validity.

`EquipmentLedger` is the sole writer of equipment ownership. Every item receives a unique deployment-local identity and exactly one location: Raider-carried, ground, recovered, or extracted. Ordinary loadouts contain a rifle (prototype value 4) and electronics kit (2); a responder carries a worn rifle (1). These values describe relative loot desirability, with no currency, equipping, sale, or persistent progression yet. Only admitted actors receive allocations. Physical purple cases are read-only views; duplicate death/recovery, unknown ownership, and transfers after sealing are rejected. Ownership validity is checked after every accepted allocation or transfer.

Material accounting stays separate: reinforcing actor registration adds zero cargo and cannot increase the finite material total. Cyan material stacks retain immediate E recovery. An eligible cyan stack takes priority; holding E then recovers nearby equipment once it is cleared. The nearest eligible purple case highlights and uses the same identity, distance, and unobstructed-access check as hold completion. Releasing E, movement input, moving more than 0.25 m, firing, losing access, changing target, or receiving damage cancels equipment progress. Cursor/focus handling clears held intent through `RobotInput`.

Committed tickets keep the hunt active even when no current Raider survives. With all Raiders resolved and no tickets, either ground materials or equipment enter recovery-only. Once both are recovered, existing success/extraction-loss policy applies; untouched salvage does not block completion. Death and the deadline stop response/interaction work and seal both ledgers, retaining all categories. Summaries distinguish equipment carried, ground, recovered, and extracted separately from mission materials. Leaving the flare area is always allowed; no stationary-defense objective or persistent inventory is introduced.

## Phase 3, Stage G Recall Dock and persistent stash

Use **F12**, or `godot --path . res://scenes/levels/extraction_arena.tscn`. Recall Deployment uses three armed Raiders entering at 0/5/10 seconds, nine materials, both Raider exits, death flares, seed 51017, and a 180-second deadline. F6-F10 keep their accepted completion/recovery rules and do not write stash rewards.

The blue Recall Dock is at the southern edge near the robot's initial position, distinct from the green Raider exits. Within 2 m and with unobstructed access, hold E while stationary for five seconds. Releasing E, movement input, residual movement, displacement over 0.25 m, firing, or leaving range cancels the channel. **Nonlethal hits do not interrupt recall:** the player decides whether to hold on under fire. Destruction and the deadline still end deployment before an unfinished recall can succeed. Eligible loot retains E priority before recall. Extraction remains available with Raiders and reinforcement tickets active, so retreating with partial loot is valid. Resolving all Raiders or collecting every drop alone does not end this preset; the player must recall before the deadline.

Recovered materials and equipment are deployment cargo until recall. Successful extraction first saves one identified reward receipt, then moves that deployment's recovered allocations into BANKED records and stops simulation. Those sealed records describe the deployment outcome; the stash owns the persistent inventory. Repeating the same receipt cannot credit twice, and a changed reward for that receipt is rejected. Player destruction and deadline expiration instead move only recovered/player-carried allocations into FORFEITED records. Ground loot, protected stock, Raider cargo, and actual Raider extraction losses keep their original meanings. Previously banked inventory is unchanged by a failed deployment. Summaries explicitly distinguish successful recall, destruction, expiration, banking, and forfeiture.

The local stash lives at **`user://stash.json`** in Godot's application user-data directory, with `.bak` and `.tmp` siblings. A versioned JSON schema stores materials, identified equipment, and deployment receipts; the on-screen stash display shows totals and item counts. A fresh missing stash loads empty without writing a file. Saves validate the reward, write/flush a temporary file, verify its contents, preserve the previous validated primary as backup, and replace the primary with a same-directory rename. A corrupt primary can load the previous valid backup; this is recovery to the previous snapshot, not reconstruction of damaged data. Invalid saves with no usable backup and unsupported versions are preserved and block reward saving. Orphan temporary files grant no rewards.

If saving fails, recall reports the error and leaves the deployment and cargo active for retry; it does not claim extraction or bank loot. The save and settlement path is synchronous within one game instance, with no multiplayer/shared-file writer coordination. Restart and scenario selection reset deployment state and create a new receipt identity while retaining the stash. Crafting, equipping saved items, stash spending, deployment loadouts, and support machines remain outside this checkpoint.

## Ownership and material conservation

`MaterialLedger` is the sole writer of all material quantities and locations:

```text
Protected + Carried + Ground + Recovered + Lost + Banked + Forfeited = Total Mission Materials
```

- Protected: remaining stock indexed by salvage location ID.
- Carried: stock indexed by registered Raider ID.
- Ground: stacks indexed by unique mission-local drop ID, retaining their source Raider ID.
- Recovered: mission inventory credited by accepted recovery transfers; at-risk deployment cargo in Recall Deployment.
- Lost: materials that actually left through Raider extraction.
- Banked: this deployment's material outflow through successful player extraction; zero in legacy presets.
- Forfeited: player cargo lost through destruction/expiration; distinct from Raider extraction and zero in legacy presets.

The ledger derives aggregate totals from its records and validates nonnegative quantities and conservation after **every accepted transfer**, including empty death/extraction resolution. Validation executes in release builds too; debug assertions add diagnostics. Unknown IDs, duplicate resolutions/recovery, depleted stock, and transfers after the ledger is sealed are rejected without mutation.

Raiders request collection and report death/extraction. They read cargo from the ledger; they cannot mint cargo. The arena validates the requesting actor, state, timing, and location before requesting a collection transfer. On death it asks the ledger to move that Raider's cargo into a new drop allocation, then creates its physical representation. Empty deaths create no drop.

`MaterialDrop` only exposes its ledger stack and renders its highlight/label. It cannot independently consume, create, or credit materials. Recovery credits the ledger once and removes that physical stack. Duplicate/stale drop IDs retain no recoverable quantity.

The same eligibility function drives candidate selection, highlight, prompt, and pickup: active mission, registered drop identity, positive ledger allocation, distance, and unobstructed access. Choose the nearest eligible stack; equal distances within a small numerical tolerance break by lower drop ID. Only that stack highlights. Mouse capture governs physical input; eligibility remains a spatial/gameplay rule. Recovering cargo is allowed while other Raiders are active.

## Mission outcome policy

`MissionRules` is separate from the ledger. It reads material totals and the number of unresolved Raiders; it never transfers materials.

The following table describes F6-F10; F10 also counts pending reinforcement tickets and ground equipment. F12 requires explicit player extraction and applies the Stage G outcome/settlement rules above.

| Condition | Outcome |
| --- | --- |
| Any Raider remains active | HUNTING: intercept and recover simultaneously |
| All Raiders resolved, ground cargo remains | RECOVERING: player retains controls until recovery or deadline |
| All Raiders resolved, no ground cargo, no extraction loss | SUCCEEDED |
| All Raiders resolved, no ground cargo, extraction loss exists | FAILED |
| Deployment deadline expires | FAILED; preserve every material category as it stands |

Materials still protected at their original salvage points **do not block completion**. One death/extraction cannot end the other Raiders' simulation. An early extraction loss is recorded immediately, but the mission remains playable while other Raiders or ground cargo remain.

At the deadline, ground cargo remains **unrecovered**, not extracted/lost. Still-Raider-carried cargo remains carried. The summary reports material categories separately; F12 additionally settles player cargo as forfeited. Terminal completion seals transfers, stops all live actors and player combat/movement input, releases the cursor, and shows the restart control. Cosmetic cleanup can continue. Restart creates fresh deployment ledgers, actors, drops, timers, and outcomes; Stage G's persistent stash survives separately, without a global mission singleton.

## Stage H machine ecosystem

F4 or `godot --path . res://scenes/levels/ecosystem_arena.tscn` deploys three armed Raiders at 0/4/8 seconds, one blue flying scout and one green ground guard. The 180-second mission includes existing flares, equipment, recall and persistent rewards. Original scenarios keep their existing configurations.

Each support machine owns its health, state, movement and destruction. The scout has 50 hull, patrols authored aerial waypoints at 2.5 m/s, and observes Raiders within 20 m with physical line of sight. The ground guard has 80 hull, follows navigation at 2.5 m/s, detects within 12 m and engages within 10 m. Its defensive pulse deals 5 damage every 1.2 seconds after a 0.5-second aim warning; green tracers show actual shots. Cover blocks shots, and allied machines block guard fire without taking damage. Support machines have cosmetic death tumbles and do not launch human death flares. They remain expendable and cannot replace player combat.

Sensors scan every 0.25 seconds. The mission-local awareness board stores each source's latest position snapshot for three seconds, removes a destroyed source's report, and returns detached observations. The guard independently investigates reported positions when it cannot engage a visible Raider. Player warnings expire with their reports. Shared awareness never controls another actor's movement or tracks an unseen Raider's live position.

Armed Raiders use the existing common FSM, cover logic and shot executor to hunt visible eligible machines. They choose the nearest visible machine, with a 30% distance-score preference for their current target to limit switching. Switching restarts the aim warning. Destroyed targets are discarded safely, and all firing still requires fresh visibility. F3 shows each Raider's current target.

The ecosystem ledger starts with **11 total materials: nine salvage plus one installed component per support machine**. Installed components count as protected stock until destruction transfers them to an identified ground stack. No actor or loot mesh creates materials. Raiders score component drops alongside salvage and collect through validated scavenging requests; their death drops or extraction retain normal ledger accounting. Players recover components with E and bank them through recall as ordinary materials; there is no separate crafting currency. Every accepted transfer checks conservation. Surviving installed components do not block completion, and terminal deployment stops support movement and fire.

## Stage I traversal experiment

Press **F2**, or launch `godot --path . res://scenes/levels/traversal_arena.tscn`, for the dedicated traversal test preset with armed recall, scheduled Raiders, flares and loot. Following director feedback after Stage K, **jump and boost now default to enabled in all nine mission presets and both original arena scenes**. F2 is no longer required to use them. Restart and preset switching preserve traversal availability. The controller option can still explicitly disable traversal for a custom fixture; the mission resource retains its historical `experimental_traversal` property name, now defaulting to true.

- **Space:** a grounded jump with approximately 1.5 m apex above the starting floor. Requests in midair are discarded; holding Space does not repeat jumps.
- **Shift:** a 0.25-second horizontal burst at 16 m/s, followed by a 1.5-second cooldown. WASD determines its camera-relative direction; without WASD it uses camera forward. Diagonal input has the same speed. The chosen direction stays fixed during the burst while the camera remains free to orbit. Boost works on the ground or in the air and preserves gravity/jump velocity. Normal acceleration/braking resumes when the burst ends. Holding Shift does not automatically repeat boosts.
- The lower-left HUD shows ready, boosting and remaining recharge time. Jump and boost retain normal aiming/firing, collision and camera spring-arm behavior. There is no teleport, invulnerability or boost damage.
- Releasing the mouse or losing focus clears pending requests and cancels an active boost into cooldown. Existing movement braking and gravity continue. Jumping, airborne movement and boosting prevent recall; nonlethal incoming damage still permits recall as accepted in Stage G. Terminal mission shutdown stops traversal and clears velocity.

`RobotInput` produces requests; `RobotController` consumes them in physics and is the only writer of physical velocity and boost state/timer. The camera owns orbit and aim direction independently. `traversal_feedback.gd` only reads controller state; shared arena composition adds one HUD in each enabled scene and hides it during spectator mode or terminal shutdown. There is no new chassis, attack, upgrade economy or persistent movement unlock. Tuning lives in the controller's exported jump height, boost speed, duration and cooldown.

## Code boundaries

- `scripts/gameplay/material_ledger.gd`: authoritative material transfers, identity, actor resolution, invariants.
- `scripts/gameplay/mission_rules.gd`: mission phase and outcome policy.
- `scripts/gameplay/raider_arena.gd`: composition, registration, event validation, spawn validation, interaction, and HUD/summary wiring.
- `scripts/gameplay/mission_arena.gd`: Stage C entry scheduling, admission validation, and debug scenario selection using shared arena composition.
- `scripts/gameplay/mission_config.gd`, `resources/missions/`: mission definitions, with no mutable runtime mission state.
- `scripts/ai/raider.gd`: common per-instance state machine and physical movement using NavigationAgent3D.
- `scripts/gameplay/material_drop.gd`: ledger-backed world presentation.
- `scripts/player/`: input, CharacterBody3D movement, independent camera orbit, combat presentation.
- `scripts/gameplay/hitscan_weapon.gd`, `resources/weapons/`: weapon cadence/resolution and tuning.
- `scripts/gameplay/shot_executor.gd`: shared shot execution, cooldown, physical obstruction and damage.
- `scripts/ai/raider_combat.gd`, `raider_combat_profile.gd`: armed decision/aim intent and combat tuning, using the common Raider FSM.
- `scripts/player/player_damage_feedback.gd`: hull, incoming damage, directional feedback and destruction presentation.
- `scripts/gameplay/flare_director.gd`, `flare_config.gd`: bounded mission-local response tickets, local notification and equipment hold interaction.
- `scripts/gameplay/equipment_ledger.gd`, `equipment_drop.gd`: authoritative item ownership and read-only world representation.
- `scripts/presentation/death_flare.gd`: cosmetic launch, lingering signal, and audio.
- `scripts/gameplay/recall_controller.gd`: extraction eligibility/channel, reward commit and terminal player-cargo settlement.
- `scripts/gameplay/persistent_stash.gd`: versioned persistent inventory, receipt validation, atomic replacement and backup recovery.
- `scripts/gameplay/machine_ecosystem.gd`: support composition, visible machine target selection and ledger-backed component drop wiring.
- `scripts/gameplay/machine_awareness.gd`: expiring mission-local observation snapshots.
- `scripts/ai/support_machine.gd`: independent scout/guard FSM, sensors, health and physics.
- `scripts/components/`: health, visual hit reaction, cosmetic death tumble.
- `scripts/presentation/`, `scenes/effects/`: self-contained deployment presentation.

Health, weapon damage/cadence, movement, camera ownership, and physics presentation retain their existing boundaries. The blaster deals 25 damage at 0.2 s intervals over 80 m. The center camera ray chooses aim; the muzzle ray checks cover, extending 5 cm past the surface hit to avoid curved-collider rounding misses.

Navigation bakes synchronously once from the small arena's tagged collision geometry, including practice targets. Agent path height offset remains 0.5 m for this bake. Destroyed targets leave conservative footprints until restart. There is no dynamic crowd avoidance. Crowding and player obstruction remain manual testing priorities, especially with five Raiders. Path targets change when destinations change or the watchdog explicitly retries; perception decisions remain on a 0.15 s interval. Path scoring runs during objective/exit selection, not every render frame.

All visual/audio assets are engine primitives or original generated PCM. Cosmetic tumble bodies have collision layer zero: gameplay shots, movement, perception, and pickup queries ignore them. Cargo stays stationary and recoverable after the tumble expires.

## Validation

Run the editor import before the script tests:

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/robot_controller_test.gd
godot --headless --path . --script res://tests/combat_test.gd
godot --headless --path . --script res://tests/raider_test.gd
godot --headless --path . --script res://tests/mission_test.gd
godot --headless --path . --script res://tests/destruction_test.gd
godot --headless --path . --script res://tests/multi_raider_test.gd
godot --headless --path . --script res://tests/dynamic_ai_test.gd
godot --headless --path . --script res://tests/mission_variety_test.gd
godot --headless --path . --script res://tests/awareness_test.gd
godot --headless --path . --script res://tests/hostile_combat_test.gd
godot --headless --path . --script res://tests/flare_loot_test.gd
godot --headless --path . --script res://tests/extraction_test.gd
godot --headless --path . --script res://tests/machine_ecosystem_test.gd
godot --headless --path . --script res://tests/traversal_test.gd
godot --headless --path . --script res://tests/spectator_test.gd
godot --headless --path . --script res://tests/social_rivalry_test.gd
godot --headless --path . --script res://tests/social_cooperation_test.gd
godot --headless --path . --script res://tests/betrayal_test.gd
godot --headless --path . --script res://tests/integrated_extraction_test.gd
godot --headless --path . --script res://tests/post_death_spectator_test.gd
godot --headless --path . --quit-after 180
godot --path . --quit-after 180
```

The five original suites use the inherited single-Raider scene to preserve movement, combat, scavenging, extraction, loot, mission outcomes, restart, and cosmetic cleanup coverage. Accounting unit checks now address the separate ledger and policy.

Stage A coverage includes contested/partial salvage, accepted-transfer invariants, duplicate events, same-frame deaths, independent actor state, identified overlapping drops, deterministic selection, recovery during active interception, recovery-only controls, mixed losses, deadline categories, sealing, untouched protected stock, and multi-actor restart. Natural bounded navigation runs exercise three and five Raiders without teleporting them; these runs accelerate simulation time for test duration. Other setup-specific interaction tests place actors near objectives to isolate transitions.

Automated tests and graphical startup do not establish gameplay feel, visual readability, or performance on typical gaming PCs. Manual Stage A review should cover competing interception choices, crowding at salvage/exit, multiple kills and pickups, nearest-stack prompts around cover, F3 readability, deadline summary distinctions, and restart.

Stage A validation on 2026-10-18: all five adapted regression suites and the new multi-Raider suite passed, including actual independent hitscan kills and bounded three/five-Raider navigation runs. Godot 4.7.2 editor import/parsing, bounded headless startup, and Vulkan Forward+ graphical startup passed without reported errors. Manual Stage A play-testing is pending.

## Review checkpoints and Git

The accepted primitive prototype was preserved in baseline commit `d51acfd` before this refactor. Stage A is committed separately after validation. Work remains on the existing `master` branch; no remote is configured or changed. Generated `.godot/` state and builds are ignored; script `.uid` files are tracked.

Stage A was accepted in commit `49cf442`. Stage B tests cover profile-specific reactions, investigation interruption, resuming scavenging, seeded scoring, reachable/safe exit choice, finite two-location cargo accumulation, repath/alternate/stranded transitions, a physical no-progress watchdog, and natural three/five-Raider resolution. Manual Stage B review remains necessary for personality differences, investigation readability, retreat/resume pacing, route choices, and congestion recovery.

Stage B validation (2026-10-18): the five original regression suites, Stage A suite, and new Stage B suite passed. Godot 4.7.2 import/parsing and bounded Forward+ startup passed without reported errors. Simulation checks are automated; profile feel and navigation recovery in player-created congestion still require manual play-testing.

Stage B, including the stationary-threat investigation fix (`ee3159b`), has been accepted by the director.

Stage C coverage includes configuration validation, initial ground stock and unique IDs, timed entries, pending-entry completion guards, collision/support/navigation checks, blocked-entry retry, same-tick separation, seeded replay, restricted exits, normal recovery, deadline accounting, scenario switching, restart, reachable map locations, physical ramp traversal, and natural resolution of all three presets. Manual review should cover interception distances and timing, five-Raider congestion, camera behavior in passages/on the ramp, cover readability, and Recovery pickup routes.

Stage C validation (2026-10-18): all eight automated suites passed, including the seven existing regression suites and `mission_variety_test.gd`. Godot 4.7.2 import/parsing, bounded headless startup, and Vulkan Forward+ graphical startup passed without reported errors. Manual Stage C play-testing remains pending; automated runs establish simulation behavior rather than encounter feel or typical-PC performance.

Stage C (`e9d6e48`) has been accepted by the director.

Stage D automated coverage includes actual missed-shot dispatch, cooldown suppression, independent profile reactions, hearing through cover, out-of-range rejection, last-known-position memory, investigation re-arming, damage priority, repeated-shot task preservation, return to scavenging, feedback ownership/cleanup, depleted salvage, terminal events, and legacy behavior. All nine suites, Godot 4.7.2 import/parsing, bounded headless startup, and Forward+ graphical startup passed on 2026-10-18. Manual review remains necessary for hearing distances, sustained-fire behavior, alert/cargo readability, and clutter with five Raiders.

Stage D (`9f21ae8`) and Phase 2 were accepted by the director. Phase 3 Stage E was approved separately with temporary death accounting that preserves ledger categories.

Stage E coverage includes real hostile hits and a lethal shot, warning/cadence/range, physical cover obstruction, visibility interruption, distinct cover reservations, damage interruption, retreat/extraction, return to scavenging, independent attackers, one-time player death, terminal shutdown, exact material categories, seeded restart, cosmetic destruction, and natural firing/cover/peek physics. All ten automated suites passed on 2026-10-18, including the nine existing regression suites. Godot 4.7.2 import/parsing and bounded headless/Forward+ Survival startup passed without reported errors. Manual survival testing must establish incoming damage readability, warning fairness, accuracy, cover choices/congestion, difficulty against multiple attackers, and restart behavior.

Stage E (`c8d6686`) has been accepted by the director. Stage F's implementation plan and initial timings/limits were approved separately.

Stage F tests cover duplicate/simultaneous deaths, empty-cargo equipment, unique ownership, low responder loot value, delayed local response before reinforcements, blocked entry retry, active caps, finite reinforcement chains, equipment-only completion, hold interruption/eligibility, deadline sealing, restart, and natural physics response timing. Manual review must establish flare/audio readability, looting-window fairness, responder routes and congestion, overlapping material/equipment prompts, and the ability to disengage.

Stage F validation (2026-10-19): all eleven automated suites passed, including the ten existing regressions. Godot 4.7.2 import/parsing, bounded headless Loot Pressure startup, and Forward+ graphical startup passed without reported errors. Manual play-testing remains pending.

Stage F (`9cf9be1`) has been accepted by the director. Stage G's Recall Dock, five-second channel, and cargo-forfeiture rules were approved separately.

Stage G tests use unique isolated saves under ignored `.godot/stage_g_tests/`; they do not modify the player's stash. Coverage includes natural physics recall, interruption and stationary checks, active-hostile extraction, terminal ordering, separate banking/forfeiture, unchanged prior inventory on death/timeout, receipt replay/conflict, save reload, backup recovery, invalid/future saves, orphan temporary files, failed-save retry, and restart isolation. Manual review must establish dock visibility, channel fairness under fire, overlapping pickup/recall prompts, summary readability, and stash retention after closing and reopening the game.

Stage G validation (2026-10-19): all twelve suites passed, including the eleven existing regressions. Godot 4.7.2 import/parsing and bounded headless/Forward+ Recall Deployment startup passed without reported errors. Save tests were isolated from the real stash; gameplay feel and real-session retention still require manual play-testing.

Stage G and the refinement allowing recall through nonlethal damage (`6c9dcfd`) were accepted by the director. Stage H's machine ecosystem implementation was approved separately.

Stage H tests cover independent patrol physics, real machine-to-machine shots, defensive cadence, scout observations, detached snapshots and expiry, player warnings, target switching and destroyed target cleanup, one-time component release, validated Raider collection, normal player recovery, conservation, isolated saves, restart and terminal shutdown. Save tests use unique ignored `.godot/stage_h_tests/` directories and never bank into the player's stash.

Stage H validation (2026-10-19): all thirteen suites passed, including the twelve regressions. Godot 4.7.2 editor import/parsing and bounded headless/Forward+ ecosystem startup passed without reported errors. Parallel regression runs reported two ObjectDB cleanup warnings in each of the flare/recall suites; separate reruns passed without those warnings. No Stage H test or startup errors remain. Generated `.godot/` data and builds remain ignored; script `.uid` files are tracked.

Stage H (`c1abc5d`) was accepted by the director. The focused Stage I jump/boost experiment was approved separately. Stage H's patrol congestion, warning readability, guard balance, targeting and component pickup placement remain useful ongoing play-test checks.

Stage I automated checks cover physical key mappings, grounded jump height and landing, rejection of midair jumps, low ceiling collision, immediate camera-relative boost, fixed direction, diagonal normalization, cooldown rejection/recovery, braking, airborne boost/aiming, camera independence, mouse-release cancellation, boundary/obstacle collision, ramp traversal, recall cancellation, death shutdown, restart, isolated saves and return to the baseline preset.

Stage I validation (2026-10-19): all fourteen suites passed, including all thirteen existing regressions. Godot 4.7.2 editor import/parsing, bounded default headless startup, and bounded headless/Forward+ traversal startup passed without reported errors. The known two-instance ObjectDB cleanup warning appeared in the parallel flare-suite run and did not recur on its separate verbose rerun. Generated test/save data remains ignored under `.godot/stage_i_tests/`; the tests do not alter the player's stash. Automated validation establishes simulation behavior; movement feel and combat balance remain manual review items.

**Checkpoint I accepted:** the director confirmed jump and boost function and approved jump height. The jump feels floaty; refinement was explicitly deferred. After Stage K feedback, traversal was enabled throughout the test scenes; see the [availability follow-up](docs/development/reports/traversal_availability_followup.md). Jump/boost tuning is unchanged. Ongoing manual checks include midair control, landing and slopes, camera comfort near cover, cooldown feedback and escape difficulty under fire. Further mechanics and progression require a new agreed scope.

- Stage B: objective scoring, extraction choices, personalities, threat behavior, navigation recovery.
- Stage C: expanded graybox, dynamic/configurable entries, three mission presets, scenario selection.
- Stage D: gunfire awareness and additional gameplay feedback.

Keep networking, crafting/loadout progression, detailed Blender models, and final art outside this stage.

Stage J is implemented under the [Phase 4 spectator amendment](docs/development/ledgers/phase_4_stage_j_spectator_amendment.md). The director confirmed it works perfectly and approved it. Its [implementation report](docs/development/reports/stage_j_spectator.md) records validation and acceptance. Social AI requires a separate agreed scope.

Stage K's [approved scope and architectural clarification](docs/development/plans/phase_4_social_ai_plan.md) is implemented. The director accepted Stages L, M and N, including the display refinement. The [Stage N report](docs/development/reports/stage_n_integrated_extraction.md) records integrated mission validation. Stage O's approved plan is implemented: twenty suites, parsing, headless/Forward+ startup and graphical spectator checks passed. Stop at [Checkpoint O](docs/development/reports/stage_o_post_death_spectating.md) for manual review. Changes after Stage I remain uncommitted.
