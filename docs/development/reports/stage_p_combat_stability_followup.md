# Stage P combat stability follow-up

Date: 2026-10-19; updated 2026-10-20. Status: accepted by the director on 2026-10-20 after both correction rounds. Subsequent Stage Q implementation is recorded [separately](stage_q_personality_combat.md). Changes are uncommitted.

The director reported frequent switches from combat to salvage and Raiders pushing against guards while targeting other Raiders. Perception could replace a target every decision tick, and each replacement cancelled combat through SELECTING. Incoming damage recorded the attacker without selecting it, restarted cover work, and renewed flight whenever no protective cover was available.

Social targeting now retains a living, eligible opponent during combat and its existing threat memory, including brief occlusion. Expired memory, death and changed eligibility still release that commitment. Fresh line of sight remains mandatory for firing. A visible, eligible damage instigator can redirect retaliation; unseen damage does not reveal an attacker or change neutral/allied relationships. Target changes reset aim warning without discarding a cover route.

Repeated noncritical hits preserve cover reservations and dwell progress. Healthy fighters without available cover return fire at a visible opponent rather than repeatedly renewing a retreat. Low-health retreat remains. A stalled combat route releases its cover reservation and re-engages a visible target or investigates its remembered location instead of immediately selecting salvage. Perception rays also recognize bodies when the ray begins inside them at very close range.

Encounter layouts, entry schedules, relationships, stock, mission rules and camera behavior are unchanged. This is a correction to existing combat behavior, not a new tactical planner or general crowd-avoidance system.

## Validation

All twenty-one existing automated suites and the new `combat_stability_test.gd` passed. The integrated extraction fixture now explicitly checks retained guard commitment before expiring memory and checking rival selection. The new suite covers closer-rival stability, occlusion, contact-distance guard visibility and actual return fire, attacker retaliation, repeated-hit aim/cover progress, preserved cover routes across target changes, unseen-attacker rejection, navigation stall recovery, target death, memory expiry and material conservation. Saves remain isolated under ignored `.godot/` paths.

Godot 4.7.2 editor parsing/import, bounded 900-frame headless encounter startup and 300-frame Vulkan Forward+ graphical startup passed with no reported errors. Output and exit status were inspected. The existing flare/recall suites reported two audio ObjectDB instances at shutdown during the parallel run. A separate verbose flare rerun was clean; recall passed again but retained its AudioStreamPlaybackWAV/AudioStreamWAV cleanup warning. No gameplay assertion failed. This known test shutdown warning remains separate from combat validation.

## Manual review

Use Shift+F5 and developer spectating to assess sustained guard fights, cover/peek rhythm, retaliation under crossfire, and whether rivals meet naturally after a shared guard dies. Check congested passages and low-health escapes. Automated checks establish the transitions and physical contact shot, not the subjective fluidity of whole encounters or all crowd collisions. Stop at Checkpoint P for feedback.

## 2026-10-20: guard contact and sustained fire

Director feedback found that Greedy still pressed against the guard and fights still broke off after a few shots. The first correction covered target retention and individual firing decisions, but did not establish physical clearance around a blocking actor or sustained firing across the automatic cover interval.

Raider movement now sweeps its own body ahead of a navigation step and selects a clear sideways direction around a nearby blocking CharacterBody3D. Static geometry still blocks both directions. Combat supplies a short spacing destination when a visible grounded opponent is within 2.5 metres; Raider remains the sole movement/velocity owner. While backing away in ENGAGING, visuals continue facing the opponent. This is local steering, not a replacement navigation planner or a guarantee against every crowded choke point.

The periodic cover request now requires recent incoming damage. An unanswered attack on a scout no longer triggers cover every three seconds solely because a timer expired. After completing a peek, a bounded warning-plus-two-shot-interval window allows return fire before another noncritical hit requests cover. Visibility, physical shot obstruction, cooldowns, health damage and critical-health retreat still apply. Detection and weapon ranges are unchanged: inspection confirmed armed setup already uses the rifle's 18-metre range.

All **23 automated suites passed**, including `combat_movement_test.gd`. New physical cases verify opening a gap from a contacting live guard, navigating around a live guard deliberately blocking a cover route, sustained scout hits beyond the former automatic cover interval despite available cover, range rejection, return fire during repeated damage, resumed cover response and critical retreat. The autonomous rivalry fixture now parks/freezes the player out of perception range to isolate its claimed no-player scenario; previously it left a valid stationary player target inside rifle range.

Godot 4.7.2 editor parsing/import and a bounded 600-frame Vulkan Forward+ encounter launch passed without errors. Separate 900-frame accelerated headless observation runs exercised seeds 87017 (south) and 87018 (north), alongside the full encounter-generation regression. In the north trace, Raiders maintained scout fire beyond three seconds before switching to the guard; the south trace showed completed cover routes and longer firing windows. These are observations, not assertions about a guaranteed winner. The existing two-instance audio ObjectDB cleanup warnings appeared in flare/recall test shutdown; their assertions passed. New combat tests and startup checks reported no warnings.

The director accepted the corrected behavior and approved proceeding on 2026-10-20. Changes remain uncommitted. The default Greedy/guard opening, scout attacks, sustained crossfire after peeking, low-health escapes and narrow passages remain useful regression scenarios. The separately approved Stage Q work preserves this accepted P baseline; see its own plan and report.
