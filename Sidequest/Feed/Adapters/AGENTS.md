# Native pager adapter

This folder owns UIKit gesture, viewport, and hosting behavior for approved issue #87. Feed rules and eligibility remain in `FeedController`; game rules remain in their game folders. Follow [feed guidance](../AGENTS.md) and [the pager contract](../../../docs/FEED.md#navigation-and-eligibility) before changing native recognition or completion callbacks.

Use public UIKit APIs on iOS 17. Keep at most three adjacent pages, commit only settled native offsets, and stop/dismantle obsolete hosts. Forward the selected card's eligibility to hosted input and accessibility. The owned inner scroller consumes in-range content gestures; the pager handles outward-edge gestures. Maintain the one-way recognizer failure dependency rather than replacing UIKit delegates or allowing both vertical pans simultaneously. Validate motion and overflow with real simulator gestures; a final index alone cannot certify continuous paging.

Requests carry their originating controller identity as well as a unique action ID. A fresh active pager rejects requests from a retired/replaced session even when both decks share card IDs. Test both rejection and legitimate new-session navigation at a real native viewport size.

## Appended windows

Compare adjacent-window membership as well as selected index on update. Rebuild/recenter only when native tracking, dragging, deceleration, and requested animation are idle; refresh after settlement. Appending cards cannot move selection or start/reset play. Keep hosted child ownership bounded to the adjacent window and verify removed hosting roots release game owners. See [ENDLESS.md](../../../docs/ENDLESS.md).
