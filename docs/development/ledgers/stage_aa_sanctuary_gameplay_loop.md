# SCRAP Raiders — Stage AA Development Ledger

## The Sanctuary, Quick Deployment & Complete Gameplay Loop

**Project:** SCRAP Raiders  
**Studio:** BadRobot Studios — Engineering Bad Behavior  
**Engine:** Godot 4.7.2  
**Stage:** AA  
**Status:** Planned — begin after Stage Z acceptance  
**Prerequisite:** Accepted Stage Z hybrid inventory and extraction economy

**Development significance:** Final major AI-led foundation stage before director-led development.

---

# 1. Director's Development Directive

**PRIORITY: CRITICAL**

Stage AA marks the transition from constructing individual gameplay systems to delivering a complete, playable game.

The director intends to assume primary responsibility for development after Stage AA.

Codex must prioritize:

1. Completing the application lifecycle.
2. Establishing the sanctuary and deployment transitions.
3. Connecting existing gameplay systems.
4. Providing usable player-facing interaction points.
5. Preserving authoritative state and persistence.
6. Delivering maintainable, extensible architecture.
7. Producing a clean developer handoff.

**Functional completeness takes priority over extensive refinement.**

Do not spend substantial time perfecting decoration, animations, crafting depth, or UI polish before the complete gameplay loop works.

Do not introduce additional major systems beyond the approved Stage AA scope.

# 2. Core Game Vision

SCRAP Raiders consists of three interconnected experiences.

## 2.1 Sanctuary

A permanently safe, physically navigable home where the player can relax, organize equipment, dismantle salvage, upgrade systems, accept contracts, and customize their workshop.

## 2.2 Preparation

A shared set of inventory, loadout, fabrication, and mission-selection services accessible either from physical workshop stations or through direct interfaces.

## 2.3 Deployment

The existing hostile extraction environment containing autonomous Raiders, finite salvage, combat, objectives, and extraction.

**The extraction world is where the player survives. The sanctuary is where the player lives.**

# 3. Non-Negotiable Sanctuary Rules

**PRIORITY: CRITICAL**

The sanctuary is permanently safe.

There must be no:

- Raider invasions.
- Equipment theft.
- Base defense requirements.
- Mandatory maintenance.
- Upkeep timers.
- Passive equipment deterioration.
- Time pressure.
- Punishment for remaining at home.

The player may remain in the sanctuary indefinitely.

The sanctuary must never become another source of pressure.

# 4. Mandatory Repository Inspection

**PRIORITY: CRITICAL**

Inspect the accepted Stage Z repository before implementation.

Review:

- `project.godot` and the current main scene.
- `mission_arena.gd` and `raider_arena.gd`.
- Player controller, input, and camera.
- Existing mission and objective systems.
- InventoryLedger and transfer authority.
- PersistentStash and prepared loadout handling.
- Deployment escrow and settlement.
- EquipmentBinding and weapon compatibility.
- Existing inventory and loadout interfaces.
- Scene transitions and restart behavior.
- Save schema and migration.
- Environment assets and Blender pipeline.
- Automated regression suites.
- Existing architecture documentation.

The current architecture is arena-centered. Stage AA must introduce the necessary application-level lifecycle without unnecessarily moving gameplay responsibilities out of the arena.

Preserve the existing authoritative inventory, mission, combat, and AI systems.

# 5. Architecture Proposal & Approval Gate

**PRIORITY: CRITICAL**

Prepare an architecture proposal covering:

1. Application entry and title screen.
2. Game session and scene-transition ownership.
3. Sanctuary scene structure.
4. Player actor and camera reuse.
5. Shared station interaction framework.
6. Physical and quick-access navigation.
7. Shared preparation services.
8. Saved loadout templates.
9. Prepared kit ownership.
10. Direct-to-raid preparation.
11. Contract selection.
12. Deployment initialization.
13. Extraction settlement and return.
14. Salvage processing and upgrades.
15. Sanctuary customization.
16. Item displays.
17. Persistence and migration.
18. Automated testing.
19. Developer handoff architecture.
20. Exact proposed file changes.

