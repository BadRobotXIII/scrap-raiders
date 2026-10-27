# SCRAP Raiders — Stage Z Development Ledger

## Hybrid Inventory, Looting & Extraction Economy

**Project:** SCRAP Raiders  
**Studio:** BadRobot Studios — Engineering Bad Behavior  
**Engine:** Godot 4.7.2  
**Stage:** Z  
**Status:** Architecture proposal required — implementation not yet authorized  
**Prerequisite:** Accepted Stage Y  
**Design reference:** Escape from Duckov  
**Inventory model:** Hybrid — slot-based cargo, weight limits, dedicated equipment slots

---

# 1. Project context

SCRAP Raiders is a third-person extraction shooter in which the player controls a machine competing with autonomous human Raiders for valuable salvage.

The project already includes:

- Independent Raider personalities and decision-making.
- Raider cooperation, rivalry, and betrayal.
- Combat between Raiders, machines, and the player.
- Finite world salvage.
- Loot drops and equipment recovery.
- Raider extraction.
- Player Recall Dock extraction.
- Persistent player storage.
- Deployment settlement.
- Mission objectives.
- Seeded dynamic encounters.
- Expanded industrial environment.
- Original Blender-generated actors and animations.
- Combat feedback, audio, and environmental presentation.
- Environmental storytelling and industrial asset population.

Stage Z must turn the existing salvage and extraction mechanics into a coherent inventory and loot economy.

The existing repository is authoritative. Do not assume previous stage proposals were implemented exactly as written.

**Inspect before designing. Propose before implementing.**

# 2. Primary objective

Create a functional extraction-shooter inventory loop in which:

1. The player prepares a loadout.
2. The player enters a deployment with selected equipment.
3. Loot exists as identifiable, finite items.
4. Loot can be collected from the world, containers, and defeated actors.
5. Cargo space and weight impose meaningful constraints.
6. Items can be transferred, stacked, split, equipped, and dropped.
7. Autonomous Raiders interact with the same underlying item economy.
8. Successful extraction transfers surviving items into persistent storage.
9. Death or failed extraction applies consistent item-loss rules.
10. Stored items provide a foundation for future progression.

The implementation must preserve the existing AI simulation, mission structure, combat, and persistence contracts.

This stage establishes the inventory foundation and a playable extraction loop. It does not require a fully developed crafting, trading, or upgrade economy.

# 3. Mandatory repository inspection

**Priority: Critical**

Before writing code, inspect the complete relevant architecture.

## 3.1 Gameplay systems

Locate and document:

- Player controller and player actor scene.
- Raider controller and Raider actor scene.
- Ground and flying machine implementations.
- Combat and damage components.
- Death and loot-drop handling.
- World salvage objects.
- Salvage ownership and collection logic.
- Raider scavenging decisions.
- Raider extraction behavior.
- Player Recall Dock.
- Mission objectives.
- Deployment settlement.
- Persistent stash.
- Loadout preparation, if present.
- Restart and scene transitions.
- Seeded encounter and loot generation.
- Debug and spectator systems.

## 3.2 Existing data contracts

Determine how the current project represents:

- Materials.
- Equipment.
- Salvage quantities.
- Actor-carried resources.
- World resource pools.
- Dropped loot.
- Extracted resources.
- Banked resources.
- Persistent storage.
- Item or drop identifiers.

Identify existing authoritative ledgers and ownership rules.

Do not replace accepted systems merely because a new inventory abstraction would be cleaner.

Identify what can be adapted, what must be migrated, and what should remain unchanged.

## 3.3 Existing UI

Inspect:

- HUD.
- Mission briefing.
- Player interaction prompts.
- Salvage interaction.
- Equipment display.
- Deployment results.
- Stash or preparation interfaces.
- Input mapping.
- Mouse capture.
- Pause behavior.
- Spectator controls.

Determine how the inventory interface can integrate without creating conflicting input ownership.

## 3.4 Existing validation

Inventory all relevant automated tests.

Identify baseline scenarios for:

- Finite resource conservation.
- Raider looting.
- Raider extraction.
- Player extraction.
- Death and loot drops.
- Mission settlement.
- Persistence.
- Seed reproducibility.

Run or document the current baseline before implementation.

# 4. Architecture proposal checkpoint

**Priority: Critical**

After repository inspection, produce a written architecture proposal.

It must include:

