# Common game adapter contract

Each game owns pure rules and its presentation adapter under [STRUCTURE.md](../../docs/STRUCTURE.md). Consume [GameLifecycle](../../docs/CONTRACT.md) without adding game-specific behavior to the feed or shared core.

The feed selects visibility; appearance cannot start a game. Apply lifecycle effects after the value transition: start initializes an attempt without making a move; reset first cancels pending work, then resets rules/selection/feedback; stop cancels work while preserving the completed result. Check the current attempt and visibility before every input, timer tick, and delayed mutation, including after suspension. Cancellation alone cannot prevent stale results. Returning to an unfinished skipped card requires a new start; completed cards retain completion.

Task ownership and concrete UI composition remain with the adapters and #3/#9. No shared timer, scoring, persistence, or replay requirement is introduced.
