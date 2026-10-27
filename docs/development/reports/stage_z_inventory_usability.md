# Stage Z inventory usability refinement

Delivered 2026-10-26 in response to director review. **Checkpoint Z manual acceptance remains pending.** The director confirmed that Raider rifles stay human-only: the robot may recover, extract and store them. Disassembly at base and using recovered resources for robot/weapon upgrades are recorded as future proposals.

## Delivered refinement

The inventory now has twelve original item silhouettes, visible cargo tiles, labeled robot mounts, selected-item outlines, quantity controls and a carried-weight meter. Compatible robot equipment has a consistent visual treatment; names and compatibility text remain readable independently of color. The selected-item details explicitly identify Raider-only rifles and disable Equip for those items. Empty base storage and unarmed loadouts explain recovery options.

Actions reflect preparation, deployed cargo and the searched source. Preparation uses Store / Prepare cargo, hides Drop and source-only actions, and rejects an unavailable action instead of silently treating it as a transfer. Compatible equipment can be equipped directly from storage. Replacing a prepared mount returns its previous item to storage in the same existing durable candidate transaction; failure discards the candidate.

| Control while inventory is open | Behavior |
| --- | --- |
| Shift+click | Move the full selected stack; source pickup takes only the amount that fits |
| Double-click | Equip/unequip compatible owned or stored gear; otherwise move cargo when a destination is available |
| F | Equip/unequip selected compatible equipment |
| T | Move selected quantity to prepared cargo, base storage or searched source; source pickup takes what fits |
| A | Take all source loot that fits; remainders stay in the source |
| X | Drop selected deployment cargo |
| I / Escape | Close inventory |

Shortcuts appear in the panel, respect action availability, ignore repeated or Ctrl/Alt/Meta-modified input and do not fire while entering a quantity. World simulation, source access checks and damage/death closure remain active. The panel fits the viewport; renderer captures verify both 1600×900 and 1280×720.

## Loadout weapon clarification

Industrial blasters are robot-compatible. Raider and worn-response rifles remain human-only cargo. There is one starter blaster per new/migrated profile and one finite recoverable blaster in the normal deployment tool cabinet. If the starter was lost, preparation does not create a replacement: deploy unarmed to recover compatible equipment, then extract it for subsequent loadouts. Other actors can affect finite recovery opportunities.

This refinement changes presentation and preparation interaction, not compatibility, weapon statistics, quantities, loot generation, capacity, AI decisions or deployment loss rules. All ownership still goes through InventoryLedger; PersistentStash remains the sole persistent writer. The twelve SVG icons are original project assets; no external art was used. Armor/power/mobility/utility retain their documented lack of stat effects.

Affected sources: `scripts/presentation/inventory_view.gd`, `scripts/player/player_interaction_mode.gd`, twelve catalog item Resources, `assets/ui/items/`, `tests/inventory_ui_test.gd`, README and the Stage Z report. Existing accepted runtime integrations and source pins are unchanged.

## Validation

The [separate refinement evidence](../baselines/stage_z_inventory_usability/README.md) preserves logs, screenshots, probes and source hashes without replacing the original Stage Z delivery.

- Godot 4.7.2 editor import/parsing: passed; no script/import errors.
- All 47 automated regression suites: passed. Thirty-seven suite processes retained the known shutdown audio warning; verbose leaked types are exclusively AudioStreamWAV / AudioStreamPlaybackWAV. No new non-audio leak type or assertion failure appeared.
- Extended UI tests: actual keyboard and mouse events verify durable transfers, direct stored-weapon equipping, quantity-field isolation, source access and the distinction between human-only equipment and robot cargo. Existing simulation/death/spectator/conservation checks pass.
- Bounded native Forward+ smoke: deployment, source recovery, Recall, restart and post-death checks pass.
- Separate native populated-loadout fixture: rifle labels/disabled Equip, atomic blaster replacement, deployment and conservation pass; no errors or warnings.
- Visual inspection: populated equipment, storage, searched loot and cargo are readable at both captured resolutions.

Development used randomized ignored saves exclusively. The actual player stash was not read or modified. Automated smoke checks and screenshot inspection do not constitute director gameplay acceptance.

## Director review

Open preparation with I. Store and re-equip a blaster using the mouse and shortcuts; verify rifles remain transferable cargo with a clear restriction. Search a cache, take fitting loot, equip recovered compatible gear and test dropping cargo during a deployment. Enter a quantity without triggering transfer shortcuts. Confirm the controls are comfortable at your usual window size.

Future scope: disassembly, resource-consuming robot/weapon upgrades and richer equipment effects require a subsequent approved stage. This delivery adds no commit, publication or stage advancement.
