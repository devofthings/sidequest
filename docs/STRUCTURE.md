# Source layout and ownership

Selected for [issue #29](https://github.com/devofthings/sidequest/issues/29). [Foundation #1](https://github.com/devofthings/sidequest/issues/1) establishes the project, app, resources, and unit/UI test roots. Contract #2 adds core cards/lifecycle, news values, and deck construction. Feed #3 adds selection/presentation and the common retained game runtime. News #4 implements `News/Domain`, local snapshot `News/Adapters`, sourced-card/import `News/Presentation`, and fictional samples/schema in `Resources`. Sudoku #5 implements `Games/Sudoku/Rules`, its retained controller/SwiftUI `Presentation`, and matching unit/UI tests. Memory #6 implements `Games/Memory/Rules`, its retained controller/SwiftUI `Presentation`, and mirrored rule/controller/running-app tests. Chess #7 implements validated original JSON fixtures, pure `Games/Chess/Domain`, the bundled loader in `Adapters`, retained controller/view in `Presentation`, and unit/UI checks. Bubble-shooter rules and presentation adapters remain planned until its owning feature lands.

## Source ownership tree

```text
Sidequest.xcodeproj/           # Foundation-owned project and shared schemes
Sidequest/
  App/                        # Entry point and composition root
  Core/                       # Shared cards, lifecycle contracts, and small ports
  Feed/
    Domain/                   # Deck/session behavior using shared contracts
    Presentation/             # SwiftUI feed and visibility/action adapter
  News/
    Domain/                   # News values and content-loading boundary
    Adapters/                 # Local snapshot decoding and validation
    Presentation/             # News card and source-link actions
  Games/
    Presentation/             # Retained runtime bridging core lifecycle to game adapters
    Sudoku/
      Rules/                  # Pure Swift behavior
      Presentation/           # SwiftUI input and rendering adapter
    Memory/
      Rules/
      Presentation/
    Chess/
      Rules/
      Presentation/
    BubbleShooter/
      Rules/
      Presentation/           # Rendering choice remains with game implementation
  Resources/                  # App assets and redistributable sample data
SidequestTests/
  Core/
  Feed/
  News/
  Games/                      # One subfolder per game
  Fixtures/                   # Deterministic fictional/import-safe test data
SidequestUITests/
  Fixtures/                   # Deterministic critical-flow inputs
```

These paths describe ownership, not a requirement to create empty folders or placeholder types. Start with one app module and appropriate test targets; separate packages and a dependency-injection framework are unnecessary. The foundation records the supported toolchain, language mode, minimum iOS version, and compiler isolation defaults.

## Dependency direction

Follow [ADR 0003](adr/0003-hexagonal-architecture.md) and [CODING.md](CODING.md). `Core`, `Feed/Domain`, `News/Domain`, and each game's `Rules` contain pure Swift behavior and import no UI, rendering, networking-client, or storage SDK. Folder boundaries express this rule; a single app module does not enforce it automatically.

Presentation and adapters depend on their domain behavior and shared contracts. The feed never imports or inspects individual game rules. `App` wires concrete games and news adapters to the shared card/lifecycle contract. [Contract #2](https://github.com/devofthings/sidequest/issues/2) owns that interface and the agreed start/reset semantics; this layout does not invent its types. Time and randomness enter through small deterministic seams where behavior requires them.

Keep assets and redistributable fictional samples in `Resources`. Real personal news captures remain ignored and outside Git and bundled assets. Test fixtures are explicit test resources, not production news or app resources. UI tests interact through the running app and its deterministic inputs, rather than reaching into game implementation.

## Source discovery

Use Xcode filesystem-synchronized folders for the app and each test root, with distinct target membership. Select folders that track changes on disk instead of maintaining a per-file project list. Apple's [folder guidance](https://developer.apple.com/documentation/xcode/managing-files-and-folders-in-your-xcode-project) explains how this reduces project-file changes when sources are added or removed.

The foundation verifies this choice with [INSTALL.md](INSTALL.md#build-and-test)'s `scripts/verify-source-discovery.py` command. In a disposable source copy, added compilation-error probes are discovered automatically; removing them restores successful builds without changing the project file. Unit/UI sources stay out of app compilation and their fixtures reach only their own bundles. Target-wide `EXCLUDED_SOURCE_FILE_NAMES = *.md` excludes current and subsequently added nested scoped guidance from all products. Ordinary sources/resources need no per-file membership exceptions.

Private captures and generated outputs stay outside all synchronized source roots; ignored `.local-news/` and `DerivedData/` provide repository-local locations. The verification checks an external private-input probe is not copied into products and inspects actual app/test resources. Keep these boundaries when adding features; ignored files inside a synchronized root are still visible to Xcode and must not be used for private captures.

## Agent ownership

| Area | Owning issue | Scoped guidance when introduced |
| --- | --- | --- |
| Project, schemes, app composition, build settings | #1; later integration #9 | `Sidequest/AGENTS.md`, `Sidequest/App/AGENTS.md` |
| Shared lifecycle and ports | #2 | `Sidequest/Core/AGENTS.md` |
| Feed domain and presentation | #3 | `Sidequest/Feed/AGENTS.md` |
| News domain, snapshots, and presentation | #4 | `Sidequest/News/AGENTS.md` |
| Common game adapter conventions and retained runtime | #2/#3, coordinated with #5–#8 | `Sidequest/Games/AGENTS.md` |
| Sudoku, memory, chess, bubble shooter | #5, #6, #7, #8 respectively | Each game's `AGENTS.md` |
| Shared test/resource conventions | #1; integrated flows #9 | `SidequestTests/AGENTS.md`, `SidequestUITests/AGENTS.md` |

Create scoped guidance with the first owned sources or local decision, applying the [root decision-recording rule](../AGENTS.md#development-decisions-and-scoped-guidance). Link shared rules rather than copying them. Each feature's tests mirror its ownership under the test root; local test decisions get closer guidance when needed.

Before parallel work, claim the issue and files/interfaces in its GitHub handoff and use isolated feature checkouts. Project/build settings, shared contracts, common game guidance, and shared fixtures each need one active coordinating owner. A feature agent adding ordinary files should stay in its source and test folders. Changes to shared interfaces require coordination with dependent agents and compatible consumers; isolation alone does not resolve shared ownership.

## Handoff to foundation

Create the smallest runnable app and test targets using this tree and record real build/test/launch commands in the installation guide. Add the first scoped files for the actual foundation decisions. Report source-discovery and physical-device verification honestly. Game implementations, gameplay tests, CI, and release automation remain with their own issues.
