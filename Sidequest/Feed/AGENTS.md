# Feed ownership

`Domain` owns deck/session behavior; presentation consumes domain values and shared lifecycle effects. See [CONTRACT.md](../../docs/CONTRACT.md) and [source ownership](../../docs/STRUCTURE.md).

Build and store a shuffled deck once per deliberate session creation using injected randomness. Rendering never reshuffles it. Reject duplicate card IDs rather than dropping content; multiple cards of the same game kind are valid when their IDs differ. Visibility means the host's selected card, not SwiftUI appearance. Feed presentation and background handling follow issue #3, not the contract's sample launch view.

Issue #3 uses one selected card, a dedicated vertical swipe rail outside game interaction, and accessible Previous/Next buttons. The rail advances one card per intentional vertical swipe; interactive card drags never navigate. Selection stays bounded at the first/last card, and the last card shows an end message without automatic reshuffling. Empty decks show an explicit empty state; a deck containing games without news remains usable.

`FeedController` owns selection and scene eligibility, using retained `GameRuntime` references supplied by composition. Invalidate the previous card and deliver reset synchronously before enabling another card. An inactive/background scene makes every runtime invisible and resets unfinished attempts once; returning activates the selected preview without starting it. Completed results remain retained. Views render phase and send explicit actions; they never copy lifecycle values or own game rules/tasks.

`FeedView(controller:gameContent:newsContent:)` accepts main-actor render closures `(GameCard, GameRuntime) -> AnyView` and `(NewsSnapshot) -> AnyView`. Composition provides a runtime for every game ID before exposing the feed. Rendering a closure cannot create a controller, reshape the deck, or mutate lifecycle. See [feed adapter contract](../../docs/FEED.md) for ownership, effect ordering, and downstream integration.
