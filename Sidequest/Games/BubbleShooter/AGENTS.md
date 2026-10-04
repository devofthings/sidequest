# Bubble shooter

Issue #8 owns one original, bounded challenge. Keep its rules/normalized geometry independent of SwiftUI and rendering frameworks. Presentation consumes the merged #3 retained `GameRuntime`; issue #8 owns its compatible completed-visible replay extension, while the lead coordinates app composition. Never start or fire from visibility/appearance or the tap-to-play action.

## Implementation question record

The implementation agent used the project-local agent-grill as a self-assessment; the lead reviewed and approved these delegated technical choices within #8. These choices do not add scoring, a campaign, purchases, assets, or scheduling.

| Question | Kind | Decision and rationale | Verification needed |
| --- | --- | --- | --- |
| How can collisions avoid tunneling? | Delegated technical choice | Unit-radius bubbles in a normalized width-10 board; continuous ray/swept-circle first contact, with side-wall reflection. Snap only into a valid empty front-facing hex neighbor or ceiling slot. This avoids frame-dependent collision detection and overlapping placement. | First-contact/edge/wall/ceiling, nonoverlap, valid bounds and nearest reachable slot tests. |
| What makes the challenge short and attainable? | Delegated technical choice | Nine fixed bubbles in two staggered rows; red/blue/green shots repeat deterministically. Win by clearing all bubbles; lose after eight shots, a dangerous bottom-row attachment, or no valid attachment. Three actual aimed shots must prove the win route before handoff. | Reproducible actual aimed win and legal loss sequences; no fictional success claim. |
| How are detached bubbles handled? | Delegated technical choice | Clear connected groups of at least three; after a clear, also remove every bubble without a path to the ceiling row. | Same-color/anchoring/detached tests. |
| How can delayed shots avoid stale attempts? | Fact and delegated technical choice | Rules return an immutable shot plan tied to the current board revision; commit rejects old plans. Presentation owns a cancellable shot task, checks the runtime token after suspension, and resets on lifecycle effects. Completed-visible replay gets a fresh shared lifecycle/token under #8. | Revision rejection and later adapter reset-during-shot/replay tests; no UI work before feed interfaces merge. |

Angles are radians measured from vertical: negative aims left, positive right. The supported continuous range is ±π/3. Geometry and shot sequences are deterministic; do not use Swift's process-randomized hash as board identity. Rules revision and exact generated plans protect delayed commits; runtime attempt identity remains the presentation boundary.

## Presentation ownership

`BubbleShooterController(runtime:game:pause:)` retains rules and one private cancellable shot task. `fire() -> Bool` acknowledges accepted input without exposing task handles. Its injected main-actor pause is the replaceable animation timing boundary; after every pause check cancellation and the same runtime attempt before changing flight or committing a shot. Reset/stop cancel work first. Reset restores board, aim, flight, and feedback; stop retains win/loss rules and feedback. The start action initializes a challenge without firing.

`BubbleShooterView` uses a continuous -60...60 degree slider, an explicit Fire button, and original circles labeled R/B/G beyond color. Gameplay is plain content inside the native pager's owned `feed.cardScroll`; full-card paging and compact menu navigation follow [feed guidance](../../Feed/AGENTS.md). Preserve the single content scroller and actual horizontal aim input. Completed win/loss offers Replay through the same retained runtime; ordinary revisits retain completion. No scores or campaign are introduced.

Replay replaces the runtime's private lifecycle value only for a visible completed card. Deliver reset with the old token ineligible and phase preview before starting a fresh token. Reject a duplicate injected identity rather than accepting stale callbacks. A reset that hides the card cannot start it. Controllers never own a second lifecycle; root coordinates the common composition and running-app wiring.

Running-app tests use root-owned Debug composition arguments `-sidequest-bubble-fixtures` (bubble first, then another card) and `-sidequest-bubble-slow-shot` (longer injected shot pauses only for cancellation observation). They must not affect Release or normal gameplay timing. The game agent owns BubbleFlowTests; root owns central wiring. The retained app wiring is implemented in the game branch; actual running-app results belong in BUBBLES.md and the PR.

Honor the system `accessibilityReduceMotion` value: keep the pending bubble stationary at the launcher rather than showing interpolated flight positions. Collision physics, bounded timing, cancellation, and final attachment remain identical. Do not override the system preference in production. The Aim slider keeps native range accessibility semantics; a separate labeled angle provides degrees, avoiding a custom value that interferes with normalized assistive/automation adjustment.

The lead delegated central Bubble composition wiring to the game agent in the isolated #8 branch after Sudoku established `ComposedGame`; preserve other adapters when rebasing onto their merged work. Fire and Replay use the native large control size, with running-app checks requiring their actual accessibility frames to measure at least 44 by 44 points. A layout wrapper alone does not establish that touch target.

The system Reduce Motion running-app test changes only its destination simulator through native Settings, checks the observed switch value, and restores the original value in deferred cleanup. Relaunch Settings and query its current foreground hierarchy before restoring; stale coordinates after switching apps can miss. Keep temporary repair probes, original-fixture screenshots, and result bundles outside delivery claims and Git.

## Native pager adaptation

The implementation agent reassessed #8 after merged #87: use shared UI menu-navigation and system Reduce Motion helpers, reveal controls fully within the owned inner scroller, and verify native horizontal/diagonal Slider drags change the angle without advancing or firing. Normalized slider automation alone does not establish gesture arbitration. Short board drags preserve an attempt; committed direct skips reset pending shots before reverse navigation restores the preview. The complete 26-test focused run on the rebased native pager passed; see [verification](../../../docs/BUBBLES.md#verification) for actual results and remaining final-base review/CI gates. DEBUG slow-flight pauses are 250ms per frame (six seconds total), permitting actual native paging and stationary-board inspection; Release keeps 20ms pauses. The actual 44-point frame checks use the pager suite’s 0.001-point floating-point tolerance.

## Generated challenges #104

`BubbleChallengeGenerator` bounds candidate preparation to 16 small ceiling-connected shapes and 121 real-physics angle probes per shape. Accept only a replayed winning witness within the existing eight-shot bound, otherwise try a small varied fallback with the same bound; failure remains explicit. Freeze geometry/colors/shot sequence per card. Skip/reset and Replay restore that configuration. Completed win/loss archives include game, aim, feedback, and lifecycle identity. Rehydration binds one fresh inactive runtime; old owners retire permanently. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Stable feedback and Replay #108

Reserve supported feedback, next-color, angle, and Fire/Replay text using the shared measured region. Use monospaced digits plus the bounded slot count for numeric feedback widths. On completion, replace the actual aiming subtree with a hidden, inaccessible, disabled reservation; opacity alone leaves native Slider accessibility alive. Keep Replay in Fire's measured position and fully readable outcome/feedback. Read [stable layout](../../../docs/GAME_LAYOUT.md) before changing these regions.
