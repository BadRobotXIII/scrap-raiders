# SCRAP Raiders — Stage U Development Ledger
## World Expansion & Encounter Geography

**Phase:** 7 — Integrated Gameplay & World Production  
**Stage:** U  
**Status:** Proposed — architecture and layout approval required  
**Engine:** Godot 4.7.2 / GDScript  
**Prerequisite:** Stage T integration checkpoint accepted

---

## 1. Project context

SCRAP Raiders is a third-person extraction shooter where the player controls a machine operating in a world contested by human Raiders and autonomous machines.

The gameplay baseline includes:

- Independent Raider AI personalities.
- Raider combat, scavenging, retreat, and extraction.
- Raider rivalry, cooperation, and opportunistic betrayal.
- Autonomous flying and ground machines.
- Seeded dynamic encounter opportunities.
- Finite material and equipment accounting.
- Player combat, recovery, extraction, and persistent inventory.
- Mission objectives and deployment results.
- Developer and post-death spectating.

Stage T established the intended integrated gameplay baseline. Verify its accepted implementation and outstanding limitations in the repository.

Stage U expands the environment while preserving the existing gameplay architecture.

## 2. Primary objective

Create a larger, interconnected, gameplay-oriented environment that supports exploration, independent AI activity, tactical movement, scavenging, combat, and extraction.

The expanded world must:

- Feel meaningfully larger than the existing test arena.
- Contain distinct and recognizable operational areas.
- Support multiple viable navigation routes.
- Create natural encounter opportunities.
- Preserve autonomous Raider behavior.
- Support player exploration and tactical decisions.
- Maintain reliable navigation and combat.
- Preserve acceptable performance.
- Remain reproducible for development and testing.

**World size is not the primary success metric.**

The goal is useful, interconnected playable space.

## 3. Scope and implementation philosophy

Stage U is a **graybox world-expansion stage**.

Use simple geometry, placeholder structures, collision primitives, and reusable blockout components.

Do not begin detailed environmental art production.

Avoid spending time creating decorative assets that may need to move after gameplay testing.

Prefer modular scene composition over a single monolithic level script.

Preserve the existing mission controller and authoritative gameplay systems.

Do not introduce a new world simulation framework.

## 4. Existing environment audit

**Priority: Critical**

Before modifying the environment, inspect:

- Current `mission_arena.tscn`.
- Current `test_arena.tscn`.
- Current mission configuration.
- Existing player and Raider spawn logic.
- Existing navigation regions and meshes.
- Extraction locations.
- Salvage distribution.
- Machine patrol behavior.
- Encounter opportunity configuration.
- Camera and spectator behavior.
- Existing world collision layers.
- Existing performance characteristics.

Determine which portions of the current environment are reusable.

Identify dependencies on hardcoded positions, world bounds, path lengths, or assumptions about the compact arena.

Document any required migration before implementation.

## 5. Proposed world concept

**Working environment: Automated Industrial Salvage Complex**

A partially operational industrial facility where human Raiders enter to recover valuable machine components while autonomous machines continue operating.

The environment should support both industrial realism and the game's stylized comedic identity.

Suggested operational areas:

### A. Central salvage yard

An open area containing valuable scrap, machinery, containers, and partially dismantled equipment.

Gameplay purpose:

- High-value scavenging.
- Multi-Raider convergence.
- Machine patrol interception.
- Long sightlines with intermittent cover.
- Player opportunities to intercept cargo carriers.

### B. Processing facility

An industrial structure containing equipment platforms, conveyor machinery, partitions, and narrow access routes.

Gameplay purpose:

- Close-range combat.
- Occluded sightlines.
- Ambush opportunities.
- Short tactical engagements.
- Alternate interior movement routes.

### C. Maintenance and service corridors

A connected network of service passages and utility spaces.

Gameplay purpose:

- Retreat and escape.
- Flanking.
- Concealed traversal.
- Navigation around major combat zones.
- Shortcuts between operational areas.

### D. Storage and shipping area

A location containing containers, loading platforms, and material storage.

Gameplay purpose:

- Contested salvage.
- Cover-heavy combat.
- Raider loot concentration.
- Multiple routes toward extraction.

### E. Exterior perimeter

A less congested area surrounding portions of the facility.

Gameplay purpose:

