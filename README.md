<p align="center">
  <img src="Sidequest/Resources/Assets.xcassets/StartupLogo.imageset/CardS.png" alt="Sidequest logo" width="112" height="112">
</p>

<h1 align="center">Sidequest</h1>
<p align="center"><strong>A little play. A little perspective. One more swipe.</strong></p>

Turn a spare moment into a small adventure. Sidequest brings colorful pocket games and short news stories together in one iPhone feed. Solve a puzzle, pop some bubbles, catch up on a story, and discover what comes next.

## Find your next little win

| Think | Remember | Checkmate | Pop |
| --- | --- | --- | --- |
| **Sudoku** — classic 9×9 puzzles for a quick thinking break. | **Memory** — bright pairs to flip, spot, and match. | **Chess** — compact mate-in-one challenges with direct piece moves. | **Bubble shooter** — tap a target or drag to aim, and clear matching clusters. |

Easy, Medium, and Hard cards keep the mix varied. Start with your first move and swipe whenever you feel like a change. Scroll in either direction through an endless supply of local challenges.

## Small moments, satisfying rewards

- **Feel every little win.** Colorful celebrations, playful motion, and tactile feedback make successful moves feel good.
- **Keep your daily flame alive.** Solve a game or swipe to another card to count toward your daily streak.
- **Keep the flow going.** A three-second countdown takes you to the next card after a win; tap the timer to turn it off.
- **Take a reading break.** Tagesschau stories and images bring news into the mix, refreshed when you reopen the app.

Vivid games. Clean surroundings. Room to play.

## Try Sidequest

Sidequest is a **private iPhone prototype**. Build the latest source with Xcode for your simulator or your own iPhone; a free Apple Account is enough for personal-device testing. There are currently no downloadable GitHub releases.

**[Install and play](docs/INSTALL.md#install-on-your-own-iphone)** · **[Simulator setup](docs/INSTALL.md#build-and-test)**

Tagesschau content is used for private testing. Public distribution and commercial news reuse remain unapproved.

## The experiment behind Sidequest

Sidequest is an experiment in **native SwiftUI and 100% agent-driven development**. The developer steers the product and tests the app on an iPhone; agents write the application code, tests, and documentation.

Work starts with a scoped GitHub issue. An agent implements it on a feature branch, a fresh agent independently reviews the change, and findings are fixed before merging. Automated checks verify the exact PR commit. Shared [agent instructions](AGENTS.md) and [recorded decisions](docs/DECISIONS.md) give each new agent the context to continue.

Pure game rules stay separate from the interface and replaceable adapters through hexagonal architecture. Build, signing, and verification instructions live in [Installation](docs/INSTALL.md); the iOS deployment target is 17.0, with actual execution evidence documented there.

[Improvements board](https://github.com/users/devofthings/projects/2) · [Issues](https://github.com/devofthings/sidequest/issues) · [MVP brief](docs/MVP.md)
