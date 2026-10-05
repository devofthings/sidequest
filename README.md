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
| Your iPhone | The owner reports successful installation and gameplay ([personal test](docs/INSTALL.md#owner-reported-iphone-test)); exact device/build details remain unknown; [local source signing instructions](docs/INSTALL.md#install-on-your-own-iphone) are available |
| Verified checks for 2026.10.14 | 133 native tests (96 unit, 37 UI), Debug/ARM64 Release builds, and source discovery passed in the [release verification job](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111366112952); fresh tagged-source and downloaded-app installation/launch [also passed](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) |

The recorded MVP and test results describe that selected release. Later documentation updates do not create another download. Seven older preview releases and their 21 assets were removed; Git tags/source remain, including the `2026.10.7` statistics baseline. Routine verification runs on exact PR heads; merging starts no automatic main job. The workflow badge links PR verification; open its details for actual checks. Simulator archives cannot be installed directly on an iPhone.

## What's playable?

Game cards show their actual inactive boards with a lightweight **Tap to play** hint; tap the preview game surface or activate its accessible Start game action. Memory stays face down. Starting enables play without moving or reshuffling the board. Skipping or backgrounding resets unfinished attempts; completed results survive revisits during the session. Current source requests one system success haptic and briefly shows a readable celebration after a solved/won attempt; Bubble losses and completed revisits stay quiet. Physical vibration remains unverified pending your iPhone test.

Current #91 source adds a brief Card S introduction on cold launch while preparation and app access continue; Reduce Motion omits it. The #181 [launch canvas](docs/design/LAUNCH.md) matches the static system background to the app in light and dark appearances; native verification is pending. [Startup checks](docs/INSTALL.md#cold-launch-logo-introduction-91) distinguish the policy from pending native verification.

Current Bubble source uses left/right dragging in the lower-board aiming area and a dotted trajectory, with no visible numeric angle. Releasing a drag does not shoot; **Fire** stays explicit. A native 44-point Slider remains available for assistive and keyboard precision. See [the refinement and verification status](docs/BUBBLES.md#simplified-horizontal-aiming-163).

Current source supports full-card native vertical paging: swipe up/down directly on a card or use the compact **Feed navigation** menu. Overflowing content scrolls within its card; a new outward gesture at its top/bottom edge changes cards. See [feed navigation](docs/FEED.md#navigation-and-eligibility). Game boards and primary controls retain their geometry when feedback or results change; [stable layout](docs/GAME_LAYOUT.md) describes the current source correction and verification.

| Game | Merged implementation | Details / next step |
| --- | --- | --- |
| Pocket Sudoku | Standard9×9 source; historical4×4 fixtures | [Rules, controls, and checks](docs/SUDOKU.md) |
| Memory pairs | Playable six-pair board | [Rules, controls, and checks](docs/MEMORY.md) |
| Chess puzzles | Fixed 4×4 focus, compact normal controls, full 8×8 rules | [Rules, accessible controls, and exhaustive fixture checks](docs/CHESS.md) |
| Bubble shooter | Compact attainable three-group challenges, within eight shots | [Rules, aiming, win/loss, and replay checks](docs/BUBBLES.md) |

Current source includes a compatible [9×9 Sudoku rule foundation](docs/SUDOKU.md#standard-format-foundation-162--partial-source-support). Standard 9×9 presentation and production exposure are merged through [PR #172](https://github.com/devofthings/sidequest/pull/172), with [final focused checks, independent review and exact-head CI](docs/INSTALL.md#verified-source-refinements-october-5). Historical mini fixtures remain 4×4; difficulty classifications and labels are not implemented. The owner selected mixed Easy/Medium/Hard game cards with a label on each game, without a manual selector or automatic progression; see [the research and accepted exposure](docs/pocket-games/DIFFICULTY.md).

Merged #104 source extends normal launch to endless generated Sudoku, frozen Memory layouts, attainable Bubble challenges, and reused validated Chess puzzles. Merged #106 source adds 30 clearly fictional demo stories when saved news is absent, cycles the active pool after every five games, and removes the bottom counter. Games shuffle; story order stays stable. [Demo policy](docs/DEMO_NEWS.md) describes nil-only demo resolution and five-game cadence. The immutable `2026.10.14` download retains the finite five-game deck. Use **News snapshots** in the header to import a JSON replacement through Files. Empty imports intentionally disable news; corrupt/unavailable storage stays recoverable without demo fallback. Rejected imports preserve saved bytes and the current deck. Integrated delivery and selected-release source/download installation evidence are recorded in [#9](https://github.com/devofthings/sidequest/issues/9) and the [install guide](docs/INSTALL.md#verified-mvp-delivery). The owner completed [iPhone testing and feedback](docs/MVP.md#personal-test-outcome) in #10: keep the mixed concept and improve bland games through design, animation, and fun. News interruptions are liked; five-game cadence remains under question. Device/build details and accessibility outcomes remain unknown. See [news preparation and import](docs/NEWS.md). Accounts, synced preferences, and leaderboards are deferred to phase two; [MVP.md](docs/MVP.md) owns the approved scope.

## Code snapshot

<!-- sidequest:stats:start -->
| Swift source | Files | Physical lines |
| --- | ---: | ---: |
| App | 72 | 6,255 |
| Unit tests | 34 | 4,704 |
| UI tests | 17 | 2,953 |
| **Total** | **123** | **13,912** |

Swift changes since `2026.10.7` (`5dc0320e2757`): **+11,466 / −617 lines**.
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
- [Selected Card S identity](docs/logo-concepts/README.md): owner-approved editable artwork, local app-icon rendering, and retained concept comparisons; actual appearance verification is recorded in #14.
- [Phase-two gamification proposal](docs/gamification/README.md): per-game personal results, shared ranking credibility, and static result-screen examples; owner selection pending.
- [Vocabulary](CONTEXT.md): domain names used by issues and implementation.
- [Agent setup](docs/AGENT_SETUP.md): isolated checkout ownership, portable review skill, and read-only readiness checks.
- [Agent guidance](AGENTS.md): how to pick up and complete an issue.
- [Coding rules](docs/CODING.md): ownership, Swift interfaces, state, concurrency, errors, and verification for agents.
- [Card and lifecycle contract](docs/CONTRACT.md): stable IDs, validated news values, shuffled decks, and explicit start/reset effects.
- [Stable game layout](docs/GAME_LAYOUT.md): measured feedback regions, completion controls, and iPhone review checks.
- [Feed presentation](docs/FEED.md): manual navigation, bounded game adapters, scene handling, and injected card surfaces.
- [Demo news and cadence](docs/DEMO_NEWS.md): original fictional stories, nil-only fallback, unique appearances, and five-game cadence.
- [Endless feed](docs/ENDLESS.md): local generation, stable history, completed restoration, atomic replacement, and verification.
- [Pocket Sudoku](docs/SUDOKU.md): standard9×9 source, historical4×4 fixtures, controls, validation, and lifecycle.
- [Proposed difficulty research](docs/pocket-games/DIFFICULTY.md): selected first-pass Chess/Memory criteria, proposed Sudoku/Bubble criteria, proof plans, and accepted mixed-feed exposure; no implemented tiers.
- [Memory pairs](docs/MEMORY.md): the six-pair board, delayed mismatches, and attempt reset.
- [Chess puzzles](docs/CHESS.md): original one-move puzzles, accessible coordinates, and exhaustive fixture validation.
- [Bubble shooter](docs/BUBBLES.md): aiming, connected matches, bounded win/loss, flight cancellation, and replay.
- [Source structure](docs/STRUCTURE.md): folder ownership, game grouping, scoped guidance, and verified foundation source discovery.
- [Review gates](docs/REVIEW_GATES.md): reproducible validation, durable review evidence, and pinned merges.
- [Continuous verification](docs/CI.md): free foreground self-hosted execution, exact-commit checks, owned-command cancellation, run-specific simulator recovery, and retained local diagnostics.
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

The [design baseline](https://github.com/devofthings/sidequest/issues/13) guides vivid, modern visuals and animations for a pitch-ready MVP. The [researched baseline](docs/DESIGN.md) is selected. Shared feed/news styling is implemented; #124 adds vivid game surfaces and contained motion, with actual verification recorded in its PR. The owner selected the [pocket-game specification](docs/pocket-games/README.md): Chess uses fixed 4×4 focus windows with standard 8×8 rules and full-board coordinate controls; the original mini Sudoku choice is superseded by standard #170 while Memory remains six pairs. Difficulty remains a separate specification.

The initial [compact-game and harder Bubble follow-up](docs/POCKET_BUBBLE.md), [#135](https://github.com/devofthings/sidequest/issues/135), is complete: harder generation (#137), compact Chess/viewport controls (#142), and direct Bubble controls plus the all-game fit audit (#138 / [PR #144](https://github.com/devofthings/sidequest/pull/144)) are merged with actual native evidence. The current [#163 horizontal aiming refinement](docs/BUBBLES.md#simplified-horizontal-aiming-163) removes visible numeric angle text; its corrected native check, fresh independent review, and exact-head CI passed before [PR #165](https://github.com/devofthings/sidequest/pull/165) merged. These source changes do not alter the immutable `2026.10.14` download.

The [private Figma refinement](docs/design/PRIVATE_FIGMA.md) preserves original #157 state boards and actual browser screenshots. The owner selected its shared visual direction for #182: vivid header actions, rounded game hierarchy, and a quiet reading surface with clear provenance. Source refinements are prepared; actual native rendering and exact-head verification remain pending. Logo/startup integration is merged through [PR #184](https://github.com/devofthings/sidequest/pull/184); its [launch guidance](docs/design/LAUNCH.md) records the bounded implementation.

[Proposed icon family](docs/design/ICONS.md) includes original Chess pieces, Memory artwork, and existing app-action examples in private Figma. The lead selected Memory and current Chess artwork for bounded #171 implementation under the existing autonomous design authorization; native Memory and current Chess adoption is merged through PR173, with [actual simulator/review/CI evidence](docs/INSTALL.md#verified-source-refinements-october-5).

Committed game feedback adds restrained interaction haptics for Sudoku entries, Memory matches, and Bubble clears, with contained Bubble pop motion. Final actions use existing success feedback, including one-move Chess. See [event and lifecycle guidance](Sidequest/Games/Presentation/AGENTS.md#committed-interaction-feedback-161); unit and focused simulator verification passed through PR169; [exact evidence](docs/INSTALL.md#verified-source-refinements-october-5) separates this from physical iPhone vibration, which needs owner testing.

Original Memory faces and both-side King/Queen silhouettes are implemented in native source through [PR #173](https://github.com/devofthings/sidequest/pull/173); [game artwork guidance](docs/design/NATIVE_GAME_ART.md) records the design. Its source-bound checks are separate from the final combined Sudoku verification; the private Figma sheet alone does not verify app rendering.

Current source follow-up #170 exposes standard 9×9 Sudoku with digits 1–9, compact overview and full-size coordinate alternatives; generated cards use at most 12 editable cells as a bounded baseline, without difficulty labels. Historical mini fixtures and release evidence remain unchanged. Source49b3db9 passed all three focused native flows; final-head 375-point normal/largest checks, fresh review and exact-head CI passed before [PR #172](https://github.com/devofthings/sidequest/pull/172) merged. See [delivered refinement evidence](docs/INSTALL.md#verified-source-refinements-october-5) and [Sudoku](docs/SUDOKU.md).

The owner selected first-interaction activation under [#185](https://github.com/devofthings/sidequest/issues/185): the first valid game action starts and applies immediately. Implementation and verification remain pending; see [the policy](docs/GAME_PREVIEWS.md).
