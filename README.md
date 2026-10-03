# sidequest

A private SwiftUI iPhone MVP combining short English news snapshots, Sudoku, memory pairs, chess puzzles, and a bubble shooter in one shuffled feed.

## Start here

- [MVP brief](docs/MVP.md): confirmed product direction and delivery sequence.
- [Project decisions](docs/DECISIONS.md): accepted choices, proposals, and source research.
- [Vocabulary](CONTEXT.md): domain names used by issues and implementation.
- [Agent setup](docs/AGENT_SETUP.md): isolated checkout ownership, portable review skill, and read-only readiness checks.
- [Agent guidance](AGENTS.md): how to pick up and complete an issue.
- [Coding rules](docs/CODING.md): ownership, Swift interfaces, state, concurrency, errors, and verification for agents.
- [Card and lifecycle contract](docs/CONTRACT.md): stable IDs, validated news values, shuffled decks, and explicit start/reset effects.
- [Feed presentation](docs/FEED.md): manual navigation, retained game runtimes, scene handling, and injected card surfaces.
- [Source structure](docs/STRUCTURE.md): folder ownership, game grouping, scoped guidance, and verified foundation source discovery.
- [Review gates](docs/REVIEW_GATES.md): reproducible validation, durable review evidence, and pinned merges.
- [Continuous verification](docs/CI.md): free foreground self-hosted execution, exact-commit checks, and local diagnostics.
- [Swift formatting](docs/FORMATTING.md): shared style, local commit-hook setup, and tooling checks.
- [Autonomous delivery plan](docs/AUTONOMY.md): technical ownership, start authorization, usage guardrails, and the documentation audit.
- [Manual news imports](docs/NEWS.md): prepare, validate, replace, and privately retain English snapshots.
- [Installation and running](docs/INSTALL.md): verified simulator build/test/launch commands and local personal-iPhone signing steps.
- [Private release delivery](docs/RELEASES.md): exact-commit preview workflow, traceable assets, and publication/retry policy.
- [GitHub Issues](https://github.com/devofthings/sidequest/issues): tasks and dependencies.
- [MVP board](https://github.com/users/devofthings/projects/1): current workflow status; see [task workflow](docs/WORKFLOW.md) for status definitions.

## Development status

The SwiftUI feed hosts a once-shuffled fictional sample session with explicit tap-to-play game demos, a vertical swipe rail, and accessible Previous/Next controls. Skipping or backgrounding resets unfinished play; completed demo state survives revisits. Manual news imports with sourced, dated cards are implemented in a standalone Debug preview; imported-news integration and the four game implementations follow their own tickets. `Sidequest.xcodeproj` provides the shared `Sidequest` scheme and unit/UI tests. Xcode 27.0 and the iOS 27.0 simulator were verified; the deployment target is iOS 17.0. [CI](docs/CI.md) verifies same-repository PRs and main on the foreground Mac runner. The private preview workflow verifies and publishes successful main updates; see [release guidance](docs/RELEASES.md) for actual availability.

The user authorized app implementation on October 3, 2026; see the [autonomous delivery plan](docs/AUTONOMY.md). Start with [INSTALL.md](docs/INSTALL.md) to build, test, and run. Physical-iPhone installation is documented but remains unverified and requires local account/signing setup.

Sidequest is the working project name. Public naming availability has not been established.
