# SCRAP Raiders — Stage V Development Ledger
## Environment Art, Modular Assets & Blender-to-Godot Pipeline

**Phase:** 7 — Integrated Gameplay & World Production  
**Stage:** V  
**Status:** Proposed — architecture and visual direction approval required  
**Engine:** Godot 4.7.2  
**Primary modeling tool:** Blender  
**Prerequisite:** Completed and accepted Stage U

---

## 1. Project context

SCRAP Raiders is a third-person extraction shooter where the player controls a machine in an industrial world contested by autonomous human Raiders and machines.

The accepted gameplay systems include:

- Raider personality and independent decision-making.
- Raider relationships, cooperation, rivalry, and betrayal.
- Autonomous combat, scavenging, and extraction.
- Ground and flying machines.
- Finite salvage and equipment recovery.
- Mission objectives, settlement, and persistent inventory.
- Developer and post-death spectating.
- Seeded encounter generation.
- Expanded world geography from Stage U.

Stage V begins visual production of the environment.

The repository and Stage U delivery report are authoritative. Inspect them before proposing implementation.

## 2. Primary objective

Establish a repeatable environment asset production workflow and begin transforming the expanded graybox environment into a visually recognizable industrial salvage complex.

Stage V must deliver:

1. A documented Blender-to-Godot workflow.
2. Consistent world scale and coordinate conventions.
3. Reusable modular environment assets.
4. Consistent material and texture conventions.
5. Clear separation between visual geometry and gameplay collision.
6. A small representative asset library.
7. One visually developed demonstration area.
8. Regression validation proving gameplay remains intact.

**The objective is to establish the production pipeline, not complete all environmental art.**

## 3. Visual identity

**Priority: Critical**

Proposed direction:

**Grounded industrial realism with restrained stylization.**

The environment should feel like a plausible industrial facility that has deteriorated, been partially dismantled, or continued operating after human abandonment.

Visual characteristics:

- Functional industrial construction.
- Recognizable mechanical equipment.
- Heavy steel structures.
- Weathered painted surfaces.
- Exposed mechanical systems.
- Utility piping and conduit.
- Industrial electrical enclosures.
- Salvage piles and discarded components.
- Clearly differentiated operational areas.
- Limited but deliberate color accents.

Avoid excessive science-fiction decoration.

Avoid filling the environment with arbitrary pipes, glowing lights, or mechanical details that have no plausible purpose.

The world should feel designed and constructed for a reason.

### Tone

The environment is serious enough to make the machines believable.

The game's humor should primarily emerge from:

- Machine identities.
- Raider behavior.
- Combat interactions.
- Opportunistic scavenging.
- Betrayal.
- Unexpected encounters.

Do not require every environmental asset to look comedic.

## 4. Existing environment audit

**Priority: Critical**

Inspect the Stage U expanded world and identify:

- Geometry modules.
- Structural graybox objects.
- Navigation regions.
- Collision surfaces.
- Cover objects.
- Cover and peek markers.
- Spawn locations.
- Salvage markers.
- Extraction routes.
- Machine patrol paths.
- Lighting.
- Environment settings.
- Existing imported meshes and materials.

Classify geometry as:

- Gameplay-critical structural geometry.
- Replaceable visual geometry.
- Navigation-dependent geometry.
- Collision-dependent cover.
- Temporary development markers.
- Existing reusable production assets.

Do not begin replacing geometry before establishing which objects are gameplay-critical.

## 5. Asset pipeline

**Priority: Critical**

Establish a Blender-to-Godot workflow using `.blend` source files and a supported interchange format, preferably `.glb` / glTF 2.0.

The pipeline must support:

- Consistent unit scale.
- Correct object orientation.
- Applied transforms.
- Predictable object origins.
- Material assignments.
- UV coordinates.
- Reimport without destructive manual repairs.
- Reusable asset instances.
- Version-controlled source files.
- Documented naming conventions.

Validate the pipeline with one simple structural asset before producing a larger library.

Do not assume Blender source files can be imported identically across every developer machine.

