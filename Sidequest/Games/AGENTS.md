# Common game adapter contract

Each game owns pure rules and its presentation adapter under [STRUCTURE.md](../../docs/STRUCTURE.md). Consume [GameLifecycle](../../docs/CONTRACT.md) without adding game-specific behavior to the feed or shared core.

The feed selects visibility; appearance cannot start a game. Apply lifecycle effects after the value transition: start initializes an attempt without making a move; reset first cancels pending work, then resets rules/selection/feedback; stop cancels work while preserving the completed result. Check the current attempt and visibility before every input, timer tick, and delayed mutation, including after suspension. Cancellation alone cannot prevent stale results. Returning to an unfinished skipped card requires a new start; completed cards retain completion.

Task ownership and concrete UI composition remain with the adapters and #3/#9. No shared timer, scoring, persistence, or replay requirement is introduced.

Issue #3 establishes the concrete `@MainActor @Observable GameRuntime` in `Presentation`: it owns the single private `GameLifecycle` for a card and exposes phase/visibility, `setVisible`, `start`, `complete(attempt:)`, and `acceptsInput(from:)`. Bind one synchronous effect handler during composition with `installEffectHandler`; capture the owning controller weakly to avoid a cycle. Finite harnesses retain controllers by `CardID`. Production caches only adjacent adapters and archives completed rule values for later rehydration, as specified in [ENDLESS.md](../../docs/ENDLESS.md). A missing or second handler is a programmer wiring error, not a recoverable content error.

Every transition finishes before its effect is delivered immediately to the retained controller, including when its view is offscreen. Reset cancels owned tasks before clearing state; stop cancels tasks while preserving the result. Controllers gate every input and delayed mutation through this same runtime. Never create a second lifecycle in a controller or use a view's disappearance as the sole reset/cancellation signal. Bubble-shooter replay remains explicitly owned by #8 and must coordinate a compatible runtime extension; no other replay action is introduced. See [FEED.md](../../docs/FEED.md).


Issue #8 adds `GameRuntime.replay() -> Bool` solely for bubble-shooter completion. It accepts a visible completed card, replaces the same owner's private lifecycle, delivers `.reset(oldAttempt)` while preview, then `.start(freshAttempt)` if still visible. It rejects preview/playing/hidden or duplicate-identity attempts. Ordinary revisits retain completion; other games do not expose replay. See [bubble guidance](BubbleShooter/AGENTS.md).

## Endless feed #104

The user approved extending production beyond its finite deck on October 4, 2026. Before changing replenishment, generated challenges, adapter eviction, or completed-result restoration, read [ENDLESS.md](../../docs/ENDLESS.md). Keep challenge identity/configuration stable per card, preserve manual settled paging and explicit start/reset, and retain completed revisits using lightweight state. Issue #106 supersedes the initial news-once default with five-game/news cadence and nil-only demo resolution. Validated Chess reuse remains a stated implementation default, not an owner answer. Issue #104 is merged; its evidence is recorded in ENDLESS.md. Preserve the immutable finite-MVP release evidence.

## Stable presentation #108

Use the shared `StableGameRegion` for state-dependent text that could change board/control geometry. Reserve every supported message at its actual font, width, and Dynamic Type size; update reservations with copy/styling changes. Keep full visible feedback, hide reservations from accessibility/input, and retain game-owned completion control footprints. Playable feed roots anchor at the top; the pager retains overflow ownership. Follow [stable layout guidance](../../docs/GAME_LAYOUT.md) for the accepted choices, actual reproduction, and verification limits.
