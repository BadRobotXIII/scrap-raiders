# SCRAP Raiders — Stage T Development Ledger
## Full Gameplay Integration & Systems Audit

**Phase:** 7 — Integrated Gameplay & World Production  
**Stage:** T  
**Status:** Proposed — repository audit required before implementation  
**Engine:** Godot 4.7.2 / GDScript  
**Prerequisite:** Completed Stage S

### 1. Objective

Establish one complete, stable, repeatable gameplay experience incorporating all accepted systems developed through Stage S.

The normal integrated mission must support the complete interaction of autonomous Raiders, machines, loot, combat, extraction, player objectives, and spectator functionality.

This is an integration and verification stage, not a feature expansion stage.

### 2. Repository and implementation audit

Inspect the current repository, stage completion reports, scene hierarchy, mission configuration, AI components, and automated tests.

For every previously implemented mechanic, identify:

- Its authoritative implementation.
- Its initialization and lifecycle.
- Its configuration and activation conditions.
- Whether it is enabled in the normal integrated mission.
- Its interactions with other systems.
- Existing automated coverage.
- Manual evidence of functional behavior.
- Any limitations, disabled paths, or incomplete integrations.

Distinguish clearly between implemented, enabled, exercised, and verified behavior.

Do not assume that passing an isolated test proves integration into the normal mission.

### 3. Raider personality integration

Verify Greedy, Cowardly, and Aggressive personalities are all represented in normal deployments.

Confirm that:

- Personality selection varies across appropriate deployments.
- Armed behavior reflects the Stage Q personality policies.
- Greedy Raiders make cargo-sensitive decisions.
- Cowardly Raiders favor survival and defensible escape.
- Aggressive Raiders pursue eligible threats with bounded commitment.
- Personalities preserve independent objectives.
- Actors avoid repeated decision oscillation.
- Behavior remains consistent through combat, scavenging, and extraction.

Do not equalize personality outcomes artificially.

### 4. Raider social interaction integration

**Critical priority**

Audit all implemented Raider relationship and social systems.

Verify:

- Allied, neutral, and hostile relationship states.
- Raider-versus-Raider combat.
- Temporary cooperation against shared threats.
- Shared threat reports and their expiration.
- Opportunistic betrayal.
- Relationship and target eligibility changes.
- Contested salvage and loot recovery.
- Post-conflict scavenging.
- Independent retreat and extraction.
- Relationship state cleanup after death or extraction.

Confirm these mechanics are reachable during ordinary integrated deployments.

Do not force cooperation or betrayal to occur every mission.

If normal scenario configuration unintentionally suppresses a mechanic, identify and correct the configuration or integration problem.

Preserve the distinction between relationship state and current combat intent.

### 5. Autonomous machine integration

Verify:

- Ground machine behavior.
- Flying machine behavior.
- Independent machine patrol and threat detection.
- Raider-versus-machine combat.
- Shared expiring threat knowledge.
- Machine destruction and finite component drops.
- Machine interactions with Raider social conflicts.
- Continued autonomous operation after player destruction.

Machines must remain independent participants rather than scripted encounters requiring player proximity.

### 6. Encounter generation and world activity

Verify Stage P encounter opportunities are active within the normal integrated mission.

Audit:

- Seeded encounter configuration.
- Initial Raider populations.
- Staggered arrivals.
- Salvage distribution.
- Patrol intersection opportunities.
- Rival convergence.
- Extraction competition.
- Death flare escalation.
- Population and reinforcement bounds.
- Encounter resolution and cleanup.

The mission should permit multiple independent situations to develop without requiring player participation.

Do not guarantee particular winners or outcomes.

### 7. Loot, combat, and extraction integration

Verify:

- Player and Raider combat.
- Valid target selection and line-of-sight firing.
- Death and equipment drops.
- Material recovery.
- Contested pickup.
- Raider extraction.
- Player Recall Dock extraction.
- Inventory banking.
- Failed deployment forfeiture.
- Persistent stash integrity.
- Finite resource conservation.
- No duplicated or orphaned material/equipment transfers.

MaterialLedger and EquipmentLedger retain exclusive transfer authority.

All settlement paths must remain idempotent.

### 8. Mission objective integration

Verify Stage S player-facing mission functionality:

- Mission briefing.
- Primary and optional objectives.
- Objective progress.
- Objective completion.
- Early extraction.
- Successful extraction.
- Failed deployment.
- Results presentation.
- Mission replay and restart.

Ensure objectives are evaluated from authoritative gameplay events and do not override independent Raider behavior.

### 9. Spectator integration

Verify both developer spectating and post-death spectating.

Confirm:

- Developer free camera does not affect AI perception.
- Normal post-death spectating cannot control actors.
- Player deployment settlement occurs exactly once.
- The world continues after player destruction where permitted.
- Actor following handles death and extraction.
- Spectator transitions do not change encounter outcomes.
- Return and restart cleanly release resources.

### 10. Integrated mission configuration

Review the normal mission configuration to ensure the full implemented gameplay feature set is accessible.

Preserve dedicated development presets for isolated testing.

Where appropriate, introduce bounded variation in:

- Raider personality distribution.
- Initial relationships.
- Actor arrival timing.
- Salvage opportunities.
- Machine activity.
- Encounter seed.
- Extraction routes.

Do not introduce uncontrolled randomness or new gameplay systems.

Prefer existing configuration fields and seeded random sources.

