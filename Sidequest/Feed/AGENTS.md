# Feed ownership

`Domain` owns deck/session behavior; presentation consumes domain values and shared lifecycle effects. See [CONTRACT.md](../../docs/CONTRACT.md) and [source ownership](../../docs/STRUCTURE.md).

Finite historical routes build and store a shuffled deck once per deliberate session. Production shuffles only prepared games and interleaves the story pool under the cadence policy below. Rendering never reshuffles it. Reject duplicate card IDs rather than dropping content; multiple cards of the same game kind are valid when their IDs differ. Visibility means the host's selected card, not SwiftUI appearance. Feed presentation and background handling follow issue #3, not the contract's sample launch view.

Issue #87 supersedes the dedicated swipe rail. Full-card vertical paging is a UIKit adapter with native distance/velocity snapping and at most previous/current/next hosted SwiftUI pages. Commit selection only after native scrolling settles. Short/canceled drags keep the current attempt; neighboring pages remain rendered with input and accessibility disabled. Compact navigation-menu actions request a settled page through the same adapter. Finite Debug routes retain explicit bounds/end feedback; production uses endless replenishment and an accessible retry on generation failure.

Each hosted card has one owned vertical content scroller. Use unwrapped news content and plain game content. A drag beginning within available content range scrolls the card; a subsequent outward drag beginning at its top/bottom edge pages. Reaching an edge during a content drag keeps that gesture content-owned. Both recognizers reject horizontal drags; the parent defers when an owned slider starts tracking. Keep the one-way child-pan failure requirement and UIKit's internal gesture delegates. See [FEED.md](../../docs/FEED.md#navigation-and-eligibility) before changing arbitration or hosting.

`FeedController` owns selection, scene/host eligibility, and permanent session retirement, using retained `GameRuntime` references supplied by composition. Invalidate the previous card and deliver reset synchronously before enabling another card. An inactive/background scene makes every runtime invisible and resets unfinished attempts once; returning activates the selected preview without starting it. Completed results remain available; endless sessions archive pure values when an adapter leaves the adjacent window. Views render phase and send explicit actions; they never copy lifecycle values or own game rules/tasks.

`FeedView(controller:gameContent:newsContent:)` accepts main-actor render closures `(GameCard, GameRuntime) -> AnyView` and `(NewsSnapshot) -> AnyView`. Composition supplies runtimes for the adjacent game window before rendering it; finite harnesses retain every adapter. Rendering a closure cannot create a controller, reshape the deck, or mutate lifecycle. See [feed adapter contract](../../docs/FEED.md) for ownership, effect ordering, and downstream integration.

Forward public Dynamic Type, color scheme, locale, and layout-direction values into separate hosting roots. Reduce Motion comes from the system and makes requested navigation nonanimated; direct finger tracking remains native. Keep start, compact navigation, and overflowing card controls reachable at the largest text size. Preserve proper child-controller containment and stop the obsolete pager when its controller is replaced.

Bind every native navigation request to its originating controller identity. `FeedView` clears obsolete request state and applies the current scene phase when that identity changes, even if the outer view identity stays the same. Deliberate replacement owns retiring the previous controller; the fresh pager rejects old-session requests before moving.

Owner-approved #191 places the optional News snapshots action inside the existing 44-point More options menu, preserving `feed.news` as the menu action identifier and `feed.navigation` as the menu identifier; its root coordinator owns the library modal and synchronously sets host availability before presentation. Keep the same outer FeedView identity during imported-news replacement. Apply current scene eligibility on controller identity change as #87 requires; the coordinator retires old sessions and supplies the fresh retained adapters. News/game/source actions do not request pages. Retain one owned content scroller per page and full control containment at largest text.

## Endless feed #104

The user approved extending production beyond its finite deck on October 4, 2026. Before changing replenishment, generated challenges, adapter eviction, or completed-result restoration, read [ENDLESS.md](../../docs/ENDLESS.md). Keep challenge identity/configuration stable per card, preserve manual settled paging and explicit start/reset, and retain completed revisits using lightweight state. Issue #106 supersedes the initial news-once default with five-game/news cadence and nil-only demo resolution. Validated Chess reuse remains a stated implementation default, not an owner answer. Issue #104 is merged; its evidence is recorded in ENDLESS.md. Preserve the immutable finite-MVP release evidence.

## Demo news and cadence #106

Interleave an available story pool after exactly five games, carrying cadence across batch boundaries and preserving history on revisits. Remove the bottom counter completely; native tests observe settled semantic card identity without hidden numeric state or raw-ID speech. Preserve native gesture and lifecycle boundaries. See [demo news policy](../../docs/DEMO_NEWS.md).

## Stable playable cards #108

Anchor playing/completed game content at the top of the viewport-sized host so changing text cannot re-center the game. Issue #88 makes previews top anchored with actual inactive game content and a measured start reservation. Preserve title/start semantics and the existing owned scroller/pager. Game adapters reserve their supported dynamic regions to preserve overflow extent; the feed does not inspect game states or fix text heights. See [stable layout](../../docs/GAME_LAYOUT.md).

