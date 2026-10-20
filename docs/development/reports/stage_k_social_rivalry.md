# Stage K — Relationships and rival combat

Recorded: 2026-10-19. **Implemented and validated; awaiting manual review and acceptance. Changes are uncommitted.** Stage K alone was approved from the [social AI plan](../plans/phase_4_social_ai_plan.md), with the director's architectural clarification that relationships, competition and permanent squads are distinct.

Subsequent director feedback: all new mechanics seem to work well; jump/boost appeared unavailable. The original F2-only restriction is superseded by the [traversal availability follow-up](traversal_availability_followup.md). The report below preserves Stage K's delivered scope and validation before that follow-up.

## Delivered

- Separate F11 Social Rivalry preset: three armed Raiders, nine finite materials, fixed seed 81017, 180-second deadline and authored immediate entries. R1/R2 are allied; R3 is hostile to both. None has a squad assignment. Robot begins distant and remains vulnerable.
- Mission-local RaiderRelations owns explicit symmetric pair attitudes, default neutrality, validated changes, reasons and terminal sealing. Squad metadata never derives a relationship, and relationships do not reserve stock, transfer cargo or change ledger ownership.
- Neutral Raiders retain independent objective scoring and can compete for the same finite salvage. Allied Raiders can independently target the same machine without a permanent squad or shared movement controller.
- General combat-target callback supports eligible hostile humans alongside machines through the existing FSM. Visibility, target stickiness, fresh aim warning, cover, retreat and physics movement remain shared.
- Optional ShotExecutor damage-eligibility callback prevents allied/neutral human damage while retaining their physical obstruction. Health records accepted hit origin and instigator object-instance ID; old damage callers remain compatible. Live Raider instigators are shown by Raider ID in the inspector.
- F1/Tab/F and F3 show pair attitudes/reasons, absent squad membership, current target/reason, objectives, cargo and damage source. Other presets retain their previous human-friendly weapon rules and behavior.
- Ordinary cargo drops, duplicate-event protection, conservation, deadline sealing and restart remain ledger/mission-owned. No new material transfer or reward is triggered by a relationship change.

## Validation

All **sixteen suites passed**, including the fifteen prior regressions and `social_rivalry_test.gd`. Godot 4.7.2 parsing/import, bounded headless rivalry startup and Forward+ graphical rivalry startup passed without reported errors.

New tests verify default neutral attitudes; independent alliances without squads; invalid/duplicate/resolved/sealed relation rejection; detached diagnostics; conflicting configuration rejection; three legal entries; physical hostile damage/instigator attribution; aim warning; allied/neutral blockers; eligibility changes; occlusion; two neutral contenders for one finite stock; spectator inspection; allies targeting the robot without squads; simultaneous ordinary death/cargo outcomes; freed targets; terminal shutdown; authored restart; natural human combat and a real combat death with the robot uninvolved; conservation; and legacy Survival damage behavior.

The pre-existing two-instance ObjectDB shutdown warning appeared in the parallel extraction suite. New rivalry tests and rivalry startup checks reported no cleanup warnings. This checkpoint does not claim to fix general audio cleanup.

The authored three-Raider encounter is covered by natural combat simulation. Existing five-Raider regression scenarios still pass, but a five-Raider social encounter has not been separately balanced or benchmarked. No persistent stash is used by the new preset/tests.

## Boundaries and manual review

Pair attitudes are symmetric in Stage K. Dynamic alliances, asymmetric opinions, shared allied observations, formation/squad commands, betrayal, human equipment looting and Raider collection of defeated humans' cargo are not introduced. Proposed Stages L/M remain unapproved. Flares/reinforcements, machines and traversal retain separate presets to keep this first rivalry review focused.

Play-test F11 followed by F1. Assess fight length, one-versus-two balance, warning fairness, target switching, cover/retreat paths, return to scavenging and relationship/target readability in Tab/F3. Repeat with the robot entering the encounter to verify independent machine threat targeting feels sensible. Verify that neutral competition and alliance behavior remain understandable before considering richer cooperation.

Stop at **Checkpoint K** for feedback. Keep the accepted Stage J and documentation work intact; no commit has been created under this request.
