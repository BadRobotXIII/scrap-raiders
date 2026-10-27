# SCRAP Raiders — Stage W Development Ledger
## Character & Machine Visual Production

**Phase:** 7 — Integrated Gameplay & World Production  
**Stage:** W  
**Status:** Proposed — architecture and character design approval required  
**Engine:** Godot 4.7.2  
**Modeling tool:** Blender  
**Prerequisite:** Completed Stage V

---

## 1. Project context

SCRAP Raiders is a third-person extraction shooter in which the player controls an autonomous machine competing against human Raiders.

The accepted project includes:

- Autonomous Raider personalities and decision-making.
- Raider relationships, cooperation, rivalry, and betrayal.
- Raider and machine combat.
- Scavenging, finite loot, and extraction.
- Player mission objectives and deployment settlement.
- Developer and post-death spectating.
- Expanded industrial salvage environment.
- Modular environment asset production pipeline.

Stage V established the intended Blender-to-Godot workflow and environment visual standards.

Stage W extends that pipeline to characters and autonomous machines.

The repository and Stage V completion report are authoritative. Inspect them before proposing implementation.

## 2. Primary objective

Replace the most important placeholder actor visuals with recognizable, production-direction character and machine models.

Establish a reusable workflow for:

1. Character modeling.
2. Rigging.
3. Basic animation.
4. Godot import.
5. Animation playback.
6. Visual state integration.
7. Character variation.
8. Asset iteration without gameplay regressions.

The objective is to establish the actor visual-production foundation, not complete every final animation or character variant.

## 3. Architectural principle

**Priority: Critical**

Maintain strict separation between gameplay authority and visual presentation.

Gameplay controllers continue to own:

- Actor health.
- AI state machines.
- Movement decisions.
- Navigation.
- Combat decisions.
- Target selection.
- Social relationships.
- Inventory and loot interactions.
- Extraction.
- Death and cleanup.

Visual components own:

- Meshes.
- Skeletons.
- Animation playback.
- Visual effects.
- Appearance variations.
- Cosmetic attachments.

Visual components must not independently modify authoritative gameplay state.

Animations may represent accepted gameplay events, but must not become a second authority for combat, damage, or inventory transfer.

## 4. Existing actor audit

**Priority: Critical**

Inspect the current implementations of:

- Player robot.
- Human Raider.
- Ground support machine.
- Flying scout.
- Weapons.
- Equipment drops.
- Existing hit reactions.
- Death presentation.
- Muzzle flashes.
- Actor inspection and spectator camera.

Identify:

- Actor scene roots.
- Collision shapes.
- Navigation agents.
- Combat components.
- Current visual nodes.
- Animation-related scripts.
- Weapon attachment points.
- Camera assumptions.
- Existing scale conventions.
- Scene dependencies.

Determine the smallest visual replacement strategy that preserves the accepted gameplay architecture.

## 5. Visual design language

**Priority: Critical**

Establish a coherent character and machine design direction.

Recommended style:

**Grounded industrial science fiction with restrained stylization.**

Machines should look functional and mechanically plausible.

Human Raiders should look like scavengers adapting equipment for survival in an industrial environment.

Avoid excessive decorative science-fiction elements without a functional purpose.

Maintain consistency with the Stage V environment materials and visual standards.

### Player machine

The player should have a distinct silhouette recognizable from the third-person camera.

Design priorities:

- Clear forward orientation.
- Recognizable mechanical structure.
- Durable industrial construction.
- Visible articulation.
- Weapon attachment compatibility.
- Readable damage and movement feedback.

### Human Raiders

Raiders should have a recognizable human silhouette.

Design priorities:

- Scavenger clothing.
- Improvised armor.
- Equipment packs.
- Weapon attachment.
- Readable movement.
- Visual differentiation without requiring unique rigs for every Raider.

### Ground machine

The ground machine should communicate:

- Mobility method.
- Sensor direction.
- Combat capability.
- Industrial construction.
- Mechanical functionality.

### Flying scout

The flying scout should communicate:

- Propulsion.
- Observation role.
- Direction of travel.
- Sensor orientation.
- Lightweight construction.

Do not add weapons or gameplay capabilities to an actor merely because its visual design suggests them.

## 6. Character scale and coordinate standards

**Priority: Critical**

Reuse Stage V scale conventions.

Requirements:

- One world unit equals one meter.
- Consistent character forward direction.
- Correct Blender-to-Godot orientation.
- Applied export transforms.
- Predictable skeleton origin.
- Stable actor root transform.
- Visual geometry aligned to existing collision.
- Animation-compatible attachment points.

Verify the existing actor dimensions before selecting final model proportions.

Do not resize gameplay collision simply to accommodate a model without evaluating movement, combat, and navigation consequences.

## 7. Asset organization

**Priority: High**

Proposed structure:

```text
assets/
  characters/
    source/
      player/
      raider/
      ground_machine/
      flying_scout/

    exports/
      player/
      raider/
      ground_machine/
      flying_scout/

scenes/
  characters/
    visuals/

resources/
  characters/
    materials/
    animations/

docs/
  art_pipeline/
```