Explain whether a session coordinator, scene manager, autoload, or another repository-consistent mechanism is appropriate.

Do not create a second authority for inventory, mission settlement, or progression.

**STOP FOR DIRECTOR APPROVAL BEFORE IMPLEMENTATION.**

# 6. Application Entry & Title Screen

**PRIORITY: CRITICAL**

Introduce a proper application entry experience.

The game must no longer require launching directly into an arena.

The title screen must provide:

- Enter Sanctuary.
- Quick Deploy.
- Settings.
- Quit.

Credits may be included if straightforward.

## 6.1 Enter Sanctuary

Loads the persistent sanctuary with the player's robot physically present.

The player may explore, customize, manage equipment, accept contracts, and deploy.

## 6.2 Quick Deploy

Opens a direct preparation interface without requiring the player to navigate the physical sanctuary.

The player can:

- Select a contract or available deployment.
- Choose a saved loadout template.
- Select an existing prepared kit.
- Build or modify a loadout manually.
- Review equipment availability.
- Confirm readiness.
- Begin deployment.

Quick Deploy must use the same authoritative inventory and deployment systems as sanctuary preparation.

**Do not duplicate loadout, crafting, or mission logic for the Quick Deploy interface.**

## 6.3 Entry-path equivalence

Both entry paths must produce equivalent gameplay outcomes for equivalent player choices.

Quick Deploy may bypass physical navigation but must not bypass inventory validation, crafting costs, equipment restrictions, or progression.

# 7. Game Session & Scene Lifecycle

**PRIORITY: CRITICAL**

Establish a reliable lifecycle:

Title Screen → Sanctuary or Quick Preparation → Deployment → Results → Sanctuary.

The session-level system should coordinate transitions.

The arena must remain responsible for its own:

- Actor simulation.
- Raider AI.
- Combat.
- World loot.
- Mission rules.
- Deployment-specific inventory.
- Extraction behavior.

The persistent systems must remain authoritative for durable player progression.

## 7.1 Transition requirements

- No duplicated inventory.
- No lost prepared equipment.
- No repeated settlement.
- No stale arena references.
- No leaked event subscriptions.
- No active deployment simulation while in sanctuary.
- No accidental reset of persistent progression.
- Safe recovery from failed scene initialization.

## 7.2 Return behavior

After successful or failed extraction, the player returns to the sanctuary.

The results screen may appear before the transition.

The player must be able to prepare and deploy again without restarting the application.

# 8. Sanctuary Environment

**PRIORITY: HIGH**

Create a modest industrial robot workshop.

Required areas:

- Storage.
- Robot maintenance.
- Fabrication.
- Salvage disassembly.
- Operations/contracts.
- Deployment.
- Equipment displays.
- Limited customizable floor space.

Reuse accepted industrial environment assets where appropriate.

The sanctuary should feel safe, functional, quiet, and personal.

Avoid extensive environmental decoration before the playable loop is complete.

# 9. Elevated Third-Person Camera

**PRIORITY: HIGH**

Use an elevated third-person, top-downish perspective inspired by Helldivers 1.

Prototype an approximately 40–55-degree downward camera angle.

Requirements:

- Comfortable movement.
- Clear environmental visibility.
- Camera following.
- Useful zoom.
- Collision handling.
- Station interaction transitions.
- Placement-mode compatibility.

Reuse the existing robot controller where practical.

Disable combat behavior in the sanctuary.

Camera usability takes priority over strict visual imitation.

# 10. Shared Workshop Station Framework

**PRIORITY: CRITICAL**

Implement a common station interface and registry.

Required stations:

- Storage.
- Maintenance.
- Fabrication.
- Disassembly.
- Contracts.
- Deployment.

Each station exposes:

- Stable identifier.
- Display name.
- World position.
- Safe interaction anchor.
- Availability state.
- Context interface.
- Interaction entry point.
- Progression requirements.

## 10.1 Physical interaction

The player walks to a station and interacts normally.

## 10.2 Quick navigation

The player selects a station from a navigation menu.

