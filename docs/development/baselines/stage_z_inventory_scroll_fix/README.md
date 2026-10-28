# Stage Z inventory scroll correction

Validated 2026-10-26. Selection refreshed the storage list by destroying its ScrollContainer, resetting the offset. The container, item-list owner and caption now persist across refreshes; only item buttons are rebuilt. A new inventory session or different container/page explicitly resets the offset. Godot clamps retained offsets naturally if the list shrinks.

- Editor import/parsing: exit zero, no errors.
- Inventory UI regression: exit zero. Real mouse selection below the fold, actual F equip with ledger refresh, repeated refreshes, page changes and reopening are covered with a 31-item isolated stash fixture.
- Inventory lifecycle regression: exit zero; existing shutdown audio cleanup warning remains (8 resources in this run).
- Bounded native Forward+ run of the UI suite: exit zero, all assertions pass, no errors/warnings.

Logs and exact source hashes are preserved here. Only randomized ignored test saves were used. Full 47-suite validation from the usability delivery remains historical; this localized follow-up reran the two affected inventory suites and the UI suite graphically. Director play-testing remains separate.
