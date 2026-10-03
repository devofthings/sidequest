# Common game adapter contract

Each game owns pure rules and its presentation adapter under [STRUCTURE.md](../../docs/STRUCTURE.md). Consume [GameLifecycle](../../docs/CONTRACT.md) without adding game-specific behavior to the feed or shared core.

The feed selects visibility; appearance cannot start a game. Apply lifecycle effects after the value transition: start initializes an attempt without making a move; reset first cancels pending work, then resets rules/selection/feedback; stop cancels work while preserving the completed result. Check the current attempt and visibility before every input, timer tick, and delayed mutation, including after suspension. Cancellation alone cannot prevent stale results. Returning to an unfinished skipped card requires a new start; completed cards retain completion.

Task ownership and concrete UI composition remain with the adapters and #3/#9. No shared timer, scoring, persistence, or replay requirement is introduced.

Issue #3 establishes the concrete `@MainActor @Observable GameRuntime` in `Presentation`: it owns the single private `GameLifecycle` for a card and exposes phase/visibility, `setVisible`, `start`, `complete(attempt:)`, and `acceptsInput(from:)`. Bind one synchronous effect handler during composition with `installEffectHandler`; capture the owning controller weakly to avoid a cycle. Composition retains the controller and runtime by `CardID` across view recreation, so completed rules/results survive revisits. A missing or second handler is a programmer wiring error, not a recoverable content error.

Every transition finishes before its effect is delivered immediately to the retained controller, including when its view is offscreen. Reset cancels owned tasks before clearing state; stop cancels tasks while preserving the result. Controllers gate every input and delayed mutation through this same runtime. Never create a second lifecycle in a controller or use a view's disappearance as the sole reset/cancellation signal. Bubble-shooter replay remains explicitly owned by #8 and must coordinate a compatible runtime extension; no other replay action is introduced. See [FEED.md](../../docs/FEED.md).
