# Shared card and game contract

Implemented in [issue #2](https://github.com/devofthings/sidequest/issues/2), following the [MVP](MVP.md), [coding rules](CODING.md), and [source ownership](STRUCTURE.md). All domain values below are pure Swift; UI and loading adapters depend inward.

## Card data

`CardID.init(_ rawValue: String) throws` preserves an explicit nonblank source identity and encodes as a string. IDs survive rendering; never regenerate them in a view body. `GameCard(id:kind:)` stores that ID and one `GameKind`: `sudoku`, `memory`, `chess`, or `bubbleShooter`. `FeedCard` is `.news(NewsSnapshot)` or `.game(GameCard)` and exposes the underlying `id`. These values are Codable and Sendable.

`NewsSnapshot.init(id:headline:excerpt:publisher:sourceURL:capturedAt:publishedAt:isSample:) throws` requires nonblank text, an absolute HTTP(S) URL with a host, finite captured time, and finite publication time when provided. Publication time defaults to nil; `isSample` has no default and must be supplied. Custom decoding uses the same validation. `CardValidationError` identifies an empty field, invalid source URL, or invalid timestamp. Text is preserved; the contract imposes no article-length or invented date-order constraint. Import adapters choose a date-encoding strategy and wrap decoding errors with actionable input context in #4.

## Deck creation

`DeckBuilder.shuffled(_:using:) throws -> [FeedCard]` accepts an inout `RandomNumberGenerator`. It rejects duplicate IDs with `DeckConstructionError.duplicateCardID`, supports empty/single decks, and preserves every input card exactly once. The app/session owner calls it once when creating a session and stores the result. A re-render reads that stored deck; a deliberate new session calls it again. Tests inject controlled randomness; production uses `SystemRandomNumberGenerator`.

The launch composition constructs two clearly fictional news cards and all four game kinds in memory, with example.com source links and fixed sample timestamps. It reports the sample session's card count without pretending the feed or games are implemented. Sample-construction errors remain visible rather than silently replacing failed data.

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

Visibility is the host's selected card, never `onAppear`. Background/partial-visibility policy is the feed adapter's responsibility in #3. The feed observes phase and delivers effects through composition without inspecting individual game rules. The contract deliberately avoids an unused game protocol; introduce the concrete presentation boundary when the feed and game consumers exist.

## Verification

Unit tests cover validation/decoding and identity round trips; reproducible shuffled membership and duplicate rejection; visibility, explicit start, idempotence, reset, completion, and stale attempts. Foundation UI launch remains verified. The app uses only fictional in-memory fixtures here; manual imports, game rules, gameplay UI, and integrated end-to-end tests belong to #3–#9.