Document the required Blender and Godot import configuration.

### Source and runtime separation

Maintain a clear distinction between:

- Editable Blender source.
- Exported runtime meshes.
- Godot scenes.
- Godot materials.
- Collision representations.

Avoid making exported meshes the only editable copy of an asset.

## 6. Asset coordinate and scale standards

**Priority: Critical**

Adopt a consistent convention for all new environment assets.

Recommended:

- One Blender unit equals one meter.
- Apply object scale and rotation before export.
- Use consistent local origins.
- Prefer modular dimensions.
- Keep reusable assets aligned to predictable axes.
- Maintain clean transform hierarchies.
- Avoid negative-scale collision geometry.
- Validate orientation after Godot import.

Suggested modular dimensions:

- Structural grid: 1 m.
- Common wall sections: 2 m and 4 m.
- Common floor sections: 2 × 2 m and 4 × 4 m.
- Industrial doors: sized for existing actor collision requirements.
- Platforms and ramps: match validated Stage U gameplay geometry.

These are proposed conventions, not requirements to resize accepted gameplay paths.

## 7. Asset organization

**Priority: High**

Proposed structure:

```text
assets/
  environment/
    source/
      structures/
      machinery/
      props/
      materials/

    exports/
      structures/
      machinery/
      props/

scenes/
  environment/
    modules/
    props/

resources/
  materials/
    environment/

docs/
  art_pipeline/
```

Adapt to the existing repository structure.

Do not rename accepted scene resources unnecessarily.

Do not create duplicate source directories or parallel asset pipelines.

## 8. Modular asset library

**Priority: Critical**

Create a small reusable library.

### Structural assets

Suggested initial set:

- Concrete floor sections.
- Industrial wall sections.
- Steel support columns.
- Structural beams.
- Platform sections.
- Guardrails.
- Industrial stairs or ramps where compatible.
- Door frames.
- Roof sections.

### Industrial equipment

Suggested initial set:

- Electrical control cabinet.
- Conveyor section.
- Machine enclosure.
- Industrial equipment base.
- Pipe or conduit support.
- Utility junction box.

### Salvage and storage

Suggested initial set:

- Shipping container.
- Industrial crate.
- Steel pallet.
- Scrap bin.
- Machinery debris.
- Material storage rack.

These are candidate assets.

Prioritize reusable pieces that appear in multiple operational areas.

Do not model every proposed item automatically.

The architecture proposal should identify the smallest useful initial library.

## 9. Asset detail levels

**Priority: High**

Establish practical geometry complexity standards.

Classify assets as:

### Large structural assets

Prioritize silhouette, scale, and correct proportions.

### Mid-sized gameplay props

Prioritize recognizable form and clear cover geometry.

### Small decorative props

Prioritize efficient repetition and minimal collision complexity.

Avoid arbitrary universal polygon budgets.

Instead, inspect the existing rendering baseline and propose reasonable per-category budgets.

Use shared materials and reusable geometry where practical.

Do not introduce elaborate LOD generation before measuring its value.

## 10. Materials and textures

**Priority: Critical**

Establish a coherent material library.

Suggested foundational materials:

- Painted industrial steel.
- Exposed weathered steel.
- Galvanized steel.
- Concrete.
- Rubber.
- Industrial plastic.
- Painted safety markings.
- Glass or transparent panels where appropriate.

Prefer physically based materials.

Support roughness and metallic response.

Use normal maps selectively where they materially improve appearance.

Avoid excessive unique materials and unnecessarily large textures.

Preserve visual readability under the game's intended lighting conditions.

### Material reuse

Assets should share appropriate base materials.

Variation can be achieved through:

- Material parameters.
- Color changes.
- Decals.
- Limited texture variants.
- Geometry variation.

Do not generate a unique texture set for every repeated prop.

## 11. Collision and navigation separation

**Priority: Critical**

Gameplay collision must remain stable during visual replacement.

Preferred approach:

- Retain validated Stage U collision geometry initially.
- Add production meshes as visual children or separate instances.
- Use explicit collision primitives where new geometry requires collision.
- Do not automatically replace all collision with detailed mesh collision.
- Avoid decorative collision that blocks navigation unexpectedly.
- Keep collision layers and masks consistent with accepted systems.

Do not rebake navigation simply because a decorative mesh was added.

If a structural change requires navigation changes, isolate and validate that change.

### Cover integrity

For gameplay-critical cover:

- Preserve physical occlusion.
- Preserve valid cover and peek markers.
- Preserve bullet collision behavior.
- Preserve actor movement clearance.
- Verify visual and physical cover alignment.

A visually impressive object that permits bullets to pass through its apparent solid surface is unacceptable.

Likewise, invisible collision significantly outside the visible object should be identified and corrected.

## 12. Demonstration area

**Priority: Critical**

Choose one representative section of the expanded world.

Recommended initial target:

**Processing facility.**

Reasons:

- Contains multiple structural asset types.
- Benefits from industrial equipment.
- Exercises cover and navigation.
- Supports lighting and material evaluation.
- Includes close-range Raider combat.
- Can demonstrate modular construction.

Create a limited visual pass of this area using the approved asset library.

Do not replace the entire map during Stage V.

The demonstration area should establish the visual and technical standards for subsequent production.

## 13. Lighting and atmosphere

**Priority: High**

Establish a coherent baseline environment.

Potential direction:

- Natural exterior lighting.
- Soft industrial interior lighting.
- Controlled shadows.
- Limited atmospheric haze.
- Selective emissive equipment indicators.
- Distinct visual contrast between operational areas.

Avoid dramatic lighting that makes combat targets difficult to identify.

Test both:

- Player camera.
- Spectator camera.

Lighting should support spatial readability.

Do not introduce expensive post-processing solely for visual spectacle.

## 14. Blender automation

**Priority: High**

Where appropriate, create reusable Blender Python scripts for generating simple industrial assets.

Potential candidates:

- Structural beams.
- Modular wall sections.
- Guardrails.
- Industrial cabinets.
- Containers.
- Conveyor frames.
- Simple piping.

Generated assets must remain editable.

Prefer parameterized scripts for repetitive geometry.

Do not force all artistic assets through procedural generation.

The pipeline should support both manually modeled and script-generated assets.

## 15. Asset quality control

**Priority: Critical**

Establish validation checks for:

- Scale.
- Orientation.
- Applied transforms.
- Missing textures.
- Missing materials.
- Broken exports.
- Incorrect origins.
- Excessive mesh complexity.
- Unexpected collision.
- Navigation interference.
- Resource path errors.
- Duplicate asset variants.
- Reimport consistency.

Automate checks where practical.

Document manual checks for properties that cannot be reliably verified automatically.

## 16. Performance validation

**Priority: Critical**

Compare the Stage V demonstration area against the accepted Stage U graybox baseline.

Evaluate:

- Frame time.
- Draw calls.
- Triangle count.
- Material count.
- Texture memory.
- Physics cost.
- Navigation cost.
- Scene loading.
- Repeated asset instancing.
- Shadow cost.

Use comparable camera positions and runtime settings.

Separate rendering regressions from gameplay simulation cost.

Do not optimize prematurely, but identify avoidable costs before multiplying assets across the entire world.

## 17. Automated regression

Preserve all accepted gameplay tests.

Add asset pipeline validation covering:

1. Asset export and import.
2. Scene resource integrity.
3. Valid asset transforms.
4. Material availability.
5. Visual scene startup.
6. Existing collision compatibility.
7. Navigation integrity.
8. Cover and peek compatibility.
9. Raider movement through the demonstration area.
10. Combat occlusion.
11. Player camera clearance.
12. Spectator camera behavior.
13. Mission objective continuity.
14. Extraction and settlement.
15. Scene restart.
16. Performance smoke testing.

Do not require pixel-perfect visual comparison unless the repository already supports a stable image-regression workflow.

## 18. Manual acceptance

### A. Asset pipeline

Create, export, import, and update one Blender asset.

