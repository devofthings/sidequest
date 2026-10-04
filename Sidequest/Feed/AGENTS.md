# Feed ownership

`Domain` owns deck/session behavior; presentation consumes domain values and shared lifecycle effects. See [CONTRACT.md](../../docs/CONTRACT.md) and [source ownership](../../docs/STRUCTURE.md).

Finite historical routes build and store a shuffled deck once per deliberate session. Production shuffles only prepared games and interleaves the story pool under the cadence policy below. Rendering never reshuffles it. Reject duplicate card IDs rather than dropping content; multiple cards of the same game kind are valid when their IDs differ. Visibility means the host's selected card, not SwiftUI appearance. Feed presentation and background handling follow issue #3, not the contract's sample launch view.

Issue #87 supersedes the dedicated swipe rail. Full-card vertical paging is a UIKit adapter with native distance/velocity snapping and at most previous/current/next hosted SwiftUI pages. Commit selection only after native scrolling settles. Short/canceled drags keep the current attempt; neighboring pages remain rendered with input and accessibility disabled. Compact navigation-menu actions request a settled page through the same adapter. Finite Debug routes retain explicit bounds/end feedback; production uses endless replenishment and an accessible retry on generation failure.

Each hosted card has one owned vertical content scroller. Use unwrapped news content and plain game content. A drag beginning within available content range scrolls the card; a subsequent outward drag beginning at its top/bottom edge pages. Reaching an edge during a content drag keeps that gesture content-owned. Both recognizers reject horizontal drags; the parent defers when an owned slider starts tracking. Keep the one-way child-pan failure requirement and UIKit's internal gesture delegates. See [FEED.md](../../docs/FEED.md#navigation-and-eligibility) before changing arbitration or hosting.

`FeedController` owns selection, scene/host eligibility, and permanent session retirement, using retained `GameRuntime` references supplied by composition. Invalidate the previous card and deliver reset synchronously before enabling another card. An inactive/background scene makes every runtime invisible and resets unfinished attempts once; returning activates the selected preview without starting it. Completed results remain available; endless sessions archive pure values when an adapter leaves the adjacent window. Views render phase and send explicit actions; they never copy lifecycle values or own game rules/tasks.

`FeedView(controller:gameContent:newsContent:)` accepts main-actor render closures `(GameCard, GameRuntime) -> AnyView` and `(NewsSnapshot) -> AnyView`. Composition supplies runtimes for the adjacent game window before rendering it; finite harnesses retain every adapter. Rendering a closure cannot create a controller, reshape the deck, or mutate lifecycle. See [feed adapter contract](../../docs/FEED.md) for ownership, effect ordering, and downstream integration.

Forward public Dynamic Type, color scheme, locale, and layout-direction values into separate hosting roots. Reduce Motion comes from the system and makes requested navigation nonanimated; direct finger tracking remains native. Keep start, compact navigation, and overflowing card controls reachable at the largest text size. Preserve proper child-controller containment and stop the obsolete pager when its controller is replaced.

Bind every native navigation request to its originating controller identity. `FeedView` clears obsolete request state and applies the current scene phase when that identity changes, even if the outer view identity stays the same. Deliberate replacement owns retiring the previous controller; the fresh pager rejects old-session requests before moving.

Integration #9 adds an optional accessible 44-point News action to the existing header; its root coordinator owns the library modal and synchronously sets host availability before presentation. Keep the same outer FeedView identity during imported-news replacement. Apply current scene eligibility on controller identity change as #87 requires; the coordinator retires old sessions and supplies the fresh retained adapters. News/game/source actions do not request pages. Retain one owned content scroller per page and full control containment at largest text.

## Endless feed #104

The user approved extending production beyond its finite deck on October 4, 2026. Before changing replenishment, generated challenges, adapter eviction, or completed-result restoration, read [ENDLESS.md](../../docs/ENDLESS.md). Keep challenge identity/configuration stable per card, preserve manual settled paging and explicit start/reset, and retain completed revisits using lightweight state. Issue #106 supersedes the initial news-once default with five-game/news cadence and nil-only demo resolution. Validated Chess reuse remains a stated implementation default, not an owner answer. Issue #104 is merged; its evidence is recorded in ENDLESS.md. Preserve the immutable finite-MVP release evidence.

## Demo news and cadence #106

Interleave an available story pool after exactly five games, carrying cadence across batch boundaries and preserving history on revisits. Remove the bottom counter completely; native tests observe settled semantic card identity without hidden numeric state or raw-ID speech. Preserve native gesture and lifecycle boundaries. See [demo news policy](../../docs/DEMO_NEWS.md).

## Stable playable cards #108

Anchor playing/completed game content at the top of the viewport-sized host so changing text cannot re-center the game. Issue #88 makes previews top anchored with actual inactive game content and a measured start reservation. Preserve title/start semantics and the existing owned scroller/pager. Game adapters reserve their supported dynamic regions to preserve overflow extent; the feed does not inspect game states or fix text heights. See [stable layout](../../docs/GAME_LAYOUT.md).

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../docs/GAME_PREVIEWS.md).
