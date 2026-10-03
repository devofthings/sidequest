# Memory pairs

Issue #6 owns this short, six-pair challenge. Keep `Rules` independent of UI and time; its presentation adapter consumes the retained `GameRuntime` established by #3. Composition owns one controller per card ID and binds its runtime once. No scores, persistence, replay, or additional game modes belong to this issue.

## Implementation question review

The implementation agent answered the project-local agent-grill questions; the lead coordinates shared runtime/composition ownership. The following delegated technical choices implement the accepted issue; verification distinguishes executed checks from pending app integration.

| Question | Kind | Answer and rationale | Evidence | Verification |
| --- | --- | --- | --- | --- |
| Which board stays short and readable? | Delegated technical choice | Six distinct symbols, each exactly twice; three columns normally and two at accessibility text sizes. Symbols have shape and spoken names, beyond color. | Issue #6 requires a fixed readable board and distinguishable pairs; CODING.md requires Dynamic Type and accessible labels. | Controlled shuffle/pair-count rule tests passed; normal/largest-text running-app inspection remains pending composition. |
| How do flips and mismatch resolution behave? | Delegated technical choice | Pure value rules model choosing, unresolved mismatch, and completion. Ignore repeated, matched, out-of-bounds, or mismatch-pending input. Reveal a mismatch for 700 ms through an injected async delay, then conceal it. | Issue #6 matching/delay/input criteria. | Double taps, locked mismatch, all-pairs completion, and controlled delay without real sleeps passed. |
| Who owns an attempt and delayed work? | Fact and delegated technical choice | The single shared runtime owns lifecycle. `MemoryController` binds one weak effect handler, creates rules only on explicit start, owns/cancels its delay task, and checks cancellation plus current attempt/visibility after suspension. Reset clears rules; completion retains them. | Shared lifecycle and common game guidance require invalidation before reset and post-suspension eligibility checks. | Skip/reset while pending, canceled old callbacks during a new mismatch, pre-start input, completed revisit, and unexpected delay failure passed. Actual feed start/skip remains pending composition. |

Tests mirror this area under `SidequestTests/Games/Memory`; deterministic UI tests use only the composition root's DEBUG fixture route. Keep those fixtures original and separate from real content. No shared feed, app, or lifecycle interfaces are edited by this feature.

## Controller and presentation interface

`MemoryController(runtime:makeBoard:delay:)` retains the composition-provided runtime and installs exactly one weak effect handler. Its injected board factory returns a validated `MemoryRules` value; the default creates a shuffled board with `SystemRandomNumberGenerator`. A fixed original board with adjacent pairs supports running-app fixtures without changing production randomness. The controller exposes read-only optional `rules` and `flip(_:)`; preview/reset has no board, start creates one without flipping, and stop preserves completion.

The injected delay is an explicitly main-actor, Sendable async closure. It only suspends; the default uses `Task.sleep` for 700 ms without blocking the UI actor. Reset/stop/teardown cancel the controller-owned task. After any delay outcome, check task cancellation and this runtime's attempt/visibility eligibility before concealing a mismatch. If a non-cancellation delay failure occurs while the attempt remains eligible, conceal the mismatch immediately so input cannot stay permanently locked. No attempt identity or lifecycle is copied into mutable controller state.

`MemoryGameView(controller:)` renders the retained board inside the feed's existing scroll surface. Three columns become two at accessibility text sizes. Shaped symbols and spoken names distinguish pairs without color; hidden tile labels do not disclose their symbol. Matching pairs remain visible, mismatch input is disabled, and completion stays in the card. Actual running-app usability checks remain planned until composition wiring is available.

Controller tests use a test-owned, deliberately noncooperative main-actor continuation gate. They explicitly resume every delayed callback, including an old callback during a newer attempt's pending mismatch. Tests observe public rules/phase instead of exposing a private task handle or using gameplay sleeps.

Actual implementation check: Xcode 27.0/Swift 6.4 built the Debug app and passed five rule plus five controller tests on the existing ARM64 Sidequest Feed iPhone simulator, iOS 27.0. No failures, skips, or runtime warnings were reported. Running-app Memory flows, visual usability, final full CI, and physical-device execution have not been verified at this handoff.
