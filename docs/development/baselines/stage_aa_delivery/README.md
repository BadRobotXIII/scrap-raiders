# Stage AA final implementation evidence

Captured **2026-10-27**, after director acceptance of AA-5 and authorization to continue. AA-6 through AA-9 is implemented for final director review. See the [delivery report and checklist](../../reports/stage_aa_sanctuary_gameplay_loop.md). The [AA-5 evidence](../stage_aa_playable/README.md) and [pre-AA audit](../stage_aa_architecture_audit/README.md) remain separate historical records.

- `summary.json`: final suite counts, warning classification, four seeded observations, graphical/performance samples and profile-access boundary.
- `regression/validation.json` plus 52 logs: full active batch with final affected-suite reruns. Scripts/assertions and completion markers were inspected, not exit status alone. Later reruns cover exact craftability, display stack identity, ordinary transfer behavior and upgraded deployment.
- `editor_import.log.txt`: final clean Godot 4.7.2 parsing/import output.
- `graphical.log.txt`, `graphical_metrics.json`, `screenshots/`: actual native Forward+ recipe confirmations, paid upgrade, item assignment, bounded placement and cold reload. Seven screenshots include 1600 x 900 and 1280 x 720.
- `natural.json` / `natural.log.txt`: passive application deployments of both contracts at seeds 87017 and 87018, bounded to 160 simulation seconds each. All continued after player destruction, conserved accounting and returned home; outcomes were observed rather than prescribed.
- `persistence_metrics.json` / corresponding log: five ordinary writes, five writes with 1,000 available equipment records, exact cold reload and cache sizes. These short-chain samples do not bound years of journal growth.
- `reviewed_sources.json`: nine exact overrides relative to AA-5, including two rifle description updates, inventory/persistence/preparation, shared views, Sanctuary and the asset-pipeline guard. All other prior runtime source identities remain unchanged.
- `source_manifest.json`: 451 current script/UID/scene/resource/config/test identities. Generated `.godot` files are excluded.
- `working_tree_status.txt`: final working-tree inventory. Earlier accepted scroll changes remain present. No commit/publication was performed.
- `*.gd.txt` and `*.py.txt`: retained probe/runner source as text, outside active Godot/test discovery.

To reproduce the probes, restore the final helper text to `.godot/stage_aa_final/`. Restore `graphical_base.gd.txt` as `.godot/stage_aa_build/graphical.gd`, which the final graphical probe extends. That base uses the actual `tests/application_lifecycle_test.gd` helpers. The runner executable is this machine's `C:/Users/kzulf/bin/godot.cmd`; adjust it for another environment. Active suites run with `--headless --verbose --path . --fixed-fps 60 --script res://tests/<suite>.gd --quit-after 20000`.

Every application probe sets a randomized ignored profile path before adding its scene to the tree. The real `user://stash.json` was not read, migrated or written during development. Normal interactive startup uses the documented application profile and existing backup/migration policy.

Thirty-four suite logs retain known WAV cleanup warnings, as does the natural probe; verbose leaked-instance types are exclusively `AudioStreamWAV` and `AudioStreamPlaybackWAV`. Editor, graphical and persistence-measurement output is clean. Functional tests and screenshots do not imply final director visual/gameplay acceptance.
