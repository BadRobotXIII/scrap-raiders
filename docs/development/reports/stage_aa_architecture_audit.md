# Stage AA repository and lifecycle audit

Prepared **2026-10-27** after the director accepted Checkpoint Z, including inventory usability and scroll corrections. **Audit only; no AA gameplay implementation.** Read alongside the [original ledger](../ledgers/stage_aa_sanctuary_gameplay_loop.md), [architecture proposal](../plans/stage_aa_sanctuary_gameplay_loop_plan.md) and existing [code-flow guide](../../architecture/game_code_flow.md).

## Repository and evidence

HEAD is `e5a9ddb` (Stage P–Z substantial gameplay mechanics and visual upgrades). The accepted scroll correction remains in the working tree in `inventory_view.gd` and `inventory_ui_test.gd`, with its evidence/report. This audit preserved it and all user work. Acceptance updates and AA planning documents are the only project changes in this turn. No commit, reset, deletion, publication or real-profile access occurred.

The AA attachment is archived byte-for-byte with SHA256 `548c09fd4966bedcd84e4bdd9cef4fd6de15036519f2994c92f1503359e908da`. It specifies Stage AA without a new phase number; filenames do not invent one. The [fresh baseline](../baselines/stage_aa_architecture_audit/README.md) contains source identities, Git status and logs.

## Implemented baseline versus AA gaps

| Area | Authoritative implementation / actual behavior | AA integration gap |
| --- | --- | --- |
| Entry | `project.godot` starts `scenes/levels/asset_recovery_arena.tscn`; no gameplay autoload | No title, persistent application root or home scene |
| Mission configuration | `mission_arena.gd._ready()`, MissionConfig and seeded EncounterSetup; expanded scene uses an override | No player-facing contract catalog or persistent selection |
| Initialization | `raider_arena.gd._ready()` creates inventory, stock, Recall/stash, navigation, actors and views | Workshop must not instantiate a hostile arena to obtain storage services |
| Prepared ownership | InventoryLedger owns `stash`, `prepared`, `escrow`, `quarantine`; one reserved configuration | No desired-loadout templates or multiple prepared kits |
| Preparation UI | InventoryView has icons, context actions and stable scrolling | Direct `mode.arena` dependencies require an explicit context for safe-home/Quick Deploy reuse |
| Player | `robot.tscn`, RobotController, RobotInput, RobotCamera, HitscanWeapon/ShotExecutor and Health | Sanctuary must permit walking while refusing shots and damage; input currently has one broad gameplay permission |
| Camera | Yaw/pitch, shoulder obstruction query, SpringArm3D; scene starts at −8° with 5 m arm | No elevated home preset, zoom control or placement framing |
| Weapons | EquipmentBinding enables the existing blaster from mounted ownership | Human-only rifles remain cargo by director instruction; no robot rifle conversion is proposed |
| Profile | PersistentStash is sole disk writer; v2 verified journal, backups and idempotent commands | Needs versioned home/template/preferences/result metadata and session binding |
| Profile attachment | `RecallController.setup()` constructs PersistentStash; `attach_inventory()` loads and resolves abandoned escrow | Calling this loading path during an active application handoff could misclassify its own escrow as abandoned |
| Deployment start | `start_deployment()` durably debits prepared → escrow, then runtime moves escrow → player | No application preflight/readiness/refund protocol for failed initialization |
| Settlement | RecallController, PersistentStash.settle_inventory(), InventoryLedger.settle_player() | Durable item receipt does not contain frozen objective/contract results |
| Objectives | MissionObjectives owns four existing types and freezes results after settlement; MissionRules owns outcome/world lifetime | No persistent completion history/unlocks; a new quest engine is unnecessary |
| Return/restart | `select_scenario()` removes the arena from SceneTree.root and replaces current_scene | App-managed child scenes must delegate replacement to the session; preserve standalone behavior |
| Death/spectating | Irreversible player failure with optional autonomous continuation and separate world termination | Return Home must reconcile settlement before disposing the remaining local world |
| Accounting | One InventoryLedger; material/equipment facades project state; per-definition/cohort invariants | Recipes need explicit authorized transformations; transfers cannot change definition |
| Workshop/progression | Nonweapon mounts are data-only; no recipes, permanent upgrades or workshop services | AA-6 adds a small deterministic processing/capacity foundation |
| Layout/displays | Art scenes are presentation; no persistent furniture or real-item displays | Need bounded placement and ledger-backed display reservation after AA-5 approval |
| Assets | Sixteen original environment modules, W actors and X ambience; explicit GLB pipeline | Reuse existing walls, cabinets, utility runs, bins and pallets; no new art pipeline |
| Validation | 47 suites, isolated saves, diagnostic scenes and historical exact source guards | Add application/path-equivalence/fault coverage and narrow AA source-change evidence |

## Fresh verification

All 47 batch processes exited zero. **This is not an entirely clean batch pass:** 46 suites completed without assertion/script failures, but `tests/post_death_spectator_test.gd:205` accessed `arena.raiders[1]` while that key was absent. It reached bounded termination without its completion marker. A subsequent isolated verbose rerun completed with `failures: 0`.

The fixture freezes simulation, waits a fixed number of frames and calls `process_entries()` once. A timing-dependent actor-admission assumption is the suspected cause, not a verified production spectator defect. Propose a bounded wait for authoritative admission with explicit setup failure; keep the observer assertion. Do not skip absent actors or substitute an unbounded delay.

Thirty-two batch suites retained the documented shutdown audio warning. Verbose leaked types were exclusively AudioStreamWAV/AudioStreamPlaybackWAV. Editor parsing/import completed without errors. A bounded native Forward+ UI suite passed with actual mouse/keyboard input, including below-fold selection/equipping, and no errors/warnings. No AA feature exists to play-test yet. Development did not inspect or change the actual player profile.

## Required architectural safeguards

1. Revoke outgoing command access before publishing the next inventory authority; transaction candidates remain unpublished previews.
2. Run abandoned-escrow recovery once at profile open, not at every scene bind.
3. Distinguish an unstarted committed kit from an active deployment; failed initialization refunds only the former, preserving identities.
4. Commit authoritative frozen results and contract completion with settlement so progression cannot be lost or rewarded twice.
5. Reconstruct home from the verified persistent projection; never unseal and reuse a terminal world ledger.
6. Share preparation commands and UI context between physical and quick paths; no copied station-specific mutations.
7. Authorize and record recipe debits/credits explicitly; no second material balance or unlogged output issuance.
8. Extend the existing architecture document with the application/home branch while retaining its AI/accounting/asset maps.

The [proposal](../plans/stage_aa_sanctuary_gameplay_loop_plan.md) requires approval before runtime changes. The spectator fixture correction is proposed, not implemented. Z acceptance remains recorded independently of this baseline finding.
