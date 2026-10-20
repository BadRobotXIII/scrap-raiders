# SCRAP Raiders — Phase 2: Dynamic Gameplay and Replayability

You are continuing development of SCRAP Raiders, an original comedic third-person 3D extraction game built with Godot 4.7.2 and GDScript.

The initial playable prototype is complete. It includes a controllable robot, third-person shoulder camera, hitscan combat, muzzle flashes, audio, hit confirmation, health and damage, Raider AI, loot recovery, mission accounting, extraction outcomes, and physical death reactions.

We are now entering Phase 2: Dynamic Gameplay and Replayability.

Your objective is to evolve the existing prototype into a more entertaining and replayable gameplay sandbox without losing architectural clarity or introducing unnecessary complexity.

## 1. Development approach

First, inspect the actual repository and determine the current implementation state.

Do not assume that every system described here exists exactly as documented. The repository is authoritative.

Review:

- Existing scenes, scripts, and resources.
- AGENTS.md and README.md.
- Git status and recent commits.
- Current gameplay and mission architecture.
- Raider state ownership and navigation.
- Weapon, health, interaction, and loot systems.
- Current automated tests and validation commands.

Preserve working functionality.

Identify architectural problems before extending systems.

Do not rewrite functioning systems unnecessarily.

Before major implementation, provide a concise plan identifying dependencies, expected changes, and potential risks.

You are authorized to execute Phase 2 incrementally, but stop at the defined review checkpoints.

## 2. Multiple autonomous Raiders

Replace the single-Raider limitation with support for multiple simultaneously active Raiders.

Requirements:

- Spawn multiple Raider instances.
- Each Raider maintains independent state and objectives.
- Raiders can select different salvage locations.
- Raiders can collect cargo independently.
- Raiders can flee, extract, or die independently.
- Multiple Raiders can navigate simultaneously.
- Raiders must not overwrite each other's state.
- Mission accounting must correctly aggregate outcomes across all Raiders.

Use a configurable Raider count rather than hardcoding a fixed number throughout the codebase.

Initially target 3–5 active Raiders, subject to gameplay and performance testing.

Ensure one Raider's death or extraction does not accidentally terminate another Raider's behavior.

### Mission ownership

The mission controller remains the sole authority for material accounting and mission completion.

Raiders report relevant events.

They do not directly manipulate mission totals.

Maintain the invariant:

Protected + Carried + Ground + Recovered + Lost = Total Mission Materials

Adapt this invariant if the actual implementation has additional material states, but document the accounting model explicitly.

Prevent double-counting during death, extraction, recovery, and simultaneous events.

## 3. Dynamic salvage objectives

Introduce multiple salvage locations distributed throughout the arena.

Raiders should choose salvage objectives based on simple, understandable rules.

Possible selection factors:

- Distance to salvage.
- Available material quantity.
- Current threat proximity.
- Whether another Raider is already targeting the location.
- Raider behavioral preferences.

Start with deterministic scoring and controlled randomness.

Use a seeded random generator where practical so scenarios can be reproduced during debugging.

Avoid building a complicated planning system.

Salvage locations should expose clear ownership and availability rules.

Two Raiders attempting to collect the same material must not duplicate it.

If an objective becomes unavailable, the Raider should select another valid objective or proceed toward extraction.

## 4. Improved Raider behavior

Expand the Raider AI beyond a linear scavenging path.

Preserve explicit state-machine ownership.

Introduce behavior such as:

- Choosing between multiple salvage objectives.
- Investigating nearby threats.
- Fleeing when threatened.
- Seeking a safer extraction route.
- Returning to scavenging when danger subsides.
- Extracting after collecting enough cargo.
- Reacting to nearby Raider deaths or gunfire.

Do not implement every behavior simultaneously.

Build and test each transition independently.

### Behavioral personalities

Introduce a small data-driven Raider profile system.

Start with three profiles:

**Greedy**
- Higher willingness to continue scavenging.
- Greater cargo target before extraction.
- More reluctant to abandon loot.

**Cowardly**
- Larger threat-detection radius.
- Earlier retreat decisions.
- Greater preference for safe extraction routes.

