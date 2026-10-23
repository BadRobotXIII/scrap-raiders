# SCRAP Raiders — Stage R Development Ledger
## Encounter Balance, Gameplay Refinement & Integrated Mission Polish

**Phase:** 5 — Emergent Encounters, Spectating & Gameplay Depth  
**Stage:** R  
**Status:** Proposed — implementation plan required  
**Engine:** Godot 4.7.2 / GDScript  
**Prerequisites:** Accepted Stage P and completed Stage Q implementation, subject to Checkpoint Q acceptance

---

## 1. Project context

SCRAP Raiders is a third-person PvE extraction shooter featuring independent Raider AI, autonomous machines, finite loot, combat, scavenging, social interactions, extraction, and post-death spectating.

The current development baseline includes:

- Independent Greedy, Cowardly, and Aggressive Raider personalities.
- Personality-aware armed combat decisions introduced in Stage Q.
- Raider-versus-Raider conflict, cooperation, and opportunistic betrayal.
- Autonomous machine combat and patrol behavior.
- Finite material and equipment accounting.
- Raider looting and extraction.
- Automatic death flares and bounded reinforcements.
- Seeded encounter generation and staggered arrivals.
- An integrated mission combining gameplay mechanics.
- Developer spectating and post-death actor following.

Inspect the current repository and accepted completion reports to verify actual implementation details.

Do not assume proposed features were delivered unless confirmed by code or completion records.

## 2. Primary objective

Improve the quality, pacing, clarity, and reliability of existing gameplay without substantially expanding the feature set.

Stage R should make a normal deployment feel like a coherent extraction experience rather than a collection of interacting test systems.

The target experience should include:

- Periods of exploration and scavenging.
- Occasional independent encounters.
- Meaningful pursuit and escape.
- Recognizable Raider personalities.
- Readable combat and damage.
- Valuable opportunities to recover loot.
- Successful and unsuccessful Raider extractions.
- Unexpected multi-actor interactions.
- Player agency to engage, avoid, interrupt, or exploit encounters.

Preserve emergent outcomes. Do not force a specific narrative, winner, betrayal, or extraction result.

## 3. Design principles

1. Improve existing systems before adding new ones.
2. Preserve one authoritative owner for each gameplay state.
3. Preserve the existing Raider FSM and combat composition.
4. Maintain independent actor decision-making.
5. Prefer measurable corrections over speculative tuning.
6. Preserve seeded reproducibility.
7. Keep actor populations and scheduling bounded.
8. Avoid hidden difficulty manipulation.
9. Preserve all material and equipment conservation guarantees.
10. Use the integrated mission as the primary gameplay acceptance environment.

Do not introduce a new AI controller, strategic planner, encounter director, or parallel mission framework.

## 4. Workstream A — Encounter pacing

**Priority: Critical**

Review how often encounters occur, how long they last, and how they affect the player's ability to pursue objectives.

Investigate:

- Excessive combat immediately after deployment.
- Long periods without meaningful activity.
- Multiple encounters collapsing into one continuous firefight.
- Raiders repeatedly converging on the same location.
- Too many actors extracting before the player can interact.
- Reinforcements overwhelming existing encounters.
- Encounters continuing indefinitely without progress.

Prefer tuning existing scheduling, objective distribution, actor counts, awareness, and encounter placement.

Do not script mandatory quiet periods or forced combat.

### Acceptance

Across several seeds, the integrated mission produces varied pacing, including opportunities for scavenging, interception, combat, and extraction.

Not every deployment should have the same intensity curve.

## 5. Workstream B — Personality and combat balance

**Priority: Critical**

Evaluate Stage Q personality-aware combat in actual gameplay.

### Greedy

Verify that Greedy Raiders:

- Pursue valuable salvage when conditions are favorable.
- Defend against immediate attackers.
- Recognize when carried cargo is worth preserving.
- Disengage when appropriate.
- Do not oscillate between combat and salvage objectives.

### Cowardly