The system validates availability, moves the robot to a safe interaction anchor, and opens the same station interface.

## 10.3 Shared authority

**Physical and quick-access interaction must invoke identical operations.**

No separate inventory mutations, crafting logic, or progression rules.

Closing a station interface returns the player to normal sanctuary navigation at that station.

# 11. Saved Loadout Templates

**PRIORITY: CRITICAL**

Introduce reusable player-defined loadout templates.

A template describes a desired equipment configuration.

It does not automatically reserve or consume inventory.

The player may create, rename, edit, duplicate, and delete templates.

Templates should support:

- Primary weapon.
- Armor.
- Power module.
- Mobility module.
- Utility module.
- Cargo items.
- Consumable quantities where supported.
- Optional descriptive name.

Examples:

- Scavenger.
- Heavy Combat.
- Balanced.
- Lightweight Recovery.
- High-Value Extraction.

These are examples only. Players must be able to name templates freely.

## 11.1 Template persistence

Templates must survive application restart.

Use stable item-definition identifiers.

A template must remain distinguishable from actual owned item instances.

Missing or obsolete item definitions must be reported safely.

# 12. Prepared Kits

**PRIORITY: HIGH**

Distinguish loadout templates from prepared kits.

**Template:** Desired equipment configuration; no item reservation.

**Prepared kit:** Actual owned items allocated to a ready-to-deploy configuration.

Prepared kits must respect Stage Z ownership rules.

An item assigned to a prepared kit cannot simultaneously be available for unrelated transfers or another prepared kit.

## 12.1 Initial implementation

Implement at least one-action preparation from a saved template using available stash items.

Support selection and deployment of a prepared configuration.

If multiple simultaneously reserved kits require substantial additional persistence architecture, document the proposed design and defer the full feature until after the director handoff.

Do not compromise item ownership to support multiple kits prematurely.

# 13. Loadout Validation

**PRIORITY: CRITICAL**

Selecting a template must evaluate:

- Owned equipment.
- Available stash items.
- Equipment compatibility.
- Required quantities.
- Cargo slot limits.
- Cargo weight limits.
- Existing reservations.
- Missing definitions.
- Progression restrictions.

Provide clear status:

- Ready.
- Partially available.
- Craftable.
- Unavailable.

Do not silently replace missing equipment with alternatives.

## 13.1 Missing-item feedback

Display:

- Required item.
- Available quantity.
- Missing quantity.
- Whether fabrication is possible.
- Relevant material shortages.

An unavailable item must not simply disappear from the loadout interface.

# 14. On-Demand Kit Fabrication

**PRIORITY: ARCHITECTURAL FOUNDATION IN AA**

Design the preparation system to support fabricating missing kit components from available materials.

The complete automatic fabrication workflow may be implemented after the handoff.

## 14.1 Required planning architecture

A fabrication planner should be able to:

1. Read a loadout template.
2. Compare it with available inventory.
3. Identify missing items.
4. Resolve supported fabrication recipes.
5. Calculate aggregate material requirements.
6. Account for shared ingredients.
7. Identify shortages.
8. Produce a non-mutating preparation preview.

The planner must not consume materials while evaluating a template.

## 14.2 Future execution

When implemented, automatic fabrication must:

- Require explicit player confirmation.
- Revalidate inventory before committing.
- Use authoritative item-transfer and crafting operations.
- Avoid partial resource loss.
- Avoid duplicate equipment creation.
- Report failure clearly.

Do not silently craft items merely because a template is selected.

## 14.3 Scope boundary

Do not allow a sophisticated crafting planner to delay the first playable loop.

The Stage AA requirement is a compatible architectural foundation and clear loadout availability reporting.

Full automatic fabrication may remain documented future work.

# 15. Storage & Equipment Preparation

**PRIORITY: CRITICAL**

Connect the sanctuary storage station and Quick Deploy interface to the accepted Stage Z persistent stash.

Required operations:

- Inspect stash.
- Transfer equipment.
- Equip compatible items.
- Prepare cargo.
- Select saved templates.
- Apply available loadout items.
- Inspect missing equipment.
- Review total carried weight.