1. Existing system inventory.
2. Current ownership and persistence model.
3. Proposed item-definition architecture.
4. Proposed item-instance architecture.
5. Proposed inventory/container architecture.
6. Proposed transfer authority.
7. Player and Raider integration strategy.
8. World-loot representation.
9. Equipment-slot model.
10. Cargo-slot and weight model.
11. Looting UI design.
12. Stash and loadout design.
13. Extraction and death settlement.
14. Persistence schema and migration.
15. Seeded generation strategy.
16. Regression and conservation strategy.
17. Exact files to create or modify.
18. Implementation order and risks.

Explain the tradeoffs between extending the existing finite salvage ledger and introducing a unified item model.

**STOP after presenting the proposal.**

Do not begin implementation, generate assets, migrate saves, or modify gameplay behavior until director approval.

# 5. Core architectural principle

**Priority: Critical**

There must be one authoritative item-ownership and transfer mechanism.

Items may exist in:

- World loot.
- Searchable containers.
- Player cargo.
- Player equipment.
- Raider cargo.
- Raider equipment.
- Dropped actor loot.
- Persistent player stash.
- Extracted Raider inventory.
- Other explicitly defined terminal states.

An item must not exist simultaneously in multiple authoritative locations.

Recommended conceptual flow:

```text
                    ITEM DEFINITIONS
                           |
                           v
                      ITEM INSTANCES
                           |
                           v
                 AUTHORITATIVE OWNERSHIP
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      World Loot      Actor Inventory   Persistent Stash
          |                |                |
          +----------------+----------------+
                           |
                           v
                   VALIDATED TRANSFERS
                           |
                           v
                  UPDATED OWNERSHIP
                           |
                           v
                 PRESENTATION EVENTS
```

Use existing architecture wherever practical.

Avoid creating a parallel inventory system that bypasses the accepted salvage ledger.

# 6. Item definitions

**Priority: Critical**

Establish data-driven item definitions.

Prefer Godot Resources or another repository-consistent data format.

Each item definition should support:

- Stable item type identifier.
- Display name.
- Description.
- Category.
- Icon or presentation reference.
- Unit weight.
- Maximum stack size.
- Equipment compatibility, if applicable.
- Base economic value.
- Relevant metadata.

Suggested categories:

- Raw materials.
- Mechanical components.
- Electronics.
- Power components.
- Weapons.
- Armor.
- Mobility modules.
- Utility modules.
- Consumables, reserved for future use.
- Valuable miscellaneous salvage.

Do not create hundreds of items.

Start with a compact, meaningful catalog sufficient to validate the loop.

## 6.1 Suggested initial items

Illustrative examples:

| Item | Category | Role |
|---|---|---|
| Scrap steel | Material | Common industrial salvage |
| Copper winding | Material | Valuable electrical material |
| Servo motor | Mechanical | Equipment component |
| Industrial sensor | Electronics | Specialized salvage |
| Control PCB | Electronics | Valuable recoverable component |
| Power module | Power | Equipment or valuable salvage |
| Actuator assembly | Mechanical | Heavy recoverable component |
| Damaged drive | Electronics | High-value salvage |
| Armor plate | Equipment | Robot protection |
| Mobility actuator | Equipment | Mobility module |

The catalog must reflect existing project systems and item types where possible.

These are suggestions, not mandatory additions.

# 7. Item instances and identity

**Priority: Critical**

Separate item definitions from individual item instances.

A definition describes what an item type is.

An instance represents an owned quantity or unique piece of equipment.

Item instances should support:

- Stable identity where required.
- Definition reference.
- Quantity.
- Current owner or container reference.
- Optional instance metadata.
- Durability or condition only if justified by current gameplay.

Avoid unnecessary complexity.

For ordinary stackable materials, use quantity-based stacks with clearly defined ownership and conservation rules.

For unique equipment, preserve distinct instance identity.

## 7.1 Stack identity and conservation

Define explicit rules for:

- Stack merging.
- Stack splitting.
- Partial transfers.
- Item creation.
- Item destruction.
- Extraction.
- Save/load reconstruction.

A split must preserve total quantity.

A merge must not duplicate items.

If unique instance identifiers are used for stacks, document whether they identify the stack or the underlying items.

Do not assume a stack ID is equivalent to a unique physical-item ID.

# 8. Hybrid inventory model

**Priority: Critical**

The approved inventory model is:

**Slot-based cargo + weight capacity + dedicated equipment slots.**

Do not implement a spatial packing puzzle.

## 8.1 Cargo inventory

Cargo uses a fixed number of slots.

Each occupied slot holds one item stack or one non-stackable item.

