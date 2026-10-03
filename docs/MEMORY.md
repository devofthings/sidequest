# Play memory pairs

Memory has six distinct symbols, each appearing twice on a shuffled twelve-card board. Flip cards to find all six pairs. The board uses three columns normally and two at accessibility text sizes; scroll inside the game surface to reach every card. Symbols have different shapes and spoken names rather than relying on color.

## Controls and feedback

1. Navigate to Memory and choose **Tap to play**. Starting creates a board without flipping a card.
2. Tap one hidden card, then another. Tapping the same revealed card again changes nothing. Hidden accessibility labels disclose the card's position, not its symbol.
3. Matching pairs stay revealed. Unmatched pairs turn back over after 700 ms; extra input is ignored while that mismatch is being resolved. Already matched cards cannot be flipped again.
4. Find every pair to see **All pairs found!**. Completion stays on the card, without advancing the feed. Leaving and returning retains the completed board.

Skipping or backgrounding an unfinished attempt cancels pending work and clears its board. Returning shows the preview and requires another explicit start, creating a fresh shuffle. Late callbacks from an old attempt cannot change the new attempt. No scores, timers beyond mismatch presentation, persistence, replay, or additional modes are added.

## Ownership and deterministic checks

Pure `MemoryRules` owns pair validation, flip state, matches, and completion. The retained `MemoryController(runtime:makeBoard:delay:)` owns its delayed work and consumes the composition-provided `GameRuntime`; it never creates another lifecycle. Randomness and delay are injectable. See [Memory guidance](../Sidequest/Games/Memory/AGENTS.md), [FEED.md](FEED.md), and [INSTALL.md](INSTALL.md).

The DEBUG-only `-sidequest-memory-fixtures` route places Memory before one news card, uses adjacent original pairs in symbol order, and delays mismatches for two seconds so running-app checks can inspect them before skipping. Production retains shuffled boards and the 700 ms delay. `-sidequest-large-text` selects the largest accessibility text size for checks. Release ignores these test routes. The generic `-sidequest-feed-test` harness still uses demos independently of actual game rules.

## Verification

Ten targeted simulator unit tests passed: five pure-rule tests and five retained-controller tests. They cover deterministic pairs/shuffling, invalid boards, repeated/matched/out-of-range input, mismatch input locking, all-pairs completion, start without a flip, skip/reset, completed revisit, and an old noncooperative callback resuming during a newer mismatch. A controlled unexpected delay failure also verifies recovery without permanently locking input. These tests use explicit continuations rather than gameplay sleeps.

Three running-app flows passed for matching/completion retention, mismatch/skip-reset, and largest-text tile/navigation reachability. The checks reached and matched all twelve tiles at the largest text size without changing global simulator settings. Normal and largest-text fixture screenshots are retained outside Git for visual inspection. Final full-suite/current CI/Release verification and physical-iPhone/iOS 17 runtime execution are not yet claimed. The first UI invocation stalled after its runner exited and was interrupted with diagnostics preserved; the complete retry passed.
