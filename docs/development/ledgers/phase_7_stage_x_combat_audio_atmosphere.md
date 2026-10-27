# SCRAP Raiders — Stage X Development Ledger

## Combat Feedback, Audio & Environmental Atmosphere

**Project:** SCRAP Raiders  
**Studio:** BadRobot Studios — Engineering Bad Behavior  
**Engine:** Godot 4.7.2  
**Stage:** X  
**Status:** Proposed — architecture approval required  
**Prerequisite:** Completed Stage W

---

## 1. Project context

SCRAP Raiders is a third-person extraction shooter in which the player controls a machine operating against autonomous human Raiders.

The accepted project includes:

- Independent Raider personalities and objective selection.
- Raider social relationships, cooperation, rivalry, and betrayal.
- Player, Raider, and autonomous-machine combat.
- Finite salvage, extraction, deployment objectives, and settlement.
- Dynamic encounters and seeded simulation.
- Developer and post-death spectator modes.
- Expanded industrial salvage environment.
- Blender-to-Godot environment asset pipeline.
- Original character and machine models, rigs, and animations.
- Stage W actor visual inspection environment.

Stage W is complete and accepted by the director.

Stage X focuses on presentation quality, feedback, and atmosphere while preserving the accepted gameplay simulation.

The actual repository, accepted architecture, and Stage W completion report are authoritative.

## 2. Primary objective

Improve the moment-to-moment experience of SCRAP Raiders through:

1. Weapon firing feedback.
2. Impact and damage feedback.
3. Character and machine reactions.
4. Spatial audio.
5. Environmental ambience.
6. Lighting and atmospheric effects.
7. Readable gameplay presentation.
8. Reusable visual and audio effect architecture.

The result should feel substantially more cohesive without requiring new gameplay systems.

**Stage X must not change the underlying combat rules, AI decisions, or mission outcomes.**

## 3. Architecture: authoritative gameplay, observational presentation

**Priority: Critical**

Presentation must remain subordinate to gameplay.

Existing systems retain authority over:

- Weapon firing permission.
- Ammunition and cooldowns, where applicable.
- Hit detection.
- Damage.
- Health.
- Death.
- AI targeting.
- Threat awareness.
- Navigation.
- Extraction.
- Inventory and loot.
- Mission outcomes.

Presentation systems may observe authoritative events such as:

- Weapon fired.
- Projectile or hitscan impact resolved.
- Actor damaged.
- Actor killed.
- Machine destroyed.
- Salvage collected.
- Extraction initiated.
- Extraction completed.

Do not allow visual effects, animation events, or audio playback to become independent gameplay authorities.

### Recommended pattern

```text
Gameplay action
      |
      v
Authoritative gameplay resolution
      |
      +----> Gameplay state update
      |
      +----> Presentation event
                 |
                 +----> Visual effect
                 +----> Audio effect
                 +----> Animation reaction
                 +----> HUD feedback
```

Inspect existing signals and event mechanisms before proposing new abstractions.

Avoid duplicating events already emitted by the accepted gameplay components.

Do not create a global event bus unless the existing architecture demonstrates a concrete need.

## 4. Stage W integration audit

**Priority: Critical**

Inspect:

- Player visual scene.
- Raider visual scenes.
- Ground-machine visual scene.
- Flying-scout visual scene.
- Animation controllers.
- Weapon attachments.
- Muzzle origins.
- Damage and death presentation.
- Actor inspection environment.
- Existing audio nodes.
- Existing particles and effects.
- Existing HUD feedback.
- Existing mission-level lighting.

Identify current functionality before replacing or extending anything.

Preserve the Stage W Blender sources, imported models, rigs, and animation pipeline.

Do not remodel the actors during Stage X.

## 5. Weapon discharge feedback

**Priority: Critical**

Improve weapon firing presentation for player and Raider weapons.

Evaluate and implement where appropriate:

- Muzzle flash.
- Short-lived muzzle illumination.
- Recoil animation.
- Weapon discharge audio.
- Impact sparks.
- Surface impact particles.
- Hit confirmation.
- Brief mechanical response.

