# Bubble-shooter challenge

Issue #8 implements one original compact challenge: nine ceiling-connected bubbles, deterministic red/blue/green shot colors, and at most eight shots. Aim continuously within 60 degrees left/right of vertical. Clear connected groups of at least three matching bubbles; after a match, bubbles without a path to the ceiling also drop. Clear the board to win. Reaching the danger row, exhausting shots with bubbles remaining, or finding no valid attachment ends the attempt in a loss.

Pure rules and geometry live in `Sidequest/Games/BubbleShooter/Rules`. A unit-radius staggered grid uses continuous swept-circle first contact, reflected side walls, and valid empty front-facing neighbors. Board revision rejects stale shot plans; shared lifecycle tokens will guard asynchronous presentation commits. Normalized geometry is independent of pixel size, animation cadence, and SwiftUI.

The actual rules probe reproduces a three-shot win at 0°, 0°, then 6° right, and a loss after seven shots aimed straight upward. These are verification routes, not automatic play. Connected colors, detachments, edge/ceiling/wall contacts, bounded loss, nonoverlap, invalid input, and stale plans have deterministic unit coverage.

Presentation and running-app tap-to-play/aim/fire/skip/replay verification remain pending until the feed runtime is merged. Root owns shared replay and app composition; game-local presentation will use the same owned state and lifecycle. No game UI or physical-device success is claimed by the rules layer alone. See [scoped guidance](../Sidequest/Games/BubbleShooter/AGENTS.md) and [shared contract](CONTRACT.md).