The number of occupied slots must not exceed capacity.

The total cargo weight must not exceed the configured weight limit.

Both restrictions apply independently.

An inventory can be full because:

- All slots are occupied.
- The weight limit has been reached.
- The requested item cannot stack with existing items.
- The requested transfer exceeds an allowed stack size.

The interface must explain why an item cannot be collected.

## 8.2 Initial capacity

Propose a reasonable baseline after reviewing the existing economy.

For prototyping, 20 cargo slots and a 35 kg limit may be considered.

These are illustrative values, not approved balance constants.

Centralize capacity configuration.

Avoid scattering hardcoded limits across gameplay scripts and UI.

## 8.3 Equipment slots

Recommended robot slots:

- Primary weapon.
- Armor plating.
- Power module.
- Mobility module.
- Utility module.

Inspect the existing player and combat architecture before introducing functional equipment effects.

Do not create equipment slots that silently alter combat or movement rules.

Where functional equipment behavior is not yet supported, clearly identify the slot as a data and presentation foundation.

## 8.4 Player and Raider differences

Use shared inventory rules.

Player and Raider inventories may have different:

- Slot capacities.
- Weight limits.
- Compatible equipment.
- Initial loadouts.
- Loot preferences.

Differences must be explicit configuration, not separate implementations.

# 9. Inventory operations

**Priority: Critical**

Implement or adapt validated operations for:

- Add item.
- Remove item.
- Transfer item.
- Merge stacks.
- Split stacks.
- Equip item.
- Unequip item.
- Drop item.
- Collect world item.
- Transfer to stash.
- Transfer from stash.

Operations must be transactional from the perspective of authoritative gameplay.

## 9.1 Transfer guarantees

Each transfer must:

1. Validate the source.
2. Validate available quantity.
3. Validate the destination.
4. Validate slot availability.
5. Validate weight capacity.
6. Validate equipment compatibility where relevant.
7. Apply the change atomically.
8. Return a clear success or failure result.
9. Emit presentation events only after success.

A failed transfer must leave the authoritative state unchanged.

## 9.2 Partial transfers

Support partial stack transfers where useful.

For example, a player may collect five components from a stack of twelve.

If only three can fit, the system must apply a documented policy:

- Reject the full request, or
- Accept a clearly reported partial transfer.

Never silently discard the remainder.

## 9.3 Concurrency

Although the current game is single-player, multiple autonomous actors can compete for the same resource.

Two Raiders must not successfully collect the same final item quantity.

Validate ownership and available quantity at the authoritative transfer boundary.

Do not rely on visual object removal as the mechanism preventing duplicate collection.

# 10. World loot

**Priority: Critical**

Replace or adapt abstract salvage interactions into identifiable item-based world loot.

Each world loot object should provide:

- Visual representation.
- Item identity or contents.
- Available quantity.
- Interaction range.
- Interaction prompt.
- Ownership linkage.
- Collection result.

Use existing world-loot scenes and presentation systems where possible.

Avoid creating a separate authoritative item count inside the visual object.

The visual object should represent authoritative inventory state.

## 10.1 Finite resources

Preserve the accepted finite-resource model.

World resources must not regenerate accidentally through:

- Scene reload.
- Actor death.
- Container reopening.
- Inventory UI refresh.
- Mission restart within the same deployment.
- Repeated extraction settlement.

A fresh deployment may generate new resources according to its defined scenario rules.

## 10.2 Visual distinction

Players must distinguish:

- Collectible salvage.
- Decorative industrial scrap.
- Searchable containers.
- Dropped actor equipment.
- Mission-critical items.

Use clear but restrained visual cues.

Avoid overwhelming the industrial environment with floating labels.

# 11. Searchable containers

**Priority: High**

Introduce a small reusable set of searchable container types.

Suggested examples:

- Industrial storage crate.
- Electrical cabinet.
- Tool chest.
- Salvage bin.
- Equipment locker.

Each container owns or references an authoritative inventory.

Opening a container reveals its contents.

The player can transfer items between container and cargo.

## 11.1 Container rules

- Contents are generated or assigned once per deployment.
- Opening a container does not regenerate loot.
- Closing and reopening preserves remaining contents.
- Partial looting is supported.
- Multiple actors cannot duplicate contents.
- Empty containers remain empty.
- UI state reflects actual authoritative contents.

## 11.2 Container presentation

Support:

- Interaction prompt.
- Container name.
- Contents panel.
- Item transfer.
- Empty-state feedback.
- Full-inventory feedback.