Adapt this structure to the accepted Stage V conventions.

Avoid creating a second asset pipeline.

Keep Blender source files editable and exported assets reproducible.

## 8. Rigging architecture

**Priority: Critical**

Establish a reusable rig for each actor class that requires skeletal animation.

### Human Raider

Prioritize a standard humanoid skeleton supporting:

- Idle.
- Walking.
- Running.
- Aiming.
- Firing.
- Hit reaction.
- Death.
- Carrying equipment.

Use one base Raider rig wherever practical.

Different Raider personalities should not require separate skeletons.

### Player robot

Use an appropriate mechanical skeleton or articulated transform hierarchy.

Support:

- Idle.
- Locomotion.
- Turning.
- Weapon orientation.
- Firing.
- Hit reaction.
- Destruction.

### Ground machine

Use skeletal animation only where beneficial.

Simple mechanical movement may be better represented by transform animation.

### Flying scout

Prefer simple transform-based animation for:

- Propeller or rotor motion.
- Sensor orientation.
- Hovering.
- Movement response.
- Destruction.

Do not build complex skeletal rigs for machines that do not need them.

## 9. Animation foundation

**Priority: Critical**

Implement a minimal animation set sufficient for readable gameplay.

### Required initial animations

| Actor | Required animations |
|---|---|
| Raider | Idle, walk, run, aim/fire, death |
| Player | Idle, locomotion, fire, destruction |
| Ground machine | Idle/movement, attack, destruction |
| Flying scout | Hover/movement, destruction |

Additional animation may be proposed after inspecting existing visual feedback.

### Animation state ownership

The actor's existing gameplay state drives animation selection.

Examples:

- Movement velocity determines locomotion presentation.
- Combat events trigger firing presentation.
- Accepted damage events trigger hit feedback.
- Authoritative death triggers death presentation.

Animation playback must not independently decide whether damage occurred or whether an actor died.

Avoid duplicate animation-state machines that reproduce the entire gameplay FSM.

## 10. Animation integration

**Priority: Critical**

Use Godot's existing animation systems where appropriate.

Evaluate:

- AnimationPlayer.
- AnimationTree.
- BlendSpace configurations.
- One-shot animation playback.
- Skeleton3D.
- BoneAttachment3D.
- Visual-only transform animation.

Choose the smallest implementation appropriate for the accepted actors.

Prefer clear, maintainable animation state mapping over complex visual state graphs.

Do not introduce animation-driven movement unless specifically approved.

Existing gameplay movement remains authoritative.

## 11. Weapon and equipment attachment

**Priority: High**

Establish consistent attachment points for:

- Raider weapons.
- Player weapon.
- Salvage packs.
- Equipment carried by Raiders.
- Cosmetic accessories.

Attachment transforms should be defined relative to the visual rig.

Existing weapon collision, firing origins, targeting, and damage calculations remain authoritative.

If the visual muzzle differs from the gameplay firing origin, document and correct the visual alignment without changing combat behavior unnecessarily.

Avoid weapon clipping through the body or ground.

## 12. Raider appearance variation

**Priority: High**

Introduce bounded visual variation among Raiders.

Possible variations:

- Clothing colors.
- Armor pieces.
- Helmets.
- Backpacks.
- Equipment arrangements.
- Material parameters.

Prefer shared rigs and reusable mesh components.

Do not create separate actor controllers for appearance variants.

Appearance should not automatically reveal hidden personality or relationship state unless that becomes an intentional design decision.

Preserve deterministic variation where seeded deployment reproducibility requires it.

## 13. Character materials

**Priority: High**

Reuse Stage V material standards.

Suggested materials:

- Painted steel.
- Bare metal.
- Rubber.
- Industrial polymer.
- Fabric.
- Protective armor.
- Glass or sensor lenses.

Use consistent roughness and metallic response.

Avoid excessive unique texture sets.

Maintain readable silhouettes under bright and shaded lighting.

## 14. Death and destruction presentation

**Priority: Critical**

Integrate visual destruction with existing accepted death logic.

Requirements:

- Death presentation begins after authoritative death.
- Combat targeting respects existing death state.
- Loot drops remain governed by existing systems.
- Destruction animation does not duplicate loot release.
- Dead actors do not continue normal locomotion animation.
- Cleanup occurs according to accepted lifecycle rules.
- Spectator targeting remains stable during death transitions.

Where existing death effects already exist, reuse them.

Do not add a new corpse persistence or physics-ragdoll system during this stage.

## 15. Spectator and camera compatibility

**Priority: Critical**

Validate actor visuals from:

- Third-person player camera.
- Developer free camera.
- Post-death spectator camera.
- Actor-follow spectator mode.

Check:

- Camera clipping.
- Character visibility.
- Animation playback at distance.
- Attachment alignment.
- Death transitions.
- Actor cleanup.
- Visual orientation.

Do not change spectator permissions or AI perception.

## 16. Performance

**Priority: Critical**

