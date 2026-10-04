# Retained game runtime

Follow [common game guidance](../AGENTS.md) and [feed contract](../../../docs/FEED.md). `GameRuntime` remains the sole lifecycle owner for each stable card. Issue #8 owns the compatible bubble-shooter replay extension; other start/visibility/completion behavior is unchanged.

Replay requires visible completion and a distinct new attempt. Replace the private lifecycle value, retain visibility, deliver reset synchronously while preview, then start through the core visibility gate. This ordering blocks old callbacks before canceling/resetting adapters and does not consume a shot. If reset hides the card, no start occurs. Reject duplicate injected identities without mutating completion. Keep caller-specific board/outcome state outside this runtime.

## Eviction and completed restoration

`GameRuntime.retire()` permanently rejects visibility, start, replay, and input. Composition retires evicted owners before releasing them. Rehydration creates a new invisible runtime initialized from trusted completed attempt identity and binds its effect handler exactly once. Preserve game-owned completed values; never rebind an obsolete runtime. See [ENDLESS.md](../../../docs/ENDLESS.md).
