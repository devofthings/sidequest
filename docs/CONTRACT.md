# Shared card and game contract

Implemented in [issue #2](https://github.com/devofthings/sidequest/issues/2), following the [MVP](MVP.md), [coding rules](CODING.md), and [source ownership](STRUCTURE.md). All domain values below are pure Swift; UI and loading adapters depend inward.

## Card data

`CardID.init(_ rawValue: String) throws` preserves an explicit nonblank source identity and encodes as a string. IDs survive rendering; never regenerate them in a view body. `GameCard(id:kind:)` stores that ID and one `GameKind`: `sudoku`, `memory`, `chess`, or `bubbleShooter`. `FeedCard` is `.news(NewsSnapshot)` or `.game(GameCard)` and exposes the underlying `id`. These values are Codable and Sendable.

`NewsSnapshot.init(id:headline:excerpt:publisher:sourceURL:capturedAt:publishedAt:isSample:) throws` requires nonblank text, an absolute HTTP(S) URL with a host, finite captured time, and finite publication time when provided. Publication time defaults to nil; `isSample` has no default and must be supplied. Custom decoding uses the same validation. `CardValidationError` identifies an empty field, invalid source URL, or invalid timestamp. Text is preserved; the contract imposes no article-length or invented date-order constraint. The local import adapters implemented in #4 own strict timestamp parsing and actionable decoding errors; see [NEWS.md](NEWS.md) for their file format and provenance requirements.

## Deck creation

`DeckBuilder.shuffled(_:using:) throws -> [FeedCard]` accepts an inout `RandomNumberGenerator`. It rejects duplicate IDs with `DeckConstructionError.duplicateCardID`, supports empty/single decks, and preserves every input card exactly once. The app/session owner calls it once when creating a session and stores the result. A re-render reads that stored deck; a deliberate new session calls it again. Tests inject controlled randomness; production uses `SystemRandomNumberGenerator`.

The sample composition constructs two clearly fictional news cards and all four game kinds in memory, with example.com source links and fixed sample timestamps. Issue #2's original `FoundationView` proved this contract by reporting the sample card count; the standalone Debug news-preview route retains that foundation surface. Normal launch waits for #7's off-UI fixture loading in retained `FeedStartup`, then uses #3's retained `FeedComposition(chessPuzzles:)`, manual feed selection, and one `GameRuntime` per stable game-card ID. Sudoku uses its playable #5 adapter and a validated puzzle selected once during composition; Memory uses its #6 retained adapter and creates a shuffled board only on explicit start. Chess uses two stable cards for original White/Black mate-in-one fixtures with separate retained controllers; the bubble-shooter surface remains a provisional demo until #8 lands. The DEBUG generic harness retains one card per game kind. Saved-import feed composition remains with #9. Sample or puzzle-construction errors remain visible rather than silently replacing failed data. See [FEED.md](FEED.md) for the implemented presentation boundary.

## Game lifecycle

`GameLifecycle()` begins in `.preview`, invisible. Its read-only `phase` is `.preview`, `.playing(GameAttemptID)`, or `.completed(GameAttemptID)`. `isVisible` reports host selection. The adapter owns its rules/UI state and asynchronous work; the lifecycle owns eligibility and attempt identity.

| Call | Result and required handling |
| --- | --- |
| `setVisible(true)` | Select the card. Preview remains preview; no game input or time advancement is permitted. |
| `start(makeAttemptID:)` | Only a visible preview starts. Return `.start(attempt)`, initialize rules/work for that token, and consume the tap without making a move. Repeated starts return nil and do not mint tokens. The default factory uses UUID; tests inject stable tokens. |
| `acceptsInput(from:)` | True only for the visible, playing, current token. Gate every move, timer tick, and asynchronous result immediately before state mutation, including after every suspension. |
| `setVisible(false)` | A playing attempt becomes preview before returning `.reset(oldAttempt)`. Cancel pending work first, then clear rules, selection, and feedback. Repeated skips return nil. Preview stays preview; completion stays completed. |
| `complete(attempt:)` | Only the eligible current token completes. Return `.stop(attempt)`; cancel work and preserve final rules/result. Stale, invisible, preview, and completed events return nil. |

Apply each returned effect after the transition. Reset invalidates the token before cancellation, so late callbacks fail the eligibility gate even when cancellation is cooperative. Returning to a skipped game requires a new token/start. A completed card can be revisited but cannot restart through this interface. Explicit bubble-shooter replay belongs to #8: its adapter creates a fresh lifecycle and attempt on the replay action while ordinary revisits preserve completion. Persistence and scoring are outside the MVP contract.

Visibility is the host's selected card, never `onAppear`. The implemented #3 `FeedController` owns selection and scene eligibility: backgrounding makes games ineligible and resets unfinished attempts while preserving completion. The retained `GameRuntime` owns one private lifecycle and delivers accepted effects synchronously after transitions to its bound controller. The feed observes this concrete presentation boundary without inspecting individual game rules or adding an unused game protocol; [FEED.md](FEED.md) documents its ownership, binding, and input gates.

## Verification

Unit tests cover validation/decoding and identity round trips; reproducible shuffled membership and duplicate rejection; visibility, explicit start, idempotence, reset, completion, and stale attempts. Running-app tests cover foundation launch, the standalone news preview/importer, and #3's demo start, skip/reset, retained completion, backgrounding, independent navigation gestures, sourced fictional cards, and empty/end states. These deterministic tests use fictional inputs. Manual imports are implemented in #4; Sudoku's pure rules and retained adapter have focused unit and normal/largest-text running-app checks, with remaining validation recorded in [SUDOKU.md](SUDOKU.md#verification). Memory rule/controller checks cover pairs, controlled delays, reset during noncooperative pending work, and retained completion; running-app/final verification is recorded in [MEMORY.md](MEMORY.md#verification). Chess rules and lifecycle checks are documented in [CHESS.md](CHESS.md); bubble-shooter remains with #8, and saved-import feed integration remains with #9.