- Longer traversal.
- Machine patrol routes.
- Raider arrival opportunities.
- Alternative approaches to objectives.
- Less frequent but more visible encounters.

### F. Extraction approaches

Several connected routes leading toward existing or relocated extraction locations.

Gameplay purpose:

- Raider escape.
- Player interception.
- Pursuit and disengagement.
- Risk-versus-reward decisions.
- Multiple viable approaches rather than a single choke point.

These areas are a proposed layout vocabulary, not a requirement to build six separate detailed environments.

Combine or simplify them as needed after reviewing the existing scene and navigation architecture.

## 6. World topology and connectivity

**Priority: Critical**

Design the world as an interconnected network rather than a linear sequence of rooms.

Requirements:

- Multiple routes between important operational areas.
- Avoid single mandatory choke points.
- At least one alternate approach to major salvage locations.
- Viable paths between spawn locations and extraction.
- Routes suitable for fleeing Raiders.
- Opportunities for pursuit and interception.
- Distinct open and enclosed spaces.
- Navigable transitions between elevation changes.
- Clear separation of decorative obstacles and true movement blockers.

Do not make every route equally safe or equally short.

Different paths should offer meaningful tradeoffs involving exposure, travel distance, and available cover.

### Proposed topology

```text
                   EXTERIOR PERIMETER
                   /       |        \
                  /        |         \
          STORAGE AREA   SALVAGE YARD
             |    \        /     |
             |     \      /      |
             |    PROCESSING     |
             |     FACILITY      |
             \        |          /
              \   MAINTENANCE   /
               \   CORRIDORS   /
                \      |      /
                 EXTRACTION
                  APPROACHES
```

This is a conceptual connectivity diagram, not an exact spatial blueprint.

Codex should propose the actual scene layout before construction.

## 7. Encounter geography

**Priority: Critical**

The environment must encourage existing AI interactions without scripting their outcomes.

### Salvage convergence

Place finite valuable salvage in locations accessible to multiple Raiders.

Avoid distributing all valuable materials evenly.

Some areas should naturally attract more competition than others.

### Machine interception

Design patrol routes that intersect likely Raider movement without guaranteeing combat.

### Rival contact

Provide shared routes, contested spaces, and alternate paths that permit Raider-versus-Raider encounters.

### Cooperation opportunities

Create locations where multiple Raiders may perceive the same machine threat.

Do not force cooperation.

### Betrayal opportunities

Ensure allied Raiders can encounter valuable cargo, changing threats, and competing objectives under the existing social AI rules.

Do not trigger betrayal based solely on entering a particular location.

### Extraction competition

Provide several viable approaches where a Raider carrying valuable loot may encounter another actor.

Avoid extraction paths that are impossible to defend or impossible to escape.

## 8. Encounter density and world scale

**Priority: Critical**

The existing compact arena produces entertaining behavior partly because actors regularly encounter one another.

A larger world can unintentionally reduce this interaction frequency.

Preserve meaningful encounter density through:

- Objective placement.
- Connected travel routes.
- Raider arrival distribution.
- Machine patrol locations.
- Salvage value concentration.
- Extraction approaches.
- Existing bounded encounter scheduling.

Do not compensate for excessive world size simply by spawning unlimited Raiders.

Start with a modest expansion.

Compare encounter frequency and time-to-contact against the accepted Stage T baseline.

If the expanded world becomes consistently uneventful, adjust geography before increasing actor population.

## 9. Navigation architecture

**Priority: Critical**

Review the current Godot navigation implementation before expanding the world.

Requirements:

- Valid navigation coverage across intended walkable areas.
- Reachable Raider objectives.
- Valid paths between spawn, salvage, combat, retreat, and extraction locations.
- Correct navigation around static obstacles.
- Reliable path recovery.
- No persistent path requests toward inaccessible destinations.
- Consistent collision and navigation layers.
- Proper handling of elevation transitions.
- No unexpected gaps between navigation regions.

Preserve existing Raider navigation and recovery logic.

Do not replace the AI movement architecture unless a concrete integration problem requires it.

### Navigation validation

Test:

- Long-distance movement.
- Narrow corridors.
- Open spaces.
- Multiple simultaneous Raiders.
- Combat around cover.
- Retreat from interior areas.
- Extraction from distant salvage areas.
- Machine patrol intersection.
- Dynamic actor congestion.
- Path recovery after blocked movement.