**Aggressive**
- More willing to approach danger.
- Less likely to immediately flee.
- Can investigate the player's position.

Aggressive does not necessarily mean armed combat. Do not introduce Raider weapons until separately approved.

Profiles should modify parameters and decisions rather than duplicate the entire AI implementation.

Maintain one common Raider state machine.

### Predictability and debugging

Expose useful debug information:

- Current Raider state.
- Selected salvage target.
- Cargo carried.
- Current destination.
- Active personality profile.
- Current threat status.

Use readable labels or a toggleable debug overlay.

Do not allow debug information to interfere with gameplay controls.

## 5. Dynamic spawning and extraction

Introduce configurable Raider spawn points and extraction locations.

Requirements:

- Multiple possible spawn locations.
- Multiple possible extraction destinations.
- Variable Raider entry timing.
- Basic spawn validation.
- No spawning inside obstacles or other actors.
- Raiders choose reachable extraction locations.
- Spawn behavior should be reproducible with a debug seed.

Do not create an elaborate spawning director yet.

A simple mission configuration resource or equivalent centralized configuration is sufficient.

Avoid embedding mission-specific coordinates directly into Raider scripts.

## 6. Expand the graybox arena

The current arena was designed for validating basic movement and combat.

Expand it into a more interesting but still lightweight test environment.

Include:

- Multiple traversable routes.
- Obstacles that break line of sight.
- Cover opportunities.
- Open combat areas.
- Narrower passages.
- Several salvage locations.
- Multiple extraction zones.
- A few elevated or sloped areas if navigation supports them reliably.

Preserve the stylized, simple visual approach.

Use primitive geometry and basic materials.

The objective is to test navigation, pursuit, interception, and combat—not create finished environmental art.

### Navigation

Validate that all important gameplay locations are reachable.

Avoid situations where Raiders become permanently stuck.

If a Raider cannot reach its destination, provide a clear recovery strategy:

- Retry navigation.
- Select another objective.
- Choose an alternate extraction.
- Enter a documented fallback state.

Do not silently teleport Raiders unless explicitly approved as a debug-only recovery mechanism.

## 7. Improve combat interactions

Preserve the current shooting system, audio, muzzle flash, hit markers, and damage feedback.

Add limited enhancements where they support the new gameplay:

- Raiders react to nearby gunfire.
- Damage interrupts relevant Raider behaviors.
- Death reactions preserve cargo accounting.
- Physics reactions remain presentation effects.
- Multiple Raiders can be hit and killed independently.

Keep weapon damage, cooldowns, and health ownership centralized.

Do not implement weapon inventories, complex ballistics, or advanced combat equipment in this phase.

## 8. Interaction and loot recovery

Preserve the existing proximity-based recovery prompt.

Ensure the same authoritative interaction check controls both prompt visibility and pickup eligibility.

Support multiple independent loot drops.

Requirements:

- Multiple loot objects can coexist.
- Each drop has a unique identity or otherwise unambiguous ownership.
- Recovering one drop does not affect unrelated drops.
- Recovery cannot happen twice.
- Loot remains recoverable after the Raider's death animation finishes.
- Mission accounting updates exactly once.

If multiple interactable objects are in range, choose one deterministically, preferably the nearest valid target.

The debug HUD and gameplay interaction prompts must remain logically separate.

## 9. Mission variety and replayability

Introduce a small number of mission configuration parameters:

- Raider count.
- Total salvage.
- Mission duration.
- Raider spawn timing.
- Available extraction points.
- Random seed.

The same gameplay systems should support different configurations without code duplication.

Create at least three test configurations:

**Intercept**
A small number of Raiders attempt to steal a limited amount of salvage.

**Swarm**
More Raiders enter the map, creating multiple simultaneous interception decisions.

**Recovery**
Some salvage begins on the ground and must be recovered before the mission ends.

Use the existing mission rules where possible.

Do not introduce an elaborate campaign, progression system, or menu architecture yet.

Make configurations accessible through a simple debug selection mechanism if practical.

## 10. Visual and audio feedback

Retain the current blocky, humorous visual identity.

Do not replace the player robot with a detailed Blender model during this phase.

