# Sidequest

[![PR verification](https://github.com/devofthings/sidequest/actions/workflows/verification.yml/badge.svg?event=pull_request)](https://github.com/devofthings/sidequest/actions/workflows/verification.yml)
![iOS 17+ deployment target](docs/assets/readme/ios.svg)
![Swift 6 language mode](docs/assets/readme/swift.svg)

A private iPhone prototype mixing short English news and quick games in one manually paged feed. The first test: is switching between reading and playing enjoyable enough to come back?

**[Install and run](docs/INSTALL.md)** · **[Private releases](https://github.com/devofthings/sidequest/releases)** · **[MVP board](https://github.com/users/devofthings/projects/1)** · **[Issues](https://github.com/devofthings/sidequest/issues)**

## Try it

Open `Sidequest.xcodeproj`, select the shared **Sidequest** scheme, and run on an iPhone simulator. The verified environment is Xcode 27.0 and the iOS 27.0 simulator on Apple silicon; the minimum deployment target is iOS 17.0, whose execution remains unverified. See [installation instructions](docs/INSTALL.md) for tools, commands, and troubleshooting.

| Delivery | Availability |
| --- | --- |
| Recorded MVP | [2026.10.14](https://github.com/devofthings/sidequest/releases/tag/2026.10.14), from `65bd39003a2a`, published October 4, 2026 |
| Download | Verified unsigned ARM64 simulator archive for an Apple-silicon Mac; [download and checksum instructions](docs/INSTALL.md#download-a-simulator-preview) |
| Publication | Owner-authorized manual main dispatch under [release policy](docs/RELEASES.md); merging starts no automatic main job |
| Your iPhone | Physical installation is deferred and unverified ([#79](https://github.com/devofthings/sidequest/issues/79)); [local source signing instructions](docs/INSTALL.md#install-on-your-own-iphone) are available |
| Verified checks for 2026.10.14 | 133 native tests (96 unit, 37 UI), Debug/ARM64 Release builds, and source discovery passed in the [release verification job](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111366112952); fresh tagged-source and downloaded-app installation/launch [also passed](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) |

The recorded MVP and test results describe that selected release. Later documentation updates do not create another download. Seven older preview releases and their 21 assets were removed; Git tags/source remain, including the `2026.10.7` statistics baseline. Routine verification runs on exact PR heads; merging starts no automatic main job. The workflow badge links PR verification; open its details for actual checks. Simulator archives cannot be installed directly on an iPhone.

## What's playable?

Game cards show their actual inactive boards before **Tap to play**; Memory stays face down. Starting enables play without moving or reshuffling the board. Skipping or backgrounding resets unfinished attempts; completed results survive revisits during the session.

Current source supports full-card native vertical paging: swipe up/down directly on a card or use the compact **Feed navigation** menu. Overflowing content scrolls within its card; a new outward gesture at its top/bottom edge changes cards. See [feed navigation](docs/FEED.md#navigation-and-eligibility). Game boards and primary controls retain their geometry when feedback or results change; [stable layout](docs/GAME_LAYOUT.md) describes the current source correction and verification.

| Game | Merged implementation | Details / next step |
| --- | --- | --- |
| Mini Sudoku | Playable 4×4 puzzle | [Rules, controls, and checks](docs/SUDOKU.md) |
| Memory pairs | Playable six-pair board | [Rules, controls, and checks](docs/MEMORY.md) |
| Chess puzzles | Playable one-move mates for both colors | [Rules, accessible controls, and exhaustive fixture checks](docs/CHESS.md) |
| Bubble shooter | Playable bounded challenge | [Rules, aiming, win/loss, and replay checks](docs/BUBBLES.md) |

Merged #104 source extends normal launch to endless generated Sudoku, frozen Memory layouts, attainable Bubble challenges, and reused validated Chess puzzles. Merged #106 source adds 30 clearly fictional demo stories when saved news is absent, cycles the active pool after every five games, and removes the bottom counter. Games shuffle; story order stays stable. [Demo policy](docs/DEMO_NEWS.md) describes nil-only demo resolution and five-game cadence. The immutable `2026.10.14` download retains the finite five-game deck. Use **News snapshots** in the header to import a JSON replacement through Files. Empty imports intentionally disable news; corrupt/unavailable storage stays recoverable without demo fallback. Rejected imports preserve saved bytes and the current deck. Integrated delivery and selected-release source/download installation evidence are recorded in [#9](https://github.com/devofthings/sidequest/issues/9) and the [install guide](docs/INSTALL.md#verified-mvp-delivery). The enjoyment hypothesis still needs your personal test in #10. See [news preparation and import](docs/NEWS.md). Accounts, synced preferences, and leaderboards are deferred to phase two; [MVP.md](docs/MVP.md) owns the approved scope.

## Code snapshot

<!-- sidequest:stats:start -->
| Swift source | Files | Physical lines |
| --- | ---: | ---: |
| App | 52 | 4,465 |
| Unit tests | 23 | 3,564 |
| UI tests | 14 | 2,114 |
| **Total** | **89** | **10,143** |

Swift changes since `2026.10.7` (`5dc0320e2757`): **+7,625 / −545 lines**.
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
- [Stable game layout](docs/GAME_LAYOUT.md): measured feedback regions, completion controls, and iPhone review checks.
- [Feed presentation](docs/FEED.md): manual navigation, bounded game adapters, scene handling, and injected card surfaces.
- [Demo news and cadence](docs/DEMO_NEWS.md): original fictional stories, nil-only fallback, unique appearances, and five-game cadence.
- [Endless feed](docs/ENDLESS.md): local generation, stable history, completed restoration, atomic replacement, and verification.
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

Until design agreement, verification uses [all unit tests and three UI smoke cases](docs/TESTING.md) on one owned simulator that is [deleted after the run](docs/TESTING.md#owned-simulator-cleanup-114), current-source Debug compilation, and exact-head PR checks before merge. Merging starts no automatic main job under the owner's [PR-only decision](docs/CI.md#verification-contract). Longer UI journeys remain available explicitly. The approved 123-case PR gate passed in 3 minutes 45 seconds, and main's full-gate fallback passed in 3 minutes 41 seconds with fresh install/launch and Release verification; [recorded evidence](docs/TESTING.md#measured-temporary-gate-ci) distinguishes these from the historical broader benchmark. Historical main inheritance remains available for explicitly owner-authorized manual releases; [#90](https://github.com/devofthings/sidequest/issues/90) records its proof. Focused checks do not replace exact-head CI.

The next [design baseline](https://github.com/devofthings/sidequest/issues/13) will research vivid, modern visuals and animations for a pitch-ready MVP. The [researched baseline](docs/DESIGN.md) is selected; implementation remains planned.
