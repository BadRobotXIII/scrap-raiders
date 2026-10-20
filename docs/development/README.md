# Development records

Last updated: **2026-10-19**. Internal working title: SCRAP Raiders.

## Current position

The prototype, Phase 2 Stages A–D, Phase 3 Stages E–I and Stages J–O are accepted. Baseline commit `bac0f6d` preserves all accepted pre-P work and development records. The Stage P implementation plan was approved; seeded encounter opportunities are implemented and validated for Checkpoint P manual review. Relationships, competition and squad membership remain independent. Stage Q is not authorized.

Older stage reports retain their validation-time Git status; their previously uncommitted J–O work is now preserved by the baseline above. Stage P is a separate focused commit containing its report and implementation.

Stage I acceptance: the director confirmed jump and boost work, approved the jump height, and noted that the jump feels floaty. Refinement was explicitly deferred. The original F2-only rollout was superseded by the [post-K availability follow-up](reports/traversal_availability_followup.md): jump and boost now default to enabled across all test scenes, with their tuning unchanged.

The broad Phase 3 ledger includes future possibilities. Completion here means the approved E–I scope, not delivery of every optional capability, crafting system, chassis, or upgrade described in that ledger.

## Original ledgers

These are unchanged copies of the director's three supplied attachments. Their original planning status, dates, instructions and future-facing statements are historical. Later approvals and implemented scope are recorded in the reports below; reading a ledger does not authorize future implementation.

| Document | Original attachment |
| --- | --- |
| [Phase 1 project charter](ledgers/phase_1_project_charter.md) | `b752a4d9-75a0-4321-a33e-8a6c06ca69a7/Pasted text.txt` |
| [Phase 2 dynamic gameplay and replayability](ledgers/phase_2_dynamic_gameplay.md) | `937e55ae-6100-4f6a-aa49-7c05cdab1258/Pasted text.txt` |
| [Phase 3 hostile world, survival and extraction](ledgers/phase_3_hostile_world.md) | `e8f1b12f-c190-46d6-8633-82810f5ad497/Pasted text.txt` |

The later [Phase 4 Stage J spectator amendment](ledgers/phase_4_stage_j_spectator_amendment.md) preserves the director's supplied message as a separate ledger. No full Phase 4 social AI ledger has been supplied in this archive.

## Reports

Current work: [Stage P ledger](ledgers/phase_5_stage_p_dynamic_encounter_generation.md), [approved implementation plan](plans/phase_5_stage_p_dynamic_encounter_plan.md) and [delivery/validation report](reports/stage_p_dynamic_encounters.md). Stop at Checkpoint P for passive, active, replay, population and post-death play-testing.

The [Phase 4 social AI plan](plans/phase_4_social_ai_plan.md) records approved K–M scope and the architectural clarification.

- [Phase 1 prototype completion](reports/phase_1_completion.md): retrospective summary created for this archive.
- [Phase 2 completion](reports/phase_2_completion.md): completion report previously provided in the conversation, preserved below a short archive note.
- [Phase 3 completion](reports/phase_3_completion.md): consolidated report created for this archive, including approved scope, validation and deferred work.
- [Phase 4 completion](reports/phase_4_completion.md): accepted Stages J-M, spectator tooling, social AI, traversal/display follow-ups, validation and remaining limits.
- [Checkpoint report register](reports/checkpoints.md): reconstructed milestone summaries for Stages A–I from repository records and review feedback; not a verbatim chat transcript.
- [Stage J spectator implementation report](reports/stage_j_spectator.md): implemented debug tool, validation and director acceptance.
- [Stage K social rivalry implementation report](reports/stage_k_social_rivalry.md): relationships, rival combat, validation and subsequent director feedback.
- [Traversal availability follow-up](reports/traversal_availability_followup.md): jump/boost enabled across all test scenes following director feedback after Stage K.
- [Stage L social cooperation report](reports/stage_l_social_cooperation.md): accepted local allied reports, contested cargo recovery and opt-in flare integration.
- [Stage M opportunistic betrayal report](reports/stage_m_opportunistic_betrayal.md): accepted authored opportunity, warning, bounded pair hostility, ordinary combat/loot and display/HUD follow-up.
- [Stage N integrated extraction report](reports/stage_n_integrated_extraction.md): accepted combined deployment-to-stash mission and nineteen-suite validation.
- [Stage O post-death spectating report](reports/stage_o_post_death_spectating.md): accepted player/world lifetime separation, restricted follow view and twenty-suite validation.
- [Stage P dynamic encounters report](reports/stage_p_dynamic_encounters.md): seeded layouts, staggered arrivals, shared limits, twenty-one-suite validation and pending manual acceptance.

Use the [project README](../../README.md) for current launch commands, architecture, tuning and validation instructions. Use these records for historical scope and acceptance. Git commits identify the actual implementation at each checkpoint.

## Maintaining these records

1. Preserve original ledgers; add a new dated ledger or amendment when the director changes scope.
2. Add a completion report at each accepted phase and update the checkpoint register with its commit, validation and acceptance.
3. Update this current-position section when a checkpoint is accepted. Distinguish proposed work from approved work and implemented behavior.
4. Keep manual feedback and deferred issues explicit. Passing automated tests does not establish gameplay feel or cross-hardware performance.
