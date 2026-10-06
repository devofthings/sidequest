# Native pager adapter

This folder owns UIKit gesture, viewport, and hosting behavior for approved issue #87. Feed rules and eligibility remain in `FeedController`; game rules remain in their game folders. Follow [feed guidance](../AGENTS.md) and [the pager contract](../../../docs/FEED.md#navigation-and-eligibility) before changing native recognition or completion callbacks.

Use public UIKit APIs on iOS 17. Keep at most three adjacent pages, commit only settled native offsets, and stop/dismantle obsolete hosts. Forward the selected card's eligibility to hosted input and accessibility. The owned inner scroller consumes in-range content gestures; the pager handles outward-edge gestures. Maintain the one-way recognizer failure dependency rather than replacing UIKit delegates or allowing both vertical pans simultaneously. Validate motion and overflow with real simulator gestures; a final index alone cannot certify continuous paging.

Requests carry their originating controller identity as well as a unique action ID. A fresh active pager rejects requests from a retired/replaced session even when both decks share card IDs. Test both rejection and legitimate new-session navigation at a real native viewport size.

## Appended windows

Compare adjacent-window membership as well as selected index on update. Rebuild/recenter only when native tracking, dragging, deceleration, and requested animation are idle; refresh after settlement. Appending cards cannot move selection or start/reset play. Keep hosted child ownership bounded to the adjacent window and verify removed hosting roots release game owners. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Palette hosting #123

Keep the pager and hosting root backgrounds transparent so the opaque SwiftUI semantic canvas is consistent through native page movement. Appearance, contrast, and Reduce Motion are explicitly forwarded by FeedView into each separate hosting root; UIKit retains gesture and content-scroll ownership.


## Dedicated game-control ownership #138

A narrow shared UI-only marker identifies direct game aiming controls. Both the outer pager and owned inner scroller decline their vertical pan when the originating hit is that control or its descendant, or a native Slider. Preserve the existing one-way failure relationship and ordinary outside-control paging/overflow. This adds no game-rule dependency and does not exempt all UIControl instances. Actual horizontal/vertical/diagonal control gestures must prove unchanged selected card and inner offset.

## Stable prepended hosts #216
Key hosted pages by immutable CardID, while native offsets retain the settled adjacent index window. Prepending must keep the selected hosting root and owned inner content offset; deferring insertion until idle alone does not preserve overflow. Reindexing cannot recreate a retained card, shift its reading position, start/reset an attempt or qualify participation.
