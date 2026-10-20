# SCRAP Raiders — Phase 3 Development Ledger
## Hostile World, Survival & Extraction

**Status:** Planned — not approved for implementation  
**Current development:** Phase 2, Stage C  
**Purpose:** Establish the next major gameplay requirements without interrupting current development.

---

## 1. Core game identity

SCRAP Raiders is a stylized, comedic third-person extraction shooter with reversed machine/human roles.

The player controls an autonomous machine operating in a world where human Raiders scavenge machine technology, hunt robots for valuable components, and attempt to extract their acquisitions.

**The player is powerful, but not invincible.**

The game must retain the fundamental characteristics of an extraction shooter:

- Dangerous encounters and the possibility of player death.
- Valuable equipment and recoverable resources.
- Decisions about when to engage, loot, retreat, or extract.
- Meaningful consequences for unsuccessful deployments.
- Persistent progression supported by successful extraction.
- Emergent encounters between human Raiders and autonomous machines.

Humor should come from the visual identity, exaggerated physics, character behavior, and unexpected interactions—not from removing the danger.

Maintain original characters, machine designs, equipment, and terminology rather than copying ARC Raiders assets.

## 2. Armed human Raiders

**Priority: Critical**

Raiders must evolve from scavenging targets into genuine combat threats.

Required capabilities:

- Detect and engage the player.
- Use weapons with appropriate range and accuracy.
- Cause damage to the player robot.
- Seek and use cover.
- Reposition when threatened.
- Retreat when overwhelmed.
- Coordinate at a basic squad level.
- Continue scavenging when combat is unnecessary.

Introduce distinct Raider roles:

| Role | Behavior | Loot value |
|---|---|---|
| Scavenger | Searches for scrap, fights when threatened | Moderate–high |
| Machine hunter | Actively targets robots for components | High |
| Flare responder | Investigates Raider deaths and attacks nearby machines | Low |
| Elite Raider | Better-equipped, higher-risk opponent | Very high |

Roles should be implemented through shared AI architecture with configurable behavior, not duplicated controllers.

Combat AI must preserve explicit state ownership and understandable transitions.

## 3. Automatic Raider death flares

**Priority: Critical — signature mechanic**

When a human Raider dies, an automatic flare launches from its death location.

This flare alerts nearby Raiders and may attract additional hostile response units.

**The flare is triggered by death, not deliberately launched by a surviving Raider.**

Intended gameplay:

1. The player kills a Raider.
2. A visible flare launches and reveals the approximate encounter location.
3. The dead Raider drops recoverable equipment and materials.
4. The player has a limited opportunity to loot the body.
5. Nearby Raiders investigate or converge on the location.
6. The player must decide whether to finish looting, fight, retreat, or extract.

Requirements:

- Visible flare launch and lingering signal.
- Audio feedback.
- Configurable alert radius.
- Configurable response delay.
- Nearby existing Raiders respond before additional units are spawned.
- Responders approach through believable routes and entry points.
- Flare response must not cause uncontrolled infinite reinforcement loops.
- Response behavior must not require stationary defense; escaping is a valid and often preferable strategy.

The central mechanic is **loot quickly and leave before reinforcements arrive**.

## 4. Raider loot and equipment

**Priority: Critical**

All defeated Raiders drop loot, including their loadouts and human-engineered equipment.

Potential loot categories:

- Weapons.
- Ammunition and consumables.
- Machine scrap.
- Engineered machine modifications.
- Electronic components.
- Rare equipment and upgrade materials.

Loot value should reflect Raider role, equipment, and encounter difficulty.

Flare responders must have substantially lower expected loot value than ordinary scavengers, hunters, and elite Raiders.

This prevents intentionally farming reinforcement waves from becoming the dominant resource strategy.

Consider different recovery times for different loot categories, creating additional risk when remaining near a death flare.

Maintain authoritative inventory and transfer ownership.

## 5. Player health, damage, and destruction

**Priority: Critical**

The player robot must be vulnerable to hostile Raider attacks.

Implement:

- Authoritative player health and damage handling.
- Weapon impact and damage feedback.
- Clear indication of incoming damage.
- Player destruction and death sequence.
- Failed-deployment handling.
- Appropriate consequences for carried resources.
- Mission restart and recovery behavior.

Potential later extensions:

- Armor and component durability.
- Damaged movement systems.
- Temporary weapon malfunctions.
- Field repairs.
- Destructible equipment modules.

Do not introduce a detailed component-damage simulation before basic combat and death are reliable.

## 6. Player extraction

**Priority: Critical**

The player must eventually extract successfully rather than merely survive until a mission timer ends.

Develop an original machine-themed extraction mechanic.

Requirements:

- At least one designated extraction location or method.
- Clear extraction availability and interaction rules.
- An extraction process that can be interrupted by danger.
- Successful extraction transfers carried loot into persistent inventory.
- Player destruction before extraction triggers failure and appropriate resource loss.
- Mission outcomes distinguish successful extraction, death, and expiration.