Use existing Stage Y environment props where appropriate.

Do not introduce destructible container mechanics.

# 12. Player inventory interface

**Priority: Critical**

Create a usable inventory UI designed for the current third-person gameplay.

The player should be able to:

- Open inventory.
- Inspect cargo.
- Inspect equipped items.
- View item details.
- View slot usage.
- View total weight.
- Equip compatible items.
- Unequip items.
- Drop items.
- Split stacks.
- Transfer items when interacting with storage.

## 12.1 UI layout

Recommended structure:

```text
+------------------------------------------------------+
| INVENTORY                                            |
+------------------------+-----------------------------+
| EQUIPMENT              | CARGO                       |
|                        |                             |
| Weapon                 | [ ][ ][ ][ ][ ]             |
| Armor                  | [ ][ ][ ][ ][ ]             |
| Power                  | [ ][ ][ ][ ][ ]             |
| Mobility               | [ ][ ][ ][ ][ ]             |
| Utility                | [ ][ ][ ][ ][ ]             |
|                        |                             |
|                        | Slots: 8 / 20               |
|                        | Weight: 18 / 35 kg          |
+------------------------+-----------------------------+
| SELECTED ITEM                                        |
| Name / Description / Quantity / Weight / Value       |
| [Equip] [Transfer] [Split] [Drop]                    |
+------------------------------------------------------+
```

This is a conceptual layout.

Adapt it to the existing HUD and viewport design.

## 12.2 Interaction design

Prefer predictable, straightforward interactions.

Minimum requirements:

- Mouse-based item selection.
- Context-sensitive action buttons.
- Keyboard inventory toggle.
- Clear selected-item state.
- Clear disabled actions.
- Useful transfer failure messages.
- Reliable mouse capture and release.

Drag-and-drop may be added if it fits the existing UI architecture, but must use the same validated transfer operations as button actions.

Do not create separate transfer logic inside UI scripts.

## 12.3 Inventory while deployed

Propose a clear policy for inventory interaction during combat.

Recommended initial policy:

- Inventory is an overlay.
- The simulation continues while inventory is open.
- Player movement and firing input are suppressed while interacting with the UI.
- Autonomous Raiders and machines continue operating.

This preserves extraction-shooter risk.

If the existing game architecture requires a different approach, explain the tradeoff and request approval.

## 12.4 Spectator compatibility

Inventory input must not interfere with:

- Developer free camera.
- Actor-follow camera.
- Post-death spectator controls.
- Mission result screens.

Do not permit inventory transfers after authoritative player death unless the accepted gameplay explicitly supports them.

# 13. Looting interface

**Priority: Critical**

When interacting with a container or defeated actor, present a two-inventory interface.

Recommended layout:

```text
+------------------------------------------------------+
| LOOT                                                 |
+--------------------------+---------------------------+
| SOURCE                   | PLAYER CARGO              |
|                          |                           |
| Industrial Cabinet       | Cargo Bay                 |
|                          |                           |
| Control PCB x2           | Scrap Steel x5           |
| Copper Winding x4        | Industrial Sensor x1      |
| Power Module x1          |                           |
|                          |                           |
| [Take] [Take All]        | [Drop] [Transfer]         |
+--------------------------+---------------------------+
| Capacity / Weight / Item Information                 |
+------------------------------------------------------+
```

Requirements:

- Source and destination remain clearly identified.
- Transfers are validated.
- Partial transfers are supported.
- Capacity limits are visible.
- Empty source inventories update immediately.
- Closing the UI does not alter item ownership.
- UI cannot display stale contents as transferable.

# 14. Raider inventory integration

**Priority: Critical**

Autonomous Raiders must use the shared inventory and transfer architecture.

Preserve the existing AI personalities and objective-scoring framework.

Do not rewrite the Raider FSM.

## 14.1 Raider looting

Raiders should:

- Evaluate available loot using existing decision mechanisms.
- Approach valid loot locations.
- Collect items through authoritative transfers.
- Respect inventory capacity.
- Respect item availability.
- Stop attempting to collect depleted resources.
- Continue existing retreat and extraction behavior.

## 14.2 Loot value

The inventory system should expose information that AI can use, such as:

- Item value.
- Weight.
- Category.
- Quantity.
- Capacity cost.

Do not introduce a new personality system during this stage.

Where appropriate, adapt existing loot scoring to item-based data.

A Raider may value different items according to its accepted personality and objectives, but that behavior must remain consistent with existing AI architecture.

