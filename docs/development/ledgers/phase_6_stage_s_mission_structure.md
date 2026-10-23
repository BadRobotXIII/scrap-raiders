# SCRAP Raiders — Stage S Development Ledger
## Mission Structure, Objectives & Deployment Flow

**Phase:** 6 — Playable Game Loop & Mission Identity  
**Stage:** S  
**Status:** Proposed — architecture review and approval required  
**Engine:** Godot 4.7.2 / GDScript  
**Prerequisites:** Completed Stage R and accepted prior gameplay systems

---

## 1. Project context

SCRAP Raiders is a third-person PvE extraction shooter in which the player controls a machine defending and recovering technology from human Raiders.

The current implementation includes:

- Player movement, combat, damage, destruction, and extraction.
- Independent Raider personalities and combat decisions.
- Raider scavenging, pursuit, retreat, and extraction.
- Raider relationships, cooperation, rivalry, and betrayal.
- Autonomous machines.
- Finite materials and equipment.
- Authoritative material and equipment ledgers.
- Persistent recovered inventory.
- Seeded encounter generation.
- An integrated playable mission.
- Developer and post-death spectating.
- Gameplay balance and reliability work through Stage R.

The current repository and completion reports are authoritative. Verify the actual implementation before proposing changes.

## 2. Primary objective

Transform the integrated mission into a structured, repeatable deployment experience.

The player should understand:

1. Why they are deploying.
2. What they can accomplish.
3. What they stand to gain or lose.
4. When they should continue or extract.
5. What happened when the deployment ended.

Preserve the sandbox-like independence of Raiders and machines.

Mission objectives must create motivation, not dictate AI behavior.

## 3. Architectural requirements

**Priority: Critical**

Preserve existing authoritative ownership.

- Mission controller owns deployment lifecycle and orchestration.
- Existing material and equipment ledgers own resource transfers.
- Persistent stash owns banked inventory.
- Individual actors own their state and movement.
- Existing AI systems own autonomous decisions.
- Existing spectator systems own observation behavior.

Before implementation, inspect `mission_arena.tscn`, `mission_arena.gd`, and their current dependencies.

Identify existing mission-start, extraction, death, settlement, and restart paths.

Do not introduce a second mission lifecycle controller.

Do not introduce a separate resource accounting mechanism.

Prefer small, explicit mission states and configuration data.

## 4. Deployment lifecycle

**Priority: Critical**

Formalize the player-facing deployment flow using the existing mission architecture.

Suggested conceptual states:

- Preparation
- Deploying
- Active
- Extracting
- Settled
- Spectating
- Returning

These are conceptual states, not a mandate to create a new enum or parallel FSM.

Map them to existing lifecycle behavior first.

Requirements:

- Clear mission initialization.
- Defined deployment start.
- Existing extraction mechanics remain authoritative.
- Player destruction produces the correct failed-deployment outcome.
- Settlement occurs exactly once.
- Post-death spectating can continue without reopening settlement.
- Return and restart perform clean teardown.
- Existing development presets remain available.

Do not create additional state transitions unless necessary.

## 5. Mission objectives

**Priority: Critical**

Introduce a small, data-driven objective framework.

Begin with objectives supported by existing gameplay:

### A. Recover materials

Recover a specified quantity or value of finite materials.

### B. Recover equipment

Recover eligible dropped equipment already tracked by EquipmentLedger.

### C. Survive and extract

Complete a successful player extraction.

### D. Optional combat objective

Defeat a specified number of eligible hostile Raiders or autonomous machines.

Combat objectives must use accepted destruction events and must not award duplicate credit.

Objectives should support:

- Required or optional designation.
- Clear progress.
- Completion state.
- Failure or expiration where applicable.
- Read-only inspection.
- Explicit reset between deployments.

Use existing authoritative events and ledgers.

Objective progress is derived from accepted gameplay outcomes, not independently invented quantities.

Avoid complex dependency graphs or scripted mission sequences.

