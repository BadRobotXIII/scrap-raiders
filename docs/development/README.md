# Development records

Last updated: **2026-10-27**. Internal working title: SCRAP Raiders.

## Current position

The prototype through **Checkpoint Z is accepted**, including the inventory usability and scroll corrections. AA-1–AA-5 was accepted and continuation approved. AA-6–AA-9 is implemented and validated for final director review; see the [Stage AA handoff](reports/stage_aa_sanctuary_gameplay_loop.md). Baseline commit `bac0f6d` preserves accepted pre-P work; accepted P/Q/R/S work also remains in the working tree. The director approved the Stage S plan on 2026-10-21. **The director accepted Checkpoint S on 2026-10-21.** Normal startup now opens the title screen; Asset Recovery remains available as an existing contract. The [S delivery report](reports/stage_s_mission_structure.md) records objectives, deployment/settlement ownership, 29-suite validation, graphical/natural checks, director acceptance and retained refinement checks.

The director approved the [Stage T audit/remediation plan](plans/phase_7_stage_t_remediation_plan.md) on 2026-10-21. Its implementation is **accepted at Checkpoint T on 2026-10-21**, with a dead-target eligibility correction, normal-only north entry-placement refinement, physical S integration coverage, 30 passing suites and eight natural observations. The [T delivery report and updated matrix](reports/stage_t_full_gameplay_integration.md) distinguish natural events, constructed fixtures and remaining director review. The [original audit](reports/stage_t_integration_audit.md) remains the historical S baseline. The director explicitly stated "Stage T is approved." No commit is included; Stage U planning is recorded below.

The director subsequently reported rapid spinning and decision paralysis during multi-threat encounters and close allied contact. The [Raider decision follow-up](reports/stage_t_raider_decision_followup.md) records three reproductions and targeted movement/target/attacker-response corrections. The director subsequently accepted Stage T including this follow-up; it does not alter mission resources or expand scope.

Older stage reports retain their validation-time Git status; their previously uncommitted J–O work is now preserved by the baseline above. Stage P is a separate focused commit containing its report and implementation.

Stage I acceptance: the director confirmed jump and boost work, approved the jump height, and noted that the jump feels floaty. Refinement was explicitly deferred. The original F2-only rollout was superseded by the [post-K availability follow-up](reports/traversal_availability_followup.md): jump and boost now default to enabled across all test scenes, with their tuning unchanged.

The broad Phase 3 ledger includes future possibilities. Completion here means the approved E–I scope, not delivery of every optional capability, crafting system, chassis, or upgrade described in that ledger.

The supplied [Stage U ledger](ledgers/phase_7_stage_u_world_expansion.md) is archived byte-for-byte from attachment `37d23ca3-1204-42b0-bf24-2502a0a52f0b/Pasted text.txt`. The [world-expansion architecture/layout proposal](plans/phase_7_stage_u_world_expansion_plan.md) assesses the accepted compact baseline and proposes a 72 x 64 m interconnected graybox. **The director approved the proposal and accepted Checkpoint U on 2026-10-21 after confirming everything functioned perfectly.** See the [Stage U report](reports/stage_u_world_expansion.md) for navigation, physical travel/combat, seeded observations, graphical validation and performance evidence. Default startup remains compact Asset Recovery.

The supplied [Stage V ledger](ledgers/phase_7_stage_v_environment_art.md) is archived byte-for-byte from attachment `194b4572-b6fb-40e6-88c4-156e5499e064/Pasted text.txt`. The [environment pipeline and processing-bay proposal](plans/phase_7_stage_v_environment_art_plan.md) incorporates the director's industrial reference images and grounded visual direction. Blender 4.5.10 LTS is verified locally. **The director accepted Checkpoint V on 2026-10-22.** The [delivery report](reports/stage_v_environment_art.md) records eight original assets, the limited bay, source-edit/reimport proof, 33 passing suites, graphical checks, measured cost, acceptance and retained refinement checks. The [production guide](../art_pipeline/README.md) documents the Blender-to-GLB workflow. Stage W is recorded below; no Git commit is authorized.