The exact effects must correspond to actual authoritative weapon events.

### Requirements

- No muzzle flash when firing is rejected.
- No duplicate effect when a single shot is accepted.
- Weapon origin visually aligns with the Stage W model.
- Effects remain attached to the correct actor.
- Effects do not alter aim or hit detection.
- Multiple simultaneous Raiders can fire without presentation conflicts.
- Effects clean up correctly when actors die or scenes restart.

Avoid excessive camera shake or screen effects that obscure gameplay.

## 6. Impact feedback

**Priority: Critical**

Distinguish meaningful impact types using existing gameplay information.

Suggested categories:

- Metal.
- Concrete.
- Industrial equipment.
- Machine armor.
- Raider body or protective gear.

Only use surface distinctions supported by reliable collision or material data.

If the current game does not identify surface materials, propose the smallest reliable classification mechanism.

Do not introduce a large material-detection framework without approval.

### Visual presentation

- Metal sparks.
- Concrete dust.
- Brief impact flashes.
- Small debris.
- Appropriate hit reactions.

### Audio presentation

- Metallic impacts.
- Hard-surface strikes.
- Armor hits.
- Character damage.
- Machine damage.

Effects should be readable but short-lived.

## 7. Damage and destruction

**Priority: Critical**

Improve damage presentation without changing health or death authority.

### Human Raiders

Potential effects:

- Hit reaction.
- Brief flinch.
- Equipment movement.
- Damage sound.
- Death animation transition.

### Player machine

Potential effects:

- Mechanical hit response.
- Sparks.
- Damage audio.
- Subtle visual indication of critical condition.
- Destruction effect.

### Ground and flying machines

Potential effects:

- Electrical sparks.
- Brief smoke.
- Mechanical damage sound.
- Destruction flash.
- Existing death animation integration.

Avoid persistent damage systems that require new gameplay state.

If persistent visual damage is proposed, it must derive from existing authoritative health or damage information.

Do not add ragdolls or simulated dismemberment.

## 8. Audio architecture

**Priority: Critical**

Establish a maintainable audio structure compatible with Godot.

Evaluate:

- AudioStreamPlayer.
- AudioStreamPlayer3D.
- Audio buses.
- Sound categories.
- Positional attenuation.
- Voice limits.
- Audio pooling where justified.

Recommended categories:

- Weapons.
- Impacts.
- Machines.
- Environment.
- Interface.
- Music, reserved for future use.

### Requirements

- Spatialized actor and environmental sounds where appropriate.
- UI audio remains non-positional.
- Sound levels are consistent.
- Multiple overlapping events remain intelligible.
- Audio nodes do not leak after scene transitions.
- Repeated sounds do not become excessively loud.
- No gameplay dependency on audio playback completion.

Prefer original, procedurally generated, or properly licensed audio assets.

Document asset provenance and licensing.

Do not assume that an asset available online is licensed for redistribution.

## 9. Weapon audio

**Priority: High**

Create distinct sonic identities for:

- Player weapon.
- Raider weapon.
- Ground-machine weapon, if present.
- Flying-scout weapon, if present.

The sounds should communicate weapon character without introducing new weapon mechanics.

Use restrained variation to avoid identical repeated samples.

Preserve clear positional information.

Do not overproduce loud or distorted audio.

## 10. Machine audio

**Priority: High**

Machines should have recognizable mechanical identities.

Potential sound layers:

- Electric motors.
- Servos.
- Mechanical movement.
- Rotor or propulsion noise.
- Idle machinery.
- Damage and destruction.

Use audio intensity or pitch variation only when driven by reliable actor state.

Avoid adding continuous audio emitters that become unnecessarily expensive at scale.

## 11. Environmental ambience

**Priority: High**

Establish ambience appropriate to the industrial salvage environment.

Potential sources:

- Distant machinery.
- Ventilation.
- Electrical hum.
- Wind.
- Metallic creaking.
- Loose industrial equipment.
- Occasional mechanical impacts.

Prefer localized ambience where spatial context matters.