## 6. Objective ownership and evaluation

**Priority: Critical**

Assign one authoritative owner for objective state.

The objective evaluator may subscribe to existing mission events, but must not become an alternative owner of material, equipment, combat, or extraction state.

Requirements:

- Idempotent completion.
- No duplicate event credit.
- Deterministic initialization.
- Clear terminal conditions.
- No progress after terminal settlement unless explicitly supported.
- No reliance on incidental scene-tree callback ordering.
- No dependence on HUD visibility.

For material objectives, distinguish between:

- Materials picked up during a deployment.
- Materials currently carried.
- Materials successfully banked.

Select the intended meaning explicitly in mission configuration.

Do not treat temporary possession as successful recovery if the objective requires extraction.

## 7. Mission configuration

**Priority: High**

Extend the existing scenario configuration rather than creating a competing framework.

Support:

- Mission identifier.
- Display name.
- Short description.
- Objective definitions.
- Required recovery targets.
- Optional objective targets.
- Existing encounter seed.
- Existing Raider and machine configuration.
- Existing deployment time limits where applicable.
- Existing extraction configuration.

Preserve seeded reproducibility.

Keep development presets independent of normal player mission selection.

## 8. Player-facing deployment information

**Priority: High**

Introduce a lightweight mission briefing using existing UI architecture.

Display:

- Mission name.
- Primary objective.
- Optional objectives.
- Basic deployment risk.
- Relevant extraction information.

Do not create a complex frontend or inventory management interface.

The player should be able to start a deployment without navigating a large menu system.

## 9. In-mission objective presentation

**Priority: High**

Display concise objective progress during gameplay.

Requirements:

- Primary objective is identifiable.
- Optional objectives are distinguishable.
- Progress updates after authoritative events.
- Completed objectives remain visibly completed.
- HUD does not obscure combat.
- Developer diagnostics remain separate.

Do not display hidden Raider objectives or private AI decision information.

## 10. Mission completion and extraction

**Priority: Critical**

Define the relationship between objective completion and extraction.

Recommended initial policy:

- Completing an objective does not automatically extract the player.
- Extraction remains a deliberate player action.
- Successful extraction banks eligible carried inventory.
- Mission success requires the configured objective conditions and successful extraction.
- Player destruction remains a failed deployment.
- Optional objectives may improve the reported result without blocking extraction.

The player may choose to extract early.

An early extraction can preserve recovered inventory even when the primary objective is incomplete, provided that this is compatible with existing persistence rules.

Do not retroactively alter the accepted extraction or stash accounting semantics.

## 11. Deployment results

**Priority: High**

Provide a clear end-of-deployment summary.

Suggested information:

- Mission name.
- Deployment outcome.
- Required objective completion.
- Optional objective completion.
- Materials recovered and banked.
- Equipment recovered.
- Player destruction or extraction.
- Deployment duration.

Use existing authoritative records.

Do not invent rewards or new currencies.

Ensure that the results screen can be displayed after settlement without modifying the settled state.

## 12. Preserve emergent gameplay

**Priority: Critical**

Mission objectives must not force Raiders to behave according to the player's goals.

Raiders should continue to:

- Scavenge independently.
- Compete over loot.
- Fight machines.
- Cooperate temporarily.
- Betray one another.
- Retreat.
- Extract.

The player's mission may overlap with Raider objectives, creating natural competition.

For example, a mission to recover valuable components becomes more interesting when Raiders are independently trying to extract those same components.

Do not script Raider behavior to guarantee player success or failure.

## 13. Dedicated Stage S mission

**Priority: Critical**

Create one representative mission using the existing integrated arena.

Suggested mission concept:

**Operation: Asset Recovery**

Premise:

Human Raiders have entered an automated salvage facility to recover valuable machine components. The player deploys to intercept them and secure recoverable assets.

Initial objective structure:

- Primary: Recover and successfully extract with a configured material value.
- Optional: Recover one eligible equipment item.
- Optional: Destroy a configured number of hostile Raiders.

