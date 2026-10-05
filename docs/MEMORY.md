# Play memory pairs

Current production Memory has six distinct symbols, each appearing twice on a shuffled twelve-card board. Flip cards to find all six pairs. The board uses three columns normally and two at accessibility text sizes; scroll inside the game surface to reach every card. Symbols have different shapes and spoken names rather than relying on color.

## Controls and feedback

1. Navigate to Memory and choose **Tap to play**. Starting initializes the card's frozen board without flipping a card.
2. Tap one hidden card, then another. Tapping the same revealed card again changes nothing. Hidden accessibility labels disclose the card's position, not its symbol.
3. Matching pairs stay revealed. Unmatched pairs turn back over after 700 ms; extra input is ignored while that mismatch is being resolved. Already matched cards cannot be flipped again.
4. Find every pair to see **All pairs found!**. Completion stays on the card, without advancing the feed. Leaving and returning retains the completed board.

The inactive preview shows the actual frozen board face down before starting. Skipping or backgrounding an unfinished attempt cancels pending work and clears playable progress while immediately displaying that initial board. Returning shows the preview and requires another explicit start with the same frozen layout. Production generates and freezes each layout before publishing its card, so reset does not reshuffle. Late callbacks from an old attempt cannot change the new attempt. No scores, timers beyond mismatch presentation, persistence, replay, or additional modes are added.

## Ownership and deterministic checks

Pure `MemoryRules` owns pair validation, flip state, matches, and completion. The retained `MemoryController(runtime:makeBoard:delay:)` owns its delayed work and consumes the composition-provided `GameRuntime`; it never creates another lifecycle. Randomness and delay are injectable. Production retains concrete controllers only for previous/current/next cards; eviction archives completed rules and permanently retires the old runtime. A completed revisit restores those rules in a fresh inactive owner. See [ENDLESS.md](ENDLESS.md) for this ownership policy, plus [Memory guidance](../Sidequest/Games/Memory/AGENTS.md), [FEED.md](FEED.md), and [INSTALL.md](INSTALL.md).

The DEBUG-only `-sidequest-memory-fixtures` route places Memory before one news card, uses adjacent original pairs in symbol order, and delays mismatches for two seconds so running-app checks can inspect them before skipping. Finite Debug composition retains its original fixtures and controllers; #88 freezes its board factory once during initialization too. Production uses a shuffled layout frozen per card and the 700 ms delay. `-sidequest-large-text` selects the largest accessibility text size for checks. Release ignores these test routes. The generic `-sidequest-feed-test` harness still uses demos independently of actual game rules.

## Verification

Ten targeted simulator unit tests passed: five pure-rule tests and five retained-controller tests. They cover deterministic pairs/shuffling, invalid boards, repeated/matched/out-of-range input, mismatch input locking, all-pairs completion, start without a flip, skip/reset, completed revisit, and an old noncooperative callback resuming during a newer mismatch. A controlled unexpected delay failure also verifies recovery without permanently locking input. These tests use explicit continuations rather than gameplay sleeps.

Three running-app flows passed for matching/completion retention, mismatch/skip-reset, and largest-text tile/navigation reachability. The checks reached and matched all twelve tiles at the largest text size without changing global simulator settings. Normal and largest-text fixture screenshots are retained outside Git for visual inspection. The owning issue and live PR checks record full-suite/Release verification and the independent merge gates; focused results here do not certify those gates. Physical-iPhone/iOS 17 runtime execution remains unverified. The first UI invocation stalled after its runner exited and was interrupted with diagnostics preserved; the complete retry passed.

## Configurable workload foundation #178

Approved #178 adds validated three/four/six-pair configurations, classified Easy/Medium/Hard as an objective workload proxy rather than a demonstrated human difficulty rating. The default production board and six-pair fixtures remain compatible. Mixed labeled feed integration is separate; this foundation does not expose a difficulty selector or new production distribution.

A frozen `MemoryChallenge` carries seed, workload, and original shuffled layout. Its opt-in controller initializer preserves that configuration through start/reset and accepts only completed results with the identical layout for restoration. Instructions and progress use each board's actual pair count. The source includes deterministic seed sweeps, invalid arrangements, exact legacy shuffle/random-consumption checks, and all-workload reset/completion/restoration tests. Native/CI execution remains root-owned and pending until the PR records actual results.
