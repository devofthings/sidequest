# Retained game runtime

Follow [common game guidance](../AGENTS.md) and [feed contract](../../../docs/FEED.md). `GameRuntime` remains the sole lifecycle owner for each stable card. Issue #8 owns the compatible bubble-shooter replay extension; other start/visibility/completion behavior is unchanged.

Replay requires visible completion and a distinct new attempt. Replace the private lifecycle value, retain visibility, deliver reset synchronously while preview, then start through the core visibility gate. This ordering blocks old callbacks before canceling/resetting adapters and does not consume a shot. If reset hides the card, no start occurs. Reject duplicate injected identities without mutating completion. Keep caller-specific board/outcome state outside this runtime.