## 10. Cover and combat geography

**Priority: High**

Create meaningful differences between combat locations.

Include:

- Open areas with longer sightlines.
- Partial cover.
- Full occluding cover.
- Corners and flanking routes.
- Narrow passages.
- Wider areas for multi-actor combat.
- Elevated terrain where supported.
- Obstacles that interrupt pursuit.

Cover placement should support the existing Raider combat implementation.

Verify cover reservations and movement around cover.

Avoid decorative geometry that unintentionally blocks bullets, vision, or navigation.

## 11. Verticality

**Priority: High**

Introduce limited, purposeful elevation changes.

Potential examples:

- Loading platforms.
- Ramps.
- Raised walkways.
- Processing platforms.
- Industrial service access.

Verticality must remain compatible with existing navigation, movement, combat, and spectator behavior.

Do not introduce extensive multi-level traversal until the existing systems have been validated in a simpler expanded layout.

Avoid adding climb, mantle, ladder, or advanced traversal systems during this stage.

## 12. Scene organization

**Priority: Critical**

Use reusable, logically separated environment scenes.

Suggested conceptual organization:

```text
scenes/
  levels/
    test_arena.tscn
    expanded_salvage_complex.tscn

    environment/
      salvage_yard.tscn
      processing_facility.tscn
      storage_area.tscn
      maintenance_corridors.tscn
      perimeter.tscn
```

This structure is illustrative.

Inspect existing conventions and reuse them where appropriate.

Do not move or rename existing scenes unnecessarily.

The existing compact test arena must remain available for regression testing.

The expanded environment should be selectable without duplicating mission logic.

## 13. Mission integration

**Priority: Critical**

Reuse the existing Stage S mission objective and deployment systems.

The expanded world must support:

- Mission briefing.
- Objective initialization.
- Raider arrivals.
- Autonomous machine activity.
- Material and equipment recovery.
- Player combat.
- Extraction.
- Successful and failed deployment settlement.
- Post-death spectating.
- Deployment results.
- Mission restart.

Do not implement a second mission controller.

Do not duplicate MaterialLedger, EquipmentLedger, or PersistentStash.

If current mission configuration contains arena-specific coordinates, propose a data-driven way to supply level-specific locations.

Prefer existing scene markers, configuration resources, or established spawn-point conventions.

## 14. Development and debugging support

**Priority: High**

Preserve developer camera and actor inspection.

Add only the debugging support necessary to validate the expanded environment.

Useful diagnostics:

- Actor world position.
- Current navigation destination.
- Current objective.
- Target extraction point.
- Encounter seed.
- Active Raider population.
- Stuck or recovering navigation state.
- Current relationship and combat target.

Avoid expensive always-on debugging.

Do not expose developer diagnostics in normal player-facing UI.

## 15. Performance requirements

**Priority: Critical**

Measure the expanded world against the accepted Stage T baseline.

Investigate:

- Scene startup time.
- Navigation initialization.
- Physics processing cost.
- AI decision cost.
- Rendering cost.
- Collision complexity.
- Actor counts.
- Simultaneous combat.
- Spectator camera movement.
- Scene teardown and restart.

Prefer reusable low-complexity geometry during graybox development.

Avoid detailed meshes and expensive materials.

Do not introduce streaming or complex world partitioning unless measured performance demonstrates a need.

## 16. Automated validation

Preserve all accepted regression tests.

Add or extend tests covering:

1. Expanded level loading.
2. Scene and mission initialization.
3. Valid player spawn.
4. Valid Raider spawn placement.
5. Valid machine placement.
6. Navigation connectivity.
7. Salvage reachability.
8. Extraction reachability.
9. Raider long-distance scavenging.
10. Raider retreat through alternate routes.
11. Combat around expanded cover geometry.
12. Raider-versus-Raider interactions.
13. Machine patrol interception.
14. Encounter scheduling and population bounds.
15. Material and equipment accounting.
16. Player extraction and mission settlement.
17. Post-death spectating.
18. Mission restart.
19. Compact arena regression.
20. Expanded arena performance smoke testing.

Do not require specific emergent outcomes in general-purpose integration tests.

