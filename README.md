# Sidequest

[![PR verification](https://github.com/devofthings/sidequest/actions/workflows/verification.yml/badge.svg?event=pull_request)](https://github.com/devofthings/sidequest/actions/workflows/verification.yml)
![iOS 17+ deployment target](docs/assets/readme/ios.svg)
![Swift 6 language mode](docs/assets/readme/swift.svg)

A private SwiftUI iPhone app mixing short news and quick games in one swipeable feed. The first test: is switching between reading and playing enjoyable enough to come back?

**[Install and run](docs/INSTALL.md)** · **[Project board](https://github.com/users/devofthings/projects/1)** · **[Issues](https://github.com/devofthings/sidequest/issues)**

## Try it

Open `Sidequest.xcodeproj`, select the shared **Sidequest** scheme, and run on an iPhone simulator. The verified environment is Xcode 27.0 with an iOS 27.0 simulator on Apple silicon. The deployment target is iOS 17.0; execution on that version remains unverified.

For your own iPhone, follow the [free Apple Account / Personal Team setup](docs/INSTALL.md#install-on-your-own-iphone). Local signing stays outside Git; free provisioning requires reinstallation after seven days. The owner has reported successful installation and basic play.

The retained [2026.10.14 simulator download](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) is an older, immutable finite-deck MVP. Build current source for the refinements below. The unsigned simulator archive cannot be installed on an iPhone; see [download instructions and verification evidence](docs/INSTALL.md#download-a-simulator-preview).

## What's playable

Swipe vertically in either direction through endless locally generated game cards. The first meaningful game interaction starts play immediately. Skipping resets unfinished attempts; revisiting preserves the card's challenge and completed results within the session. Game cards mix labeled Easy, Medium, and Hard challenges. A cancellable three-second timer auto-continues after a win; tap it to disable, or reenable Auto-continue in More options.

| Game | Current source |
| --- | --- |
| [Sudoku](docs/SUDOKU.md) | Standard 9×9 puzzles with certified technique-based tiers |
| [Memory](docs/MEMORY.md) | Three-, four-, and six-pair challenges |
| [Chess](docs/CHESS.md) | Direct piece/destination play, varied cropped views, and standard 8×8 rules |
| [Bubble shooter](docs/BUBBLES.md) | Drag-and-release shooting, trajectory aiming, and tiered shot budgets |

[Tagesschau RSS excerpts and images](docs/TAGESSCHAU.md) appear at future five-game boundaries for a private German news test. Refresh runs at launch and foreground reopening; an in-memory cache keeps the latest valid articles if refresh fails. A fresh offline launch shows games. **More options → News snapshots** also supports private manual imports.

Games use vivid artwork, contained animations, and interaction feedback; app surroundings stay neutral. A static system launch screen shows the Sidequest logo. The [daily flame](docs/STREAK.md) counts a successful solve or committed physical card swipe once per local calendar day; opening alone and accessible or automatic navigation do not count.

Accounts, synced preferences, and leaderboards remain phase-two scope. See the [MVP brief](docs/MVP.md) and [decisions](docs/DECISIONS.md) for accepted direction and proposals. Public news reuse and distribution are not approved.

## Contribute with agents

Start with [AGENTS.md](AGENTS.md) and the assigned issue. It routes to checkout setup, coding guidance, tests, and fresh-agent review as needed. All changes use feature branches and reviewed PRs; routine verification runs on the exact PR commit, with no second main check.

[Installation](docs/INSTALL.md) owns runnable build/test commands. [Workflow](docs/WORKFLOW.md) owns task status and handoffs. [Decisions](docs/DECISIONS.md) owns durable choices; issues and PRs retain implementation and verification evidence.

Sidequest is the working name; public naming availability has not been established.
