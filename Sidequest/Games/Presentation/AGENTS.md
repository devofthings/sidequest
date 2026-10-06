# Retained game runtime

Follow [common game guidance](../AGENTS.md) and [feed contract](../../../docs/FEED.md). `GameRuntime` remains the sole lifecycle owner for each stable card. Issue #8 owns the compatible bubble-shooter replay extension; other start/visibility/completion behavior is unchanged.

Replay requires visible completion and a distinct new attempt. Replace the private lifecycle value, retain visibility, deliver reset synchronously while preview, then start through the core visibility gate. This ordering blocks old callbacks before canceling/resetting adapters and does not consume a shot. If reset hides the card, no start occurs. Reject duplicate injected identities without mutating completion. Keep caller-specific board/outcome state outside this runtime.

## Eviction and completed restoration

`GameRuntime.retire()` permanently rejects visibility, start, replay, and input. Composition retires evicted owners before releasing them. Rehydration creates a new invisible runtime initialized from trusted completed attempt identity and binds its effect handler exactly once. Preserve game-owned completed values; never rebind an obsolete runtime. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Successful attempt feedback #86

`GameRuntime.complete(attempt:successful:)` defaults to silent terminal completion. Controllers explicitly mark real success; Bubble loss remains silent. After the core accepts the current visible attempt and synchronous stop effects finish, recheck visibility/retirement/completed identity, then request the injected main-actor success haptic exactly once. Duplicate/stale completion cannot emit feedback. Restored completed runtimes begin quietly, and feedback state is never archived.

The runtime owns an optional celebration identity and cancellable 1.5-second presentation task with an injected main-actor delay. Every visibility loss, retirement, and successful replay reset clears presentation directly, including completed cards whose core visibility change emits no lifecycle effect. After suspension, check cancellation, visible completed identity, and celebration identity before clearing; old callbacks cannot clear a later attempt. Delay failure clears only an eligible decoration. No task changes game rules or navigation.

`SuccessHaptic` uses Apple's standard `UINotificationFeedbackGenerator` success pattern. Under owner-approved #193, `SuccessCelebrationView` is a larger lime badge with decorative sparkles centered over the fixed game viewport. A 280 ms spring introduces it; Reduce Motion removes sparkles and spatial transitions, using a 150 ms fade. Keep the existing 1.5-second runtime-owned lifetime and cancellation; no extra timer or gameplay state. The overlay passes input through and never contributes to header/board layout. The readable completion label remains accessible and the app title stays visible. Physical vibration remains separately unverified.

Agent-grill decision record: The shared retained runtime is the fact-backed lifecycle boundary (GameLifecycle accepts only current visible input; Bubble distinguishes won/lost). Injected synchronous haptic and asynchronous decoration expiry are bounded replaceable presentation dependencies. Direct cancellation on completed-card hide is required because the core returns no effect there. Primary sources: [Apple notification feedback](https://developer.apple.com/documentation/uikit/uinotificationfeedbackgenerator) and [haptic guidance](https://developer.apple.com/design/human-interface-guidelines/playing-haptics). Planned verification: current/failed/stale/revisit/restored/replay/delay behavior through unit tests, actual four-game success/loss/system Reduce Motion/navigation through focused native tests, and separate device vibration acceptance. No human-owned feature or spending choice is introduced.

Historical #86 correction moved an offscreen card-owned badge into the header. #193 supersedes that location with a viewport-owned center overlay, keeping it independent of the card scroller. Require viewport containment and center-position assertions, including scrolled Chess controls and Reduce Motion.

## Preview activation lease #160

A presentation-only `GameRuntime.visibilityIdentity` changes on real visibility transitions and retirement, never on redundant host updates. `PreviewStartRequest` captures it only for a visible preview and rechecks phase/visibility/identity before ordinary runtime start. This blocks a held tap after hide/reset/revisit without adding a second lifecycle. `GamePreviewSurface` is a transparent preview-content-only UIView with a single-touch tap recognizer that waits for ancestor native pans to fail; it never excludes feed pans. Starting/removal cancels its captured request. Accessible/keyboard activation uses the reserved semantic hint in feed composition. See [preview policy](../../../docs/GAME_PREVIEWS.md).

## Committed interaction feedback #161

Agent-grill self-assessment, approved by the lead: `feedbackForInteraction(attempt:)` accepts only the current visible playing attempt. Request one synchronous light impact through an injected UIKit adapter, with a monotonic 120 ms minimum interval per runtime. This interval is a restrained lead-selected burst limit, not an Apple-prescribed duration. Hide/background, replay reset, and retirement clear its cooldown; no effects are queued, archived, or replayed by restoration. Controllers request only meaningful nonfinal rule changes. Final actions use existing success feedback exclusively, avoiding a second haptic for the same outcome. Pure rules remain independent of platform effects.

[Apple impact feedback](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator) supports standard physical accents; [haptic guidance](https://developer.apple.com/design/human-interface-guidelines/playing-haptics) supports restrained feedback accompanying visible changes. Existing readable game feedback remains primary. Deterministic event/cooldown tests and six focused running-app/Reduce Motion checks passed before PR169 merged; see [delivered refinement evidence](../../../docs/INSTALL.md#verified-source-refinements-october-5). Physical iPhone vibration remains owner acceptance in #161/#86; simulator checks cannot establish it.

## First meaningful interaction #185

The owner selected first interaction starts and applies the same action, superseding #160's inert tap/hint for real games. Follow [the authoritative preview policy](../../../docs/GAME_PREVIEWS.md). Validate meaningful input before synchronous runtime preparation; capture visibility identity for held callbacks and preserve attempt/lease cancellation. No appearance/scroll activation, swallowed first action, real-fixture bypass or new lifecycle owner. Keep the static empty chrome reservation and native accessible controls. Actual native/CI proof remains pending in the owning PR.

## Accepted success participation observer #217

Composition may install exactly one separate successful-completion observer. Deliver it only after the existing accepted successful visible-completion gate and synchronous stop handler, independently of the single lifecycle effect binding. Loss, hidden/stale/duplicate completion and quiet completed restoration/revisit emit nothing. New reconstructed runtimes bind their own observer once; game rules retain no persistence dependency. See [streak guidance](../../Streak/AGENTS.md).

## Varied success #230

[The selected celebration decision](../../../docs/DECISIONS.md#varied-success-celebrations-230) supersedes the fixed Nice/lime treatment. Composition owns the ephemeral four-style cycle; select only after accepted visible success, never during rendering or restoration. Freeze style with the attempt and clear both together. Key one-shot decorative progress by attempt identity; Reduce Motion removes all particle travel/rotation. Keep the existing runtime lifetime, viewport center, pass-through input, stable game geometry and haptic gate. Do not archive styles or add a second timer/observer.