Measure character visual cost against the accepted Stage V baseline.

Evaluate:

- Skinned mesh count.
- Skeleton complexity.
- Animation evaluation.
- Material count.
- Draw calls.
- Triangle count.
- Texture memory.
- Shadow casting.
- Multiple simultaneous Raiders.
- Ground and flying machines.
- Spectator camera movement.

Use representative maximum accepted actor populations.

Avoid adding expensive visual complexity without evidence of benefit.

## 17. Automated validation

Preserve all accepted gameplay tests.

Add or extend validation for:

1. Character asset import.
2. Skeleton and animation availability.
3. Actor visual initialization.
4. Attachment point existence.
5. Animation playback state mapping.
6. Movement animation transitions.
7. Firing animation triggering.
8. Death animation triggering.
9. Existing collision integrity.
10. Navigation compatibility.
11. Combat origin compatibility.
12. Raider personality independence.
13. Social AI independence.
14. Loot drop integrity.
15. Extraction and settlement.
16. Spectator compatibility.
17. Restart and cleanup.
18. Rendering performance.

Automated tests should validate observable state and resource integrity, not brittle internal animation implementation details.

## 18. Manual acceptance

### A. Player machine

Move, turn, fire, take damage, and die.

Verify readable movement and weapon alignment.

### B. Raider

Observe idle, scavenging, movement, combat, retreat, extraction, and death.

Verify appropriate animation presentation.

### C. Multiple Raiders

Observe multiple personalities and relationships in the same mission.

Verify appearance variation without altering gameplay decisions.

### D. Ground machine

Observe patrol, combat, damage, and destruction.

### E. Flying scout

Observe hovering, travel, sensor orientation, and destruction.

### F. Spectator

Follow multiple actors and inspect animation and attachment behavior.

### G. Reimport

Modify and re-export an actor model.

Verify that the Godot scene updates without breaking gameplay components.

### H. Performance

Compare accepted actor populations before and after visual replacement.

## 19. Stage W acceptance criteria

Stage W is complete when:

- Character and machine visual direction is approved.
- The existing asset pipeline supports actor production.
- A reusable Raider rig exists.
- A recognizable player-machine model exists.
- A recognizable Raider model exists.
- Ground and flying machines have recognizable visual models.
- Basic locomotion and combat animations are integrated.
- Death and destruction presentation is functional.
- Weapon and equipment attachments are aligned.
- Raider appearance variation is supported.
- Existing AI and gameplay authority remain unchanged.
- Spectator behavior remains functional.
- Existing regression tests pass.
- Performance remains acceptable.
- Source assets and import settings are documented.

## 20. Explicit exclusions

Do not implement:

- New Raider personalities.
- New AI relationships.
- New weapons.
- New combat systems.
- New machine classes.
- Ragdoll physics.
- Advanced inverse kinematics.
- Motion matching.
- Procedural character generation.
- Multiplayer.
- Crafting.
- New mission architecture.
- Major world expansion.
- Full cinematic animation.

These belong to future stages.

## 21. Implementation workflow

### Step 1 — Inspect

Review Stage V delivery, actor scenes, visual nodes, combat components, navigation, camera assumptions, and existing animation resources.

### Step 2 — Propose

Present:

- Actor visual architecture.
- Character design direction.
- Modeling and rigging strategy.
- Minimal animation sets.
- Attachment conventions.
- Asset directory structure.
- Blender export/import workflow.
- Performance expectations.
- Regression risks.

**Stop for director approval before producing actor models.**

### Step 3 — Establish actor pipeline

After approval:

1. Produce a representative Raider model.
2. Establish the base humanoid rig.
3. Export and import into Godot.
4. Verify scale and orientation.
5. Integrate the visual component without changing gameplay ownership.
6. Validate source reimport.

### Step 4 — Produce machine visuals

Create the approved player, ground-machine, and flying-scout models.

Use simple rigs or transform animation where appropriate.

### Step 5 — Integrate animation

Connect visual animation playback to accepted gameplay state and events.

Preserve authoritative movement, combat, and death.

### Step 6 — Validate

Run:

- Asset import checks.
- Godot editor parsing/import.
- Existing gameplay regression suites.
- Bounded headless simulations.
- Forward+ graphical startup.
- Actor animation tests.
- Spectator checks.
- Performance comparison.
- Manual gameplay testing.

### Step 7 — Checkpoint W

Deliver:

- Actor asset inventory.
- Blender source files.
- Exported runtime assets.
- Rig and animation documentation.
- Scene integration summary.
- Validation results.
- Performance comparison.
- Known limitations.
- Manual acceptance checklist.
- Recommendations for Stage X.

Do not advance to Stage X without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Inspect the current SCRAP Raiders repository and Stage V completion report.

Prepare the Stage W character and machine visual-production proposal.

Prioritize recognizable actor identities, reusable rigs, basic animation, and strict separation between visual presentation and gameplay authority.

**Do not begin asset production until the proposal is approved.**

The objective is to replace placeholder actors with coherent, functional game characters without destabilizing the accepted simulation.