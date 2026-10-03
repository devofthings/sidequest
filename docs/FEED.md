# Feed presentation contract

Issue #3 implements the host using the [shared card contract](CONTRACT.md) and [coding rules](CODING.md). Feed domain values remain pure Swift. Observable presentation owners run on the main actor and depend inward.

## Composition and interfaces

`FeedSelection(cards:)` retains the ordered deck and bounded selected index. Navigation does not shuffle, drop, or add cards. `FeedController(cards:runtimes:)` receives a runtime for each game card, owns selection and scene eligibility, and exposes `selectedCard`, `position`, `count`, `canGoBack`, `canGoForward`, `next()`, `previous()`, and `setSceneActive(_:)`. Construct the deck through `DeckBuilder` before composition; missing game runtimes are a programmer wiring error.

`GameRuntime(makeAttemptID:)` is a retained observable reference around one private `GameLifecycle`. It exposes read-only `phase` and `isVisible`, plus `setVisible(_:)`, `start()`, `complete(attempt:)`, and `acceptsInput(from:)`. The default attempt factory uses the core default identity; deterministic tests can inject identities. Call `installEffectHandler(_:)` exactly once during composition, before interaction. The handler runs synchronously after each accepted transition. Repeated starts or visibility changes that return no effect call no handler.

Each game controller retains its runtime. App composition retains game controllers by `CardID`; the effect closure captures its controller weakly. Reset invalidates the old token first, cancels delayed work in the controller, then clears rules/selection/feedback. Stop cancels work and keeps the completed result. Game input and every delayed mutation must call `acceptsInput(from:)`, including after suspensions. A disappearing view is never the sole task owner or cancellation path.

`FeedView(controller:gameContent:newsContent:)` receives main-actor closures `(GameCard, GameRuntime) -> AnyView` and `(NewsSnapshot) -> AnyView`. Its preview renders the accessible Tap to play button and consumes the start tap; playing/completed phases render the injected surface. The game closure resolves an already-retained controller; it does not create one. Individual game rules remain outside the host. The concrete runtime avoids adding unused protocols or a dependency-injection framework.

The current composition supplies playable [mini Sudoku](SUDOKU.md) and [memory pairs](MEMORY.md), provisional chess/bubble-shooter demos, and sourced fictional news using the existing `NewsCardView`; it retains source/date/sample labels instead of duplicating news presentation. App-owned `ComposedGame` resolves each retained concrete controller and its runtime without teaching the feed about individual rules. A validated Sudoku fixture is selected once during composition; rendering and restarting the same card do not select another puzzle. Memory creates a fresh shuffled board on each explicit start; its controller owns delayed mismatch resolution and gates every result through the same runtime. Other games and imported news connect through these closures in their owning feature/integration work. `-sidequest-news-preview` preserves the standalone Debug library/import surface until #9 connects saved imports to the normal feed. Bubble-shooter replay belongs to #8 and will coordinate its compatible runtime extension; the host adds no replay action to other games.

The DEBUG-only `-sidequest-feed-test` route intentionally supplies generic demos for every game kind to keep the host's lifecycle checks independent of game rules. Normal/Release Sudoku cards use the actual Sudoku adapter. The separate `-sidequest-sudoku-test` route selects Sudoku first, the first validated fixture, and one news card for deterministic gameplay checks; it is not a production puzzle-selection setting. The DEBUG-only `-sidequest-memory-fixtures` route selects Memory first, adjacent original pairs, one news card, and a two-second mismatch delay for inspection. Normal/Release Memory uses shuffled boards and a 700 ms delay. Feed selection, skip/reset ordering, and completion retention are unchanged.

## Navigation and eligibility

One selected card fills the content area. A dedicated vertical swipe rail advances one card per intentional swipe outside game interaction; Previous/Next buttons provide accessible navigation. Card content can scroll or accept game gestures independently. The first/last boundaries disable unavailable navigation; the final card displays End of feed, without starting another session. An empty deck has a deliberate empty state. A deck without news can still show its games.

The controller makes the previous game invisible and delivers reset before making another eligible. Scene inactivity/background also makes every game invisible: unfinished attempts reset once, and reactivation shows the selected preview. Completion is preserved across navigation and background events. These technical choices follow the explicit-start/no-offscreen-work requirements and the contract's delegated scene policy.

## Implementation question record

This is the implementation agent's self-assessment under the project-local agent-grill skill. Dependency #2 must be merged before implementation; it was merged as `d81db509abae98e96df779eaba5f8144200a4a31` before this issue began.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Where is lifecycle and rule state retained? | Delegated technical choice | One main-actor runtime per card, retained with its controller in composition. | CODING.md requires one state owner and stable identity; CONTRACT.md requires completed results to survive revisits. | Unit and running-app tests cover skipped resets and completed-state retention. |
| How do resets reach offscreen games? | Fact and technical choice | Deliver effects synchronously after core transitions; controllers cancel work before resetting. | CONTRACT.md invalidates tokens before effects; view disappearance alone cannot reliably deliver offscreen work cancellation. | Probe tests verify reset once, ineligibility during effects, and rejection of old tokens after returning. |
| How can navigation coexist with game dragging? | Delegated technical choice | Dedicated vertical rail plus explicit Previous/Next controls, independent of card gestures. | Issue #3 requires swiping outside the game and usable card interaction. | Running-app tests compare game dragging with rail swipes in both directions. |
| What happens on backgrounding or at boundaries? | Delegated technical choice | Reset unfinished play while inactive; retain completion; bounded navigation and explicit empty/end states. | CONTRACT.md delegates scene policy to #3; MVP forbids offscreen play and automatic advancement. | Controller and UI tests cover background/return, empty/games-only sessions, and end navigation. |

Verification results are recorded in the PR after actual execution. Physical-iPhone execution and completed news/game integration remain outside this ticket.