Use controlled setups when testing particular behaviors.

## 17. Manual play-testing

### Test A — Exploration

Traverse the expanded environment as the player.

Evaluate whether areas are recognizable, connected, and reasonably navigable.

### Test B — Passive simulation

Use developer spectating to observe Raiders and machines without intervention.

Evaluate encounter frequency, independent activity, and movement.

### Test C — Active gameplay

Play normally and pursue mission objectives.

Verify that travel, combat, recovery, and extraction remain enjoyable.

### Test D — Raider pursuit

Follow a Raider traveling between distant salvage and extraction locations.

Verify navigation, threat response, and route completion.

### Test E — Social encounters

Observe opportunities for cooperation, rivalry, and betrayal.

Verify that relationships and objectives remain independent of location scripts.

### Test F — Post-death spectating

Allow the player to be destroyed and continue observing the world.

Verify that distant actors continue their objectives and extraction attempts.

### Test G — Repeated seeds

Replay representative seeds.

Compare spawn conditions, navigation, encounter density, and mission outcomes.

### Test H — Compact arena comparison

Return to the original arena.

Confirm that expanded-world changes did not regress accepted gameplay.

## 18. Stage U acceptance criteria

Stage U is complete when:

- A larger interconnected graybox environment is playable.
- Distinct operational areas are recognizable.
- Multiple viable routes connect major locations.
- Salvage and extraction objectives are reachable.
- Raiders can navigate the expanded environment reliably.
- Autonomous machines can patrol and engage.
- Existing social AI remains functional.
- Encounter density remains meaningful.
- The player can complete normal mission objectives.
- Player and Raider extraction remain functional.
- Post-death spectating works across the expanded environment.
- The original compact arena remains available.
- Authoritative accounting invariants remain intact.
- Performance remains acceptable.
- Automated regression and integration tests pass.
- Manual testing demonstrates that the expanded environment improves gameplay rather than simply increasing travel time.

## 19. Explicit exclusions

Do not implement:

- Detailed environment art.
- Final character models.
- New Raider personalities.
- New social AI systems.
- New weapons.
- New machine classes.
- Crafting or progression.
- Multiplayer.
- Procedural terrain generation.
- Unbounded world generation.
- Large-scale streaming architecture.
- New traversal mechanics.
- Major animation production.
- A replacement mission controller.

These are outside Stage U.

## 20. Implementation workflow

### Step 1 — Inspect

Review the current level, scene architecture, mission configuration, navigation, spawn systems, and Stage T integration report.

### Step 2 — Propose

Produce:

- Existing-world assessment.
- Proposed expanded layout.
- Connectivity diagram.
- Operational area descriptions.
- Encounter geography plan.
- Navigation strategy.
- Scene organization.
- Mission integration changes.
- Performance risks.
- Validation strategy.

**Stop for director approval before implementing the expanded level.**

### Step 3 — Build

After approval:

1. Create the expanded graybox environment.
2. Establish navigation connectivity.
3. Integrate spawn and objective locations.
4. Configure machine patrols.
5. Configure encounter opportunities.
6. Validate extraction routes.
7. Preserve the original test arena.

### Step 4 — Validate

Run:

- Godot editor parsing and import.
- Full automated regression suite.
- Bounded headless simulation.
- Forward+ graphical startup.
- Expanded-world integration tests.
- Compact arena regression.
- Manual gameplay tests.

### Step 5 — Checkpoint U

Provide:

- Implementation summary.
- World layout description.
- Scene hierarchy.
- Navigation design.
- Encounter configuration.
- Files changed.
- Automated test results.
- Performance comparison.
- Manual play-test instructions.
- Known limitations.
- Recommendations for Stage V.

Do not advance to Stage V without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Inspect the current SCRAP Raiders repository and prepare the Stage U world-expansion architecture and layout proposal.

Use the accepted Stage T integrated mission as the gameplay baseline.

Design a larger, interconnected industrial salvage environment that creates natural opportunities for Raider scavenging, combat, cooperation, betrayal, pursuit, and extraction.

Preserve the compact test arena and existing gameplay systems.

**Do not begin level construction until the proposed layout and architecture are approved.**

The objective is to expand the world while preserving the encounter density and emergent gameplay that already make SCRAP Raiders entertaining.