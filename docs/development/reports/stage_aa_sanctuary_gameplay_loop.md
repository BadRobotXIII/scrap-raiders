# Stage AA: Sanctuary and complete gameplay loop

Prepared **2026-10-27**. **AA-5 was accepted by the director, who authorized continuation. AA-6 through AA-9 is implemented and validated for final director review.** This report supplements the [early playable delivery](stage_aa_playable_loop.md). The [approved plan](../plans/stage_aa_sanctuary_gameplay_loop_plan.md) and unchanged [director ledger](../ledgers/stage_aa_sanctuary_gameplay_loop.md) remain the scope references. No commit, publication or Stage AB work was performed.

## What is playable

Start with **F5** or `godot --path .`. Enter Sanctuary for the safe workshop, or Quick Deploy for the same preparation services directly. Existing contracts, inventory, templates, extraction, results, post-death spectating and repeated return remain functional. The real user profile was not opened during development; automated and graphical checks used isolated ignored profiles.

The four approved recipes are available at Disassembly and Fabrication. Every operation displays exact available/required/missing ingredients and output, then asks for confirmation. Processing uses only available stash items. Prepared, displayed, quarantined and deployed items cannot be ingredients.

| Operation | Consumed from available stash | Output |
| --- | --- | --- |
| Strip Raider rifle | 1 Raider rifle | 1 scrap steel |
| Strip worn response rifle | 1 worn response rifle | 1 scrap steel |
| Recover servo materials | 1 servo motor | 1 scrap steel + 1 copper winding |
| Fabricate industrial blaster | 1 scrap steel + 1 copper winding | 1 industrial blaster |
| Install Cargo Rack I | 2 servo motors + 2 control PCBs, once | Permanent 16-slot / 45 kg player cargo policy |

Cargo Rack I affects actual prepared, escrow and deployed player containers, including cold reload and subsequent deployment. The original 12-slot / 35 kg rule resource and Raider 6-slot / 24 kg policy are unchanged. Human rifles still cannot mount on the robot. There is no free replacement weapon or reverse blaster recycling recipe.

Template availability now reports **Craftable** when a supported missing blaster can be fabricated and the resulting kit actually fits. Planning aggregates ingredients, subtracts materials requested by the kit itself, reports unsupported items and runs the existing kit validation on a private candidate. It changes no live items, identities or saves. Fabrication remains individually confirmed; selecting a template never crafts automatically.

Use **Tab â†’ Arrange workshop** to place up to eight cabinets, scrap bins or pallet loads in the marked area. The camera centers on that area and restores its previous pose when leaving placement. Point at the floor or use arrows, **R** to rotate by 90 degrees, **Enter** to confirm and **Escape** to cancel. Existing saved objects can be selected, moved, rotated or removed. Positions snap to 0.5 m. Confirmation rejects overlap, protected routes, out-of-area positions and physical intersections with the robot or geometry. Preview and cancel never save.

The fixed **Item display** is available through Tab or physical E near its plinth. Assign an available stash item/stack, inspect it or return it to storage. Its icon and label represent the same reserved identity in `display:workshop`; no duplicate item is created. The display survives restart and stays unavailable to templates/recipes until removed. Decorative furniture cannot delete it.

The home retains the shared interface style, station mats and utility connections, with restrained warm/cool work lighting and quiet ventilation from existing original assets. No new art pipeline, hostile home simulation, upkeep or passive resource production was added. Representative native screenshots are archived; final visual acceptance belongs to the director.

## Authority, transactions and persistence

`GameSession`, `PersistentStash`, `InventoryLedger`, `MissionRules` and `MissionObjectives` retain their AA-5 ownership. New `RecipeDefinition`, `UpgradeDefinition`, `WorkshopService`, `PlaceableDefinition`, `SanctuaryLayout` and display/editor views extend those seams. UI controls do not consume items or maintain a second balance.

`InventoryLedger.transform_recipe` is one atomic transaction. It validates an approved recipe, consumes exact stash identities/quantities, validates output placement, allocates fresh output identities and records the authorized definition/cohort debits and credits. Runtime conservation compares original supply plus validated transformation deltas. Failed output placement restores inputs and identity counters.

`PersistentStash.persistent_command` commits the candidate inventory, operation receipt and upgrade/layout/display metadata in the existing journal. Repeated operation IDs return the original result; changed payloads, stale stash revisions and failed saves cannot spend again. Permanent capacity changes and component consumption commit together. No new currency or accounting service exists.

Persistent projection continues to establish a fresh baseline for its retained records; world-only cohorts are retired on scene handoff. Transformation provenance remains in item metadata and durable profile operation receipts. New arena admissions mark retained items imported, so workshop output cannot count as newly recovered world loot. Existing world accounting and accepted transfer APIs remain active.

Version 3, introduced at AA-5, now validates its previously empty upgrade/layout/display fields. Existing v3 profiles need no new migration or starter. Version-1/2 migration and backups remain supported. Display assignments are checked against actual inventory records, and missing-definition quarantine releases obsolete display metadata without replacing the item. Unknown future schemas remain rejected visibly. One application process remains the intended profile owner.

## Validation and observations

See [the final evidence archive](../baselines/stage_aa_delivery/README.md) for logs, probes, screenshots, manifests and measurements. Historical AA-5 evidence was preserved separately.

