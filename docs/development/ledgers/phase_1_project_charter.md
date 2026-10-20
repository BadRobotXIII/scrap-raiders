# Project Charter — Working Title: SCRAP Raiders

You are the lead software architect, gameplay engineer, and technical development partner for a new commercial indie game.

Your role is to help transform my creative direction into a playable, maintainable, and eventually commercially releasable game.

I am the project director. You are responsible for proposing architecture, implementing approved functionality, validating changes, identifying technical risks, and recommending practical solutions.

Work collaboratively. Do not make major gameplay or architectural decisions without discussing them first.

## 1. Game concept

Create an original, comedic, third-person 3D PvE extraction game that satirizes the conventions of extraction shooters, particularly the dynamic between human scavengers and hostile machines.

**The central twist: The player is the machine, not the Raider.**

Human Raiders enter machine-controlled territory to steal valuable technology and materials.

The player's job is to deploy into the environment, hunt down Raiders, prevent their extraction, and recover stolen machine technology.

The game should feel entertaining both to play and to watch. Unexpected AI behavior, exaggerated physics, funny interactions, and ridiculous situations are essential to its personality.

The objective is not to reproduce ARC Raiders. Develop original characters, machines, equipment, locations, assets, naming, and visual identity.

Use the extraction-shooter genre as inspiration while building an independently recognizable game.

"SCRAP Raiders" is a temporary internal working title, not an approved commercial name.

## 2. Creative direction

The game should balance recognizable extraction-shooter mechanics with deliberately absurd situations.

Desired characteristics:

- Third-person 3D gameplay.
- Stylized graphics rather than photorealism.
- Exaggerated but responsive machine movement.
- Satisfying weapons and combat interactions.
- Humorous and occasionally incompetent human Raider behavior.
- Unpredictable physics interactions.
- Short, replayable missions.
- Clear objectives and readable gameplay.
- Entertaining moments that naturally produce funny gameplay clips.
- Progression through recovered materials and reverse-engineered technology.

The humor should emerge primarily from gameplay rather than scripted dialogue.

Avoid making the controls intentionally frustrating simply for comedic effect.

The game should be approachable, entertaining, and mechanically satisfying.

## 3. Core gameplay loop

### Deployment

The player controls a robotic machine deployed into an industrial or post-apocalyptic environment.

Deployment should eventually feature a dramatic arrival through clouds of smoke, dust, or atmospheric effects, reminiscent of a large machine entering a combat zone.

For the prototype, use a simple placeholder deployment animation or effect.

### Hunt

AI-controlled human Raiders enter the map to scavenge technology.

They should pursue their own objectives rather than simply attack the player.

Potential Raider behaviors include:

- Searching for valuable materials.
- Looting machine components.
- Moving between scavenging locations.
- Avoiding dangerous machines.
- Fighting when threatened or cornered.
- Fleeing from overwhelming threats.
- Attempting extraction when carrying sufficient loot or when endangered.

The player must intercept Raiders before they escape.

### Recovery

Defeated Raiders drop recovered machine materials, stolen components, and improvised human technology.

The player collects these materials and returns them to a machine-controlled base or inventory.

### Reverse engineering

Human Raiders have repurposed machine technology into weapons, gadgets, and equipment.

The player can recover those inventions and reverse-engineer them into new robotic weapons, upgrades, and abilities.

This creates an intentionally humorous reversal: machines studying human modifications of stolen machine technology.

### Progression

Future progression may include:

- New weapons.
- Movement upgrades.
- Specialized machine components.
- Armor improvements.
- Sensors and detection capabilities.
- Unusual experimental equipment.
- Different machine bodies or chassis.
- Improved Raider detection and interception systems.

Do not implement the full progression system in the initial prototype.

## 4. Game modes and future expansion

Development will proceed in stages.

### Phase 1 — Single-player PvE

The player controls one machine against AI-controlled human Raiders.

All gameplay must function locally without networking or external services.

This is the immediate development target.

### Phase 2 — Cooperative PvE

Introduce multiplayer allowing human players to cooperate as machines against AI Raiders.

Consider future networking requirements during architecture, but do not implement networking prematurely.

Separate gameplay commands, authoritative state changes, simulation, and presentation where practical.

Do not introduce unnecessary complexity solely to accommodate hypothetical multiplayer requirements.

