# SCRAP Raiders — Stage P Development Ledger
## Dynamic Encounter Generation

**Phase:** 5 — Emergent Encounters, Spectating & Gameplay Depth  
**Stage:** P  
**Status:** Proposed — awaiting implementation-plan approval  
**Engine:** Godot 4.7.2 / GDScript  
**Prerequisites:** Stage N integrated mission and Stage O post-death spectator foundation

---

## 1. Project context

SCRAP Raiders is a stylized, comedic third-person extraction shooter where the player controls a machine defending and recovering technology from human Raiders.

Previous development established:

- Independent Raider objectives and personalities.
- Armed Raider combat, pursuit, retreat, and extraction.
- Automatic death flares and bounded reinforcement responses.
- Authoritative material and equipment accounting.
- Autonomous flying and ground machines.
- Raider-versus-Raider hostility, cooperation, and opportunistic betrayal.
- Loot competition and recovery.
- An integrated mission combining previously isolated mechanics.
- Developer free camera and post-death spectating.

The existing repository and development reports are authoritative. Inspect the current implementation and reconcile these capabilities before proposing changes.

Do not duplicate working systems.

## 2. Primary objective

Create a lightweight, configurable encounter system that produces varied interactions between Raiders, machines, salvage opportunities, and extraction objectives.

The world should remain active and interesting without player intervention.

Desired outcomes include:

- Raiders independently encountering and fighting machines.
- Rival Raiders competing for valuable salvage.
- Temporary cooperation against common threats.
- Opportunistic betrayal following changing circumstances.
- Raiders stealing loot and attempting extraction.
- Machine patrols intersecting Raider activity.
- Death flares drawing actors into already developing conflicts.
- Multiple independent encounters occurring during one deployment.

These are possible outcomes, not mandatory scripted sequences.

**Do not implement an encounter director that forces particular social behaviors.**

## 3. Architectural principles

Preserve:

1. One authoritative owner for each gameplay state.
2. Independent actor state machines.
3. Existing relationship and social decision systems.
4. Existing combat, perception, navigation, and extraction systems.
5. Authoritative material and equipment ledgers.
6. Seeded reproducibility.
7. Data-driven scenario configuration.
8. Clear separation between simulation and presentation.
9. Bounded processing and actor counts.
10. Minimal additional abstraction.

The encounter system may influence world conditions, spawn timing, actor placement, and objective availability.

It must not directly command Raiders to cooperate, betray, attack, or extract.

Actors continue making those decisions through their existing AI.

## 4. Encounter opportunities

**Priority: Critical**

Introduce a small collection of reusable encounter conditions.

### A. Contested salvage

Two or more Raiders discover the same valuable salvage opportunity.

Possible outcomes:

- One Raider collects the salvage first.
- Raiders ignore each other.
- Raiders cooperate against a nearby machine.
- Raiders become hostile over the objective.
- One Raider steals recovered loot after another is defeated.

Requirements:

- Finite, ledger-backed material quantities.
- No duplicate claims.
- Configurable salvage value and location.
- No forced hostility simply because actors share an objective.

### B. Machine patrol interception

An autonomous machine patrol crosses an active Raider route or scavenging location.

Possible outcomes:

- Raider attacks the machine.
- Raider avoids the patrol.
- Raiders cooperate against it.
- The machine interrupts an ongoing Raider conflict.
- The player arrives during the encounter.

Requirements:

- Reuse existing autonomous machine controllers.
- Reuse Raider machine-targeting logic.
- Preserve finite, preallocated machine components.
- No guaranteed combat outcome.

### C. Rival convergence

Independent Raiders enter overlapping operational areas.

Possible outcomes:

- Mutual avoidance.
- Competition for salvage.
- Hostile engagement.
- Temporary cooperation.
- Opportunistic betrayal.

Requirements:

- Use existing relationship and personality systems.
- Do not automatically assign hostility.
- Do not force a betrayal event.
- Allow each Raider to retain independent objectives.

### D. Extraction competition

Multiple Raiders attempt to use nearby or overlapping extraction routes.

Possible outcomes:

- Raiders extract independently.
- Hostile Raiders interfere with one another.
- A Raider abandons extraction to escape danger.
- Another Raider intercepts valuable carried loot.
- The player interrupts one or more extraction attempts.

Requirements:

- Preserve existing extraction ownership and mission rules.
- Avoid artificial extraction denial unless supported by gameplay mechanics.
- Keep navigation destinations valid and reachable.

### E. Death flare escalation

A Raider dies during an existing encounter.

The existing automatic death flare attracts nearby actors and may introduce bounded reinforcements.

Possible outcomes:

- Responders engage the machine responsible.
- Responders discover dropped equipment.
- Rival Raiders converge on the same location.
- Temporary allies compete over the resulting loot.
- The player exploits the distraction.

Requirements:

- Preserve one flare per accepted Raider death.
- Preserve reinforcement caps and anti-farming constraints.
- Reuse existing flare response and awareness systems.
- Avoid uncontrolled chains of reinforcement events.

## 5. Encounter configuration

**Priority: Critical**

Extend the existing scenario configuration system rather than introducing a separate mission framework.

Support practical parameters such as:

- Initial Raider count.
- Raider personality and relationship distribution.
- Scheduled Raider arrivals.
- Autonomous machine presence.
- Salvage locations and quantities.
- Spawn and extraction locations.
- Encounter opportunity placement.
- Optional timing offsets.
- Random seed.
- Maximum active actors.

Use existing configuration fields where available.

Add only the parameters needed to produce meaningful encounter variety.

Avoid exposing dozens of tuning variables before they are useful.

## 6. Encounter scheduling and population

**Priority: High**

Create opportunities for encounters throughout a deployment rather than concentrating all activity at mission start.

Potential techniques:

- Staggered Raider arrivals.
- Different starting objectives.
- Patrol routes that intersect salvage areas.
- Multiple extraction destinations.
- Finite high-value salvage opportunities.
- Bounded reinforcement activity.

Prefer extending existing spawn schedules and mission configuration.

Do not introduce infinite actor spawning or endless resource generation.

Do not spawn actors inside collision geometry, other actors, or unreachable areas.

Respect the existing navigation validation rules.

## 7. Emergent encounter interactions

**Priority: Critical**

The encounter system should not determine the final outcome.

For example:

A greedy Raider and an aggressive Raider arrive near valuable salvage while an autonomous machine patrol approaches.

The encounter system establishes the situation.

The Raiders independently decide whether to:

- Continue scavenging.
- Fight the machine.
- Cooperate temporarily.
- Avoid the encounter.
- Attack each other.
- Retreat.
- Extract.

Their decisions must remain governed by existing AI, relationships, perceived threats, and objectives.

If an outcome cannot occur because the existing AI lacks the necessary behavior, document that limitation.

Do not silently implement a new social decision framework as part of Stage P.

Reserve substantial behavioral changes for Stage Q.

## 8. Player participation

**Priority: High**

The player should be able to:

- Discover encounters already underway.
- Intervene in Raider-versus-Raider conflicts.
- Attack Raiders distracted by machine combat.
- Recover valuable loot after independent conflicts.
- Pursue Raiders attempting to extract.
- Retreat from dangerous multi-actor encounters.
- Exploit temporary alliances or betrayals.

Encounters must remain meaningful when the player ignores them.

Do not make the player the required trigger for every major event.

## 9. Spectator integration

**Priority: High**

Preserve the Stage O post-death spectator and existing developer camera.

Ensure encounter generation continues correctly while the player is spectating, subject to the existing mission lifecycle rules.

Useful developer diagnostics include:

- Active encounter opportunities.
- Participating actor identities.
- Current actor objectives.
- Relationship states.
- Relevant threat information.
- Encounter origin or configuration.
- Current material and equipment ownership.

Prefer extending the existing debug HUD and Raider inspector.

Do not expose internal AI reasoning or hidden encounter information through the normal player-facing spectator UI.

Do not make spectator camera position affect spawning, AI perception, or encounter selection.

## 10. Encounter reproducibility

**Priority: Critical**

Support deterministic scenario reproduction where practical.

Requirements:

- Record or expose the active scenario seed.
- Preserve stable encounter configuration.
- Keep seeded spawn and selection behavior reproducible.
- Avoid relying on nondeterministic iteration order for important decisions.
- Log meaningful encounter events during debugging.

Useful event examples:

- Raider entered encounter area.
- Raider selected salvage objective.
- Machine detected Raider.
- Rival engagement began.
- Temporary cooperation formed.
- Betrayal occurred.
- Raider recovered loot.
- Raider extracted.
- Encounter resolved.

Avoid excessive per-frame logging.

Do not promise perfectly identical physics outcomes across unrelated hardware.

The goal is reproducible setup and explainable behavior.

## 11. Encounter pacing and balance

**Priority: High**

Encounters should create tension without turning the entire map into constant combat.

Design for variation:

- Some encounters end peacefully.
- Some result in short fights.
- Some escalate into multi-actor battles.
- Some produce valuable loot opportunities.
- Some end with Raiders successfully escaping.
- Some unfold entirely without the player.

Avoid making every encounter a betrayal or firefight.

Preserve periods of exploration, pursuit, and scavenging between intense interactions.

Use bounded probabilities, personality parameters, and existing decision rules where appropriate.

Do not implement dynamic difficulty scaling during this stage unless separately approved.

## 12. Performance

**Priority: Critical**

Maintain acceptable performance with several independent actors operating simultaneously.

Requirements:

- Respect configured active actor limits.
- Avoid scanning every actor against every other actor every frame.
- Prefer existing awareness events and bounded decision intervals.
- Avoid excessive navigation recalculation.
- Avoid unnecessary scene instantiation.
- Prevent encounter scheduling from accumulating invalid or expired work.
- Ensure clean termination and restart behavior.

Record performance concerns discovered during testing.

Do not prematurely optimize unrelated systems.

## 13. Automated validation

Preserve all existing regression tests.

Add coverage for:

1. Seeded encounter configuration.
2. Valid actor spawn placement.
3. Bounded population and scheduling.
4. Multiple independent encounters.
5. Contested salvage without material duplication.
6. Raider-versus-Raider combat during encounters.
7. Autonomous machine participation.
8. Loot recovery following independent conflicts.
9. Extraction with contested or stolen cargo.
10. Automatic death flare integration.
11. Reinforcement limits.
12. Mission completion and restart.
13. Continued simulation during post-death spectating.
14. Spectator non-interference.
15. Material and equipment accounting invariants.

Tests should verify the world conditions and resulting authoritative state transitions.

Do not make tests depend on a specific betrayal or cooperation outcome unless the test explicitly controls the relevant AI conditions.

Run Godot editor parsing/import, existing automated suites, bounded headless runtime, and graphical startup validation.

Distinguish automated validation from manual play-testing.

## 14. Dedicated encounter test scenario

**Priority: Critical**

Create a new selectable scenario:

**Emergent Encounters — Development Preset**

Purpose:

Demonstrate multiple interacting systems in one reproducible mission.

Suggested initial configuration:

- Three to five Raiders.
- Mixed Raider personalities.
- At least one allied pair and one independent Raider.
- At least one autonomous machine patrol.
- Multiple salvage opportunities.
- Overlapping but reachable operational routes.
- At least two extraction destinations.
- Existing automatic death flare behavior.
- Existing material and equipment accounting.

Do not assume a specific function key is available.

Inspect existing input mappings before assigning a shortcut.

Keep previously accepted presets unchanged.

The scenario should support both normal player participation and developer spectator observation.

The exact configuration should be selected after reviewing existing navigation and performance constraints.

## 15. Manual play-testing

**Priority: Critical**

At the checkpoint, provide a practical play-test procedure.

Suggested tests:

**Passive observation**

Activate developer spectator mode and observe the raid without intervening.

Verify that actors independently scavenge, fight, cooperate, recover loot, and extract when conditions permit.

**Active participation**

Play normally and intervene in an encounter.

Verify that actors respond appropriately without abandoning their independent goals indefinitely.

**Post-death observation**

Allow the player robot to be destroyed, then follow surviving actors.

Verify that the simulation continues and that material accounting remains correct.

**Repeated deployment**

Replay the same seed and compare encounter setup and major decisions.

Change the seed and verify that encounter opportunities vary.

**High-population scenario**

Test several Raiders and autonomous machines simultaneously.

Observe congestion, targeting, navigation recovery, and performance.

## 16. Stage P acceptance criteria

Stage P is complete when:

- Multiple independent encounter opportunities can develop during one deployment.
- Raiders and machines interact without requiring player involvement.
- Rivalry, cooperation, and betrayal systems remain actor-driven.
- Valuable salvage can attract competing Raiders.
- Raiders can recover loot and extract after independent conflicts.
- Existing death flares can escalate ongoing encounters.
- Encounter schedules and populations remain bounded.
- A reproducible development scenario demonstrates the interactions.
- The player can participate in or ignore encounters.
- Developer and post-death spectating remain functional.
- Material and equipment ownership remain correct.
- Existing scenarios and regression tests remain intact.
- Automated validation passes.
- Manual play-testing demonstrates believable encounter variety.

## 17. Implementation workflow

Before implementation:

1. Inspect the current repository, documentation, and Git status.
2. Review the actual Stage M, N, and O implementations and completion reports.
3. Identify which encounter capabilities already exist.
4. Identify the minimum additional configuration or scheduling needed.
5. Propose the Stage P architecture.
6. Identify risks, dependencies, and test strategy.
7. Present a concise implementation plan for approval.

After approval:

1. Implement the minimum viable encounter system.
2. Extend automated validation.
3. Validate Godot parsing and runtime behavior.
4. Provide a reproducible development preset.
5. Document implementation decisions.
6. Report what was actually delivered.
7. Identify manual play-testing requirements.
8. Create a focused Git commit according to repository conventions.
9. Stop at Checkpoint P.

Do not advance to Stage Q without separate approval.

## 18. Immediate assignment

Inspect the current SCRAP Raiders repository and prepare the Stage P implementation plan.

**Do not begin implementation until the plan is reviewed and approved.**

Prioritize the smallest architectural change that creates substantially more interesting encounters.

The objective is not to script entertaining situations.

**The objective is to create a world in which entertaining situations can happen on their own.**