## 14.3 Raider death

When a Raider dies:

- Its inventory is settled exactly once.
- Droppable contents become recoverable world loot.
- Non-droppable or terminal items follow explicit rules.
- Existing death-flare behavior remains intact.
- Existing responder behavior remains intact.
- No duplicate items are created.
- Existing social AI relationships remain unaffected.

## 14.4 Raider extraction

When a Raider extracts:

- Carried items leave the active world according to the accepted extraction rules.
- Extracted quantities remain represented in the conservation ledger.
- World loot does not respawn.
- The same Raider cannot extract twice.
- The same inventory cannot be settled twice.

# 15. Player equipment and loadout

**Priority: High**

Introduce a basic loadout preparation flow.

The player should be able to select equipment from persistent storage before deployment.

The selected equipment becomes part of the deployed actor's authoritative inventory.

## 15.1 Equipment compatibility

Each equipment slot accepts only compatible items.

Invalid combinations must be rejected.

Examples:

- Weapon slot accepts weapons.
- Armor slot accepts armor modules.
- Power slot accepts compatible power modules.
- Mobility slot accepts compatible mobility modules.
- Utility slot accepts compatible utility modules.

## 15.2 Functional equipment

Do not introduce a broad equipment-stat system without approval.

Inspect the existing combat and movement architecture.

Where practical, support a limited number of demonstrable equipment effects through existing configuration points.

Any proposed changes to:

- Damage.
- Health.
- Movement speed.
- Jumping.
- Boosting.
- Weapon behavior.
- Energy consumption.

must be explicitly identified as gameplay changes in the architecture proposal.

A fully functional upgrade system is not required for Stage Z.

# 16. Persistent stash

**Priority: Critical**

Extend the accepted persistent stash rather than creating an unrelated storage system.

The stash should support:

- Item identity.
- Quantity.
- Unique equipment.
- Stack management.
- Equipment transfers.
- Loadout preparation.
- Save/load persistence.

## 16.1 Stash capacity

Propose whether stash capacity should be limited during Stage Z.

Recommended initial approach:

- Large or effectively unlimited stash.
- Limited deployment cargo.
- Limited equipment slots.

This keeps the first implementation focused on extraction decisions rather than base-storage management.

## 16.2 Persistence requirements

Save and restore:

- Stash contents.
- Unique item identities where required.
- Item quantities.
- Equipment state.
- Relevant item metadata.
- Schema version.

Validate loaded data.

Handle missing or obsolete item definitions gracefully.

Do not silently delete valuable player items.

# 17. Save migration and compatibility

**Priority: Critical**

Inspect the existing persistence format.

Provide a migration strategy for existing material counters and stored equipment.

Requirements:

- Existing accepted saves remain readable where feasible.
- Migration is versioned.
- Migration is idempotent.
- Repeated loading does not duplicate inventory.
- Unsupported data is reported.
- Corrupt or partial saves fail safely.
- Original save data is preserved until migration is verified.

Do not destructively overwrite the only copy of an existing save during development.

Use a backup or test-save strategy.

# 18. Extraction settlement

**Priority: Critical**

Successful extraction is the central transaction of the gameplay loop.

Define the exact boundary between:

- Active deployment inventory.
- Extracted inventory.
- Persistent stash.
- Deployment results.

## 18.1 Successful extraction

On accepted Recall Dock extraction:

1. Validate extraction eligibility.
2. Snapshot or resolve authoritative carried items.
3. Settle deployment results.
4. Transfer eligible items into persistent storage.
5. Record the settlement.
6. Prevent duplicate settlement.
7. Transition to results or preparation.

The order must be compatible with the existing mission controller.

## 18.2 Death or failed extraction

Define what happens to:

- Equipped items.
- Cargo items.
- Unique equipment.
- Mission items.
- Persistent stash items.

Recommended initial rule:

**Items brought into a deployment and items collected during it are at risk. Items already in the persistent stash remain safe.**

Do not introduce insurance or secure containers during this stage.

## 18.3 Settlement integrity

A deployment must not:

- Bank items twice.
- Lose items during a successful transaction.
- Retain deployment items after a failed settlement.
- Recreate already extracted loot.
- Corrupt persistent storage on restart.

Implement idempotent settlement using the existing deployment identity mechanism or a clearly justified equivalent.

# 19. Loot economy and value

**Priority: High**

Introduce a simple value model.

Each item should have a base value used for:

- Item comparison.
- Raider loot evaluation.
- Deployment results.
- Future trading and crafting foundations.

Do not implement a full marketplace.

Value should be centralized in item definitions or an accepted economy resource.

## 19.1 Weight versus value

Create meaningful choices.

Examples:

- Heavy common material with low value per kilogram.
- Lightweight electronics with high value.
- Rare equipment that occupies a slot but offers long-term utility.
- Valuable components that compete with mission-required cargo.

Do not make every item equally valuable per unit of capacity.

## 19.2 Initial balance

Use a compact item catalog and representative loot tables.

Balance should be sufficient to demonstrate:

- Inventory pressure.
- Valuable finds.
- Low-value filler.
- Equipment recovery.
- Extraction decisions.

Avoid premature economic complexity.

# 20. Loot generation and seeded simulation

**Priority: Critical**

Integrate with the accepted encounter and scenario seeding.

World loot must be generated predictably for a given scenario seed where the existing architecture requires reproducibility.

Requirements:

- Stable initial loot distribution.
- No regeneration on container reopening.
- No duplicate generation after restart within the same deployment.
- Deterministic inventory results for equivalent authoritative event sequences.
- Presentation randomness independent of gameplay RNG.

Separate:

- Scenario loot generation.
- Runtime item transfers.
- Cosmetic item presentation.

Do not consume gameplay RNG for UI effects, icon variation, or audio.

# 21. Resource conservation

**Priority: Critical**

Preserve and extend the finite-resource conservation tests.

The existing material conservation ledger must remain valid.

For each tracked item type, the authoritative accounting should distinguish:

- Initially generated world quantity.
- Current world quantity.
- Container-held quantity.
- Player-held quantity.
- Raider-held quantity.
- Dropped quantity.
- Extracted quantity.
- Explicitly consumed or destroyed quantity.

Avoid double-counting a dropped item as both actor inventory and world inventory.

## 21.1 Conservation invariant

For conserved items, the total across all authoritative active and terminal locations must equal the initial generated quantity plus explicitly authorized additions, minus explicitly authorized removals.

Track deployment-generated resources separately from items imported from persistent stash so the two populations are not confused.

## 21.2 Required edge cases

Test:

- Two Raiders collecting the same stack.
- Player collecting while a Raider approaches.
- Partial stack collection.
- Full inventory rejection.
- Weight-limit rejection.
- Death during a transfer.
- Extraction during a transfer.
- Container reopening.
- Repeated settlement.
- Restart during deployment.
- Save/load reconstruction.

# 22. Item and inventory UI presentation

**Priority: High**

Follow the accepted Stage W–Y visual direction.

Use a clean industrial interface appropriate to a machine-controlled extraction game.

Recommended presentation:

- Dark neutral panels.
- Restrained industrial accents.
- Clear item categories.
- Consistent icons.
- Readable quantities.
- Weight and slot indicators.
- Distinct equipment slots.
- Clear selected-item information.

Avoid excessive decorative complexity.

## 22.1 Item icons

Prefer:

- Simple generated icons.
- Existing project icon assets.
- Consistent silhouette-based item presentation.

Do not require detailed 3D models for every inventory item.

Use placeholder icons where necessary, but maintain consistent sizing and readability.

## 22.2 Accessibility

Ensure:

- Readable text.
- Sufficient contrast.
- Clear focus state.
- Clear disabled controls.
- Usable mouse interaction.
- No reliance on color alone to communicate item status.

# 23. World interaction

**Priority: High**

Integrate looting with the existing player interaction system.

Requirements:

- Valid interaction range.
- Clear target selection.
- Stable interaction prompts.
- No looting through invalid geometry.
- No interaction after death.
- No conflicting interactions with Recall Dock.
- No duplicated item collection.
- Correct behavior when a source disappears.

Do not rewrite the entire interaction architecture unless necessary.

# 24. Debugging and developer tools

**Priority: High**

Preserve existing debug and spectator systems.

Add useful inventory diagnostics where appropriate:

- Actor inventory contents.
- Container contents.
- Item ownership.
- Item transfer failures.
- Cargo weight.
- Occupied slots.
- Deployment settlement status.
- Conservation totals.

Avoid overwhelming the normal gameplay HUD.

Use developer-only inspection tools where practical.

# 25. Automated testing

**Priority: Critical**

Preserve the complete accepted regression suite.

Add dedicated inventory tests.

## 25.1 Item definition tests

- Stable identifiers.
- Valid item categories.
- Valid stack limits.
- Nonnegative weight.
- Valid equipment compatibility.
- Valid resource references.