Verify that Cowardly Raiders:

- Avoid unnecessary combat.
- Attempt early escape from credible threats.
- Use defensive fire when necessary.
- Can escape through reachable routes.
- Do not become helpless targets or permanently flee.

### Aggressive

Verify that Aggressive Raiders:

- Initiate appropriate engagements.
- Pursue observed enemies.
- Investigate bounded last-known positions.
- Maintain commitment through minor visibility interruptions.
- Release expired or invalid targets.
- Can still retreat under critical survival conditions.

### Shared combat review

Evaluate:

- Engagement distance.
- Aim and firing opportunities.
- Cover selection.
- Peek behavior.
- Damage responsiveness.
- Close-range spacing.
- Retreat routes.
- Body blocking.
- Target switching.
- Combat disengagement.

Avoid making all personalities equally effective in every situation.

Differences in survival rate, loot recovered, and combat frequency may be desirable consequences of personality.

Do not modify weapon damage, accuracy, health, and AI policy simultaneously without controlled comparison.

### Acceptance

A player should be able to recognize meaningful personality differences from behavior, without reading developer labels.

Combat remains fluid and physically credible.

## 6. Workstream C — Navigation and congestion

**Priority: Critical**

Review physical movement under integrated mission conditions.

Investigate:

- Raiders obstructing one another in narrow passages.
- Repeated failed path requests.
- Cover-position congestion.
- Actors blocking extraction routes.
- Machine and Raider collision interference.
- Pursuit loops around obstacles.
- Retreat routes that never complete.
- Actors attempting to reach inaccessible loot.
- Navigation recovery that repeatedly returns to the same failure.

Reuse existing navigation watchdogs, spacing, steering, and reachability checks.

Prioritize localized corrections over replacing the navigation architecture.

Ensure movement recovery cannot cause infinite state oscillation or bypass physical constraints.

### Acceptance

Actors can complete ordinary scavenging, pursuit, retreat, and extraction tasks without persistent stalls.

Unreachable objectives are abandoned or recovered from through documented decision paths.

## 7. Workstream D — Loot economy and extraction incentives

**Priority: High**

Review whether the existing loot and extraction rules create meaningful decisions.

Investigate:

- Raiders extracting with trivial cargo too frequently.
- Raiders carrying valuable cargo but taking unnecessary risks.
- Loot accumulation creating excessive combat incentives.
- Valuable dropped equipment being consistently ignored.
- Player recovery opportunities disappearing too quickly.
- Recovered materials lacking practical significance.
- Extraction pressure being either irrelevant or overwhelming.

Tune existing values, priorities, timing, and objective selection where justified.

Do not introduce crafting, progression, shops, equipment equipping, or a new currency system.

MaterialLedger and EquipmentLedger remain the exclusive authorities for ownership and transfers.

### Acceptance

Scavenging, protecting cargo, fighting, and extracting represent meaningful competing choices.

The player has realistic opportunities to recover valuable materials through active intervention.

All existing conservation invariants remain valid.

## 8. Workstream E — Player combat and feedback

**Priority: High**

Improve the readability of existing gameplay without requiring a major art or animation pass.

Review:

- Whether incoming damage is noticeable.
- Whether attackers can be identified.
- Whether successful hits are clearly communicated.
- Whether death and deployment failure are understandable.
- Whether extraction progress and interruptions are clear.
- Whether loot recovery interactions communicate success and failure.
- Whether combat becomes visually confusing with several actors present.

Prefer small improvements using existing HUD, audio, effects, and presentation systems.

Examples may include restrained hit indicators, damage feedback, recovery feedback, or clearer extraction-state presentation.

Do not implement an extensive new HUD, weapon system, animation pipeline, or visual-effects framework.

### Acceptance

The player can understand what is happening during a typical multi-actor encounter without relying on developer diagnostics.

## 9. Workstream F — Autonomous machine interactions

**Priority: High**

Review how autonomous machines contribute to the integrated mission.

Investigate:

- Machines overwhelming Raiders too easily.
- Machines being consistently ineffective.
- Patrols failing to intersect meaningful activity.
- Machines repeatedly obstructing navigation.
- Raiders abandoning all other objectives to hunt machines.
- Machine destruction producing disproportionate rewards.
- Machine combat triggering excessive reinforcement escalation.

Preserve existing machine controllers, finite component allocation, and threat-sharing behavior.

Avoid introducing new machine classes or combat roles during Stage R.

### Acceptance

Machines create additional tactical pressure and opportunities without dominating every deployment.

## 10. Workstream G — Spectator and simulation integrity

**Priority: High**

Use existing developer spectating and post-death spectating to observe integrated gameplay.

Verify:

- World simulation continues after player destruction where permitted.
- Spectating does not alter actor perception.
- Camera position does not influence encounters.
- Raider extraction and death are handled correctly.
- Actor-follow transitions remain reliable.
- Deployment settlement occurs exactly once.
- Material and equipment transfers remain authoritative.
- Restart and return actions clean up correctly.

Extend existing developer diagnostics only where necessary to identify gameplay problems.

Keep normal player-facing spectating separate from developer inspection.

### Acceptance

The spectator can observe ongoing gameplay without changing its outcome or corrupting mission state.

## 11. Gameplay metrics and diagnostics

**Priority: Critical**

Introduce or extend lightweight diagnostics to support objective balancing.

Prefer using existing event logging and debug systems.

Capture useful per-deployment information such as:

- Scenario seed.
- Deployment duration.
- Raider count and personality distribution.
- Raider deaths and extractions.
- Machine deaths.
- Engagement count.
- Engagement duration.
- Loot collected, dropped, recovered, extracted, or lost.
- Navigation recovery events.
- Reinforcement activations.
- Player damage and death.
- Significant unresolved actor objectives.

Metrics must read authoritative events or state.

Do not create a second gameplay accounting system.

Avoid continuous expensive polling or excessive per-frame logs.

Keep diagnostics disabled or lightweight in ordinary gameplay.

### Acceptance

A developer can compare two seeded deployments and identify meaningful differences in pacing, combat, extraction, and navigation.

## 12. Controlled tuning process

**Priority: Critical**

Avoid changing many unrelated variables simultaneously.

Use the following sequence:

1. Establish a Stage Q baseline.
2. Run representative seeds.
3. Record observed problems.
4. Prioritize issues by gameplay impact.
5. Change one related group of parameters or behaviors.
6. Re-run the same seeds.
7. Compare outcomes.
8. Test additional seeds for unintended consequences.
9. Retain or revert changes based on evidence.

Do not optimize exclusively for a single seed.

Preserve the existing Stage P encounter preset and Stage Q personality comparison preset as diagnostic references.

The integrated mission is the primary experience to refine.

## 13. Automated validation

**Priority: Critical**

Preserve all existing regression suites, including Stage P encounter and Stage Q combat coverage.

Extend tests only for concrete behavior changes or previously uncovered failure modes.

Focus on:

- Actor decision commitment and release.
- Navigation recovery.
- Cover congestion.
- Combat target eligibility.
- Physical firing validity.
- Raider extraction.
- Loot ownership.
- Reinforcement bounds.
- Mission termination.
- Post-death simulation.
- Spectator non-interference.
- Save and restart behavior.
- Material and equipment conservation.

Use actual movement and combat integration tests where relevant.

Policy-only tests are insufficient for physical movement defects.

Run:

- Godot editor parsing and import.
- Full automated regression suite.
- Bounded headless simulation.
- Forward+ graphical startup.
- Relevant scenario smoke tests.

Inspect logs and warnings rather than relying exclusively on process exit codes.

## 14. Manual acceptance matrix

Conduct manual review using the integrated mission and diagnostic presets.