All operations must use the accepted authoritative inventory system.

Raider weapons that are intended to be player-compatible must remain available through normal loadout preparation.

Do not create cosmetic-only equipment changes.

# 16. Contracts & Mission Selection

**PRIORITY: CRITICAL**

The player must be able to review and accept available contracts through:

- The physical operations terminal.
- Quick Deploy preparation.

Both interfaces use the same mission-selection authority.

Support existing objective types and progression.

Do not introduce an unrelated quest framework.

# 17. Deployment Initialization

**PRIORITY: CRITICAL**

Deployment must:

1. Validate the selected contract.
2. Validate equipment.
3. Validate inventory ownership.
4. Validate cargo capacity.
5. Commit the prepared loadout using accepted durable rules.
6. Initialize the extraction world.
7. Spawn the player with the correct equipment.
8. Activate the deployment simulation.

A failed initialization must not consume or duplicate items.

# 18. Extraction & Return Home

**PRIORITY: CRITICAL**

Successful extraction must:

- Complete authoritative settlement.
- Bank eligible recovered items.
- Apply contract progression.
- Prevent duplicate receipts.
- Present results.
- Return to sanctuary.

Failed extraction must:

- Apply accepted item-loss rules.
- Preserve safe stash items.
- Prevent repeated forfeiture.
- Present results.
- Return to sanctuary.

**The complete lifecycle must function repeatedly without application restart.**

# 19. Mandatory Early Playable Checkpoint

**PRIORITY: HIGHEST IMPLEMENTATION MILESTONE**

Before extensive customization, fabrication depth, or decorative polish, deliver:

- Working title screen.
- Enter Sanctuary.
- Quick Deploy.
- Navigable sanctuary.
- Physical station interaction.
- Quick station navigation.
- Persistent stash access.
- Saved loadout template selection.
- Basic loadout preparation.
- Contract selection.
- Deployment.
- Existing extraction gameplay.
- Successful extraction return.
- Failed extraction return.
- Persistent results.
- Repeated deployment capability.

**STOP FOR DIRECTOR PLAYTEST APPROVAL.**

Do not automatically proceed to advanced sanctuary features.

# 20. Salvage Disassembly

**PRIORITY: HIGH — AFTER PLAYABLE CHECKPOINT**

Implement a small deterministic disassembly system.

Each recipe specifies inputs and outputs.

Requirements:

- Authoritative resource consumption.
- Atomic transactions.
- Validated output destinations.
- Persistent results.
- Conservation accounting.
- Clear player feedback.

Use a small number of recipes.

# 21. Fabrication & Functional Upgrades

**PRIORITY: HIGH — AFTER PLAYABLE CHECKPOINT**

Implement a minimal functional progression foundation.

At least one meaningful upgrade must be available.

Potential examples:

- Cargo capacity improvement.
- Utility module fabrication.
- Workshop storage improvement.
- Equipment module upgrade.

Use existing item and progression systems.

Avoid extensive crafting trees.

# 22. Sanctuary Customization

**PRIORITY: HIGH — AFTER PLAYABLE CHECKPOINT**

Implement a constrained placement system.

Minimum operations:

- Select object.
- Enter placement mode.
- Move.
- Rotate.
- Validate.
- Confirm.
- Cancel.
- Save.
- Reload.

Prevent furniture from blocking required station anchors or player navigation.

Begin with a small selection of placeable objects.

Functional progression must remain independent of spatial arrangement.

# 23. Physical Item Displays

**PRIORITY: HIGH**

Implement at least one functional item display.

Support:

- Assign owned item.
- Inspect item.
- Remove item.
- Return item to available storage.
- Persist display assignment.

**Displayed items must preserve authoritative ownership and identity.**

Do not duplicate inventory to create display objects.

# 24. Sanctuary Persistence

**PRIORITY: CRITICAL**

Persist:

- Station unlocks.
- Functional upgrades.
- Furniture positions.
- Furniture rotations.
- Display assignments.
- Saved loadout templates.
- Prepared kit state where implemented.

