# Sidequest MVP

## Confirmed direction

Build a private iPhone prototype that combines short news stories and simple games in one swipeable feed. News is an essential part of the experience, rather than a separate destination alongside a game catalog.

The first test asks whether switching between reading and playing is enjoyable enough to want to reopen the app. Use English news and build the iPhone app natively with SwiftUI.

Sidequest is the working name. The GitHub repository is private. Use GitHub Issues for small tasks, the private GitHub Project for workflow status, and repository documentation for durable decisions and agent context. See [WORKFLOW.md](WORKFLOW.md) when selecting or updating work.

## First-test experience

- Start with 30 clearly fictional English demo stories when saved news is absent, or import real English snapshots with source-provided excerpts and original links. Intentional empty imports stay empty. Automatic news fetching is deferred.
- Shuffle games and show one article after every five games, cycling the current story pool. The bottom card counter is removed. Swipe directly on full-page cards; cards track the finger and settle using native paging. A compact accessible navigation menu also moves between cards. Overflowing content scrolls within its card; outward gestures starting at its top/bottom edge page. Movement stays manual.
- Each game card initially shows its actual inactive initial board with an accessible "Tap to play" action above it. Memory cards stay face down and puzzle answers stay hidden. Swiping onto the card does not start gameplay, timers, or accept game input. Tapping starts the game inside the card; that tap only starts the attempt.
- Reset an unfinished game when its card is skipped. Returning shows the tap-to-play preview and requires a new explicit start. Fresh attempts are more important than saved progress in this test.
- Include simple Sudoku, memory pairs, one-move chess puzzles, and a bubble shooter. Approved #104 extends current source to endless manual scrolling with new local challenges; the recorded MVP download remains finite.
- Test in the iPhone simulator and on the user's own iPhone through Xcode.

The overall experience is evaluated through personal testing; a quantitative retention target has not been established. Success means the user enjoys switching between news and games and wants to reopen Sidequest.

## Deferred work

The shared design baseline, wireframes, and visual polish follow the first MVP and personal test in [design task #13](https://github.com/devofthings/sidequest/issues/13). Use simple, consistent UI for the MVP based on the confirmed behavior above; a Figma or wireframe approval is not an MVP prerequisite.

Defer accounts, ads, payments, licensed game catalogs, and social-platform integrations. The user confirmed these boundaries for the first prototype. Automatic scraping and news refreshing are also deferred in favor of manual imports.

Phase two will introduce a backend for accounts and synced preferences, plus high scores and leaderboards. Backend provider and gamification rules are still open decisions; they are outside the first-test scope.

See [DECISIONS.md](DECISIONS.md) for the status of each decision.

## Delivery sequence

The selected [source structure](STRUCTURE.md) groups games into independently owned areas and defines scoped guidance and source discovery. The foundation provides runnable app/test targets and verified simulator commands using that layout. The shared card contract enables separate work on the feed, news imports, and four games. Integration follows those feature tasks; the personal test follows a working integrated build. GitHub Issues own the detailed acceptance criteria and prerequisite links.

## Current repository state

The SwiftUI feed, shared lifecycle contract, real Sudoku, Memory, two one-move Chess cards, and Bubble shooter are implemented. The recorded finite MVP integrates a once-shuffled deck with private saved English news and the native Files importer. Missing/empty news in that release leaves five real game cards; invalid input preserves saved bytes and the current deck. Tap-to-play remains explicit; skipping/backgrounding/library presentation resets unfinished play, while completed results persist within the session. That immutable release has no fictional-news fallback or game demos. Merged #104 source extends the deck with endless generated game batches; merged #106 source adds nil-only demo news and five-game cadence below. The legacy two-story samples remain separate Debug fixtures. Integrated delivery and selected-release source/download installation evidence are recorded in [#9](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508). Personal enjoyment still requires the user’s test in #10.

The [2026.10.14 MVP](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) passed all 133 native tests (96 unit, 37 UI), Debug/ARM64 Release builds, strict lint, source discovery, and offline tooling on Xcode 27.0/iOS 27.0. Fresh actual-tag source and downloaded-app installation/normal launch also passed; see [delivery evidence](INSTALL.md#verified-mvp-delivery). Game-specific checks remain in [SUDOKU.md](SUDOKU.md#verification), [MEMORY.md](MEMORY.md#verification), [CHESS.md](CHESS.md), and [BUBBLES.md](BUBBLES.md).

The deployment target is iOS 17.0; execution there is unverified. Simulator-first delivery was selected in resolved [#79](https://github.com/devofthings/sidequest/issues/79); physical-device signing/install/execution and device VoiceOver remain deferred and unverified. The personal enjoyment hypothesis is not answered by simulator tests or technical delivery. Routine exact-head PR verification remains required; the owner's #112 decision removes automatic main checks after merging. Publication remains separately owner-authorized and manual. Seven older preview release objects and 21 assets were removed after preserving tags/source, including the `2026.10.7` statistics baseline. Follow [release guidance](RELEASES.md) for actual availability and provenance.

## Approved follow-up: endless feed

On October 4, 2026, the user requested endless scrolling with automatically generated games in [#104](https://github.com/devofthings/sidequest/issues/104). Manual swiping continues beyond the initial cards using locally generated challenges; explicit tap-to-play and skip/reset remain accepted. Issue #104 merged after full 151-test verification and fresh review, with reused validated Chess puzzles and fresh Sudoku, Memory, and Bubble variants. Its initial news-once default is superseded by approved #106: the immutable `2026.10.14` release remains the verified finite-deck MVP. See [ENDLESS.md](ENDLESS.md).

## Approved follow-up: demo news cadence

The owner approved more clearly fictional English articles for realistic private testing, one article after four or five games, and removal of the visible bottom card counter in [#106](https://github.com/devofthings/sidequest/issues/106). The lead chose five and a 30-story original demo pool for genuinely absent saved news; imported or intentionally empty news stays authoritative. This supersedes the initial news-once/global mixed-shuffle default. Issue #106 merged through [PR #107](https://github.com/devofthings/sidequest/pull/107) as `f3dc1620b675a0d0e90119855a55f8326609d8eb` on October 4, 2026. The immutable finite-MVP download remains unchanged; see [DEMO_NEWS.md](DEMO_NEWS.md) for current source policy.

## Stable gameplay correction

Approved bug [#108](https://github.com/devofthings/sidequest/issues/108) keeps boards and primary controls stable during feedback/completion changes, with complete accessible text and owned overflow. See [GAME_LAYOUT.md](GAME_LAYOUT.md); this does not start the deferred design baseline.