Verify that reimport preserves intended transforms, materials, and Godot scene integration.

### B. Scale and proportions

Compare industrial assets against the player and Raider characters.

Ensure doors, platforms, equipment, and cover feel plausible.

### C. Visual identity

Inspect the demonstration area from normal gameplay perspectives.

Confirm that the environment looks like a functional industrial location rather than an arbitrary collection of props.

### D. Gameplay preservation

Fight Raiders in the visually developed area.

Verify that movement, cover, aiming, and visibility remain consistent.

### E. Navigation

Observe Raiders entering, fighting, retreating, and leaving the demonstration area.

Confirm that decorative geometry does not interfere with accepted navigation.

### F. Lighting

Inspect bright and shaded locations.

Confirm that Raiders, machines, salvage, and exits remain readable.

### G. Performance

Compare the demonstration area against the Stage U baseline using equivalent conditions.

### H. Asset iteration

Modify a source asset and re-export it.

Confirm that the revised model propagates correctly without manually rebuilding its Godot instances.

## 19. Acceptance criteria

Stage V is complete when:

- The Blender-to-Godot workflow is documented and verified.
- Source assets remain editable.
- Asset naming and organization are consistent.
- A reusable modular asset library exists.
- Foundational materials are established.
- One expanded-world area has received a representative visual pass.
- Gameplay-critical collision remains correct.
- Navigation remains functional.
- Combat and cover remain reliable.
- Lighting supports gameplay readability.
- Reimporting assets works reliably.
- Performance remains acceptable.
- Existing gameplay regression tests pass.
- The production workflow is ready to scale to additional world areas.

## 20. Explicit exclusions

Do not implement:

- Final character models.
- Raider animation systems.
- New machine classes.
- New AI behavior.
- New combat mechanics.
- New weapons.
- Crafting.
- Multiplayer.
- Major mission architecture changes.
- Full-world environmental replacement.
- Procedural terrain generation.
- Large-scale world streaming.
- Cinematic sequences.
- Complex destruction systems.

These belong to later stages.

## 21. Implementation workflow

### Step 1 — Inspect

Review Stage U delivery, current asset organization, environment scenes, collision architecture, navigation, materials, lighting, and performance baselines.

### Step 2 — Propose

Present:

- Visual style recommendation.
- Blender export/import workflow.
- Asset naming and directory standards.
- Small initial asset library.
- Material standards.
- Demonstration area selection.
- Collision/navigation preservation strategy.
- Automation opportunities.
- Performance validation plan.
- Regression risks.

**Stop for director approval before creating production assets.**

### Step 3 — Establish pipeline

After approval:

1. Create and export a representative Blender asset.
2. Import it into Godot.
3. Verify materials and scale.
4. Verify source re-editing and reimport.
5. Establish naming and organization.
6. Document the workflow.

### Step 4 — Produce initial library

Create the approved modular structures, equipment, and salvage props.

Keep the library small and reusable.

### Step 5 — Build demonstration area

Apply the asset library to the approved expanded-world section.

Preserve existing gameplay geometry.

### Step 6 — Validate

Run:

- Blender export/import checks.
- Godot parsing/import.
- Existing automated regression suites.
- Forward+ graphical startup.
- Navigation and combat tests.
- Performance comparison.
- Manual visual inspection.

### Step 7 — Checkpoint V

Deliver:

- Production pipeline documentation.
- Asset inventory.
- Blender source files.
- Exported meshes.
- Godot scene integration.
- Demonstration-area screenshots.
- Validation results.
- Performance comparison.
- Known limitations.
- Recommendations for Stage W.

Do not advance to Stage W without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Inspect the SCRAP Raiders repository and completed Stage U implementation.

Prepare a production-ready Stage V environment asset pipeline and demonstration-area proposal.

Prioritize Blender-to-Godot repeatability, modular industrial assets, visual consistency, and preservation of gameplay geometry.

**Do not create production assets or modify the expanded world until the proposal has been approved.**

The objective is to establish the foundation for scalable visual production without destabilizing the accepted game.