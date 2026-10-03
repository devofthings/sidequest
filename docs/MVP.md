# Sidequest MVP

## Confirmed direction

Build a private iPhone prototype that combines short news stories and simple games in one swipeable feed. News is an essential part of the experience, rather than a separate destination alongside a game catalog.

The first test asks whether switching between reading and playing is enjoyable enough to want to reopen the app. Use English news and build the iPhone app natively with SwiftUI.

Sidequest is the working name. The GitHub repository is private. Use GitHub Issues for small tasks, the private GitHub Project for workflow status, and repository documentation for durable decisions and agent context. See [WORKFLOW.md](WORKFLOW.md) when selecting or updating work.

## First-test experience

- Import a small set of real English news snapshots manually, including source-provided excerpts and links to the original articles. Automatic news fetching is deferred.
- Shuffle news cards and game cards together. Movement between cards is controlled by the person swiping, rather than automatic advancement.
- Each game card initially shows a preview with an accessible "Tap to play" action. Swiping onto the card does not start gameplay, timers, or accept game input. Tapping starts the game inside the card; that tap only starts the attempt.
- Reset an unfinished game when its card is skipped. Returning shows the tap-to-play preview and requires a new explicit start. Fresh attempts are more important than saved progress in this test.
- Include simple Sudoku, memory pairs, one-move chess puzzles, and a bubble shooter.
- Test in the iPhone simulator and on the user's own iPhone through Xcode.

The overall experience is evaluated through personal testing; a quantitative retention target has not been established. Success means the user enjoys switching between news and games and wants to reopen Sidequest.

## Deferred work

Defer accounts, ads, payments, licensed game catalogs, and social-platform integrations. The user confirmed these boundaries for the first prototype. Automatic scraping and news refreshing are also deferred in favor of manual imports.

Phase two will introduce a backend for accounts and synced preferences, plus high scores and leaderboards. Backend provider and gamification rules are still open decisions; they are outside the first-test scope.

See [DECISIONS.md](DECISIONS.md) for the status of each decision.

## Delivery sequence

The [project structure task](https://github.com/devofthings/sidequest/issues/29) first selects source ownership and scoped agent guidance, with games grouped into their own area. The app foundation then establishes runnable targets and verification commands using that layout. The shared card contract enables separate work on the feed, news imports, and four games. Integration follows those feature tasks; the personal test follows a working integrated build. GitHub Issues own the detailed acceptance criteria and prerequisite links.

## Current repository state

This repository contains project guidance and planning artifacts. It has no app target or implementation yet.
