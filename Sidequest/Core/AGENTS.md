# Shared pure Swift core

Shared `CardID`, `FeedCard`, `GameKind`, and `GameLifecycle` belong here. Import no UI, networking-client, or storage SDK. Core remains nonisolated under [application settings](../AGENTS.md).

Use the [card contract](../../docs/CONTRACT.md) for exact transitions and effect ordering. IDs are explicit immutable source identities; do not derive them from display order. Attempt IDs distinguish retries, and every move, tick, or delayed result must pass the lifecycle gate immediately before mutation. Invalidate an attempt before canceling/resetting its adapter. Completed cards remain completed when revisited. Explicit bubble-shooter replay belongs to #8 and creates a fresh lifecycle/attempt; persistence is deferred.

These choices were resolved through the agent-grill interview for #2. Pure value transitions and returned effects separate game rules from UI/task ownership without an unused protocol or dependency-injection framework. Feature-specific rules belong to their owning game folders.

## Endless challenge identity

`ChallengeRandom` owns reproducible SplitMix64 value state for local generation; production seeds each session from system randomness. `GameLifecycle(completed:)` restores only trusted archived completion with visibility false; external input never constructs completed state. [ENDLESS.md](../../docs/ENDLESS.md) owns generated identities and retention.

## Demo news and cadence #106

Distinguish immutable story identity from feed appearance identity. A repeated news appearance has its own CardID and retains its unchanged NewsSnapshot. Pure cadence owns game count, news cursor and ordinal; presentation and persistence stay outside it. Finite historical routes can default appearance IDs to snapshot IDs. See [demo news policy](../../docs/DEMO_NEWS.md).
