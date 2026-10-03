# Bubble-shooter challenge

Issue #8 implements one original compact challenge: nine ceiling-connected bubbles, deterministic red/blue/green shot colors, and at most eight shots. Aim continuously within 60 degrees left/right of vertical. Clear connected groups of at least three matching bubbles; after a match, bubbles without a path to the ceiling also drop. Clear the board to win. Reaching the danger row, exhausting shots with bubbles remaining, or finding no valid attachment ends the attempt in a loss.

Pure rules and geometry live in `Sidequest/Games/BubbleShooter/Rules`. A unit-radius staggered grid uses continuous swept-circle first contact, reflected side walls, and valid empty front-facing neighbors. Board revision rejects stale shot plans; shared lifecycle tokens guard asynchronous presentation commits. Normalized geometry is independent of pixel size, animation cadence, and SwiftUI.

The actual rules probe reproduces a three-shot win at 0°, 0°, then 6° right, and a loss after seven shots aimed straight upward. These are verification routes, not automatic play. Connected colors, detachments, edge/ceiling/wall contacts, bounded loss, nonoverlap, invalid input, and stale plans have deterministic unit coverage.

Presentation uses a retained main-actor controller with a private cancellable shot task and injected pause. Every frame and final commit checks cancellation and current attempt eligibility. The continuous Aim slider sets degrees left/right of vertical; Fire starts one animated shot. R/B/G letters distinguish bubbles beyond color. A winning or losing attempt retains its result on revisit; Replay resets the same runtime owner before starting a fresh attempt without a shot.

Controller and runtime tests cover actual animated win/loss, single-flight input lock, noncooperative old callbacks during a fresh flight, error recovery, ordered replay effects, distinct identity, and hidden/repeated replay rejection. App composition retains the controller and uses the actual card during normal/Release launch; generic feed tests retain their independent demos. Debug bubble fixtures select the game first and adjacent fictional news; a slow-shot flag permits cancellation checks. Running-app verification is recorded below. Physical-device execution is unverified. See [scoped guidance](../Sidequest/Games/BubbleShooter/AGENTS.md) and [shared contract](CONTRACT.md).


## Accessibility and motion

Aim uses the native slider range and a separately labeled angle in degrees. R/B/G letters and dark fills make colors distinguishable. The board provides a VoiceOver summary with ordered row/position/color values; Fire and Replay are explicit controls, and the card can scroll independently of feed navigation. Under system Reduce Motion, the in-flight bubble stays at the launcher until committing its attachment; rules, timing, cancellation, and outcomes do not change.

## Verification

On Xcode 27.0/iOS 27.0, all 19 focused checks passed: 11 pure-rule, five controller, and three shared-runtime replay tests. Actual running-app checks pass largest text, seven-shot loss/replay, skipping during an active slow flight, and three-shot win/revisit/replay. The exact pure-rule winning route is 0°, 0°, 6°; running-app automation verifies an actual third aim within the broader tested 6°–30° winning window because normalized slider commands do not set exact angles. The slider maps a native 0–1 range to degrees, with separate degree feedback. A system Reduce Motion test reaches the real simulator Settings switch, compares two pending-board screenshots, commits one shot, and restores the original setting. Final combined verification is pending. No physical-device or published game build is claimed before its reviewed merge.