## 25.2 Inventory tests

- Add and remove.
- Capacity.
- Weight limits.
- Stack merge.
- Stack split.
- Partial transfer.
- Unique item transfer.
- Equipment compatibility.
- Failed-operation atomicity.
- Repeated-operation safety.

## 25.3 World-loot tests

- World pickup.
- Container transfer.
- Empty-container behavior.
- Container reopening.
- Concurrent loot competition.
- Item-drop creation.
- No duplicate collection.

## 25.4 Raider tests

- Raider pickup.
- Inventory capacity.
- Loot preference integration.
- Death drops.
- Extraction settlement.
- Existing AI personality behavior.
- Social AI regression.

## 25.5 Player tests

- Inventory UI.
- Equipment slots.
- Looting UI.
- Item dropping.
- Recall Dock extraction.
- Death loss.
- Loadout preparation.
- Persistent stash.

## 25.6 Persistence tests

- Save/load round trip.
- Schema migration.
- Idempotent migration.
- Missing item definitions.
- Invalid save recovery.
- No duplicate settlement.

## 25.7 Full simulation tests

- Seeded deployment.
- Finite-resource conservation.
- Raider competition.
- Player extraction.
- Player death.
- Spectator transition.
- Mission restart.
- Multiple sequential deployments.

# 26. Manual acceptance

## A. Preparation

Open the persistent stash.

Equip a valid loadout.

Confirm cargo and equipment are displayed correctly.

## B. Deployment

Enter the mission with the selected loadout.

Verify equipment and inventory initialization.

## C. World pickup

Collect several item types.

Verify slot usage, weight, and stacking.

## D. Container looting

Open a searchable container.

Transfer some items.

Close and reopen it.

Verify remaining contents are preserved.

## E. Capacity limits

Fill cargo slots and approach the weight limit.

Verify transfer rejection and feedback.

## F. Raider competition

Observe Raiders collecting finite loot.

Verify collected items are no longer available to others.

## G. Raider death

Defeat a Raider.

Inspect and collect dropped equipment.

Verify no duplication.

## H. Successful extraction

Extract through the Recall Dock.

Verify carried items are banked exactly once.

## I. Failed extraction

Die with valuable items.

Verify the loss policy and persistent stash integrity.

## J. Repeated deployments

Prepare a second loadout using banked items.

Deploy again.

Verify persistence and ownership continuity.

## K. Spectator

Observe Raider inventory behavior after player death.

Verify spectator controls remain functional.

## L. Performance

Evaluate inventory UI and item generation under representative gameplay load.

# 27. Performance and complexity

**Priority: High**

Measure:

- Inventory operation cost.
- Item-instance count.
- Container count.
- UI refresh behavior.
- Save/load duration.
- Memory usage.
- World-loot node count.
- AI loot-evaluation cost.

Avoid rebuilding the entire inventory UI every frame.

Use event-driven updates where appropriate.

Do not instantiate complex 3D scenes for items that exist only as inventory data.

Keep inventory logic independent of rendering.

# 28. Stage Z acceptance criteria

Stage Z is complete when:

- A unified item-definition model exists.
- Item instances and stack quantities are represented consistently.
- Player and Raiders share authoritative inventory rules.
- Cargo slots and weight limits function.
- Dedicated equipment slots function.
- Inventory transfers are validated and atomic.
- World loot represents identifiable items.
- Searchable containers function.
- Raider death drops are recoverable.
- Raider extraction preserves accounting.
- Player inventory UI is usable.
- Looting UI is usable.
- Persistent stash supports items and equipment.
- Loadout preparation works.
- Successful extraction banks eligible items once.
- Failed extraction applies the approved loss policy.
- Existing saves are preserved or safely migrated.
- Seeded loot generation remains reproducible.
- Resource conservation tests pass.
- Existing AI, combat, mission, and spectator systems remain functional.
- Automated regression suites pass.
- Godot graphical and headless validation pass.
- A complete preparation → deployment → looting → extraction → stash cycle is demonstrated.
- The implementation and known limitations are documented.

# 29. Explicit exclusions

Do not implement:

- Full crafting trees.
- Merchant trading.
- Dynamic market prices.
- Base-building systems.
- Extensive equipment stat progression.
- Weapon modification systems.
- Armor durability simulation.
- Insurance.
- Secure containers.
- Multiplayer networking.
- Item trading between players.
- Procedural item affixes.
- Hundreds of item types.
- New Raider personalities.
- New combat systems.
- New maps.
- Major environment redesign.
- New mission architecture.