Maintain sufficient quiet space for important combat cues.

Avoid constant loud ambience that masks approaching Raiders or machine activity.

## 12. Lighting and atmosphere

**Priority: Critical**

Improve the existing industrial environment without replacing Stage U geometry or Stage V assets.

Evaluate:

- Directional lighting.
- WorldEnvironment.
- Ambient light.
- Fog.
- Localized industrial lighting.
- Emissive materials.
- Shadow quality.
- Color balance.
- Contrast and exposure.

### Visual target

Grounded industrial atmosphere with clear gameplay readability.

Lighting should make the environment feel inhabited and functional, not merely dark.

Use restrained haze and fog to add depth.

Avoid effects that make Raiders difficult to identify or hide important objectives.

### Performance

Compare changes against the accepted graphical baseline.

Do not assume volumetric effects are appropriate without measuring their cost.

## 13. Environmental visual effects

**Priority: Medium**

Introduce a small reusable set of ambient effects.

Examples:

- Dust particles.
- Steam vents.
- Electrical sparks.
- Light smoke.
- Occasional mechanical emissions.

Prefer effects attached to appropriate environment locations.

Do not scatter particles indiscriminately throughout the map.

Keep navigation, collision, and cover unchanged.

## 14. HUD feedback

**Priority: High**

Review existing player feedback for:

- Damage received.
- Damage dealt.
- Salvage collection.
- Objective progress.
- Extraction.
- Death.
- Spectator transition.

Improve clarity where the current HUD does not adequately communicate accepted gameplay events.

Do not redesign the entire HUD.

Avoid excessive notification spam.

Maintain a clear hierarchy between mission-critical information and decorative feedback.

## 15. Camera feedback

**Priority: Medium**

Evaluate limited camera responses to:

- Weapon firing.
- Damage.
- Destruction.
- Extraction completion.

Use subtle, bounded effects.

Camera feedback must not interfere with aiming or spectator controls.

Respect camera ownership and existing mode transitions.

Avoid motion that could cause discomfort.

## 16. Actor inspection environment extension

**Priority: High**

Preserve the Stage W inspection scene.

Extend it where practical to preview:

- Weapon firing.
- Muzzle effects.
- Impact effects.
- Damage feedback.
- Death and destruction.
- Actor audio.
- Animation interactions.

The inspection environment must remain separate from the mission simulation.

It may trigger presentation demonstrations, but must not alter production combat logic to accommodate previews.

Provide convenient controls for selecting effects and repeating tests.

## 17. Determinism and simulation integrity

**Priority: Critical**

Stage X presentation must not influence seeded gameplay results.

Requirements:

- Presentation randomness is independent of gameplay randomness.
- Visual variation does not consume gameplay RNG state.
- Audio selection does not change AI decisions.
- Particle timing does not change mission logic.
- Effects do not affect physics collision unless explicitly authorized.
- Presentation cleanup does not alter actor lifecycle.
- Headless execution remains supported.

Where deterministic presentation is desirable for testing, use isolated seeded presentation randomness.

The authoritative simulation must remain reproducible.

## 18. Performance budget

**Priority: Critical**

Measure representative gameplay before and after changes.

Evaluate:

- Average and worst-frame time.
- Draw calls.
- Particle count.
- Active audio players.
- Active lights.
- Shadow cost.
- Memory usage.
- Simultaneous combat events.
- Scene transition cleanup.

Test scenarios should include:

- Several Raiders fighting simultaneously.
- Player and machines firing.
- Multiple impacts.
- Actor death and destruction.
- Post-death spectating.
- Full mission restart.

Use measurements rather than arbitrary performance claims.

## 19. Automated validation

Preserve the complete accepted regression suite.

Add targeted tests for:

1. Weapon event to effect mapping.
2. Rejected firing produces no firing presentation.
3. Accepted shots produce one presentation event.
4. Impact effects receive valid locations.
5. Damage reactions follow accepted damage.
6. Death effects follow authoritative death.
7. No duplicated loot or death handling.
8. Effect cleanup.
9. Audio cleanup.
10. Audio bus and resource validity.
11. Actor visual integration.
12. Mission restart.
13. Spectator compatibility.
14. Seeded simulation integrity.
15. Headless execution.
16. Scene and resource import validity.