## Visible inactive boards #88

Render the same frozen initial board in preview and play. Under #185, the first valid game action starts through the shared runtime and applies that same action; appearance and scrolling stay inactive. Preserve hidden answers, reset/completion, and the empty static chrome reservation. Before changing this boundary, read [preview guidance](../../docs/GAME_PREVIEWS.md).

## Proposed preference-based frequency

The owner's repeated-skip recommendation idea is captured in [#119](https://github.com/devofthings/sidequest/issues/119), with its pending status in [DECISIONS.md](../../docs/DECISIONS.md#pocket-game-direction-recorded-october-4-2026). Current selection/cadence stays authoritative. Implement preference weighting only after a bounded policy is approved; separate game-type preference from difficulty, define real exposures and recovery, and preserve stable existing cards and the five-game/news cadence. This proposal selects no telemetry, storage or backend service.

## Selected MVP visual baseline

Use the researched [DESIGN.md](../../docs/DESIGN.md) direction for approved #13 styling. Keep news still and readable, preview/play boards stable, shared start footprints, settled native paging, and Reduce Motion. Styling changes must preserve feed lifecycle and source attribution.
## Shared MVP style #123

Use [shared presentation tokens](../Presentation/AGENTS.md) for the calm canvas, rounded headings, and explicit lime start action. Keep preview and play on the same top-anchored layout with the same measured start reservation. Transparent UIKit hosting backgrounds expose the opaque SwiftUI canvas; forward color-scheme contrast and Reduce Motion into separate hosting roots alongside Dynamic Type and appearance. Shared styling owns neither paging nor runtime eligibility.

## Success feedback reservation #86

Render the shared success badge in the viewport-owned header title slot after an accepted successful attempt. Reserve both app title and badge footprints from the first render; transient visual title replacement cannot resize the header or card viewport. Keep the badge outside the card-owned scroller so it remains visible when game controls are scrolled into view. The runtime owns whether it is present; the feed does not inspect rules or emit haptics on appearance/rendering. Preserve both the header and start reservations, board geometry, manual paging, and propagated Reduce Motion. The badge is noninteractive and readable beyond color, while game-owned completion text remains authoritative after it expires.

## Pocket viewport budget #142

The lead's agent-grill accepts one presentation-only context from `FeedCardController`'s actual positive native card bounds. Retain it across content updates and publish only real size changes; never derive it from UIScreen, hosting intrinsic height, scroll offset or game phase. Feed game-card presentation subtracts independently measured stable title/reserved-start chrome and padding/gaps, exposing the remaining game-content budget. This seam is groundwork for Bubble #138, which consumes it after #142. Keep the fixed success header and single owned content scroller unchanged. Root's normal375×667 probe measured579-point card height: Sudoku/Memory fit, while both Chess control stacks overflow. Leave Sudoku/Memory sources unchanged. Native/CI results remain pending.

## Historical informational start hint #160

Historically, #160 superseded the earlier explicit lime start-button styling; #185 now supersedes this real-game hint/interception policy. Feed composition renders a plain top-row Tap to play hint with semantic Start game activation and a transparent preview tap surface confined to game content; news and viewport navigation remain outside it. Retain the measured hint row in every phase, disabled actual initial boards, and one native content scroller. Existing native pans win over start taps. See [preview policy](../../docs/GAME_PREVIEWS.md).

## Selected shared chrome #182

Use leading heavy rounded game headings and vivid existing-token fills for the existing header actions. Shared styling leaves the prior start cue unchanged; the owner's selected first-game-interaction start behavior is separately owned by [#185](https://github.com/devofthings/sidequest/issues/185). Do not add a new button row, resize the header/success slot, or alter the game-content budget when styling. Game adapters own their board/control geometry.
## First meaningful interaction #185

The owner selected first interaction starts and applies the same action, superseding #160's inert tap/hint for real games. Follow [the authoritative preview policy](../../docs/GAME_PREVIEWS.md). Validate meaningful input before synchronous runtime preparation; capture visibility identity for held callbacks and preserve attempt/lease cancellation. No appearance/scroll activation, swallowed first action, real-fixture bypass or new lifecycle owner. Keep the static empty chrome reservation and native accessible controls. Actual native/CI proof remains pending in the owning PR.

## Visible completed controls #185

The feed-wide disabled gate rejects hidden cards and explicit-policy preview input only. A visible completed subtree remains eligible for game-owned actions such as Bubble Replay; `GameRuntime.canInteract` is the move gate and must not globally disable completed controls. Each adapter retains its own completed move rejection, and Replay still requires the shared visible-completed lifecycle gate. The actual #185 completed-win/revisit native flow exposed this distinction when the broader move gate disabled Replay; retain its enabled-control and frozen reset assertions.

## News access #191

Keep the header limited to app/success identity and More options, with no reserved newspaper-button footprint. The menu invokes the existing `openNews` callback; composition retains modal eligibility/reset ownership. Source links and news cards stay unchanged. See [the accepted decision](../../docs/DECISIONS.md#news-access-191).
