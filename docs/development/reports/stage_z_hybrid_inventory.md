# Stage Z — hybrid inventory, looting and extraction

Delivered **2026-10-26** against the director-approved [architecture plan](../plans/phase_7_stage_z_hybrid_inventory_plan.md). **Checkpoint Z: implementation complete; director manual review pending.** Stage Y remains accepted. No commit, publication or subsequent stage is included.

The [original ledger](../ledgers/phase_7_stage_z_hybrid_inventory.md), [repository audit](stage_z_inventory_architecture_audit.md) and [pre-implementation evidence](../baselines/stage_z_architecture_audit/README.md) remain historical records. Final logs, probes, measurements, source identities and screenshots are in the [Z delivery evidence](../baselines/stage_z_delivery/README.md).

## Delivered behavior and ownership

Player and Raiders now use **one InventoryLedger** for ownership, quantities, stack operations, combined carried mass, cargo slots, equipment compatibility and terminal transfers. MaterialLedger and EquipmentLedger are compatibility queries/events over that same owner. Their returned records are copies; neither retains a second spendable balance.

ItemDefinition, ItemCatalog and InventoryRules Resources hold the approved twelve-item catalog and capacity policies. Normal Asset Recovery and the expanded Salvage Complex opt in through MissionConfig; P/Q/R and other reference presets retain their content and unbounded legacy policies through the same ledger implementation. Weapon damage, cadence, range, health, movement, actor collision, navigation geometry and W–Y art are unchanged.

| Owner / supply | Delivered initial policy |
| --- | --- |
| Player | 12 cargo slots, 35 kg including mounted gear; primary, armor, power, mobility and utility mounts |
| Raider | 6 cargo slots, 24 kg including mounted gear; human primary and utility mounts |
| Safe storage | Unlimited gameplay stash; prepared loadout already obeys player capacity |
| Materials | Existing 12 stock units redistributed across five salvage definitions, plus two finite installed machine units; **14 total** |
| World equipment | Four unique items: one blaster, armor, power and mobility module, distributed across three registered sources |
| NPC equipment | Two items per regular admission, one per responder; existing five regular / two responder bounds permit at most 12 allocations |
| Starter | One imported blaster per new/migrated profile, issued once; no death/restart refill |
| World views | Three source views; mandatory Raider/component releases retain their reserved places; at most 52 voluntary bundles, within the 64-view policy |

Integer grams and quantities remain authoritative. Exact transfers reject without mutation when they cannot fit; Take fitting and Raider collection explicitly permit a remainder. Compatible stacks merge automatically, splitting requires a cargo slot, and unique equipment retains its identity. Command identities and expected revisions reject conflicting/stale requests. Death and extraction close the actor container and resolve cargo plus mounted gear in one transaction.

Only a compatible **mounted primary weapon** enables existing firing. Carrying a weapon as cargo does not. Armor, power, mobility and utility mounts display that they have **no stat effect in Stage Z**. Raiders retain their admitted weapons and collect found equipment as cargo; autonomous re-equipping was not added.

## Sources, Raiders and interaction

The three existing stock anchors have reusable salvage-cache/tool-cabinet cues. They reuse existing stock presentation and retain the accepted collision/navigation geometry; decorative industrial props are not automatically searchable. A digest-seeded loot stream resolves each finite manifest once before deployment. Source reopening reads current ownership and never invokes generation.

InventoryInteraction validates registered source identity, living actor, mission phase, range, line of sight and completed dwell for both player and Raider transfers. Player search uses the existing 1.5-second stationary/no-fire, damage-interruptible access. Loose material bundles use zero search dwell. Raider collection retains its 0.8 m approach and existing three-second scavenging dwell. Requests cannot use an open panel to loot remotely.

Raider remains the sole FSM/movement owner. Existing route/risk/contention selection now scores collectible value and capacity. Newly acquired value goals remain **6 / 3 / 3**; initial worn loadout is excluded. Greedy preservation and betrayal comparisons use the same acquired-loot query. Existing Q/W threat, engagement, cover and pursuit commitments remain intact.

Authored cache locations retain the previous stock routes, so an actor can travel to inspect a known location without knowing its contents. Value and contents require observation; dropped loot retains LOS/radius/expiry checks. A completed empty-cache visit remains a historical fact after contents knowledge expires. Fresh direct sight of newly deposited loot makes that cache eligible again. This prevents repeated nonproductive cache circuits without granting live knowledge of unseen items.

Physical integration found and corrected three concrete seams: briefing reactivation needed a navigation/static-collision publication barrier before entry validation; shared Raider access rays needed to exclude the requester's own body; and expired empty-cache observations could restart already completed searches. Targeted regressions exercise each affected path. No new AI controller or encounter outcomes were introduced.

## Inventory and preparation

**I** opens inventory or safe preparation; **Escape** closes it first. Equipment sits beside a four-column cargo view, item details, quantity control, total mass and source/stash contents. Limits and mounts read the authoritative container policy. Stash pages contain at most 24 item buttons. Actions include exact/fitting pickup, ordered Take All with per-item outcomes, transfer, split, equip/unequip, drop, cancel prepared loadout and quarantine inspection. Drag-and-drop and new item artwork were not added.