The supplied [Stage W ledger](ledgers/phase_7_stage_w_character_machine_visuals.md) is archived byte-for-byte from attachment `31d5341e-3e15-4b5d-bc3f-852a5fae071b/Pasted text.txt`. The [actor visual-production proposal](plans/phase_7_stage_w_actor_visual_production_plan.md) incorporates the four actor images and the director's subsequent design descriptions. It audits current physical/visual contracts, proposes one Raider rig and simple mechanical hierarchies, and addresses fixed shot anchors, cosmetic variation, existing static death-copy limitations, import/reimport, performance and regression coverage. **The director approved design/architecture on 2026-10-22 and explicitly accepted completed Stage W in the Stage X ledger on 2026-10-23.** The [delivery report](reports/stage_w_actor_visual_production.md) records four original models, a reusable human rig, minimal animation, source reimport, 35 passing suites, physical/graphical checks, simultaneous death/cleanup, measured rendering cost and remaining visual acceptance. See the [actor guide](../art_pipeline/actors.md). Stage X was subsequently approved separately; no Git commit is authorized.

## Original ledgers

These are unchanged copies of the director's three supplied attachments. Their original planning status, dates, instructions and future-facing statements are historical. Later approvals and implemented scope are recorded in the reports below; reading a ledger does not authorize future implementation.

| Document | Original attachment |
| --- | --- |
| [Phase 1 project charter](ledgers/phase_1_project_charter.md) | `b752a4d9-75a0-4321-a33e-8a6c06ca69a7/Pasted text.txt` |
| [Phase 2 dynamic gameplay and replayability](ledgers/phase_2_dynamic_gameplay.md) | `937e55ae-6100-4f6a-aa49-7c05cdab1258/Pasted text.txt` |
| [Phase 3 hostile world, survival and extraction](ledgers/phase_3_hostile_world.md) | `e8f1b12f-c190-46d6-8633-82810f5ad497/Pasted text.txt` |

The later [Phase 4 Stage J spectator amendment](ledgers/phase_4_stage_j_spectator_amendment.md) preserves the director's supplied message as a separate ledger. No full Phase 4 social AI ledger has been supplied in this archive.

The [Stage R development ledger](ledgers/phase_5_stage_r_encounter_polish.md) preserves the full supplied Stage R text. Its prerequisite was satisfied when the director separately confirmed Q acceptance. Its plan was approved and the resulting Stage R delivery is accepted; the original proposal instructions remain archived as historical text.

The [Stage S development ledger](ledgers/phase_6_stage_s_mission_structure.md) is an unchanged copy of attachment `9aa3bf23-cd8e-4756-bc7b-e218c4584e77/Pasted text.txt`. Its [architecture and implementation proposal](plans/phase_6_stage_s_mission_structure_plan.md) was approved and implemented; the original stop-before-implementation text remains archived as historical instructions.

The [Stage T development ledger](ledgers/phase_7_stage_t_integration_audit.md) combines attachment `06ce110b-9619-4559-9704-024d886eada2/Pasted text.txt`, which stops in section 9, with the director's complete follow-up reply. The director subsequently approved its focused remediation plan; the original approval instructions remain archived as historical scope.

## Reports

- [Stage U world expansion](reports/stage_u_world_expansion.md): approved modular graybox, shared mission configuration/replay, physical regressions, natural seed comparison and subsequent Checkpoint U acceptance.

Stage P play-test feedback prompted a focused [combat stability correction](reports/stage_p_combat_stability_followup.md): engagement retention, visible-attacker retaliation, uninterrupted cover progress, physical guard clearance and sustained firing. The 2026-10-20 follow-up passed twenty-three suites and was accepted by the director.

