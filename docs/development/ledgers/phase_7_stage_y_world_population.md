# SCRAP Raiders — Stage Y Development Ledger

## World Population & Environmental Storytelling

**Project:** SCRAP Raiders  
**Studio:** BadRobot Studios — Engineering Bad Behavior  
**Engine:** Godot 4.7.2  
**Stage:** Y  
**Status:** Proposed — architecture and environmental design approval required  
**Prerequisites:** Accepted Stages U, V, W, and X

---

## 1. Project context

SCRAP Raiders is a third-person extraction shooter in which the player controls an autonomous machine competing against human Raiders for finite salvage.

The accepted project includes:

- Independent Raider decision-making and personality profiles.
- Raider relationships, cooperation, rivalry, and betrayal.
- Player, Raider, and autonomous-machine combat.
- Finite salvage, extraction, and persistent deployment settlement.
- Seeded encounters and autonomous world activity.
- Developer and post-death spectator systems.
- Expanded industrial salvage environment.
- Modular Blender-to-Godot environment asset pipeline.
- Original character and machine models, rigs, and animations.
- Combat effects, spatial audio, and environmental atmosphere.

Stage Y focuses on environmental composition, world identity, and readable gameplay geography.

The repository and accepted Stage X completion report are authoritative.

Do not assume every proposed feature from previous stages was implemented. Inspect the actual project before planning modifications.

## 2. Primary objective

Transform the expanded salvage environment from a functional gameplay space into a believable industrial facility.

Establish:

1. Distinct environmental identities for major areas.
2. Plausible industrial equipment and material flow.
3. Purposeful placement of reusable environmental assets.
4. Visual landmarks supporting navigation.
5. Environmental storytelling through static details.
6. Clear visual relationships between salvage and surrounding equipment.
7. Consistent signage, markings, and facility identity.
8. Performance-conscious world population.

**The stage must preserve existing gameplay geometry, AI navigation, encounter behavior, and finite-resource authority.**

## 3. Design philosophy

**Priority: Critical**

The industrial complex should communicate a plausible operational history.

Every major area should answer three questions:

- What was this area originally used for?
- What equipment and infrastructure supported that purpose?
- What happened here before the current scavenging activity?

Avoid random decorative clutter.

Environmental detail should be organized according to functional purpose.

A believable industrial environment does not require every machine to operate, but its layout should suggest how the facility once functioned.

### Environmental storytelling

Use static environmental evidence such as:

- Abandoned maintenance work.
- Damaged processing equipment.
- Interrupted material handling.
- Improvised repairs.
- Emergency shutdown conditions.
- Partially dismantled machinery.
- Looted storage areas.
- Disconnected electrical equipment.
- Failed containment or material handling.
- Evidence of previous scavenging.

Do not introduce a fully scripted narrative campaign.

Environmental storytelling should remain observational and compatible with the emergent simulation.

## 4. Stage U–X environment audit

**Priority: Critical**

Inspect the accepted expanded environment.

Identify:

- Existing level dimensions.
- Gameplay collision.
- Navigation meshes and agents.
- Cover points.
- Raider spawn locations.
- Machine spawn locations.
- Extraction locations.
- Recall Dock.
- Salvage positions.
- Encounter layouts.
- Environmental asset instances.
- Lighting and atmosphere.
- Audio emitters.
- Existing signs and landmarks.
- Current visual density.
- Rendering and memory baselines.

Determine which existing assets can be reused.

Identify areas that are visually incomplete or inconsistent.

Document the current environment before proposing changes.

## 5. Environmental zones

**Priority: Critical**

Preserve the existing world geography and gameplay contracts.

Use the accepted Stage U area structure where applicable.

### Zone A — Central salvage yard

**Purpose:** Primary outdoor material recovery and equipment staging.

Suggested features:

- Sorted scrap piles.
- Industrial salvage bins.
- Damaged equipment.
- Loading equipment.
- Material staging lanes.
- Stacked pallets.
- Temporary barriers.
- Marked vehicle routes.
- Partially dismantled machinery.

The yard should communicate active competition over limited salvage.

Preserve visibility and combat routes.

Do not fill the entire area with obstructive props.

### Zone B — Processing facility

**Purpose:** Mechanical processing and material sorting.

Suggested features:

- Conveyor systems.
- Sorting stations.
- Machine enclosures.
- Maintenance platforms.
- Electrical control cabinets.
- Cable trays.
- Utility piping.
- Machine guarding.
- Emergency-stop stations.
- Material input and output areas.

Use a plausible process flow.

For example:

```text
Material receiving
       |
       v
Input conveyor
       |
       v
Sorting / processing
       |
       v
Output collection
       |
       v
Shipping or storage
```

The equipment does not need to function during Stage Y.

