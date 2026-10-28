# Extending the gameplay baseline

Stage AA retains the accepted owners described in [game code flow](game_code_flow.md). Application work belongs under `GameSession`; item mutations belong in `InventoryLedger`; durable changes belong in `PersistentStash`. A view requests an operation and renders its result. It never owns another spendable item balance.

## Items and weapons

For a new item, copy an appropriate `resources/items/*.tres`, give it a unique `definition_id`, valid mass/stack/category/icon and add it to `resources/items/catalog.tres`. Preserve existing IDs. Test catalog validity, identity transfer, capacity, persistence and missing-definition quarantine. A loot-table addition must replace or allocate finite stock through the existing scenario bootstrap; it must not issue supply during perception or UI refresh.

A weapon item also references a `WeaponDefinition`, declares the `primary` mount and lists compatible actor kinds. Use the existing shot executor and weapon component for discharge/hit facts. Human-only Raider rifles remain cargo for the robot. Adding an entry to a dropdown must not bypass compatibility or invent equipment. Module definitions without implemented effects must remain described as data only.

Example: another robot-compatible primary requires its approved item/weapon resources, catalog entry, explicit finite acquisition path and shot/mount regression. Do not change default weapon balance simply to expose its UI entry.

## Stations and shared preparation

A physical station uses `WorkshopStation`: stable ID, display name, context and a safe anchor. Register it through `StationRegistry`. Extend the bounded profile station-ID validator and initialization data deliberately if a new station is approved. Both physical E and quick access must use the same entry checks and service. Add a physical range/occlusion test and a blocked-anchor test.

`PreparationView` routes storage to `InventoryContext`, loadouts to `LoadoutView`, and recipes to `WorkshopView`. Quick Deploy uses these same services without constructing Sanctuary or a hostile arena. Introduce no station-specific stash copy. If a panel needs a new command, add it to a shared service and test both entry paths.

The fixed item display is a separate inspected furnishing, not a seventh production station. Its physical and quick entry call `Sanctuary.open_display`; its item operations use `WorkshopService.display_item`.

## Recipes and upgrades

Copy an approved `RecipeDefinition` resource under `resources/workshop/recipes`. Define integer input/output quantities using known catalog IDs. Add its ID to the explicit `RecipeDefinition.approved` allowlist and relevant workshop presentation. Review mass, value and recycling loops before approval. The existing four recipes preserve mass; Cargo Rack I consumes its listed components as an installed upgrade.

`WorkshopService.preview` only counts available stash. `execute` requires an operation identity and reviewed stash revision, then calls `PersistentStash.persistent_command`. The candidate ledger consumes exact inputs and creates new output IDs through `transform_recipe`; the live state is installed only after durable commit. Receipt debits/credits are validated against the approved recipe. Add replay, stale-revision, failed-write, insufficient-input and insufficient-output-space tests.

For an upgrade, add an approved resource and a bounded profile key, apply costs and metadata in the same transaction, and derive copied rules at every admission/binding. Never mutate a shared rule resource. Cargo Rack I demonstrates this seam for prepared, escrow and deployed player capacity; Raider rules remain independent. Test real deployment and cold reload, not just the metadata flag.

Fabrication planning is deliberately one level: `fabrication_preview` aggregates ingredients for supported missing items after subtracting ingredients requested by the kit itself. It reports unsupported items and shortages. Preview never creates identities. Whole-kit automatic fabrication and recursive recipes need a separate proposal.

## Templates and contracts

`LoadoutTemplate` describes definitions and quantities, while the single `prepared` container holds actual reserved identities. Extend the template schema only with bounded, validated fields. Preserve unknown IDs for visible shortages. Preparation must revalidate compatibility, ownership, reservations, slots and weight on the real candidate ledger. Displayed items are excluded.

For another approved contract, add a `ContractDefinition` resource referencing an existing/new approved scene and `MissionConfig`, then update the session's explicit contract list and bounded profile selector. Objective facts still come from `MissionObjectives`; settlement still uses `MissionRules`, Recall and the persistent receipt. Test staged initialization failure, successful/early extraction, destruction and repeated return. Do not add a parallel quest or reward manager.

## Placeables and display visuals

Copy a `PlaceableDefinition` under `resources/sanctuary`, using an existing approved visual scene and conservative collision dimensions. Extend its allowlist and editor picker together. `SanctuaryLayout.valid` checks the eight-object bound, IDs, finite snapped coordinates, quarter turns, marked-area containment, overlap and protected standing corridors. Confirmation also checks actual physics and the robot. Preview, rotate and cancel do not save. Test reload and physical station access after placing the prop.

The display's item lives only in `display:workshop`, included in persistent projection/admission. `home.display_assignments` references that exact identity and must agree with the inventory record. Its current icon and label are read-only presentation. A richer mesh resolver can replace those visuals by definition ID; it must not issue an item or infer ownership from a mesh. Removing or replacing an assignment transfers the original stack back to stash. Decorative furniture deletion cannot delete display ownership because the display is fixed.

## Raider decisions and presentation

Raider remains the single FSM and movement owner. Combat, perception, relationships and navigation remain composed helpers. Add an approved decision through the current transition/commitment path; use observed, expiring threat facts, eligibility and bounded release conditions. Do not write velocity from another planner or make the camera a perception target.

For a Raider correction, reproduce it in a policy test and an actual movement/shot integration case. Retain action-commitment, personality, physical firing, social, extraction and conservation suites. Presentation consumes authoritative shot/damage/death signals and cannot award hits or items.

## Tests and evidence

Use `tests/*_test.gd` for active suites, with an explicit completion marker and nonzero failure exit. `tests/inventory_world_test.gd` provides randomized ignored profile paths and bounded physics-frame helpers. Set application `GameSession.profile_path` before adding the app to the tree. Never test migration against the real player profile.

Run Godot 4.7.2 editor parsing/import, affected regressions and bounded runtime checks. Run the full active suite for integration changes. Inspect script errors and completion markers as well as exit codes. Use native Forward+ screenshots and interaction for presentation; headless assertions do not establish visual acceptance.

Historical manifests are evidence, not files to regenerate. Add exact reviewed overrides for approved source changes and preserve all unrelated hashes. Document schema changes and recovery behavior. Commit and publication require separate authorization.