Historical accepted work: [Stage R integrated mission polish](reports/stage_r_integrated_polish.md), including 27-suite validation, clearer feedback, optional metrics and the rejected timing experiment. The [Stage R baseline report](reports/stage_r_baseline_evaluation.md) and [evidence archive](baselines/stage_r_2026_10_20/summary.json) preserve pre-implementation observations. The approved [Stage S plan](plans/phase_6_stage_s_mission_structure_plan.md) is now delivered and accepted at Checkpoint S.

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
- [Stage P dynamic encounters report](reports/stage_p_dynamic_encounters.md): accepted seeded layouts, staggered arrivals and shared limits; twenty-one initial suites and twenty-three after combat follow-ups.
- [Stage Q personality combat report](reports/stage_q_personality_combat.md): accepted opt-in armed personality decisions, stable commitments, bounded observed-position pursuit and twenty-five-suite validation.
- [Stage S mission structure delivery](reports/stage_s_mission_structure.md): briefing, banked-loot objectives, frozen results, 29-suite validation and director acceptance on 2026-10-21.
- [Stage T integration audit](reports/stage_t_integration_audit.md): historical pre-implementation matrix, ownership/lifecycle review, fresh 29-suite validation, normal seeded evidence and classified gaps.
- [Stage T full gameplay integration](reports/stage_t_full_gameplay_integration.md): approved implementation, updated matrix, controlled configuration comparison, original 30-suite validation, graphical evidence and subsequent Checkpoint T acceptance.
- [Stage T Raider decision follow-up](reports/stage_t_raider_decision_followup.md): director-reported contact spinning and multi-threat paralysis, physical regressions, short body bypasses and bounded target/attacker commitment; 31-suite validation and director acceptance.
- [Stage R integrated polish delivery](reports/stage_r_integrated_polish.md): implemented scope, rejected timing trial, validation and director acceptance of Checkpoint R.
- [Stage R baseline evaluation](reports/stage_r_baseline_evaluation.md): current configuration audit, normal/accelerated observations, reproduced recovery feedback defect, HUD capture, source hashes and fresh validation. Historical pre-implementation evidence; see the Stage R delivery report for subsequent work.

Use the [project README](../../README.md) for current launch commands, architecture, tuning and validation instructions. Use these records for historical scope and acceptance. Git commits identify the actual implementation at each checkpoint.

## Maintaining these records

1. Preserve original ledgers; add a new dated ledger or amendment when the director changes scope.
2. Add a completion report at each accepted phase and update the checkpoint register with its commit, validation and acceptance.
3. Update this current-position section when a checkpoint is accepted. Distinguish proposed work from approved work and implemented behavior.
4. Keep manual feedback and deferred issues explicit. Passing automated tests does not establish gameplay feel or cross-hardware performance.

The director positively reviewed W models and physics, then requested steadier Raider action commitment. The [W action/steering follow-up](reports/stage_w_raider_action_commitment.md) records the focused correction, 36-suite validation and remaining manual gameplay review. Raider retains the only FSM; formal W acceptance is now explicitly recorded in the Stage X ledger.


The [Stage X ledger](ledgers/phase_7_stage_x_combat_audio_atmosphere.md) is archived byte-for-byte from attachment `cf9b2601-1a84-4e75-ba72-343026392d84/Pasted text.txt`. The [combat/audio/atmosphere architecture proposal](plans/phase_7_stage_x_combat_audio_atmosphere_plan.md) incorporates four supplied visual references, inventories current reusable feedback and identifies the existing flinch/muzzle ownership issue. Fresh audit checks passed. The director subsequently approved this architecture and its recommended muzzle correction; see the delivery below. No Git action or publication is authorized.

## Stage X checkpoint

The director approved the [combat/audio/atmosphere proposal](plans/phase_7_stage_x_combat_audio_atmosphere_plan.md), including the existing flinch/muzzle correction. **The director accepted Checkpoint X on 2026-10-25.** Documented audio-shutdown and performance caveats remain refinement items; acceptance introduces no further runtime changes. See the [delivery report](reports/stage_x_combat_audio_atmosphere.md), [validation evidence](baselines/stage_x_delivery/README.md), [presentation ownership guide](../presentation/README.md) and [original audio provenance](../../assets/audio/README.md). Stage Y, commits and publication remain outside this delivery.


## Stage Y checkpoint - accepted 2026-10-26

