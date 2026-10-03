# Source layout and ownership

Selected for [issue #29](https://github.com/devofthings/sidequest/issues/29). The tree below is planned: no app sources, targets, or test bundles exist yet. [Foundation #1](https://github.com/devofthings/sidequest/issues/1) creates and verifies this layout after app development is authorized.

## Planned tree

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

The foundation must verify this choice in an actual project: a newly added source builds without a per-file project edit; removing it removes it from compilation; unit/UI test sources stay out of the app target; fixture resources reach only their intended bundles; and `AGENTS.md`, private captures, and generated outputs stay out of build resources. Document target exclusions and any membership exceptions. If the selected toolchain cannot satisfy these checks, record an evidence-based replacement before enabling feature work. Source discovery is selected, but not executable or verified yet.

## Agent ownership

| Area | Owning issue | Scoped guidance when introduced |
| --- | --- | --- |
| Project, schemes, app composition, build settings | #1; later integration #9 | `Sidequest/AGENTS.md`, `Sidequest/App/AGENTS.md` |
| Shared lifecycle and ports | #2 | `Sidequest/Core/AGENTS.md` |
| Feed domain and presentation | #3 | `Sidequest/Feed/AGENTS.md` |
| News domain, snapshots, and presentation | #4 | `Sidequest/News/AGENTS.md` |
| Common game adapter conventions | #2, coordinated with #3–#8 | `Sidequest/Games/AGENTS.md` |
| Sudoku, memory, chess, bubble shooter | #5, #6, #7, #8 respectively | Each game's `AGENTS.md` |
| Shared test/resource conventions | #1; integrated flows #9 | `SidequestTests/AGENTS.md`, `SidequestUITests/AGENTS.md` |

Create scoped guidance with the first owned sources or local decision, applying the [root decision-recording rule](../AGENTS.md#development-decisions-and-scoped-guidance). Link shared rules rather than copying them. Each feature's tests mirror its ownership under the test root; local test decisions get closer guidance when needed.

Before parallel work, claim the issue and files/interfaces in its GitHub handoff and use isolated feature checkouts. Project/build settings, shared contracts, common game guidance, and shared fixtures each need one active coordinating owner. A feature agent adding ordinary files should stay in its source and test folders. Changes to shared interfaces require coordination with dependent agents and compatible consumers; isolation alone does not resolve shared ownership.

## Handoff to foundation

Create the smallest runnable app and test targets using this tree and record real build/test/launch commands in the installation guide. Add the first scoped files for the actual foundation decisions. Report source-discovery and physical-device verification honestly. Game implementations, gameplay tests, CI, and release automation remain with their own issues.
