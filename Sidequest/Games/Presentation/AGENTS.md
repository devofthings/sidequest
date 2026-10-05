# Retained game runtime

Follow [common game guidance](../AGENTS.md) and [feed contract](../../../docs/FEED.md). `GameRuntime` remains the sole lifecycle owner for each stable card. Issue #8 owns the compatible bubble-shooter replay extension; other start/visibility/completion behavior is unchanged.

Replay requires visible completion and a distinct new attempt. Replace the private lifecycle value, retain visibility, deliver reset synchronously while preview, then start through the core visibility gate. This ordering blocks old callbacks before canceling/resetting adapters and does not consume a shot. If reset hides the card, no start occurs. Reject duplicate injected identities without mutating completion. Keep caller-specific board/outcome state outside this runtime.

## Eviction and completed restoration

`GameRuntime.retire()` permanently rejects visibility, start, replay, and input. Composition retires evicted owners before releasing them. Rehydration creates a new invisible runtime initialized from trusted completed attempt identity and binds its effect handler exactly once. Preserve game-owned completed values; never rebind an obsolete runtime. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Successful attempt feedback #86

`GameRuntime.complete(attempt:successful:)` defaults to silent terminal completion. Controllers explicitly mark real success; Bubble loss remains silent. After the core accepts the current visible attempt and synchronous stop effects finish, recheck visibility/retirement/completed identity, then request the injected main-actor success haptic exactly once. Duplicate/stale completion cannot emit feedback. Restored completed runtimes begin quietly, and feedback state is never archived.

The runtime owns an optional celebration identity and cancellable 1.5-second presentation task with an injected main-actor delay. Every visibility loss, retirement, and successful replay reset clears presentation directly, including completed cards whose core visibility change emits no lifecycle effect. After suspension, check cancellation, visible completed identity, and celebration identity before clearing; old callbacks cannot clear a later attempt. Delay failure clears only an eligible decoration. No task changes game rules or navigation.

`SuccessHaptic` uses Apple's standard `UINotificationFeedbackGenerator` success pattern, letting hardware/system availability govern output. `SuccessCelebrationView` renders readable checkmark/text feedback in the existing start reservation, with a contained 180 ms scale/opacity transition and immediate Reduce Motion changes. It cannot take input or cover a board. Physical vibration remains unverified until actual iPhone testing; source/unit/simulator results cannot certify it.

Agent-grill decision record: The shared retained runtime is the fact-backed lifecycle boundary (GameLifecycle accepts only current visible input; Bubble distinguishes won/lost). Injected synchronous haptic and asynchronous decoration expiry are bounded replaceable presentation dependencies. Direct cancellation on completed-card hide is required because the core returns no effect there. Primary sources: [Apple notification feedback](https://developer.apple.com/documentation/uikit/uinotificationfeedbackgenerator) and [haptic guidance](https://developer.apple.com/design/human-interface-guidelines/playing-haptics). Planned verification: current/failed/stale/revisit/restored/replay/delay behavior through unit tests, actual four-game success/loss/system Reduce Motion/navigation through focused native tests, and separate device vibration acceptance. No human-owned feature or spending choice is introduced.
