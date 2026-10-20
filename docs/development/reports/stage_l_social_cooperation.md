# Stage L — Cooperation and contested material recovery

Recorded: 2026-10-19. **Implemented, validated and accepted. Changes are uncommitted.** The director confirmed the traversal availability follow-up works and authorized L, then confirmed “All functional approved. proceed” and authorized Stage M in the social AI plan.

## Delivered

- Social Cooperation (Shift+F11) and separate Social Pressure (Ctrl+F11), with direct scene files. Plain F11 remains Stage K. Eleven mission presets and both original arenas retain jump/boost and one shared traversal HUD.
- Independent RaiderSocial components own received snapshots and observed loot memory. Allies communicate within 15 m; reports expire after three seconds. Only fresh direct sightings publish, with no report relaying, machine-board reuse or global target tracking.
- Each Raider uses its existing FSM to investigate reports when appropriate. Active visible combat, retreat, low health, damage/gunfire reaction and full cargo take priority. Source death, relation changes, target invalidation and expiry invalidate reports. Stationary repeated observations preserve investigation timing.
- Nearby visible material drops are remembered by identity and position for three seconds. Unknown/occluded/expired drops are not offered as globally known loot objectives. Reachable scoring, contention, cover reservations and navigation recovery remain shared with the existing systems.
- Collection validates actor and world identity, active/live state, ledger match, capacity, time, distance and unobstructed reach. Partial quantities remain in their original ground allocation; player/Raider races cannot duplicate them. Recovered cargo stays carried until death or extraction, with Lost reserved for actual Raider extraction.
- Opt-in Social Pressure uses existing flares, delays, cap and finite response budget. Authored responder policy allies with surviving R1/R2, opposes surviving R3 and allies with admitted responders. Tickets carry relation snapshots; membership never derives an alliance, and flare knowledge never reveals a killer's live location. Late targets that have resolved cannot receive relation transitions.
- F3/spectator diagnostics show report count, source, cached positions/expiry and known drop count alongside existing relationship/target information. No new movement controller, squad commands, equipment looting, cargo sharing or betrayal was introduced.

## Validation

The new social cooperation suite covers independent perception, real sight versus blocked sight, report radius, neutral/hostile exclusion, detached snapshots, no relay/tracking, malformed observation rejection, stationary-task preservation, retreat priority and expiry. Loot coverage includes discovery, hidden-memory expiry/rediscovery, reach through cover, forged-view rejection, partial collection, capacity limits, player-first contention, consumed identity removal, cargo re-drop and actual extraction accounting.

A natural integration run uses real travel, the full scavenging dwell and navigation to an exit to collect and extract a defeated Raider's finite cargo. It isolates the drop objective from other stock without changing that stock's quantities. Other checks place actors near specific cases to isolate transfer validation. Flare integration verifies authored responder relationships, two finite admissions, no budget/material creation on responder death, deadline/equipment validity and restart reset.

All seventeen suites passed, including all sixteen previous regressions and expanded jump/boost coverage across the two new presets. Godot 4.7.2 editor parsing/import, bounded headless startup, and Forward+ graphical startup of both new presets passed. Pre-existing two-instance ObjectDB shutdown warnings occurred in parallel flare/recall regression runs; no gameplay assertions failed. No persistent stash is used by the new presets or suite.

## Manual review

Assess communication usefulness, investigation pacing, whether recipients appear to know only reported positions, shared-cover congestion, competing pickup routes, partial-stack readability, responder allegiance and flare timing. Reports are informational rather than commands; allies can decline to respond while busy or retreating. Existing cargo limits remain meaningful. Empty early deaths produce no material drops, so review loot recovery after scavenging.

Natural three-Raider cooperation/loot and finite responders are covered; existing five-Raider navigation regressions pass. A five-Raider social encounter has not been separately balanced or benchmarked. Cross-hardware performance and overall encounter entertainment still require manual testing.

Checkpoint L was accepted. The separately authorized Stage M implementation is recorded in its [report](stage_m_opportunistic_betrayal.md).