However, its placement should make mechanical and operational sense.

### Zone C — Shipping and storage

**Purpose:** Storage and transfer of processed material and equipment.

Suggested features:

- Pallet racking.
- Freight containers.
- Loading docks.
- Crates.
- Forklift lanes.
- Shipping labels.
- Material inventory markings.
- Damaged storage areas.
- Empty equipment pallets.

Create recognizable storage aisles and staging areas.

Preserve navigable pathways and existing encounter routes.

### Zone D — Service and perimeter

**Purpose:** Facility support and utility infrastructure.

Suggested features:

- Electrical distribution.
- Transformer or switchgear enclosures.
- Ventilation equipment.
- Utility piping.
- Maintenance access.
- Fencing.
- Security checkpoints.
- Emergency access routes.
- Damaged service equipment.

Use infrastructure to visually connect major zones.

Do not add interactive doors, security systems, or hazards during this stage.

## 6. Industrial plausibility

**Priority: High**

Use realistic industrial design principles when placing equipment.

Consider:

- Material input and output.
- Operator access.
- Maintenance clearance.
- Equipment guarding.
- Electrical distribution.
- Service routing.
- Vehicle circulation.
- Storage accessibility.
- Load-bearing structures.
- Equipment foundations.

The environment should not require exact engineering compliance, but obvious contradictions should be avoided.

Examples of undesirable placement:

- Conveyor systems that lead nowhere.
- Electrical cabinets inaccessible behind permanent obstacles.
- Forklift routes blocked by fixed machinery.
- Unsupported heavy equipment.
- Pipes terminating arbitrarily.
- Machine guarding that prevents all access.
- Storage racks positioned without loading clearance.

Prefer functional coherence over visual complexity.

## 7. Modular asset expansion

**Priority: Critical**

Extend the accepted Stage V Blender-to-Godot pipeline.

Do not establish a competing asset workflow.

Prioritize reusable modular assets.

### Recommended asset families

**Structural**

- Columns.
- Beams.
- Platforms.
- Guardrails.
- Stairs.
- Ramps.
- Concrete barriers.

**Processing**

- Conveyor sections.
- Sorting tables.
- Machine enclosures.
- Hoppers.
- Industrial bins.
- Equipment bases.

**Electrical**

- Control cabinets.
- Disconnect enclosures.
- Cable trays.
- Conduit.
- Junction boxes.
- Industrial lighting fixtures.

**Storage**

- Pallets.
- Crates.
- Racks.
- Containers.
- Storage cages.
- Material bins.

**Environmental detail**

- Signs.
- Floor markings.
- Safety labels.
- Equipment identification.
- Warning tape.
- Scrap fragments.
- Maintenance tools.

Reuse existing models before generating duplicates.

Keep editable Blender source files and reproducible exports.

## 8. Prop placement architecture

**Priority: Critical**

Separate environmental presentation from authoritative gameplay geometry.

The accepted collision and navigation structure must remain intact unless a specific change is reviewed and approved.

### Recommended separation

```text
World
 |
 +-- Gameplay Geometry
 |    +-- Collision
 |    +-- Navigation
 |    +-- Cover
 |    +-- Spawn Contracts
 |
 +-- Environmental Presentation
      +-- Structural Visuals
      +-- Machinery
      +-- Storage Props
      +-- Decals / Markings
      +-- Ambient Effects
```

Adapt this organization to the actual scene structure.

Do not duplicate collision shapes merely because a decorative model contains geometry.

For decorative props that overlap navigable space, resolve the conflict deliberately.

A visually solid obstacle must not silently permit actors to walk through it.

If a proposed asset requires changing collision or navigation, identify it as a gameplay-affecting change and request approval.

## 9. Environmental density and traversal

**Priority: Critical**

Maintain clear movement and combat routes.

Evaluate the environment from:

- Player third-person camera.
- Raider navigation.
- Ground-machine navigation.
- Flying-scout traversal.
- Free spectator camera.
- Actor-follow spectator camera.

Preserve:

- Primary movement corridors.
- Alternative routes.
- Existing cover.
- Extraction approaches.
- Salvage access.
- Line-of-sight relationships.
- Machine patrol routes.

Avoid excessive clutter that creates accidental bottlenecks.

The environment should feel populated without becoming difficult to navigate.

## 10. Salvage presentation

**Priority: Critical**

Improve the visual relationship between recoverable materials and the environment.

Examples:

- Components near dismantled machinery.
- Electronics near control equipment.
- Industrial materials in storage bins.
- Mechanical parts near maintenance stations.
- Salvage near damaged processing equipment.

**Do not change the authoritative salvage ledger.**

Existing finite salvage counts, identifiers, ownership, collection, and settlement remain unchanged.