The world continues while the panel is open. PlayerInteractionMode owns briefing/gameplay/inventory/developer/post-death/results permissions. It clears movement/look/fire/recovery intents and traversal, while RobotController continues gravity, braking and collision. Closing inventory suppresses held-fire reuse. Damage closes the panel; death/results revoke access. Developer camera exit resolves current equipment ownership, and normal post-death followers cannot open inventory or transfer items.

Preparation moves items between safe stash and a capacity-checked prepared loadout. Deploy durably debits that loadout before enabling simulation. Empty/unarmed deployment is supported: one finite world blaster can be recovered, mounted and fired through the same rules. The integration suite exercises that second-deployment recovery after returning/loss of the original kit.

## Persistence, migration and settlement

PersistentStash remains the sole disk writer. Version 2 stores stable item identities/provenance, safe/prepared/escrow/quarantine ownership, operation/deployment records and a verified sequence/hash chain. Serialized checkpoints and receipts are evidence, not additional inventory locations that can spend items.

Preparation and deployment changes build a validated candidate, write/flush/read-verify a temporary journal snapshot, and rename it to a unique committed sequence before publishing ownership. That journal rename is the durability boundary. A subsequent cache-write failure reports committed success; reload reads the latest verified journal rather than restoring spent gear from an older cache. A recovered cache is used in memory and refreshed by the next successful persistent operation. Broken chains and future primary versions block spending and preserve existing files.

Recall persists the return before closing objectives or declaring success. Failure before commit leaves live cargo available for retry. Repeated matching settlements return the prior outcome; conflicting outcomes reject. Death/timeout/abandon forfeits deployment cargo once. An unresolved crash forfeits imported escrow once on the next attachment; there is no mid-mission resume or player corpse grant.

Version-1 migration converts the current material balance once, maps the three known equipment names, preserves token/local item identity and old receipts, and records the one-time starter grant. Existing source bytes are preserved in `.v1.bak`. Unknown legacy names and missing modern definitions retain identity/payload in quarantine and cannot deploy. Migration refuses more than **50,000 material units or 4,000 legacy equipment entries** before expanding records; runtime reconstruction is capped at 10,000 records and individual journal snapshots at 16 MB. Oversized or malformed data is preserved rather than truncated.

**Development and validation never read, migrated or wrote the director's real stash.** All save tests, native/graphical launches and measurements used isolated ignored paths. A subsequent normal user launch intentionally performs the approved migration when needed.

Imported equipment/materials remain distinct from new world loot. Returning, dropping or recollecting imports cannot earn new-loot objective credit. On the following deployment, banked items enter as imports with their persistent identities intact.

## Validation

| Check | Evidence / result |
| --- | --- |
| Godot editor parsing/import | Godot 4.7.2 Standard, exit 0; output inspected for script/import errors |
| Full regression | **All 47 suites pass:** all 41 accepted suites retained, plus six Z suites |
| Foundation | Exact rejection/rollback, fitting transfer, split, merge, read-only snapshots, mount compatibility, mass, command deduplication and mixed terminal settlement |
| Persistence | Original-byte migration backup, no repeated starter, active-deployment exclusion, crash forfeiture, pre/post-commit failure injection, stale-cache recovery, broken journal/future version refusal, oversized migration, missing-definition quarantine round-trip |
| Real scenes / AI | Registered physical access, seeded manifests, actual Raider movement/dwell/collection/extraction, one mixed death bundle, empty-cache expiry and rediscovery |
| UI / lifecycle | Live simulation, ownership-derived firing, unarmed spectator return, held-E access, nonlethal damage closure, death permissions, real Recall, objective credit, restart and finite second-deployment blaster recovery |
| Forward+ native GUI | Real I/Escape and Deploy input, preparation/source panels, Take All, Recall/result, restart and post-death follow; exit 0, clean output and screenshots |
| Bounded normal simulation | Both normal scenes, seeds 87017/87018, through world completion; finite supply/populations and conservation remain valid |
| Spectator comparison | Expanded 87017 repeated with moving developer camera: same sampled decisions/health/loot, counters, final contents and outcomes; observed maximum position delta recorded with an explicit 2 cm tolerance |

Existing S/T/U scalar-content physical fixtures explicitly use copies with hybrid content disabled, preserving their original assertions and the shared ledger engine. The six Z suites load actual current normal/expanded configurations. Asset/source guards retain historical baselines plus **22 exact reviewed Z caller/config/fixture identities**, rather than exempting future gameplay changes broadly.

Accelerated headless runs can still report the accepted shutdown-only WAV retention. Final verbose logs classify leaked objects as AudioStreamWAV/AudioStreamPlaybackWAV; this is separate from script failures, assertions, conservation failures and native graphical teardown. Exact final warning counts are in the evidence summary.

## Seeded observations and performance