These belong to future stages.

# 30. Implementation workflow

## Step 1 — Inspect

Audit the repository and existing gameplay, salvage, persistence, and UI systems.

Run baseline validation.

## Step 2 — Propose

Prepare the complete Stage Z architecture proposal.

Include a clear migration strategy from the current salvage counters and equipment representations.

Identify all authoritative ownership boundaries.

Explain how Raider AI will use the shared item economy.

**STOP FOR DIRECTOR APPROVAL.**

## Step 3 — Item and inventory foundation

After approval:

- Implement item definitions.
- Implement item instances and stacks.
- Implement inventory containers.
- Implement validated transfers.
- Implement equipment compatibility.
- Add foundational tests.

## Step 4 — World loot and containers

- Adapt world salvage.
- Add searchable containers.
- Add dropped-item representation.
- Integrate player pickup.
- Validate finite-resource conservation.

## Step 5 — Raider integration

- Connect Raider loot collection.
- Respect inventory capacity.
- Preserve existing decision-making.
- Integrate death drops.
- Integrate Raider extraction.
- Run autonomous simulation tests.

## Step 6 — Player UI

- Implement inventory overlay.
- Implement looting interface.
- Implement equipment display.
- Implement item inspection.
- Implement transfer and drop controls.
- Validate input ownership.

## Step 7 — Stash and loadout

- Extend persistent storage.
- Implement loadout preparation.
- Integrate deployment initialization.
- Add safe persistence migration.

## Step 8 — Extraction and death settlement

- Integrate successful Recall Dock settlement.
- Implement approved loss policy.
- Verify idempotency.
- Verify conservation.

## Step 9 — Full integration validation

Run:

- Inventory unit tests.
- Existing regression suites.
- Seeded autonomous simulations.
- Save/load tests.
- Headless Godot validation.
- Forward+ graphical validation.
- Full player extraction loop.
- Failed extraction loop.
- Multiple sequential deployments.
- Spectator compatibility tests.

## Step 10 — Stage Z checkpoint

Deliver:

- Architecture summary.
- Implemented inventory data model.
- Item catalog.
- Ownership and transfer documentation.
- UI screenshots.
- Looting gameplay captures.
- Raider inventory integration results.
- Conservation test results.
- Persistence and migration results.
- Automated regression summary.
- Performance measurements.
- Known limitations.
- Manual acceptance checklist.
- Recommendations for the next stage.

Do not advance beyond Stage Z without director approval.

Do not commit, reset, discard, or publish repository changes without explicit authorization.

---

# 31. Critical design constraints

The following constraints take precedence over implementation convenience.

**A. Single authoritative ownership**

No item may exist in multiple authoritative inventories simultaneously.

**B. Shared inventory rules**

Player and Raiders use the same transfer and capacity mechanisms.

**C. Preserve existing AI**

Inventory integration must not replace the Raider decision architecture.

**D. Preserve finite salvage**

The new economy must maintain or strengthen existing conservation guarantees.

**E. Transactional transfers**

Failed transfers do not partially corrupt state.

**F. Idempotent settlement**

Extraction, death, and persistence cannot duplicate items.

**G. Safe migration**

Existing persistent data must not be destructively overwritten during development.

**H. Presentation separation**

UI, models, and animations observe inventory state; they do not own it.

**I. No uncontrolled scope expansion**

Crafting, trading, and extensive equipment upgrades remain future work.

**J. Director approval**

Repository inspection and architecture proposal must precede implementation.

---

# Immediate Codex assignment

Inspect the current SCRAP Raiders repository and accepted Stage Y implementation.

Identify all existing salvage, equipment, Raider inventory, extraction, persistent stash, and mission settlement systems.

Prepare a complete Stage Z architecture proposal for a hybrid extraction-shooter inventory system featuring:

- Dedicated robot equipment slots.
- Slot-based cargo inventory.
- Weight limits.
- Item definitions and instances.
- Stack management.
- Searchable world containers.
- Player looting interface.
- Shared Raider and player item-transfer authority.
- Raider death drops and extraction.
- Persistent stash and loadout preparation.
- Safe save migration.
- Successful extraction banking.
- Failed extraction item loss.
- Seeded loot generation.
- Finite-resource conservation.

Preserve the accepted autonomous simulation and all existing gameplay systems.

**Do not begin implementation until the architecture proposal has been reviewed and approved by the director.**