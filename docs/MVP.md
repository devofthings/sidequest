# Sidequest MVP

## Confirmed direction

Build a private iPhone prototype that combines short news stories and simple games in one swipeable feed. News is an essential part of the experience, rather than a separate destination alongside a game catalog.

The first test asks whether switching between reading and playing is enjoyable enough to want to reopen the app. Use English news and build the iPhone app natively with SwiftUI.

Sidequest is the working name. The GitHub repository is private. Use GitHub Issues for small tasks, the private GitHub Project for workflow status, and repository documentation for durable decisions and agent context. See [WORKFLOW.md](WORKFLOW.md) when selecting or updating work.

## First-test experience

- Import a small set of real English news snapshots manually, including source-provided excerpts and links to the original articles. Automatic news fetching is deferred.
- Shuffle news cards and game cards together. Swipe directly on full-page cards; cards track the finger and settle using native paging. A compact accessible navigation menu also moves between cards. Overflowing content scrolls within its card; outward gestures starting at its top/bottom edge page. Movement stays manual.
- Each game card initially shows a preview with an accessible "Tap to play" action. Swiping onto the card does not start gameplay, timers, or accept game input. Tapping starts the game inside the card; that tap only starts the attempt.
- Reset an unfinished game when its card is skipped. Returning shows the tap-to-play preview and requires a new explicit start. Fresh attempts are more important than saved progress in this test.
- Include simple Sudoku, memory pairs, one-move chess puzzles, and a bubble shooter.
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

The SwiftUI feed, shared lifecycle contract, real Sudoku, Memory, two one-move Chess cards, and Bubble shooter are implemented. Integration #9 connects the normal once-shuffled deck to private saved English news and the native Files importer. Missing/empty news leaves the five real game cards; invalid input preserves saved bytes and the current deck. Tap-to-play remains explicit; skipping/backgrounding/library presentation resets unfinished play, while completed results persist within the session. Production has no fictional-news fallback or game demos. Original fictional samples remain limited to explicit Debug verification routes. Integrated delivery and selected-release source/download installation evidence are recorded in [#9](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508). Personal enjoyment still requires the user’s test in #10.

The [2026.10.14 MVP](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) passed all 133 native tests (96 unit, 37 UI), Debug/ARM64 Release builds, strict lint, source discovery, and offline tooling on Xcode 27.0/iOS 27.0. Fresh actual-tag source and downloaded-app installation/normal launch also passed; see [delivery evidence](INSTALL.md#verified-mvp-delivery). Game-specific checks remain in [SUDOKU.md](SUDOKU.md#verification), [MEMORY.md](MEMORY.md#verification), [CHESS.md](CHESS.md), and [BUBBLES.md](BUBBLES.md).

The deployment target is iOS 17.0; execution there is unverified. Simulator-first delivery was selected in resolved [#79](https://github.com/devofthings/sidequest/issues/79); physical-device signing/install/execution and device VoiceOver remain deferred and unverified. The personal enjoyment hypothesis is not answered by simulator tests or technical delivery. Main updates continue verification while the foreground runner is active; publication remains explicit and manual. Seven older preview release objects and 21 assets were removed after preserving tags/source, including the `2026.10.7` statistics baseline. Follow [release guidance](RELEASES.md) for actual availability and provenance.