Decorative scrap must be distinguishable from collectible salvage.

Do not accidentally create the appearance of recoverable items that cannot be interacted with unless that distinction is visually clear.

Preserve existing seeded salvage placement and scenario contracts.

## 11. Environmental landmarks

**Priority: High**

Establish recognizable landmarks in each major area.

Examples:

- Large processing tower.
- Distinctive conveyor assembly.
- Collapsed storage rack.
- Tall utility structure.
- Damaged loading crane.
- Identifiable shipping container cluster.
- Facility entrance signage.

Landmarks should help players orient themselves without relying entirely on HUD markers.

Use a restrained number of prominent structures.

Do not block established sightlines without evaluation.

## 12. Signage and facility identity

**Priority: High**

Create a consistent fictional facility identity.

Possible elements:

- Facility name.
- Area designations.
- Equipment numbers.
- Safety warnings.
- Material labels.
- Directional signage.
- Maintenance notices.
- Shipping identifiers.

Use coherent naming conventions.

For example:

```text
PROCESSING / P-01
SORTING / S-02
STORAGE / WH-03
UTILITY / U-04
```

These are examples, not mandatory final identifiers.

The signage system should help distinguish areas.

Avoid excessive text that is unreadable at normal gameplay distance.

Do not reuse real company branding without authorization.

## 13. Environmental storytelling vignettes

**Priority: High**

Create a small number of deliberate environmental scenes.

Suggested vignettes:

### A. Interrupted maintenance

An open electrical enclosure, tools, disconnected components, and partially repaired machinery.

### B. Failed processing operation

Material accumulated around a damaged conveyor or sorting station.

### C. Abandoned shipping

Partially loaded pallets, damaged crates, and incomplete shipment preparation.

### D. Previous scavenging

Stripped equipment, empty storage bins, and discarded components.

Each vignette should communicate a clear idea visually.

Avoid requiring written exposition to understand the scene.

Do not introduce scripted events or additional collectible items.

## 14. Lighting and atmosphere integration

**Priority: High**

Preserve accepted Stage X lighting and audio architecture.

Use lighting to reinforce zone identity.

Examples:

- Processing: industrial task lighting.
- Storage: overhead warehouse lighting.
- Yard: broad outdoor illumination.
- Service: localized utility lighting.

Preserve gameplay readability.

Do not create excessive darkness or atmospheric obstruction.

New ambient emitters should use the accepted audio system.

Avoid duplicated ambience and unnecessary light sources.

## 15. Materials and visual consistency

**Priority: High**

Reuse the Stage V material library and Stage X presentation conventions.

Recommended material families:

- Painted steel.
- Galvanized steel.
- Concrete.
- Weathered metal.
- Rubber.
- Industrial polymer.
- Glass.
- Safety markings.

Use restrained color coding.

Maintain visual consistency between buildings, props, Raiders, and machines.

Avoid introducing unrelated art styles.

## 16. Performance and asset reuse

**Priority: Critical**

Evaluate:

- Draw calls.
- Triangle counts.
- Material count.
- Texture memory.
- Shadow casters.
- Visibility and occlusion.
- Instance counts.
- Loading time.
- Frame-time impact.
- Memory usage.

Prefer shared meshes and materials.

Consider MultiMeshInstance3D for genuinely repeated, noninteractive details where appropriate.

Do not use MultiMesh indiscriminately for objects requiring independent behavior or visibility control.

Avoid excessive unique Blender exports.

Establish practical asset budgets based on the actual Stage X performance baseline.

## 17. Seeded layout compatibility

**Priority: Critical**

Preserve accepted Stage U layout variation and Stage P encounter seeding.

Verify environmental presentation across all supported layouts.

Decorative objects must not:

- Block alternate spawn positions.
- Cover salvage.
- Obstruct extraction.
- Interfere with Recall Dock access.
- Create unintended navigation barriers.
- Hide encounter-critical information.

If visual variants are introduced, keep them independent of gameplay RNG.

Do not consume authoritative simulation randomness for decorative variation.

## 18. Inspection and debugging

**Priority: High**

Preserve the Stage W actor inspection environment and Stage X presentation tests.

Provide practical environment inspection capabilities using existing developer tools where possible.

Useful capabilities:

- Free-camera inspection.
- Zone identification.
- Navigation overlay.
- Collision visualization.
- Lighting inspection.
- Performance monitoring.
- Layout variant selection.

Do not create a complex new editor tool unless necessary.

Prefer using Godot's existing debug and editor facilities.

## 19. Automated validation

Preserve all accepted regression suites.

Add or extend tests for:

