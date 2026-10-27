# Stage X delivery evidence

Captured 2026-10-23 using Godot 4.7.2 Standard, Forward+, 1600 × 900, RTX 4060 Laptop / i7-14700HX. See the [delivery report](../../reports/stage_x_combat_audio_atmosphere.md).

- `regression/`: editor plus all 39 active suites; exit codes, completion markers and warnings. All assertions pass; 27 suites retain timing-dependent WAV shutdown diagnostics.
- `verbose_validation.json` / `cleanup_classification.json`: a second complete verbose run identifies every leaked type. Thirty suites reproduced shutdown warnings; only AudioStreamWAV and AudioStreamPlaybackWAV appeared. Two representative complete verbose logs are in `native/`.
- `native/`: ordinary-rate enabled audio and physical combat, plus dedicated accelerated audio with a test-only 200 ms mixer drain. These runs are clean. Production shutdown never waits or mutes playback.
- `final_checks.json`: final wrapper commands, exits and markers. Its regression wrapper has no warning itself; consult the per-suite records for actual warnings.
- `performance/`: corrected-W and final-X matched 30-second bay/overview samples and seven-weapon/eight-death stress. Raw CPU monitors, rare stalls, counts and hardware are retained alongside actual frame intervals.
- `replay/`: accepted W, corrected W, X disabled and X enabled observations for compact seeds 87017/87018 and expanded seed 87018. The three 40-second comparisons retain identical recorded movement (1 mm samples), state/event sequences, shots and transfers. Existing metrics event retention is bounded. This does not prove equivalence for every possible deployment.
- `source_comparison.json`: 310 identical existing runtime/scene/resource/asset/test entries, 15 changed, none missing. Changes include the test contract and index. Raider FSM/combat/threat/social/navigation, actor source art and project entry retain their identities. `reviewed_sources.json` pins the six newly changed historical U paths; previous V/W seams and reviewed AI hashes remain enforced.
- `graphical_delivered.log.txt`: actual firing, loaded Raider death, recovery, Recall banking, restart and post-death following under Forward+. `screenshots/` contains visually reviewed demos, normal mission UI and expanded views. Sounds require director listening.
- Bounded headless startup logs cover compact and expanded briefings; replay tests exercise running autonomous deployments.
- `probes/`: text copies of ignored measurement/smoke scripts. These are evidence, not extra active test suites.

The pre-X audit remains in `../stage_x_architecture_audit/`. Complete ignored snapshots, probes and isolated saves remain under `.godot/stage_x/`. Generated caches/exports stay excluded from Git. No commit or publication was performed. Manual acceptance and CPU-monitor caveats remain documented in the report.
