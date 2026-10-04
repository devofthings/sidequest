# Memory pairs

Issue #6 owns this short, six-pair challenge. Keep `Rules` independent of UI and time; its presentation adapter consumes the retained `GameRuntime` established by #3. Composition owns one controller per card ID and binds its runtime once. No scores, persistence, replay, or additional game modes belong to this issue.

## Implementation question review

The implementation agent answered the project-local agent-grill questions; the lead coordinates shared runtime/composition ownership. The following delegated technical choices implement the accepted issue; verification distinguishes executed checks from pending app integration.

| Question | Kind | Answer and rationale | Evidence | Verification |
| --- | --- | --- | --- | --- |
| Which board stays short and readable? | Delegated technical choice | Six distinct symbols, each exactly twice; three columns normally and two at accessibility text sizes. Symbols have shape and spoken names, beyond color. | Issue #6 requires a fixed readable board and distinguishable pairs; CODING.md requires Dynamic Type and accessible labels. | Controlled shuffle/pair-count rule tests passed; normal/largest-text interaction tests passed with original fixture screenshots retained outside Git. |
| How do flips and mismatch resolution behave? | Delegated technical choice | Pure value rules model choosing, unresolved mismatch, and completion. Ignore repeated, matched, out-of-bounds, or mismatch-pending input. Reveal a mismatch for 700 ms through an injected async delay, then conceal it. | Issue #6 matching/delay/input criteria. | Double taps, locked mismatch, all-pairs completion, and controlled delay without real sleeps passed. |
| Who owns an attempt and delayed work? | Fact and delegated technical choice | The single shared runtime owns lifecycle. `MemoryController` binds one weak effect handler, freezes initial display rules during composition and initializes playable rules only on explicit start, owns/cancels its delay task, and checks cancellation plus current attempt/visibility after suspension. Reset clears rules; completion retains them. | Shared lifecycle and common game guidance require invalidation before reset and post-suspension eligibility checks. | Skip/reset while pending, canceled old callbacks during a new mismatch, pre-start input, completed revisit, and unexpected delay failure passed. Actual feed start/skip and completed-revisit running-app checks passed. |

Tests mirror this area under `SidequestTests/Games/Memory`; deterministic UI tests use only the composition root's DEBUG fixture route. Keep those fixtures original and separate from real content. The lead explicitly delegated the bounded App composition wiring to this implementation agent in the isolated Memory branch after Sudoku's shared composition change; no shared feed or lifecycle interface is edited.

## Controller and presentation interface

`MemoryController(runtime:makeBoard:delay:)` retains the composition-provided runtime and installs exactly one weak effect handler. Its injected board factory returns a validated `MemoryRules` value; the default freezes one shuffled board with `SystemRandomNumberGenerator` during controller initialization. A fixed original board with adjacent pairs supports running-app fixtures without changing production randomness. The controller exposes read-only optional `rules` and `flip(_:)`; `displayedRules` supplies the frozen face-down board while playable `rules` stays nil in preview/reset; start copies the frozen value without flipping, and stop preserves completion. Composition's DEBUG fixture delay is two seconds for running-app inspection; normal/Release retains the 700 ms default.

The injected delay is an explicitly main-actor, Sendable async closure. It only suspends; the default uses `Task.sleep` for 700 ms without blocking the UI actor. Reset/stop/teardown cancel the controller-owned task. After any delay outcome, check task cancellation and this runtime's attempt/visibility eligibility before concealing a mismatch. If a non-cancellation delay failure occurs while the attempt remains eligible, conceal the mismatch immediately so input cannot stay permanently locked. No attempt identity or lifecycle is copied into mutable controller state.

`MemoryGameView(controller:)` renders the retained board inside the feed's existing scroll surface. Three columns become two at accessibility text sizes. Shaped symbols and spoken names distinguish pairs without color; hidden tile labels do not disclose their symbol. Matching pairs remain visible, mismatch input is disabled, and completion stays in the card. Composition is wired and normal/largest-text interaction checks passed; original fixture screenshots remain outside Git.

Controller tests use a test-owned, deliberately noncooperative main-actor continuation gate. They explicitly resume every delayed callback, including an old callback during a newer attempt's pending mismatch. Tests observe public rules/phase instead of exposing a private task handle or using gameplay sleeps.

Actual implementation check: Xcode 27.0/Swift 6.4 built the Debug app and passed five rule plus five controller tests on the existing ARM64 Sidequest Feed iPhone simulator, iOS 27.0. No failures, skips, or runtime warnings were reported. Three running-app Memory flows subsequently passed on that simulator, including matching, mismatch/skip-reset, completion revisit, and every tile/navigation control at the largest text size. The owning issue and live PR checks record full CI and independent merge gates; these focused checks do not certify those gates. Physical-device execution remains unverified. Retain actual result bundles and original fixture screenshots outside Git.

## Frozen generated layouts #104

Production generates each six-pair layout before publishing its card and injects that immutable `MemoryRules` value through the board factory. Skip/reset and a later new start reuse the same layout. Mismatch tasks remain controller-owned/cancellable. Completed rule values rehydrate in a fresh inactive controller after eviction. Issue #88 also freezes finite harness layouts during controller initialization. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Stable tile and feedback geometry #108

Reserve the natural footprint of all six symbols and the hidden question mark at the current font/text size, so revealing a differently shaped glyph cannot resize a tile or its grid row. Reserve mismatch/completion feedback separately. Read [stable layout](../../../docs/GAME_LAYOUT.md) before changing these regions; full feedback and all tiles remain reachable through the feed's owned scroller.

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../../docs/GAME_PREVIEWS.md).