1. Environment asset import.
2. Scene resource integrity.
3. Missing model detection.
4. Material reference validity.
5. Spawn-point accessibility.
6. Salvage accessibility.
7. Extraction accessibility.
8. Recall Dock accessibility.
9. Navigation compatibility.
10. Layout variant compatibility.
11. Existing collision integrity.
12. Cover-point integrity.
13. Mission restart.
14. Spectator compatibility.
15. Seeded simulation stability.
16. Finite-resource conservation.
17. Headless execution.
18. Forward+ graphical startup.

Tests should focus on meaningful gameplay contracts rather than arbitrary scene-tree structure.

## 20. Manual acceptance

### A. Central salvage yard

Inspect the yard from player and spectator perspectives.

Verify meaningful visual composition and clear movement routes.

### B. Processing facility

Evaluate equipment arrangement, process flow, maintenance access, and gameplay visibility.

### C. Shipping and storage

Verify coherent material staging and navigable storage areas.

### D. Service infrastructure

Evaluate utility routing, maintenance areas, and environmental consistency.

### E. Salvage

Confirm collectible salvage is recognizable and accessible.

### F. Raider simulation

Observe autonomous Raiders scavenging, fighting, retreating, and extracting.

Verify no new navigation or visibility problems.

### G. Machines

Observe ground and flying machines navigating the populated world.

### H. Layout variants

Inspect every accepted layout configuration.

### I. Spectator

Inspect the entire environment from elevated and actor-follow cameras.

### J. Performance

Compare representative deployments against the accepted Stage X baseline.

## 21. Stage Y acceptance criteria

Stage Y is complete when:

- All major environment zones have recognizable identities.
- Industrial equipment placement is coherent.
- Existing modular assets are reused effectively.
- New assets follow the accepted Blender pipeline.
- Environmental storytelling is visible without exposition.
- Salvage presentation is contextually appropriate.
- Distinct landmarks support navigation.
- Facility signage is consistent.
- Collision and navigation contracts remain intact.
- Existing AI behaviors remain unchanged.
- Finite salvage and extraction remain correct.
- All accepted layout variants work.
- Existing automated regression suites pass.
- Graphical and headless validation pass.
- Performance impact is measured.
- The environment is documented with visual evidence.

## 22. Explicit exclusions

Do not implement:

- New Raider AI behaviors.
- New combat systems.
- New weapons.
- New machine classes.
- New mission objectives.
- New salvage economy.
- New maps or major world expansion.
- Interactive factory machinery.
- Destructible environments.
- Dynamic hazards.
- Multiplayer.
- Crafting.
- New story campaigns.
- Full narrative dialogue.
- Major HUD redesign.

These belong to future stages.

## 23. Implementation workflow

### Step 1 — Inspect

Review the Stage X implementation, expanded environment, asset library, scene structure, navigation, and existing performance measurements.

### Step 2 — Propose

Present:

- Current environmental inventory.
- Zone-by-zone visual plan.
- Proposed industrial facility identity.
- Asset reuse opportunities.
- New modular asset requirements.
- Placement strategy.
- Salvage presentation approach.
- Collision and navigation risks.
- Performance budget.
- Exact proposed file changes.
- Validation plan.

**Stop for director approval before creating or placing new assets.**

### Step 3 — Pilot zone

After approval, populate one representative zone.

**Recommended pilot: Processing facility.**

This area provides the strongest opportunity to demonstrate industrial plausibility and reusable equipment assets.

Validate the pilot before expanding to other zones.

### Step 4 — Expand environment

Populate the remaining accepted zones using approved asset families and design conventions.

### Step 5 — Integrate storytelling

Add environmental vignettes, landmarks, signs, and contextual salvage presentation.

### Step 6 — Validate

Run:

- Blender export and Godot import checks.
- Editor parsing and resource validation.
- Existing gameplay regression suites.
- Seeded deployment tests.
- Navigation and accessibility checks.
- Forward+ graphical inspection.
- Spectator walkthroughs.
- Performance comparisons.

### Step 7 — Stage Y checkpoint

Deliver:

- Environmental asset inventory.
- Zone-by-zone implementation summary.
- Blender source files.
- Exported runtime assets.
- Scene changes.
- Before-and-after screenshots.
- Gameplay inspection captures.
- Performance measurements.
- Automated regression results.
- Known limitations.
- Manual acceptance checklist.
- Recommendations for Stage Z.

Do not advance to Stage Z without director approval.

Do not commit, reset, discard, or publish work without explicit authorization.

---

## Immediate Codex assignment

Inspect the current SCRAP Raiders repository and accepted Stage X implementation.

Prepare a Stage Y world-population and environmental-storytelling proposal.

Focus on believable industrial geography, reusable environmental assets, visual landmarks, and contextual salvage presentation.

Preserve the accepted gameplay simulation, navigation, collision, finite-resource economy, and performance expectations.

**Do not begin implementation until the director approves the proposal.**