The normal mission must remain reproducible for debugging.

### 11. Architecture review

Trace execution from `project.godot` through `mission_arena.tscn`, `mission_arena.gd`, mission configuration, actor spawning, runtime callbacks, signals, and mission teardown.

Identify:

- Scene and actor ownership.
- Initialization order dependencies.
- Mission lifecycle authority.
- Actor state-machine ownership.
- Combat decision ownership.
- Social relationship ownership.
- Loot and equipment authority.
- Spectator camera ownership.
- Persistent inventory ownership.
- Cleanup and restart responsibilities.

Look for accidental duplicate authority, implicit callback ordering dependencies, and redundant state.

Do not undertake a broad architectural rewrite without demonstrating a concrete problem.

### 12. Integration test scenarios

Preserve all existing automated suites.

Add or extend integration tests covering:

1. Multiple personality types in one mission.
2. Allied Raider cooperation against a shared threat.
3. Hostile Raider-versus-Raider engagement.
4. Opportunistic betrayal under valid conditions.
5. Contested finite salvage.
6. Loot recovery after Raider conflict.
7. Raider extraction with recovered cargo.
8. Machine participation in multi-actor combat.
9. Death flare escalation and reinforcement bounds.
10. Player intervention in an autonomous encounter.
11. Player extraction with completed objectives.
12. Early extraction with incomplete objectives.
13. Player destruction followed by autonomous simulation.
14. Spectator target switching and non-interference.
15. Mission restart and state cleanup.
16. Material and equipment conservation.

Tests may deliberately construct conditions required to exercise a mechanic.

The normal mission must not force those same outcomes.

### 13. Integrated gameplay validation

Run representative seeded deployments using the normal mission.

Evaluate:

- Autonomous activity without player intervention.
- Encounter frequency and variation.
- Raider social behavior.
- Combat and navigation reliability.
- Loot recovery opportunities.
- Extraction outcomes.
- Objective progression.
- Mission termination.
- Post-death continuation.
- Performance and actor population limits.

Record the seeds used for meaningful observations.

Compare multiple seeds rather than tuning exclusively for one deployment.

### 14. Manual acceptance

Provide a practical director play-test checklist.

The director should be able to:

- Start a normal deployment.
- Observe different Raider personalities.
- Encounter autonomous Raider and machine activity.
- Witness cooperation when valid conditions arise.
- Witness betrayal when valid conditions arise.
- Intervene in ongoing conflicts.
- Recover finite loot.
- Complete mission objectives.
- Extract and bank inventory.
- Die and continue spectating.
- Restart without stale mission state.

Not every event must occur in one deployment.

However, all implemented mechanics must be demonstrably reachable through the normal integrated configuration.

### 15. Acceptance criteria

Stage T is complete when:

- All accepted gameplay systems have been inventoried.
- Normal mission integration has been verified.
- Implemented social behaviors are reachable and observable.
- Autonomous encounters continue without player participation.
- Personality-aware combat remains functional.
- Loot and equipment accounting remain correct.
- Mission objectives and extraction work together.
- Spectating does not affect simulation.
- Existing test presets remain functional.
- Automated regression and integration tests pass.
- Multiple seeded deployments have been evaluated.
- Outstanding limitations are documented.
- The integrated mission is accepted as the baseline for world expansion.

### 16. Explicit exclusions

Do not implement:

- New AI personalities.
- New social relationship systems.
- New weapons or equipment systems.
- New machine types.
- Crafting or progression.
- Multiplayer.
- New maps.
- Major environment art.
- Character model replacement.
- Large-scale animation production.
- Broad architecture rewrites.
- Forced scripted encounter outcomes.

Document future opportunities separately.

### 17. Workflow

**Step 1 — Audit**

Inspect the repository and prepare an integration matrix covering all implemented mechanics.

**Step 2 — Identify gaps**

Classify issues as:

- Missing integration.
- Incorrect configuration.
- Regression.
- Unverified behavior.
- Future feature outside scope.

**Step 3 — Propose**

Present a focused remediation plan with affected systems, risks, and tests.

**Stop for director approval before modifying code.**

**Step 4 — Implement**

After approval, correct verified integration gaps and extend relevant tests.

**Step 5 — Validate**

Run full automated regression, Godot parsing/import, bounded headless simulation, graphical startup, and integrated mission smoke tests.

**Step 6 — Checkpoint T**

Provide:

- Completed integration matrix.
- Actual fixes.
- Automated test results.
- Seeded gameplay observations.
- Known limitations.
- Manual acceptance checklist.
- Recommendation on readiness for Stage U.

Do not advance to Stage U without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Audit the complete SCRAP Raiders gameplay implementation through Stage S.

Determine whether every accepted gameplay mechanic is correctly integrated into the normal mission, particularly Raider relationships, cooperation, betrayal, autonomous combat, looting, and extraction.

Produce a repository-grounded integration matrix and proposed corrections.

**Do not begin implementation until the audit and remediation plan are approved.**

The objective is to establish a complete, reliable gameplay baseline before world expansion and production asset development.


---

Archive provenance: the supplied attachment ends in section 9 after "exactly". The remainder above was supplied by the director in the follow-up reply on 2026-10-21. This archive combines those two sources; it is not an unchanged copy of the truncated attachment. The original approval requirement is retained above; subsequent director approval and delivery are recorded in the Stage T plan and report.