Use existing loot, combat, and extraction systems.

Select actual quantities after inspecting the available material pool and mission duration.

Do not introduce special mission-only loot or scripted enemies.

The mission must remain replayable across different encounter seeds.

## 14. Automated validation

**Priority: Critical**

Preserve all accepted tests.

Add coverage for:

1. Mission configuration parsing.
2. Objective initialization.
3. Objective progress from accepted events.
4. Duplicate event protection.
5. Required versus optional objectives.
6. Objective completion before extraction.
7. Early extraction with incomplete objectives.
8. Successful extraction and inventory banking.
9. Player destruction and one-time settlement.
10. Post-death spectating.
11. Mission restart and objective reset.
12. Results generation from authoritative state.
13. Seeded encounter compatibility.
14. Material and equipment conservation.
15. Existing developer presets.

Run the full existing regression suite, Godot editor parsing/import, bounded headless execution, and Forward+ graphical startup.

Report warnings separately from test failures.

## 15. Manual acceptance

Perform manual review of:

| Scenario | Expected result |
|---|---|
| Normal deployment | Mission briefing and objectives are understandable |
| Material recovery | Objective progress reflects authoritative transfers |
| Optional equipment recovery | Optional progress updates correctly |
| Early extraction | Inventory settles correctly; incomplete objective is reported |
| Completed objective extraction | Mission success is reported correctly |
| Player destruction | Deployment fails and forfeiture occurs once |
| Post-death spectating | World simulation continues without altering results |
| Repeated deployment | Objectives and state reset cleanly |
| Different encounter seed | Mission remains playable with varied encounters |
| Development preset | Existing debugging behavior remains intact |

## 16. Acceptance criteria

Stage S is complete when:

- One normal player-facing mission can be started and completed.
- The mission has clear primary and optional objectives.
- Objective progress is authoritative and correctly reset.
- Existing extraction mechanics remain intact.
- Successful and failed deployments produce accurate results.
- Persistent inventory remains correct.
- Post-death spectating remains functional.
- Autonomous encounters remain independent.
- The mission can be replayed across multiple seeds.
- Existing developer presets remain functional.
- Automated regression coverage passes.
- Manual testing confirms a coherent deployment experience.

## 17. Explicit exclusions

Do not implement:

- Crafting.
- Equipment equipping.
- Shops or vendors.
- Character progression.
- New weapons.
- New Raider personalities.
- New machine classes.
- Multiplayer.
- Campaign progression.
- Procedural map generation.
- Major art or animation production.
- A complete frontend redesign.
- A second mission controller.
- Scripted encounter outcomes.

These may be considered in future stages.

## 18. Implementation workflow

### Step 1 — Inspect

Review the current repository, Stage R completion report, mission architecture, extraction lifecycle, ledgers, persistence, UI, and existing tests.

### Step 2 — Propose

Present the smallest architecture that supports one complete player-facing mission.

Identify:

- Existing functionality to reuse.
- Required new functionality.
- State ownership.
- Event flow.
- Configuration changes.
- UI changes.
- Regression risks.
- Validation plan.

### Step 3 — Approval

Stop for director review before implementation.

### Step 4 — Implement

After approval, implement the agreed scope in focused increments.

Add regression tests and preserve existing development scenarios.

### Step 5 — Checkpoint S

Deliver:

- Implementation summary.
- Changed files.
- Architecture decisions.
- Automated validation results.
- Graphical validation results.
- Manual play-test procedure.
- Known limitations.
- Suggested follow-up work.

Do not advance to Stage T without director approval.

Git commits and publication require separate authorization.

---

## Immediate Codex assignment

Inspect SCRAP Raiders and prepare the Stage S architecture and implementation proposal.

**Do not begin coding until the plan is approved.**

Prioritize a complete, understandable, repeatable deployment experience using existing mechanics.

The objective is to turn an entertaining simulation into a playable extraction game without sacrificing the independent behavior that makes SCRAP Raiders distinctive.