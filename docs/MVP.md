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

The shared design baseline, wireframes, and visual polish follow the first MVP and personal test in [design task #13](https://github.com/devofthings/sidequest/issues/13). Use simple, consistent UI for the MVP based on the confirmed behavior above; a Figma or wireframe approval is not an MVP prerequisite.

Defer accounts, ads, payments, licensed game catalogs, and social-platform integrations. The user confirmed these boundaries for the first prototype. Automatic scraping and news refreshing are also deferred in favor of manual imports.

Phase two will introduce a backend for accounts and synced preferences, plus high scores and leaderboards. Backend provider and gamification rules are still open decisions; they are outside the first-test scope.

See [DECISIONS.md](DECISIONS.md) for the status of each decision.

## Delivery sequence

The selected [source structure](STRUCTURE.md) groups games into independently owned areas and defines scoped guidance and source discovery. The foundation provides runnable app/test targets and verified simulator commands using that layout. The shared card contract enables separate work on the feed, news imports, and four games. Integration follows those feature tasks; the personal test follows a working integrated build. GitHub Issues own the detailed acceptance criteria and prerequisite links.

## Current repository state

The SwiftUI feed, shared card/lifecycle contract, shuffled fictional session, and manual news snapshot imports are implemented. The feed currently uses fictional news, playable [mini Sudoku](SUDOKU.md), and explicitly provisional memory/chess/bubble-shooter demos. Skipping/backgrounding resets unfinished play and completed results persist. Sourced news cards display excerpts, provenance, dates, and original links; the native Files picker validates and saves private replacement sets locally. Only fictional samples are bundled. A standalone Debug Read news route provides the library/import preview until integration connects imports to the mixed feed.

Local simulator builds/tests and foreground self-hosted CI are verified on Xcode 27.0/iOS 27.0; the deployment target is iOS 17.0. Sudoku's seven focused rule/controller tests and three running-app flows, including largest-text interaction, passed; final full verification remains pending as recorded in [SUDOKU.md](SUDOKU.md#verification). The other three playable games and imported-news feed integration remain in their owning implementation tickets. Physical-device installation is documented but unverified; its pending connection/signing prerequisite is tracked in [#79](https://github.com/devofthings/sidequest/issues/79). The private preview workflow verifies and publishes successful main commits while the foreground runner is active; check [release guidance](RELEASES.md) and GitHub for each version’s actual availability.