The [director ledger](ledgers/phase_7_stage_y_world_population.md) remains archived byte-for-byte from attachment `08913bfe-d888-457e-ad60-12726614db53/Pasted text.txt`. The director approved the [base proposal](plans/phase_7_stage_y_world_population_plan.md). Four-zone RIVET RECLAMATION WORKS dressing, eight original new modules, source-backed shared batches and a sixteen-asset inspection are implemented. Existing physical/gameplay authority is preserved; the separately proposed roof supports remain excluded.

The [delivery report](reports/stage_y_world_population.md) and [evidence](baselines/stage_y_delivery/README.md) record forty passing suites, graphical recovery/Recall/death/restart, clean GLB-only import, exact west/east X/Y replay, rendering budgets and retained WAV shutdown diagnostics. The earlier [planning audit](baselines/stage_y_environment_audit/README.md) preserves the accepted X before-images and measurements. The director accepted Checkpoint Y on 2026-10-26, including the subsequent refinement below. Commit/publication remain unauthorized.

The director subsequently requested richer ground transitions, connected utilities and denser small-prop groupings. The director approved the [Stage Y refinement amendment](plans/phase_7_stage_y_environment_refinement_plan.md), including three exact collider footprints and the bounded rendering budget. The [refinement delivery](reports/stage_y_environment_refinement.md) and [separate evidence](baselines/stage_y_refinement_delivery/README.md) record integrated ground wear, service connections, shared staged loads, 41 passing suites, actual movement/contact checks, exact spectator replay and graphical validation. The director accepted Stage Y and this refinement on 2026-10-26; recorded performance/audio limitations remain future refinement items.

## Stage Z checkpoint - accepted 2026-10-27

The [supplied ledger](ledgers/phase_7_stage_z_hybrid_inventory.md) remains unchanged. The director approved the complete [architecture proposal](plans/phase_7_stage_z_hybrid_inventory_plan.md) after accepting Y. The [audit and baseline](reports/stage_z_inventory_architecture_audit.md) preserve the pre-implementation state.

The [Stage Z delivery report](reports/stage_z_hybrid_inventory.md) records one shared item authority, finite typed sources, Raider value/capacity integration, live inventory/preparation, durable loadout debit and settlement, migration/quarantine, 47-suite validation, seeded deployments, graphical checks and measured costs. See the [delivery evidence](baselines/stage_z_delivery/README.md). The director accepted Checkpoint Z on 2026-10-27, including the inventory usability and scroll corrections. Stage AA architecture is approved; AA-1 through AA-5 is implemented for mandatory play-testing. No commit or publication is authorized.

## Stage AA — approved architecture proposal

The [director ledger](ledgers/stage_aa_sanctuary_gameplay_loop.md) is archived byte-for-byte. The [repository audit](reports/stage_aa_architecture_audit.md), [fresh baseline](baselines/stage_aa_architecture_audit/README.md) and [architecture proposal](plans/stage_aa_sanctuary_gameplay_loop_plan.md) cover application entry, safe sanctuary, shared preparation, templates, one reserved kit, deployment/return, minimal processing/upgrades, placement and handoff. The director approved this architecture; AA-1 through AA-5 is now implemented. The original audit remains the pre-implementation record. The mandatory director play-test stop after AA-5 still applies.

## Stage AA early playable checkpoint — AA-1 through AA-5

The director approved the [architecture plan](plans/stage_aa_sanctuary_gameplay_loop_plan.md). The [early delivery](reports/stage_aa_playable_loop.md) connects title, safe Sanctuary, shared preparation/templates, existing contracts and repeated deployment/results/return. See its validation evidence and manual checklist. This early checkpoint was accepted; see the final handoff below for the subsequent approved implementation. No commit or publication is authorized.


## Stage AA final handoff — implementation ready for acceptance

The director accepted the early playable loop and explicitly authorized continuation. AA-6–AA-9 now adds atomic disassembly/fabrication, permanent paid cargo capacity, bounded saved furniture, one identity-preserving item display and the developer handoff. The [final report](reports/stage_aa_sanctuary_gameplay_loop.md) links 52-suite validation, native interaction, seeded observations, performance evidence and the final play-test checklist. The early report/audit remain historical records. Stop for final Stage AA acceptance; no commit/publication or next-stage work is authorized.
