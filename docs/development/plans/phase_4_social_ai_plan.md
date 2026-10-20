# Phase 4 — Social Raider AI implementation plan

Prepared: **2026-10-19**. **Stages K–M implemented and accepted.** Stage K mechanics and the jump/boost availability follow-up were confirmed functional before authorization to proceed to L. The director subsequently accepted L, approved M, and confirmed M is functionally great. The requested window/HUD refinement is recorded in the Stage M report. This plan is not a replacement for an unprovided full Phase 4 ledger.

Director clarification: neutral Raiders can still compete for salvage; allied Raiders can cooperate against the robot without belonging to a permanent squad. Relationship, resource competition, and optional squad membership must remain separate concepts. The Stage K implementation uses explicit pair attitudes with no squad assignment or squad-derived alliances.

## Goal

Create readable autonomous encounters between human Raiders: allies cooperate, rivals fight over finite salvage, survivors loot material cargo, and selected opportunists may betray an ally. The developer can observe through F1 spectator without the camera influencing decisions. Start with authored, seeded encounters and three Raiders, then validate five.

Each stage requires its own approval, validation report and review checkpoint. Approving Stage K does not authorize Stages L or M.

## Current foundation and gaps

- One Raider FSM already owns scavenging, investigation, flight, combat, cover, repositioning, extraction and terminal states. Reuse it rather than creating a second social movement/controller path.
- Existing personality resources express greed, caution and aggression. They do not currently express membership, relationships or trust. Keep affiliation separate from personality.
- Raider weapon rays hit environment/Raiders/machines, but their damage mask protects every Raider. Merely enabling a physics layer would allow indiscriminate human friendly fire. Add explicit target damage eligibility before enabling rival damage.
- Target selection currently falls back to the player, with a machine-only selector in the ecosystem preset. Generalize candidate eligibility for the social preset without changing previous presets.
- Health records impact origin, not reliable instigator identity. Retaliation/relationship events need attributed accepted hits, not guesses from an impact position.
- MaterialLedger already supports finite ground-to-Raider collection, although arena objective discovery currently offers ordinary salvage and tracked machine-component drops. Generalize discovery carefully for Raider death cargo.
- EquipmentLedger records fixed loadout ownership; humans do not currently loot/re-equip other humans' gear. Leave equipment looting outside the initial social stages.
- Stage J already inspects/follows Raiders. Replace its relationship placeholder with read-only actual data when available; keep F3 diagnostics.

## Ownership and proposed rules

| Owner | Responsibility |
| --- | --- |
| Mission configuration / arena composition | Explicit initial pair attitudes, optional independent squad metadata, entries, seed, enabled social features and scenario setup |
| Mission-local `RaiderRelations` | Sole writer of pair attitudes; validated transitions and reasons; no squad inference, movement or inventory control |
| Per-Raider social component | Observations, expiry and bounded social intent; requests actions through the common Raider FSM |
| Raider / RaiderCombat | Own FSM transitions, physical movement, cover and firing intent |
| Shared ShotExecutor / Health | Physical shot execution, damage eligibility, accepted damage and instigator attribution |
| MaterialLedger / EquipmentLedger / mission rules | Existing accounting authorities and separate outcome policy |
| Spectator / debug presentation | Read-only relationship, observation, target and decision diagnostics |

Initial relationships are **ALLIED**, **NEUTRAL** and **HOSTILE**. Use symmetric explicit pair relations for the first implementation. Unspecified pairs are neutral; squad membership does not derive an attitude. Neutral and allied Raiders can both compete for finite stock and retain separate cargo. A later valid betrayal changes that pair to hostile once, with an actor ID, timestamp and reason. It does not automatically make other allies or squad members omniscient or hostile. Dead, extracted and unknown identities cannot initiate transitions. Asymmetric opinions, permanent squad behavior and dynamic alliances are future extensions rather than Stage K requirements.

Pair attitude determines human attack eligibility; personality determines how an eligible threat is approached. Optional squad metadata does not grant exclusive salvage or shared cargo. Retain existing low-health retreat and reachable-exit behavior. Fresh line of sight remains mandatory to start/continue aiming. Target switching resets the existing warning. Last-known observations expire rather than following actors through cover.