The passive fixture leaves the physical player at its normal position and makes no player interventions. All four final seeded deployments admitted five regular Raiders, peaked at two simultaneous living Raiders, destroyed both machines, extracted all five Raiders and completed naturally before the 180-second deadline. No Raider deaths or flare activations occurred in these four observations; existing constructed combat/flare suites remain the evidence for those paths. This sample does not require those winners or extraction counts in normal play.

| Scene | Seed | World completion |
| --- | ---: | ---: |
| Compact Asset Recovery | 87017 | 130.90 s |
| Compact Asset Recovery | 87018 | 137.48 s |
| Expanded Salvage Complex | 87017 | 126.23 s |
| Expanded Salvage Complex | 87018 | 136.97 s |

The approved value goals make high-value early recovery reach extraction readiness sooner than anonymous steel. This is visible in the sample and remains a director play-test concern; no unrelated damage, population or arrival tuning was made to force more fighting.

Final matched 1600 × 900 Forward+ bay/overview measurements and large-stash timings are tabulated in the [evidence summary](../baselines/stage_z_delivery/README.md). The rendering review guides remain **487 draws / 188,020 primitives** and **+1 ms frame p95** against accepted Y; they were not increased. Measurements include configured five-Raider/two-machine overlap in a constructed population fixture. This deliberate overlap is distinct from natural scheduling.

The 1,024-stack isolated stash remained valid and used a bounded 76-node inventory view. Measured migration was about 0.52 s; initial open about 12 ms and refresh about 9.5 ms. Durable preparation transfers averaged about 171 ms and five committed snapshots occupied about 1.01 MB. Fit-query measurement fell from about 5.07 ms to 0.47 ms after limiting hypothetical work to the participating containers; invariants were changed to a single pass and compatibility counters avoid copied record lists. These optimizations preserve the same authority and decisions. Large-stash synchronous writes and growing journal history remain visible costs; no compaction/background persistence framework was added.

## Changed files and limits

New production files are the item/catalog/rules/ledger, loot table/view/access components, equipment binding, interaction-mode owner and inventory view; catalog/rule Resources; and two reusable source cues. Existing changes are confined to the two normal MissionConfigs, shared ledger facades and arena/Recall/flare integration, four Raider inventory queries/knowledge seams, input/developer permissions and objective/preparation presentation. Six new tests, three narrow legacy fixture/source-guard updates and documentation accompany them. Exact paths/hashes are archived with the evidence; existing uncommitted W–Y work was preserved.

Remaining limits: clear-text item placeholders; data-only nonweapon mounts; no Raider mid-mission re-equipping; no drag-and-drop; synchronous large-stash commits; no journal compaction or mid-mission resume. Human review of pacing, UI usability, repeated looting and emergent competition remains required. Automated and graphical checks do not constitute director manual acceptance.

## Director play-test — Checkpoint Z

Launch `godot --path .` for compact Asset Recovery, or `godot --path . res://scenes/levels/expanded_salvage_complex.tscn` for the expanded mission. Both now use Z inventory. P/Q/R references remain available for comparison.

| Ledger case | Review action and expected result |
| --- | --- |
| A — Preparation | Open I, move stash items into the prepared loadout, mount a compatible weapon, inspect cargo/mass; cancel returns preparation to safe storage |
| B — Deployment | Deploy the chosen loadout; only mounted compatible equipment permits firing; empty deployment remains possible |
| C — Pickup | Search a registered cache and take several types; quantities, stacking and mass update without creating loot |
| D — Containers | Take part of a source, close/reopen, let a Raider collect while it is open; remaining contents stay authoritative; stepping away revokes access |
| E — Capacity | Approach mass/slot limits; exact Take rejects clearly, Take fitting leaves a remainder; test split and equip/unequip |
| F — Competition | Observe independent Raiders travelling to caches and collecting finite contents; a completed empty search should not cause a repeated route loop |
| G — Raider death | Defeat a loaded Raider; search its one salvage pack containing cargo plus gear; reopen/retry cannot duplicate the bundle or flare |
| H — Recall | Hold E at the dock for five seconds; new cargo counts toward objectives and all returned ownership is banked once; early Recall can leave the primary incomplete |
| I — Failure | Die carrying brought/found items; cargo is lost, prior safe stash remains; post-death observation cannot pick up items |
| J — Repeat | Prepare from banked items and deploy again; identities/ownership persist and no starter refills; recover the finite world blaster when unarmed |
| K — Spectator | Use F1/F3 and post-death follow; camera movement must not steer Raiders or permit normal post-death transfers |
| L — Performance | Reopen inventory during several actors' activity, page storage, drop/recover bundles, and check response time and readability |

Stop at **Checkpoint Z** for feedback. No subsequent stage, commit or publication is authorized.

## Director usability follow-up

The director requested clearer visual identity, inventory shortcuts and an explanation of unavailable loadout weapons, then confirmed that Raider rifles should remain human-only cargo. See the [inventory usability refinement](stage_z_inventory_usability.md) for the delivered UI changes, validation and future disassembly proposal. Checkpoint Z manual acceptance remains pending.