Reuse existing persistence infrastructure.

Use versioned schemas and safe migration.

Do not duplicate stash ownership.

# 25. Visual & Interaction Consistency

**PRIORITY: HIGH**

Reuse the accepted Stage Z UI design language.

Title screen, sanctuary stations, loadout manager, Quick Deploy, and inventory interfaces must appear to belong to the same game.

Use shared:

- Typography.
- Colors.
- Panel styles.
- Buttons.
- Item slots.
- Tooltips.
- Focus states.
- Context menus.
- Equipment icons.

Do not independently invent a new visual style for every screen.

Require graphical screenshots and director review for representative interfaces.

Functional tests do not constitute visual approval.

# 26. Testing & Regression

**PRIORITY: CRITICAL**

Preserve all accepted regression suites.

Add coverage for:

### Application lifecycle

- Title screen loading.
- Enter Sanctuary.
- Quick Deploy.
- Scene transitions.
- Return after extraction.
- Return after death.
- Repeated deployments.

### Loadouts

- Template creation.
- Template editing.
- Template deletion.
- Template persistence.
- Missing-item reporting.
- Equipment compatibility.
- Weight and slot validation.
- One-action preparation.
- Prepared kit ownership.
- No duplicate reservations.

### Preparation paths

- Sanctuary preparation.
- Quick Deploy preparation.
- Equivalent inventory outcomes.
- Equivalent contract selection.
- Equivalent deployment initialization.

### Inventory integrity

- No duplicate ownership.
- No repeated settlement.
- No partial escrow corruption.
- No item loss during failed initialization.
- Safe save/load reconstruction.

### Sanctuary

- Physical station interaction.
- Quick station navigation.
- Safe arrival anchors.
- Disassembly.
- Fabrication.
- Upgrades.
- Furniture placement.
- Item displays.
- Persistent layout.

### Full gameplay

- Multiple consecutive deployments.
- Successful extraction.
- Failed extraction.
- Raider inventory conservation.
- Mission objective settlement.
- Spectator compatibility.

Run both headless and graphical Godot validation.

# 27. Implementation Sequence

**AA-1 — Application Entry**

- Title screen.
- Session coordinator.
- Scene transition foundation.

**AA-2 — Sanctuary Foundation**

- Environment.
- Player.
- Elevated camera.
- Safe-state enforcement.

**AA-3 — Station Framework**

- Shared station interface.
- Registry.
- Physical interaction.
- Quick navigation.

**AA-4 — Preparation & Loadouts**

- Storage integration.
- Saved loadout templates.
- Loadout validation.
- Basic one-action preparation.
- Contract selection.
- Quick Deploy interface.

**AA-5 — Complete Gameplay Loop**

- Deployment initialization.
- Extraction settlement.
- Results.
- Return to sanctuary.
- Repeated deployments.

**MANDATORY DIRECTOR PLAYTEST CHECKPOINT.**

**AA-6 — Salvage & Progression**

- Disassembly.
- Minimal fabrication.
- Functional upgrades.

**AA-7 — Customization**

- Furniture placement.
- Persistent layout.
- Physical item display.

**AA-8 — Atmosphere & Usability**

- Lighting.
- Audio.
- Camera tuning.
- Shared UI consistency.
- Navigation improvements.

**AA-9 — Final Validation & Developer Handoff**

- Regression.
- Persistence.
- Performance.
- Documentation.
- Director acceptance.

# 28. Explicit Exclusions

Do not implement:

- Base invasions.
- Base defense.
- Mandatory chores.
- Upkeep timers.
- Extensive crafting trees.
- Dynamic markets.
- Multiplayer.
- Large-scale structural construction.
- Complex furniture physics.
- New extraction maps.
- Major Raider AI rewrites.
- Hundreds of item definitions.
- Advanced weapon modification.
- Full automatic kit fabrication if it threatens the AA schedule.
- Unrelated feature expansion.

# 29. Developer Handoff Requirements

**PRIORITY: CRITICAL — FINAL CODEX-LED DEVELOPMENT CHECKPOINT**