Allied/neutral bodies still block bullets. Their hits do not deal damage or trigger retaliation in the initial version. Hostile Raiders can receive attributed damage through the same executor as machines. A betrayal must be accepted before the first hostile shot. Player and support-machine damage rules retain their accepted behavior. Collision layers remain geometry filters, not the source of social identity.

## Stage K — Relationships and rival combat

**Implemented, validated and accepted.**

1. Add mission-local relation ownership and explicit authored pair attitudes, independent of squad metadata. Default all existing presets to their current human-friendly behavior; social behavior is opt-in.
2. Add explicit candidate and damage eligibility for hostile Raiders alongside existing machine threats. Introduce reliable accepted-hit instigator attribution while preserving current hit origin/damage/cadence behavior.
3. Reuse engagement, cover, repositioning, flight and extraction states. Keep target preference simple: visible eligible candidates scored by distance with current-target stickiness, using the existing perception cadence. No every-frame random target changes.
4. Add a separate **Social Rivalry** preset with three Raiders, three salvage points and nine materials. R1/R2 are explicitly allied; R3 is hostile to both. All three have no squad assignment. Authored entries/routes should produce an encounter without teleporting or requiring a nearby player. Use a fixed seed, initially `81017`, and existing 180-second deadline rules.
5. Begin with flares/reinforcements, support machines and experimental traversal disabled in this preset to isolate rivalry. Keep the robot physically present in a sheltered starting area, vulnerable and outside the initial encounter's sightlines; do not hide it from AI or make it invincible. Use F1 to observe; expose the preset through an unused debug key after checking existing bindings.
6. Show pair relationship, independent optional squad metadata, current target and reason for target/relationship changes in spectator inspection/F3. Presentation is read-only; gameplay eligibility also queries the same relation authority.

**Checkpoint K acceptance:** rivals can acquire, warn, shoot, damage, flee from and kill each other under normal physics; allies/neutral Raiders do not take human friendly damage; the player camera cannot influence targeting; ordinary death cargo/accounting and mission resolution still work. Cooperation and betrayal are not required yet.

## Stage L — Cooperation and contested material recovery

Authorized after accepted K and the traversal follow-up. Add useful local cooperation without a shared movement controller:

- Allies within a configurable communication radius share expiring last-known hostile observations. Proposed starting values: 15 m communication, three-second lifetime. Recipients choose their own response using their FSM; a report never grants firing visibility or live target tracking. Do not reuse the machine faction's board as a shared human/machine information channel.
- Reuse contention scoring and cover reservations so allies favor different loot objectives and cover slots. No leader/follower formation, healing, forced rescue or centralized squad steering.
- Let Raiders discover nearby visible material death drops, remember their last-known location briefly, and request ordinary timed scavenging. Do not expose every world drop as perfect global knowledge. Ledger validation remains decisive if another Raider/player consumed it first.
- Validate actor identity, live/active state, world-drop identity, range, unobstructed reach, capacity and completed task time before any accepted ground transfer. Handle partial stacks and actor/player contention without double credit. Only the existing ledger changes quantities.
- Cargo looted from another Raider stays carried until ordinary death or extraction. It becomes Lost only upon actual Raider extraction. Recovery-only, deadline and player-recall categories remain separate from relations.
- Integrate death flares in an opt-in follow-up preset. Response tickets carry explicit authored relationship initialization, separate from any optional squad metadata, and retain the finite budget/cap. Initial L tuning explicitly allies responders with surviving R1/R2 and each other, and opposes surviving R3, without deriving alliances from membership. A flare communicates a location; it does not reveal a killer's current position or automatically change other relationships.

**Checkpoint L acceptance:** allies can respond to reports and independently support an encounter; a survivor can physically approach, scavenge and extract a defeated rival's finite material cargo; the player can compete for the same stack; zero material duplication occurs; fallback paths still resolve blocked objectives.

Human equipment looting, re-equipping rifles, sharing cargo, trading and loot-value economics are deferred. Equipment continues its current ledger-backed death/player-recovery lifecycle.

## Stage M — Bounded opportunistic betrayal

Authorized after accepted L. Implemented as the separate Alt+F11 Opportunistic Betrayal encounter; see the [Stage M report](../reports/stage_m_opportunistic_betrayal.md).