Add small improvements only where they support readability:

- Distinguishable Raider profiles.
- Clear salvage locations.
- Recognizable extraction areas.
- Visible threat or alert feedback.
- Readable loot interaction indicators.
- Consistent hit and death feedback.

Avoid excessive UI clutter.

Preserve a toggleable developer/debug HUD.

Gameplay information and developer diagnostics should remain separate.

## 11. Architecture and quality requirements

Continue following these principles:

- One authoritative owner per gameplay state.
- Explicit state machines.
- Centralized mission accounting.
- Event-driven communication where appropriate.
- No duplicated control paths.
- No unnecessary global state.
- Minimal speculative abstraction.
- Data-driven configuration where useful.
- Clear separation of simulation, input, and presentation.
- Predictable error handling.
- No hidden state resets from unrelated systems.

Avoid introducing an event bus, dependency injection framework, or large generic AI framework unless the existing codebase genuinely requires one.

Do not introduce multiplayer networking in this phase.

## 12. Automated testing

Expand the existing automated tests.

Prioritize:

- Multiple Raiders operating independently.
- Concurrent salvage collection.
- No duplicated materials.
- Correct accounting after simultaneous deaths and extractions.
- Unique loot recovery.
- Raider state transitions.
- Invalid objective recovery.
- Mission completion rules.
- Seeded scenario reproducibility.
- Spawn validation.
- Multiple extraction destinations.

Verify material accounting invariants after relevant state transitions.

Run:

`godot --headless --path . --editor --quit`

And the existing automated gameplay test suite.

Perform bounded runtime validation and graphical startup checks where available.

Clearly distinguish automated validation from manual gameplay testing.

## 13. Performance

The initial target is 3–5 Raiders simultaneously.

Avoid premature optimization.

However, monitor:

- Navigation performance.
- Physics overhead.
- AI decision frequency.
- Excessive per-frame allocations.
- Unnecessary repeated path calculations.

Prefer event-driven updates or fixed decision intervals where appropriate.

Do not sacrifice maintainability for speculative performance gains.

## 14. Git workflow

Preserve the existing repository and GitHub configuration.

Before implementation:

- Verify the working tree.
- Identify uncommitted user changes.
- Do not discard existing work.
- Confirm the current branch.

Create focused commits at stable milestones.

Do not force-push, rewrite history, or overwrite unrelated changes.

Follow existing repository conventions for pushing to GitHub.

## 15. Implementation stages

Proceed in this order:

### Stage A — Multi-Raider foundation
- Multiple independent Raiders.
- Multiple salvage locations.
- Correct shared material accounting.
- Multiple recoverable loot drops.
- Automated tests.

**Checkpoint A:** Stop and report results for review.

### Stage B — Dynamic AI
- Objective selection.
- Multiple extraction choices.
- Threat reactions.
- Raider personality profiles.
- Navigation recovery.
- Automated tests.

**Checkpoint B:** Stop and report results for review.

### Stage C — Arena and mission variety
- Expanded graybox arena.
- Configurable spawns.
- Three mission configurations.
- Debug scenario selection.
- Automated tests.

**Checkpoint C:** Stop and report results for review.

### Stage D — Gameplay refinement
- Improved visual cues.
- Gunfire awareness.
- More expressive Raider reactions.
- Minor interaction and combat refinements.
- Automated tests.

**Checkpoint D:** Stop and report results for review.

Do not automatically advance past a checkpoint without approval.

## 16. Completion criteria

Phase 2 is successful when:

- Multiple Raiders can independently scavenge and extract.
- The player must make meaningful interception decisions.
- Salvage and loot accounting remain correct.
- Different mission configurations produce noticeably different encounters.
- AI behavior is understandable but not completely predictable.
- The game remains responsive and stable.
- Existing movement and combat functionality are preserved.
- Automated tests pass.
- Manual play-testing confirms the experience is entertaining.

## 17. Immediate task

Inspect the current repository and present the implementation plan for Stage A.

Identify any existing systems that need refactoring and explain why.

Do not begin Stage A implementation until the plan is reviewed and approved.

After approval, implement Stage A, validate it, commit the changes, and stop at Checkpoint A.