Exact extraction presentation and fiction remain open for design review.

Preserve compatibility with the existing mission ledger and material conservation rules.

## 7. Raiders hunting other machines

**Priority: High**

Human Raiders should have two independent motivations:

**Scavenging:** Recover machine materials from salvage sites.

**Hunting:** Destroy autonomous robots and collect their valuable components.

Raiders should be able to encounter and attack non-player machines.

Potential emergent scenarios:

- Raiders fighting a machine patrol before the player arrives.
- A scavenging team changing objectives after detecting a valuable robot.
- A hunter squad targeting the player's support units.
- The player intervening in an ongoing machine-versus-human encounter.
- Raiders recovering materials from destroyed machines.

Avoid making all Raider behavior dependent on the player's presence.

## 8. Supporting autonomous machines

**Priority: High — introduce after core hostile combat**

Develop a machine ecosystem that supports the player without eliminating danger.

### Flying support machines

Potential capabilities:

- Patrol and reconnaissance.
- Raider detection and tracking.
- Threat reporting.
- Target illumination.
- Limited harassment or suppression.
- Vulnerability to Raider weapons.

### Small ground support machines

Potential capabilities:

- Guard salvage locations.
- Intercept hostile Raiders.
- Recover or transport materials.
- Patrol machine-controlled areas.
- Distract or delay hostile squads.
- Exaggerated physics-based interactions.

Support machines must have their own health, state, and destruction behavior.

They should be useful but expendable, and must not automatically solve combat encounters for the player.

## 9. Shared machine-faction awareness

**Priority: High**

Introduce a common system for sharing detected threats and relevant world information among allied machines.

Examples:

- Flying scout detects a Raider squad.
- Ground defenders receive the last known threat location.
- Player receives a contextual warning.
- Individual machines independently determine their responses.

Architecture:

- Shared information, not shared movement control.
- Each machine retains its own state machine.
- Clear ownership and expiration of threat observations.
- No direct cross-control between unrelated actors.
- No unnecessary global coordination framework.

Preserve deterministic and debuggable behavior.

## 10. Player machine identity and movement

**Priority: Medium — experimental**

Explore a more expressive and unconventional playable robot.

Desired characteristics:

- Aggressive, distinctive machine movement.
- Exaggerated acceleration and physical reactions.
- Powerful traversal capabilities.
- Unusual attacks or movement-assisted combat.
- Strong mechanical personality.

Potential future mechanics:

- Jumping or lunging attacks.
- Boosted movement.
- Physics-assisted traversal.
- Alternative machine chassis.
- Specialized equipment configurations.

Retain the current player controller as a stable baseline while experimenting.

Evaluate whether progression should focus on upgrading one chassis or unlocking multiple playable chassis.

Do not commit to a complex locomotion system until gameplay requirements justify it.

## 11. Loot economy and progression

**Priority: High**

Successful extraction should provide resources for persistent progression.

Potential systems:

- Persistent inventory.
- Recoverable Raider equipment.
- Machine scrap and components.
- Reverse-engineering human modifications.
- Robot upgrades and equipment fabrication.
- Risk-based deployment loadouts.

Loot must have a meaningful relationship to the player's willingness to risk another encounter.

Avoid introducing an elaborate crafting tree before the basic extraction and inventory loop is proven.

## 12. Visual direction

**Priority: Ongoing**

Maintain a stylized, cartoonish, mechanically expressive identity.

Desired characteristics:

- Readable silhouettes.
- Distinct machine and Raider designs.
- Exaggerated movement and death reactions.
- Comedic physics.
- Strong lighting and atmosphere.
- Clear combat and loot feedback.

Cartoonish does not mean unfinished.

Visual polish should reinforce the gameplay without requiring photorealism.

Godot remains the target engine. Blender-generated assets and animations may be introduced incrementally.

## 13. Proposed implementation order

### Stage E — Hostile Combat
Armed Raiders, player damage, player death, combat AI, and survival testing.

### Stage F — Death Flares and Loot Pressure
Automatic Raider death flares, responding Raiders, equipment drops, and loot-risk balancing.

### Stage G — Extraction and Persistent Rewards
Player extraction, deployment failure, inventory persistence, and resource consequences.

### Stage H — Machine Ecosystem
Flying and ground support machines, Raider machine-hunting behavior, and shared threat awareness.

### Stage I — Advanced Player Mechanics
Expanded traversal, chassis experiments, upgrades, and more expressive machine combat.

Each stage requires its own implementation plan, testing criteria, review checkpoint, and Git commit.

## 14. Architectural requirements

All future implementations must preserve:

- Single authoritative ownership of gameplay state.
- Explicit and manageable state machines.
- Centralized inventory and material accounting.
- Separation of gameplay simulation from presentation.
- Independent actor control.
- Predictable event processing.
- Reproducible debugging scenarios.
- Incremental automated testing.
- Minimal unnecessary abstraction.

Do not implement this ledger immediately.

Complete the current Phase 2 work, review the actual repository state, and prepare a focused Stage E implementation plan before proceeding.