| Check | Result |
| --- | --- |
| Godot 4.7.2 editor parsing/import | Passed; inspected output is clean |
| Full active regression suite | **52 passed**, with final affected-suite reruns after craftability/quarantine corrections |
| Recipe/upgrade tests | Exact inputs and deltas, replay, stale revisions, failed recipe/upgrade writes, output-space rollback, duplicate-upgrade rejection and copied policy rules |
| Actual upgraded deployment | A 13-slot kit deployed through the application, exceeding the former 12-slot limit; return preserved safe display ownership |
| Layout tests | Physical collision, station standing routes, replacing only the selected collider, overlap, bounds, snap, nonfinite data, robot intersection, preview cancellation, failed save and reconstruction |
| Native Forward+ interaction | Actual recipe confirmation, paid upgrade, item assignment, placement confirmation and cold reload; 1600 x 900 and 1280 x 720 captures |
| Seeded normal application simulations | Both contracts at seeds 87017/87018, bounded to 160 simulation seconds; autonomous post-death activity, conservation and return verified |
| Director final play-test | Pending |

The full batch plus focused reruns checks completion markers and assertions, not process status alone. 34 final suite logs retain known audio shutdown warnings; verbose leaked-instance types are exclusively `AudioStreamWAV` and `AudioStreamPlaybackWAV`. The natural probe reports the same types. Editor and native graphical logs are clean. These are documented cleanup limitations, not hidden as successful shutdowns.

The four passive natural observations matched the AA-5 durations: Asset Recovery 87017/87018 ended at **130.9 / 141.1 seconds**, and Salvage Complex at **126.2 / 137.0 seconds**. Each admitted five Raiders, sampled at most two active simultaneously, continued after player destruction and ended with all five Raiders extracted. Accounting and return checks passed in every run. The probe does not force winners, and these passive outcomes are not a balancing claim.

The furnished home sample contained **196 draw calls, 29,654 primitives and 149 nodes**, compared with the early checkpoint's 162 / 24,750 / 127. This includes the display, one placed cabinet and lighting/presentation additions. It is a scene sample, not an FPS guarantee.

Five ordinary profile metadata writes averaged **37.17 ms** (31.24–44.10 ms). A bounded profile containing **1,000 available equipment records** averaged **185.04 ms** (179.87–191.34 ms), with **323.85 ms** cold reload and a **192,001-byte** cache. Both cases reloaded exact quantities. Synchronous writes and growing journal history remain measured hitch risks; no speculative persistence rewrite was made.

## Files and developer handoff

New gameplay files: recipe/upgrade definitions and `workshop_service.gd`, recipe/upgrade resources under `resources/workshop`, `workshop_view.gd` and `display_view.gd`. New Sanctuary files: placeable definitions/resources, `sanctuary_layout.gd`, `layout_editor.gd`, `item_display.gd` and its scene. `scenes/presentation/sanctuary_atmosphere.tscn` reuses original audio and built-in lights. New tests are `workshop_test.gd` and `sanctuary_layout_test.gd`; generated script UIDs are included.

Nine existing sources changed after the accepted AA-5 source manifest: the inventory ledger, persistent stash, preparation service, loadout/preparation views, Sanctuary controller, two rifle descriptions and the exact asset-pipeline source guard. Their [reviewed hashes](../baselines/stage_aa_delivery/reviewed_sources.json) override only those paths. Earlier manifests are unchanged. AI/combat policies, weapon statistics, accepted map collision/navigation, Blender sources and GLBs remain intact. All active tests remain active; no source was archived without evidence of obsolescence.

The [code-flow guide](../../architecture/game_code_flow.md) now includes workshop transformations, reservation/display authority and placement. The [extension guide](../../architecture/extension_guide.md) gives concrete seams for items, weapons, stations, recipes, equipment/templates, contracts, placeables, display visuals, Raider decisions and tests. The [technical-debt register](../../architecture/technical_debt.md) separates measured limits from future proposals.

## Final director checklist

1. Launch normally; verify title, Sanctuary and Quick Deploy still lead to the same preparation and contracts.
2. Extract a Raider rifle. At Disassembly, review its ingredients/output, cancel once, then confirm stripping it. Confirm it cannot also remain equipped, prepared or displayed.
3. Recover servo materials and fabricate an industrial blaster. Prepare/equip that owned weapon, deploy, extract and return. Check that repeated confirmations do not repeat a completed operation accidentally.
4. Acquire the two servos and two PCBs for Cargo Rack I. Confirm its cost once. Prepare cargo beyond the old limit, deploy and return. Restart and verify the capacity remains 16 slots / 45 kg.
5. Preview missing equipment in templates. Check Craftable, unsupported recipes and shortages. Confirm that selecting/previewing a template spends nothing and no automatic fabrication occurs.
6. Open Tab â†’ Arrange workshop. Add each prop type, rotate/move a saved object, cancel a preview, remove an object and restart. Try overlapping/out-of-bounds placement and walking through the saved geometry. All six stations must remain reachable.
7. Assign an owned item to the display. Inspect it, restart, verify it is unavailable to preparation/disassembly, then return the same item to storage.
8. Repeat successful extraction, early extraction and destruction/observation/return from both preparation paths. Verify safe stash contents, displayed items and progression survive; carried losses follow the accepted rules.
9. Review camera comfort, placement visibility, small-window panels, lighting and ventilation volume. Report confusing controls or persistent hitches.

Stop for final Stage AA acceptance. Suggested director-owned follow-ups are recipe tuning after gameplay feedback, richer display/home art, carefully scoped additional contracts and a measured journal-performance proposal. Whole-kit automatic fabrication, multiple reserved kits, recursive crafting and broader progression remain future work.