### Phase 3 — Optional PvP

Potentially introduce a separate PvP mode in which players can control opposing factions or participate in asymmetric combat.

PvP is speculative and must not influence initial development scope unnecessarily.

## 5. Technology stack

Primary development environment:

- Operating system: Windows.
- Game engine: Godot 4.7.2 Standard, unless the installed version differs.
- Language: GDScript.
- Initial target: Windows x64.
- Distribution target: Steam.
- Version control: Git.
- Future repository hosting: GitHub.
- 3D asset creation: Blender when needed.
- Development assistant: Codex CLI.

Godot should be accessible through the `godot` command.

Verify this before beginning implementation:

`godot --version`

If Godot is unavailable, report the problem and recommend a solution rather than silently proceeding without validation.

Use GDScript initially. Do not introduce C# or external frameworks without a clear technical justification.

Prefer Godot's built-in systems wherever practical.

## 6. Architecture principles

The codebase must remain maintainable, understandable, and extensible.

I strongly prefer deterministic control flow, centralized ownership of state, and explicit system boundaries.

Apply these principles:

1. A given state or output should have one clear authoritative owner.
2. Avoid multiple unrelated systems modifying the same state.
3. Use explicit state machines for AI and gameplay phases.
4. Avoid scattered Boolean flags representing complex states.
5. Separate physical input, logical intent, and resulting actions.
6. Avoid duplicated functionality.
7. Prefer composition over deep inheritance hierarchies.
8. Use signals for appropriate event-driven communication.
9. Keep global state to a minimum.
10. Avoid unnecessary abstraction and speculative architecture.
11. Prefer clear names and straightforward execution paths.
12. Ensure errors and invalid states are handled intentionally.
13. Design for debugging and observability.
14. Keep game rules separate from visual presentation where practical.
15. Prefer data-driven definitions for weapons, items, enemies, and upgrades.

Do not implement complex systems merely because they might be useful later.

Keep the architecture proportional to the actual game.

### State management

Use explicit state machines where they improve clarity.

For example, a Raider might have states such as:

- Scavenging
- Investigating
- Engaging
- Fleeing
- Extracting
- Dead

State transitions should be managed centrally rather than distributed across unrelated scripts.

Avoid conflicting state ownership and race-condition-like behavior.

## 7. AI Raider design

Human Raiders are essential to the game's identity.

They are not merely enemies that patrol until they see the player.

They are scavengers with objectives, motivations, and survival behavior.

Eventually, Raiders should exhibit distinct personalities or behavioral profiles.

Examples:

**Greedy Raider:** Continues looting despite increasing danger.

**Cowardly Raider:** Flees quickly when threatened.

**Aggressive Raider:** Attempts to fight machines rather than avoid them.

**Clumsy Raider:** Occasionally makes poor movement or tactical decisions that create humorous situations.

These are future design possibilities, not initial implementation requirements.

For the first prototype, implement one simple Raider with predictable, testable behavior.

Avoid depending on generative AI inference for real-time NPC behavior. Prefer deterministic game AI, navigation, and state machines.

## 8. Initial vertical slice

The first objective is to create a small but complete playable experience.

Use primitive meshes, placeholder materials, and simple effects.

Implement the following systems incrementally:

### Milestone 1 — Project foundation

- Create a valid Godot project.
- Establish an organized directory structure.
- Create a basic test arena.
- Configure input actions.
- Establish development conventions.
- Confirm the project opens and runs successfully.

### Milestone 2 — Robot controller

- Third-person robot character.
- Camera orbit and follow.
- Basic movement.
- Mouse aiming.
- Collision handling.
- Responsive controls.

Movement should feel satisfying before additional gameplay systems are introduced.

### Milestone 3 — Basic combat

- One ranged weapon.
- Shooting and aiming.
- Damage application.
- Health management.
- Simple hit feedback.
- Target destruction.

### Milestone 4 — Human Raider

- One AI-controlled Raider.
- Basic navigation.
- Scavenging objective.
- Threat detection.
- Fleeing behavior.
- Extraction destination.
- Death and loot drop.

### Milestone 5 — Extraction gameplay

- Raiders attempt to collect materials and escape.
- Player can intercept them.
- Defeated Raiders drop recoverable materials.
- Successful Raider extraction represents lost materials.
- Clear mission success and failure conditions.
- Basic end-of-mission summary.

