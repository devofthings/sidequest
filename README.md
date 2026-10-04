# Sidequest

[![Main verification](https://github.com/devofthings/sidequest/actions/workflows/releases.yml/badge.svg?branch=main)](https://github.com/devofthings/sidequest/actions/workflows/releases.yml)
![iOS 17+ deployment target](docs/assets/readme/ios.svg)
![Swift 6 language mode](docs/assets/readme/swift.svg)

A private iPhone prototype mixing short English news and quick games in one shuffled feed. The first test: is switching between reading and playing enjoyable enough to come back?

**[Install and run](docs/INSTALL.md)** · **[Private releases](https://github.com/devofthings/sidequest/releases)** · **[MVP board](https://github.com/users/devofthings/projects/1)** · **[Issues](https://github.com/devofthings/sidequest/issues)**

## Try it

Open `Sidequest.xcodeproj`, select the shared **Sidequest** scheme, and run on an iPhone simulator. The verified environment is Xcode 27.0 and the iOS 27.0 simulator on Apple silicon; the minimum deployment target is iOS 17.0, whose execution remains unverified. See [installation instructions](docs/INSTALL.md) for tools, commands, and troubleshooting.

| Delivery | Availability |
| --- | --- |
| Recorded development preview | [2026.10.7](https://github.com/devofthings/sidequest/releases/tag/2026.10.7), from `5dc0320e2757`, published October 3, 2026; predates the current pager |
| Download | Unsigned ARM64 simulator archive for a Mac; select a verified version from the private [release history](https://github.com/devofthings/sidequest/releases) |
| Next release | Held until reviewed MVP integration readiness; afterward, explicit manual dispatch under [release policy](docs/RELEASES.md) |
| Your iPhone | Physical installation is deferred and unverified ([#79](https://github.com/devofthings/sidequest/issues/79)); [local source signing instructions](docs/INSTALL.md#install-on-your-own-iphone) are available |
| Verified checks for 2026.10.7 | Debug build, unit/UI tests (16 UI tests), and ARM64 Release build passed in the [release verification job](https://github.com/devofthings/sidequest/actions/runs/37158924819/job/111308053366) |

The recorded preview and test results describe that release, rather than the latest source or a completed MVP. Main updates continue native verification without automatic publication. The workflow badge links the latest main run; open its details for actual checks. Simulator archives cannot be installed directly on an iPhone.

## What's playable?

Game cards require **Tap to play**. Skipping or backgrounding resets unfinished attempts; completed results survive revisits during the session.

Current source supports full-card native vertical paging: swipe up/down directly on a card or use the compact **Feed navigation** menu. Overflowing content scrolls within its card; a new outward gesture at its top/bottom edge changes cards. See [feed navigation](docs/FEED.md#navigation-and-eligibility).

| Game | Merged implementation | Details / next step |
| --- | --- | --- |
| Mini Sudoku | Playable 4×4 puzzle | [Rules, controls, and checks](docs/SUDOKU.md) |
| Memory pairs | Playable six-pair board | [Rules, controls, and checks](docs/MEMORY.md) |
| Chess puzzles | Playable one-move mates for both colors | [Rules, accessible controls, and exhaustive fixture checks](docs/CHESS.md) |
| Bubble shooter | Playable bounded challenge | [Rules, aiming, win/loss, and replay checks](docs/BUBBLES.md) |

The feed currently uses clearly labeled fictional news. Manual English snapshot imports are implemented in a standalone Debug preview; connecting saved imports to the mixed feed is pending [#9](https://github.com/devofthings/sidequest/issues/9). See [news preparation and import](docs/NEWS.md). Accounts, synced preferences, and leaderboards are deferred to phase two; [MVP.md](docs/MVP.md) owns the approved scope.

## Code snapshot

<!-- sidequest:stats:start -->
| Swift source | Files | Physical lines |
| --- | ---: | ---: |
| App | 40 | 3,133 |
| Unit tests | 17 | 1,955 |
| UI tests | 10 | 1,056 |
| **Total** | **67** | **6,144** |

Swift changes since `2026.10.7` (`5dc0320e2757`): **+3,287 / −206 lines**.
<!-- sidequest:stats:end -->

These are physical lines, including blanks and comments, in Git-tracked `.swift` files under the app, unit-test, and UI-test roots. Counts describe source volume, not coverage or quality. Untracked files and personal news are excluded. Changes compare working-tree Swift source with the explicit release baseline above; README edits do not count toward that comparison. File moves count as additions/deletions.

From the repository root, refresh the table in the same feature PR when Swift source changes. Stage new source files before counting. Fetch the selected release tag if it is missing locally:

```sh
python3 scripts/readme-stats.py --baseline 2026.10.7 --write
```

Omit `--write` to print statistics without editing files. The dependency-free command replaces only the marked block; it makes no network calls or commits. Verify changes with `python3 scripts/test-readme-stats.py` and `python3 scripts/check-documentation.py`. Keep the selected baseline until intentionally choosing another verified release; the generator does not refresh game readiness or release/test claims.

## Pick up the project

Agents start with [AGENTS.md](AGENTS.md), the [MVP brief](docs/MVP.md), [decisions](docs/DECISIONS.md), and the assigned issue. Use [agent setup](docs/AGENT_SETUP.md) for an isolated feature branch, then follow the [workflow](docs/WORKFLOW.md) and [fresh-agent review process](docs/REVIEW.md). The [autonomous delivery plan](docs/AUTONOMY.md) records authorization and limits. Implementation is authorized; spending and recurring runs require their own approval.

<details>
<summary>Development documentation</summary>

- [MVP brief](docs/MVP.md): confirmed product direction and delivery sequence.
- [Project decisions](docs/DECISIONS.md): accepted choices, proposals, and source research.
- [Vocabulary](CONTEXT.md): domain names used by issues and implementation.
- [Agent setup](docs/AGENT_SETUP.md): isolated checkout ownership, portable review skill, and read-only readiness checks.
- [Agent guidance](AGENTS.md): how to pick up and complete an issue.
- [Coding rules](docs/CODING.md): ownership, Swift interfaces, state, concurrency, errors, and verification for agents.
- [Card and lifecycle contract](docs/CONTRACT.md): stable IDs, validated news values, shuffled decks, and explicit start/reset effects.
- [Feed presentation](docs/FEED.md): manual navigation, retained game runtimes, scene handling, and injected card surfaces.
- [Mini Sudoku](docs/SUDOKU.md): the 4×4 board, controls, fixture validation, and lifecycle behavior.
- [Memory pairs](docs/MEMORY.md): the six-pair board, delayed mismatches, and attempt reset.
- [Chess puzzles](docs/CHESS.md): original one-move puzzles, accessible coordinates, and exhaustive fixture validation.
- [Bubble shooter](docs/BUBBLES.md): aiming, connected matches, bounded win/loss, flight cancellation, and replay.
- [Source structure](docs/STRUCTURE.md): folder ownership, game grouping, scoped guidance, and verified foundation source discovery.
- [Review gates](docs/REVIEW_GATES.md): reproducible validation, durable review evidence, and pinned merges.
- [Continuous verification](docs/CI.md): free foreground self-hosted execution, exact-commit checks, and local diagnostics.
- [Swift formatting](docs/FORMATTING.md): shared style, local commit-hook setup, and tooling checks.
- [Autonomous delivery plan](docs/AUTONOMY.md): technical ownership, start authorization, usage guardrails, and the documentation audit.
- [Manual news imports](docs/NEWS.md): prepare, validate, replace, and privately retain English snapshots.
- [Installation and running](docs/INSTALL.md): verified simulator build/test/launch commands and local personal-iPhone signing steps.
- [Private release delivery](docs/RELEASES.md): MVP publication hold, manual verified releases, and `YYYY.MM.build` versions with full source provenance.
- [GitHub Issues](https://github.com/devofthings/sidequest/issues): tasks and dependencies.
- [MVP board](https://github.com/users/devofthings/projects/1): current workflow status; see [task workflow](docs/WORKFLOW.md) for status definitions.

</details>

Sidequest is the working project name. Public naming availability has not been established.