Stage AA must conclude with a maintainable project suitable for director-led development.

Update the existing architecture document rather than replacing it with unrelated documentation.

The handoff must include:

## 29.1 Architecture map

Document:

- Application entry.
- Scene transitions.
- Sanctuary ownership.
- Deployment ownership.
- Persistent services.
- Inventory ownership.
- Station registry.
- Loadout templates.
- Prepared kit handling.
- Mission lifecycle.
- Save/load boundaries.

## 29.2 Extension guides

Provide concise instructions for:

- Adding a new item.
- Adding a weapon.
- Adding a workshop station.
- Adding a fabrication recipe.
- Adding a loadout-compatible equipment type.
- Adding a contract.
- Adding a placeable object.
- Adding a displayable item.
- Modifying Raider behavior.
- Running automated tests.

## 29.3 Technical debt register

Identify:

- Known architectural limitations.
- Temporary implementations.
- Incomplete features.
- Duplicated or fragile logic.
- Unresolved UI issues.
- Performance concerns.
- Recommended future refactoring.

Clearly distinguish verified problems from speculative improvements.

## 29.4 Repository maintenance

Review obsolete scripts, generated artifacts, temporary tests, and unused resources.

Preserve active regression tests.

Do not delete files based solely on naming or apparent lack of direct references.

Do not commit, reset, discard, or publish changes without director authorization.

## 29.5 Final handoff

Provide:

- Complete test results.
- Working gameplay demonstration.
- Known limitations.
- Updated architecture documentation.
- Development workflow instructions.
- Recommended first director-owned tasks.

**Do not automatically begin Stage AB or any additional major development stage.**

# 30. Final Acceptance Criteria

Stage AA is complete when:

- The title screen works.
- Enter Sanctuary works.
- Quick Deploy works.
- The sanctuary is permanently safe.
- The player can physically navigate the sanctuary.
- The elevated camera is usable.
- Physical station interaction works.
- Quick station navigation works.
- Both methods use shared gameplay services.
- Saved loadout templates work.
- Basic one-action kit preparation works.
- Missing equipment is reported clearly.
- Equipment ownership remains correct.
- Contracts can be selected.
- Deployment initializes correctly.
- Successful extraction returns home.
- Failed extraction returns home.
- Multiple consecutive deployments work.
- A minimal disassembly system works.
- At least one functional upgrade works.
- Furniture placement and persistence work.
- At least one real item can be displayed.
- Save/load remains reliable.
- Existing AI, combat, inventory, missions, and spectator systems remain functional.
- Automated regression tests pass.
- Graphical validation passes.
- The architecture documentation is updated.
- The developer handoff is complete.
- The director has accepted the final implementation.

# 31. Final Director Instruction

**Stage AA is the final major AI-led foundation stage.**

Its purpose is to establish a complete, maintainable, playable game that the director can personally develop and refine.

Codex should prioritize:

- Reliable foundations.
- Complete lifecycle.
- Functional interaction points.
- Extensible systems.
- Clean documentation.
- Automated validation.

Codex should not prioritize:

- Excessive polish.
- Speculative systems.
- Unrequested mechanics.
- Unnecessary abstraction.
- Large content expansion.
- Autonomous continuation into future stages.

**The goal is not to finish SCRAP Raiders. The goal is to deliver a functioning game foundation that the director can confidently take over.**

---

# Immediate Codex Assignment

After Stage Z acceptance:

Inspect the repository and current architecture documentation.

Prepare a Stage AA architecture proposal covering the title screen, sanctuary, Quick Deploy, shared preparation services, saved loadout templates, prepared kits, station interactions, deployment lifecycle, extraction return, minimal progression, customization, and persistence.

Identify the shortest reliable path to the complete playable loop.

**Stop after the architecture proposal and await director approval.**

After approval, implement in the prescribed sequence.

**Stop after AA-5 for mandatory director playtesting.**

After approval to continue, complete the remaining approved Stage AA scope and produce the final developer handoff.

**Do not begin another major development stage without explicit director authorization.**