| Test | Expected result |
|---|---|
| Passive spectator deployment | Independent actors produce varied activity |
| Normal player deployment | Player can pursue objectives and influence encounters |
| Greedy Raider observation | Cargo-sensitive decisions are visible |
| Cowardly Raider observation | Early escape and defensive behavior are visible |
| Aggressive Raider observation | Pursuit and bounded commitment are visible |
| Multi-Raider firefight | Movement and shooting remain fluid |
| Narrow-passage conflict | Actors recover from congestion |
| Loot contest | Ownership remains correct |
| Machine interception | Machines contribute without dominating |
| Raider extraction | Valid extraction completes cleanly |
| Player death | Deployment settles once and spectating remains functional |
| Repeated seeded deployment | Configuration remains reproducible |
| Different seed | Meaningful variation remains possible |

Exact combat winners, betrayals, and loot outcomes must not be mandatory.

## 15. Stage R acceptance criteria

Stage R is complete when:

1. The integrated mission demonstrates satisfying encounter pacing across multiple seeds.
2. Raider personalities remain observably distinct in armed encounters.
3. Combat and navigation do not exhibit persistent stalls or rapid objective oscillation.
4. Loot collection and extraction create meaningful choices.
5. Autonomous machines contribute useful encounter pressure.
6. Player combat and recovery feedback are understandable.
7. Spectating and post-death simulation remain reliable.
8. Existing authoritative accounting invariants remain intact.
9. No uncontrolled actor spawning or reinforcement escalation occurs.
10. Performance remains acceptable under the configured population limits.
11. All relevant automated regression suites pass.
12. Manual testing confirms improvements without eliminating emergent variety.
13. Changes and tuning decisions are documented with supporting evidence.

## 16. Explicit exclusions

Stage R does not include:

- New Raider personalities.
- New AI state-machine architecture.
- Dynamic alliance systems beyond existing behavior.
- New weapons or weapon classes.
- Equipment equipping or crafting.
- Progression or economy expansion.
- New autonomous machine types.
- New maps or major environment production.
- Major character art or animation production.
- Multiplayer or networking.
- Procedural terrain generation.
- Unbounded random spawning.
- Scripted encounter outcomes.
- Large-scale mission-system replacement.

Any discovered need for these features should be documented as a future proposal rather than implemented without approval.

## 17. Implementation workflow

### Step 1 — Repository inspection

Review:

- Current Git status.
- Stage P completion report.
- Stage Q delivery report and acceptance status.
- Existing integrated mission.
- Combat and personality implementation.
- Navigation recovery.
- Loot and extraction rules.
- Spectator lifecycle.
- Existing tests and debug instrumentation.

### Step 2 — Baseline evaluation

Before changing code, run the existing validation suite and collect a representative integrated-mission baseline.

Identify the highest-impact problems.

If the baseline already performs well, do not invent changes to satisfy the stage.

### Step 3 — Proposed implementation plan

Present:

- Observed problems.
- Supporting evidence.
- Proposed corrections.
- Affected files and systems.
- Expected gameplay impact.
- Regression risks.
- Validation strategy.
- Recommended implementation order.

**Stop for director approval before modifying gameplay behavior.**

### Step 4 — Controlled implementation

After approval:

- Apply focused corrections.
- Preserve accepted architecture.
- Add targeted regression coverage.
- Compare against the baseline.
- Document tuning values and reasons.
- Revert changes that reduce gameplay quality.

### Step 5 — Checkpoint R

Provide:

- Implementation summary.
- Files changed.
- Tuning changes.
- Baseline versus updated observations.
- Automated test results.
- Graphical validation results.
- Known limitations.
- Manual play-test checklist.
- Recommended follow-up work.

Do not advance beyond Stage R without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Inspect the repository and prepare the **Stage R baseline evaluation and implementation proposal**.

Do not begin by implementing speculative balancing changes.

Use actual gameplay behavior, diagnostics, existing tests, and accepted reports to determine what needs improvement.

Prioritize gameplay problems that materially affect player experience.

**Stage R succeeds by making the existing game more enjoyable, understandable, and reliable — not by making it more complicated.**
