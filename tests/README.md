# Test index

Reviewed 2026-10-26. All **47** top-level `*_test.gd` scripts remain active regression suites. The original W delivery passed 35 suites; the W review adds a physical action-commitment regression, and Stage X adds physical combat presentation, audio lifecycle and autonomous on/off replay coverage; Stage Y adds source-backed static batching, all-zone physical-envelope and actual cover-shot coverage; its approved refinement adds physical routes around three explicit new blockers, visible/collision boundary checks, boost/jump/camera contact and blocked/clear rifle lanes; older stages still exercise supported mechanics and reference scenarios. No obsolete or unused suite was identified, so none was moved to the [archive](archive/README.md).

Tests are standalone Godot `SceneTree` scripts, not scenes instantiated by the normal game. A lack of runtime references does not mean a test is unused. Each `.gd.uid` is Godot resource identity metadata belonging to its `.gd` script; keep them together.

Stage Z adds six suites for the shared inventory, durable persistence/fault boundaries, registered world sources, physical Raider collection/extraction, UI/input and sequential deployment lifecycle. Existing S/T/U scalar-content fixtures explicitly select legacy configuration while retaining the same shared ledger engine; new inventory suites load the actual current normal/expanded configurations. Historical source guards retain their original baselines plus the exact reviewed Z caller identities.

## Coverage map

| Area | Active scripts |
| --- | --- |
| Shared hybrid inventory | `item_inventory_test.gd`, `inventory_persistence_test.gd`, `inventory_world_test.gd`, `inventory_raider_test.gd`, `inventory_ui_test.gd`, `inventory_lifecycle_test.gd` |
| Player movement and traversal | `robot_controller_test.gd`, `traversal_test.gd` |
| Hitscan, health and destruction | `combat_test.gd`, `destruction_test.gd`, `hostile_combat_test.gd` |
| Basic Raider and mission regressions | `raider_test.gd`, `mission_test.gd`, `multi_raider_test.gd`, `dynamic_ai_test.gd`, `mission_variety_test.gd`, `awareness_test.gd` |
| Loot, escalation, extraction and machines | `flare_loot_test.gd`, `extraction_test.gd`, `machine_ecosystem_test.gd` |
| Spectator permissions and lifecycle | `spectator_test.gd`, `post_death_spectator_test.gd` |
| Relationships, cooperation and betrayal | `social_rivalry_test.gd`, `social_cooperation_test.gd`, `betrayal_test.gd` |
| Encounter generation and combat stability | `encounter_generation_test.gd`, `combat_stability_test.gd`, `combat_movement_test.gd` |
| Personality-aware armed decisions | `personality_combat_test.gd`, `personality_integration_test.gd` |
| Integrated extraction and feedback | `integrated_extraction_test.gd`, `recovery_feedback_test.gd`, `refined_extraction_test.gd` |
| Objectives, deployment and full integration | `mission_objectives_test.gd`, `deployment_flow_test.gd`, `gameplay_integration_test.gd`, `raider_decision_stability_test.gd`, `action_commitment_test.gd` |
| Combat/audio presentation and non-interference | `combat_presentation_test.gd`, `audio_lifecycle_test.gd`, `presentation_integrity_test.gd` |
| Actor imports and presentation | `actor_import_test.gd`, `actor_visual_test.gd` |
| Expanded world and art pipeline | `expanded_world_test.gd`, `asset_pipeline_test.gd`, `world_population_test.gd`, `environment_refinement_test.gd` |

## Shared helper dependencies

The arrows mean “extends/reuses helpers from.” Each listed script still has its own runnable `run()` coverage:

```text
asset_pipeline_test → expanded_world_test → gameplay_integration_test
                                             → deployment_flow_test
                                                 → integrated_extraction_test
action_commitment_test / raider_decision_stability_test → gameplay_integration_test
refined_extraction_test → integrated_extraction_test
personality_integration_test → personality_combat_test
```

Moving a base suite without updating its dependants breaks their script paths. Stage V also checks accepted baseline source identities, so relocating an active script is more than an editor cleanup.

## Running tests

From the repository root:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/flare_loot_test.gd
```

To run all active suites sequentially in PowerShell, discover only the top level. Do not recursively include archived scripts:

```powershell
Get-ChildItem -LiteralPath tests -Filter '*_test.gd' -File | Sort-Object Name | ForEach-Object {
    godot --headless --path . --script ('res://tests/' + $_.Name)
    if ($LASTEXITCODE -ne 0) { throw ('Test failed: ' + $_.Name) }
}
```

Inspect warnings/errors as well as exit codes. Tests use isolated temporary saves under ignored `.godot/` paths. Current full-suite and focused graphical logs are in [Stage W evidence](../docs/development/baselines/stage_w_delivery/README.md), including the retained audio cleanup warnings. The [action-commitment follow-up](../docs/development/reports/stage_w_raider_action_commitment.md) records the later 36-suite run and reviewed AI source changes. Stage V evidence remains archived separately.

The [game code-flow guide](../docs/architecture/game_code_flow.md) describes production ownership and explains how these suites relate to gameplay.

Stage X validation and the remaining accelerated WAV cleanup warning are recorded in the [X delivery report](../docs/development/reports/stage_x_combat_audio_atmosphere.md) and [evidence](../docs/development/baselines/stage_x_delivery/README.md). Native-rate enabled audio and combat are checked separately; exit status alone does not establish warning-free teardown.

Stage Y final editor and forty-suite logs, source pins, native/accelerated warning classification and seeded physical replay are in the [Y evidence](../docs/development/baselines/stage_y_delivery/README.md). See its report for current acceptance status.

The [Y refinement report](../docs/development/reports/stage_y_environment_refinement.md) and [separate evidence](../docs/development/baselines/stage_y_refinement_delivery/README.md) record the later 41-suite run, focused final physical suite, clean native-rate checks and retained accelerated WAV warnings. Historical forty-suite Y evidence is preserved.

Stage Z final 47-suite logs, native graphical checks, complete seeded deployments, fault injection and large-stash measurements are in the [Z delivery evidence](../docs/development/baselines/stage_z_delivery/README.md). The director’s real stash was not used by development or validation.
