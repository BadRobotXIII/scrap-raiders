# Retired test archive

This folder is reserved for genuinely superseded tests. The 2026-10-22 review found **no unused test suites** among the 33 active top-level scripts; this archive currently contains no retired scripts. Stage W subsequently added two active suites, bringing the current total to 35; neither is retired.

Before retiring a test, document which active coverage replaces it and check script inheritance/load references. Move its `.gd` and `.gd.uid` together, update remaining references, and run the affected suites. Keep the archive outside normal top-level `*_test.gd` discovery. Do not move supported single-Raider, earlier-stage or isolated-mechanic regressions merely because the normal game does not load them.

Historical test output and temporary probes already live separately: durable evidence is under `docs/development/baselines/`; generated data is under ignored `.godot/`. They are not active test scripts requiring relocation.