- Add a separate social tuning resource for betrayal eligibility. Do not silently redefine the accepted Greedy/Cowardly/Aggressive resources in old presets.
- Use one authored betrayal-capable opportunist in a separate scenario. First prove a deterministic trigger before adding any seeded probability.
- Proposed trigger: the opportunist has less cargo than a visible ally carrying at least three materials, that ally is within 8 m, the opportunist has more than 50% health, and there is no currently observed machine/rival threat or active retreat/combat task. Require these conditions for two continuous seconds; interruption cancels the assessment.
- At most one initiated betrayal per eligible Raider per deployment. No per-frame random rolls, repeated trust oscillation or automatic reconciliation. A visible hesitation/warning cue precedes the transition, followed by the normal weapon aim warning. The victim becomes hostile to the betrayer; unwitnessed third parties do not receive universal knowledge.
- Combat proceeds through the accepted target/damage rules. Cargo remains in the victim's ledger allocation until actual death; betrayal does not steal, spawn, transfer or reward loot by itself.
- Use the existing material recovery from L for the aftermath. The betrayer can still lose, flee or die; no scripted kill or guaranteed reward.

**Checkpoint M acceptance:** the developer can reproduce a betrayal, explain its observed cause through diagnostics, see ordinary combat and looting afterward, and verify identical setup/seed reproduces the decision without claiming bitwise deterministic physics. Alliances outside the affected pair remain unchanged unless a separately specified witnessed response applies.

## Validation at each stage

Run the fifteen pre-social suites plus focused social suites (eighteen total through M). Run Godot 4.7.2 parsing/import, bounded headless runtime, graphical startup and F1 spectator checks. Tests must inspect output for script errors, not only process exit codes.

New coverage should establish:

- Relation registration, defaults, symmetry, invalid/duplicate transitions, terminal guards and fresh restart state.
- Ally/neutral protection versus rival damage, obstruction, correct hit attribution, target switches and fresh aim warnings.
- Real autonomous rival combat with the robot distant, including target death/removal and simultaneous outcomes.
- Observation radius/expiry, no tracking through cover, independent recipient decisions and witness limits.
- Finite/partial cargo transfer, simultaneous Raider/player collection, duplicate death/recovery, cargo re-drop and actual extraction loss.
- Low-health retreat, unreachable loot/cover, fallback selection, no-progress behavior and no forced teleport.
- Reinforcement affiliation, finite flare chains and absence of material creation.
- Betrayal qualification/interruption, one-shot limits, warning, relationship scope and unchanged accounting at transition.
- Existing single-Raider, unarmed, armed, ecosystem, recall, traversal and spectator regressions.

Assert material conservation after every accepted transfer and equipment ownership validity after every applicable equipment event. Use isolated stash paths for any scenario that enables player persistence. Keep social tests unarmed/flared/persistent only where their specific integration requires it.

Manual review at each checkpoint should assess whether the behavior is understandable and interesting, warning fairness, target switching, encounter duration, crowding, spectator readability and whether allies are useful without making the outcome automatic. Measure bounded three/five-Raider runs before increasing counts; no cross-hardware performance guarantee is assumed.

## Risks and controls

- **Indiscriminate friendly fire:** relation-aware damage eligibility, with blockers still respected; do not globally enable Raider layer damage.
- **Apparent telepathy:** attributed events and expiring observed snapshots, no shared live position feed or camera-dependent perception.
- **Target/relationship oscillation:** existing target stickiness, fresh aim warnings, explicit transitions and bounded betrayal.
- **Material farming:** finite initial allocations, no rewards at relation change, invariant checks and existing flare/reinforcement limits.
- **Cover competition and stalls:** existing reservations/watchdog, plus relationship/target validation on reservation reuse and release.
- **Scope growth:** K before cooperation, L before betrayal; no multiplayer, campaign reputation, crafting, persistent social memory, dialogue, new weapons, final art or advanced tactical planner.

Before gameplay refactoring, preserve the accepted Stage J/tooling and documentation as separately reviewable checkpoints. Git commits require explicit director authorization under AGENTS.md; this planning request does not authorize committing the current uncommitted work. Each implemented social stage should receive its own authorized commit and report after validation, then stop for review.

## Approval and current checkpoint

The director approved Stage K with relationships, competition and squad membership kept independent, confirmed its mechanics and the traversal follow-up, and authorized L. The subsequent confirmation that all functionality works accepted L and authorized M. Stage M was then accepted, with a larger window and HUD toggle requested as a presentation follow-up. Further gameplay scope requires separate agreement.