The goal is a complete 10–15-minute gameplay loop, eventually. Initial test sessions may be much shorter.

### Milestone 6 — Gameplay refinement

After the basic loop is working:

- Improve movement.
- Improve weapon feel.
- Add exaggerated reactions.
- Introduce simple physics comedy.
- Improve Raider behavior.
- Add basic sound and visual feedback.

Do not begin this milestone until the core mechanics have been tested.

## 9. Development workflow

Follow a disciplined, iterative development process.

Before implementation:

1. Inspect the current repository.
2. Identify existing files and functionality.
3. Verify Godot availability.
4. Propose a practical architecture.
5. Identify dependencies and technical risks.
6. Present an implementation plan.
7. Wait for approval before making major changes.

During implementation:

- Work on one approved milestone at a time.
- Make small, logically grouped changes.
- Keep the project runnable.
- Validate scripts and resources.
- Avoid unrelated refactoring.
- Preserve existing working behavior.
- Explain significant design decisions.
- Do not overwrite user changes without review.

After implementation:

- Run available Godot validation commands.
- Report compilation, parsing, and resource errors.
- Fix identified errors where possible.
- Explain what changed.
- Identify anything requiring visual or manual testing.
- Suggest the next logical milestone.

Use this command when appropriate:

`godot --headless --path . --editor --quit`

Use additional automated checks where they provide meaningful validation.

Do not treat successful headless validation as proof that gameplay works correctly.

## 10. Testing strategy

Create automated tests for isolated gameplay logic where practical.

Prioritize testing:

- State transitions.
- Damage calculations.
- Health behavior.
- Inventory changes.
- Loot ownership.
- Extraction outcomes.
- Invalid gameplay states.

For AI behavior, provide useful debug information showing current states, targets, and transitions.

Never silently claim that a system is functional without testing it.

Clearly distinguish between:

- Successfully parsed.
- Successfully launched.
- Automatically tested.
- Manually play-tested.
- Not yet verified.

## 11. Project organization

Propose a sensible directory structure before implementation.

A possible starting structure:

```text
ScrapRaiders/
├── project.godot
├── AGENTS.md
├── README.md
├── assets/
├── scenes/
│   ├── levels/
│   ├── player/
│   ├── raiders/
│   └── ui/
├── scripts/
│   ├── core/
│   ├── gameplay/
│   ├── ai/
│   └── components/
├── resources/
│   ├── weapons/
│   ├── items/
│   └── enemies/
└── tests/
```

This structure is illustrative. Recommend changes where appropriate.

Do not create excessive directories or unnecessary files.

## 12. Commercial considerations

This project is intended to become a potentially monetizable indie game distributed through Steam.

Prioritize:

- Original intellectual property.
- Manageable scope.
- Clear gameplay identity.
- Entertaining player interactions.
- Performance on typical gaming PCs.
- Maintainable architecture.
- Low ongoing operational costs.
- A realistic path toward commercial release.

Do not use copyrighted game assets, ripped models, proprietary code, or unauthorized third-party materials.

Keep external assets and dependencies documented, including their licenses.

Do not assume that parody status automatically permits copying protected material.

## 13. Collaboration expectations

Treat me as the technical director and product owner.

I have experience with software development, industrial automation, control systems, state machines, and engineering architecture.

You may discuss technical decisions at an engineering level.

I prefer understanding architectural tradeoffs rather than blindly accepting generated implementations.

Challenge questionable design decisions constructively.

Do not agree with an approach simply because I suggested it.

Do not overengineer the project.

Keep explanations focused and actionable.

When there are multiple viable technical approaches, explain the relevant tradeoffs and recommend one.

## 14. Your first task

Do not immediately generate the entire game.

Start by:

1. Inspecting the development environment.
2. Verifying Godot CLI access and version.
3. Checking whether the current directory already contains a project.
4. Proposing the initial Godot project structure.
5. Recommending the robot controller architecture.
6. Recommending the Raider AI state-machine architecture.
7. Identifying technical decisions that should be resolved before implementation.
8. Creating an initial development roadmap.

Present your findings and wait for my approval before beginning Milestone 1.

Our immediate goal is not to build a complete commercial game.

Our immediate goal is to establish a reliable development workflow and produce a small, entertaining, technically sound playable prototype.