Tests should validate observable behavior rather than implementation-specific internals.

## 20. Manual acceptance

### A. Player combat

Fire at surfaces and hostile actors.

Verify sound, muzzle effect, recoil, impacts, and hit confirmation.

### B. Raider combat

Observe multiple Raiders fighting.

Verify effects correspond to actual firing and impacts.

### C. Machine combat

Observe ground and flying machines in combat.

Verify distinctive mechanical presentation.

### D. Damage and death

Observe damage and destruction.

Verify effects do not interfere with loot, cleanup, or spectator transitions.

### E. Environment

Traverse the expanded salvage environment.

Evaluate lighting, atmosphere, visibility, and ambience.

### F. Audio

Evaluate positional accuracy, sound balance, and overlapping combat events.

### G. Spectator

Observe battles from the free and follow cameras.

Verify effects remain spatially correct.

### H. Restart

Restart the mission repeatedly.

Check for stale particles, audio emitters, and presentation state.

### I. Performance

Compare against Stage W baseline under similar conditions.

## 21. Stage X acceptance criteria

Stage X is complete when:

- Weapon firing feedback is noticeably improved.
- Impact effects are readable and correctly triggered.
- Damage and death presentation is coherent.
- Player, Raider, and machine audio is integrated.
- Environmental ambience is present.
- Lighting and atmosphere are improved.
- Existing HUD feedback remains clear.
- The Stage W actor inspection environment remains functional.
- Presentation is independent of authoritative gameplay.
- No accepted AI, combat, or mission behavior regresses.
- Existing automated suites pass.
- Graphical and headless validation pass.
- Performance changes are measured.
- Audio asset provenance is documented.
- The implementation and limitations are documented.

## 22. Explicit exclusions

Do not implement:

- New weapons.
- New combat damage rules.
- New AI behaviors.
- New Raider personalities.
- New machine types.
- New mission objectives.
- New maps.
- Multiplayer.
- Crafting.
- Full HUD redesign.
- Final cinematic sequences.
- Full character remodels.
- Advanced ragdoll physics.
- Large-scale destruction physics.
- A full music soundtrack.

These belong to later stages.

## 23. Implementation workflow

### Step 1 — Repository inspection

Inspect accepted Stage W implementation and current gameplay presentation.

Identify existing effects, audio, signals, and reusable components.

### Step 2 — Architecture proposal

Present:

- Current presentation architecture.
- Existing reusable systems.
- Proposed effect and audio structure.
- Combat-event integration points.
- Environmental lighting plan.
- Performance risks.
- Asset provenance plan.
- Testing strategy.
- Exact proposed file changes.

**Stop for director approval before implementing.**

### Step 3 — Combat feedback

After approval, implement weapon, impact, damage, and destruction presentation.

### Step 4 — Audio

Integrate spatial weapon, machine, impact, and environmental audio.

### Step 5 — Atmosphere

Improve lighting, ambience, and restrained environmental effects.

### Step 6 — Inspection and validation

Extend the Stage W inspection scene, run automated tests, and perform graphical validation.

### Step 7 — Stage X checkpoint

Deliver:

- Implemented feature inventory.
- Modified file summary.
- New audio and effect assets.
- Event integration documentation.
- Performance measurements.
- Regression results.
- Visual evidence.
- Known limitations.
- Manual acceptance checklist.
- Recommendations for Stage Y.

Do not advance to Stage Y without director approval.

Do not commit, reset, discard, or publish work without explicit authorization.

---

## Immediate Codex assignment

Inspect the current SCRAP Raiders repository and accepted Stage W implementation.

Prepare a Stage X architecture proposal focused on combat feedback, spatial audio, environmental atmosphere, and presentation quality.

Preserve authoritative gameplay, existing AI behavior, and deterministic simulation.

Prefer extending accepted systems over introducing new frameworks.

**Do not begin implementation until the director approves the proposal.**