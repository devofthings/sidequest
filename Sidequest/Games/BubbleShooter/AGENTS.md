# Bubble shooter

Issue #8 owns one original, bounded challenge. Keep its rules/normalized geometry independent of SwiftUI and rendering frameworks. Presentation will consume the shared lifecycle after feed #3 is merged; root owns shared runtime replay and app composition. Never start or fire from visibility/appearance or the tap-to-play action.

## Implementation question record

The implementation agent used the project-local agent-grill as a self-assessment; the lead reviewed and approved these delegated technical choices within #8. These choices do not add scoring, a campaign, purchases, assets, or scheduling.

| Question | Kind | Decision and rationale | Verification needed |
| --- | --- | --- | --- |
| How can collisions avoid tunneling? | Delegated technical choice | Unit-radius bubbles in a normalized width-10 board; continuous ray/swept-circle first contact, with side-wall reflection. Snap only into a valid empty front-facing hex neighbor or ceiling slot. This avoids frame-dependent collision detection and overlapping placement. | First-contact/edge/wall/ceiling, nonoverlap, valid bounds and nearest reachable slot tests. |
| What makes the challenge short and attainable? | Delegated technical choice | Nine fixed bubbles in two staggered rows; red/blue/green shots repeat deterministically. Win by clearing all bubbles; lose after eight shots, a dangerous bottom-row attachment, or no valid attachment. Three actual aimed shots must prove the win route before handoff. | Reproducible actual aimed win and legal loss sequences; no fictional success claim. |
| How are detached bubbles handled? | Delegated technical choice | Clear connected groups of at least three; after a clear, also remove every bubble without a path to the ceiling row. | Same-color/anchoring/detached tests. |
| How can delayed shots avoid stale attempts? | Fact and delegated technical choice | Rules return an immutable shot plan tied to the current board revision; commit rejects old plans. Presentation owns a cancellable shot task, checks the runtime token after suspension, and resets on lifecycle effects. Completed-visible replay gets a fresh shared lifecycle/token under #8. | Revision rejection and later adapter reset-during-shot/replay tests; no UI work before feed interfaces merge. |

Angles are radians measured from vertical: negative aims left, positive right. The supported continuous range is ±π/3. Geometry and shot sequences are deterministic; do not use Swift's process-randomized hash as board identity. Rules revision and exact generated plans protect delayed commits; runtime attempt identity remains the presentation boundary.
