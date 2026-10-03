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
- [Source structure](docs/STRUCTURE.md): folder ownership, game grouping, scoped guidance, and verified foundation source discovery.
- [Review gates](docs/REVIEW_GATES.md): reproducible validation, durable review evidence, and pinned merges.
- [Continuous verification](docs/CI.md): free foreground self-hosted execution, exact-commit checks, and local diagnostics.
- [Swift formatting](docs/FORMATTING.md): shared style, local commit-hook setup, and tooling checks.
- [Autonomous delivery plan](docs/AUTONOMY.md): technical ownership, start authorization, usage guardrails, and the documentation audit.
- [Installation and running](docs/INSTALL.md): verified simulator build/test/launch commands and local personal-iPhone signing steps.
- [Private release delivery](docs/RELEASES.md): build policy and traceable release history; automation is pending the app and CI.
- [GitHub Issues](https://github.com/devofthings/sidequest/issues): tasks and dependencies.
- [MVP board](https://github.com/users/devofthings/projects/1): current workflow status; see [task workflow](docs/WORKFLOW.md) for status definitions.

## Development status

The SwiftUI foundation launches in the iPhone simulator. `Sidequest.xcodeproj` provides the shared `Sidequest` scheme, app-hosted unit tests, and a UI launch test. Xcode 27.0 and the iOS 27.0 simulator were verified; the deployment target is iOS 17.0. The shared card/lifecycle contract and shuffled fictional sample session are implemented. The feed, news imports, games, gameplay tests, and published releases follow their own tickets. [CI](docs/CI.md) verifies same-repository PRs and main using this Mac while its foreground runner is active.

The user authorized app implementation on October 3, 2026; see the [autonomous delivery plan](docs/AUTONOMY.md). Start with [INSTALL.md](docs/INSTALL.md) to build, test, and run. Physical-iPhone installation is documented but remains unverified and requires local account/signing setup.

Sidequest is the working project name. Public naming availability has not been established.
