# Swift formatting

Use the official [swift-format](https://github.com/swiftlang/swift-format) bundled with Xcode. SwiftUI source is Swift and uses the same formatter. The committed [.swift-format](../.swift-format) is the default configuration exported from the installed Xcode 27.0 (build 27A266a) toolchain on October 3, 2026. It currently specifies two-space indentation and a 100-character line length.

## Format and check changes

From the repository root, run these commands with explicit paths to changed first-party Swift files:

```sh
xcrun swift-format format --in-place --configuration .swift-format <changed.swift> [<another.swift> ...]
xcrun swift-format lint --strict --configuration .swift-format <changed.swift> [<another.swift> ...]
```

Replace the angle-bracket arguments with actual file paths; quote paths containing spaces. Include application and test sources. Exclude generated files, dependencies, and build output. Format before committing, inspect the resulting diff, then require strict lint to exit successfully. Strict lint reports formatting and enabled style-rule violations; it does not build the app or verify gameplay.

First-party Swift sources live under `Sidequest`, `SidequestTests`, and `SidequestUITests`. The foundation's actual formatting and app verification commands are documented in [INSTALL.md](INSTALL.md#build-and-test).

## Install commit checks

From the repository root, run the installer once in each clone:

```sh
./scripts/install-git-hooks.sh
```

With no other hooks path configured and no executable native hooks, the installer selects the tracked `.githooks` directory using local `core.hooksPath`. Existing executable native hooks, including `pre-commit` and `commit-msg`, cause setup to stop with their path before changing configuration or files. Sample hooks do not block setup. Reconcile active hooks explicitly before retrying; selecting another hooks directory would disable them. Git resolves the native hooks directory, including the shared directory used by linked worktrees. Git local configuration is shared by linked worktrees belonging to the same clone, so that selection also affects those worktrees. Installing in a separate clone does not change another clone's configuration.

The existing global Tokensave setup forwards pre-commit to a repository-local hook. When the installer recognizes that exact forwarding script, it installs a small dispatcher under the current Git directory instead, preserving `core.hooksPath`, the global files, and other global hooks. Run setup for each linked worktree in this mode. The installer refuses unknown hooks paths, linked/nonregular repository hooks, and existing repository hooks it does not own; reconcile those explicitly before installing.

The hook checks staged whitespace with `git diff --cached --check`. It then strictly lints staged regular `.swift` file blobs using the staged `.swift-format`. It supports partially staged files and unusual filenames, and leaves the index and working tree unchanged. Deletions and symlinks are skipped for Swift lint. Swift lint excludes `.build`, `.swiftpm`, `build`, `DerivedData`, `Pods`, `Vendor`, `vendor`, and `Generated` at the root, plus nested `Generated` directories. All staged files still receive the whitespace check. Review these exclusions when source ownership or generated paths change.

Documentation-only commits do not require the formatter. If staged Swift files fail, use the formatting commands above, inspect the diff, and stage the intended changes before retrying. Invalid or missing staged configuration and an unavailable formatter reject commits containing Swift source. Keep builds and gameplay tests in the separate verification workflow.

The hook and installer use the system Bash and Git; Swift lint uses the existing Xcode formatter. There is no Husky/npm dependency. Hooks are local feedback and can be bypassed; successful hook execution does not replace independent review or CI verification.

To remove a direct `.githooks` selection, first confirm that `git config --local --get core.hooksPath` reports `.githooks`, then run `git config --local --unset core.hooksPath`. Any existing global hooks path becomes effective again. In Tokensave-forwarding mode, leave the configuration intact and remove only the managed dispatcher at `$(git rev-parse --absolute-git-dir)/hooks/pre-commit` after confirming it contains the Sidequest delegation marker.

## Verify tooling changes

Run these checks from the repository root with Python 3, Git, Bash, and the selected Xcode formatter available:

```sh
bash -n .githooks/pre-commit scripts/install-git-hooks.sh
python3 scripts/test-git-hooks.py
```

The integration checks exercise actual commits and installation in temporary repositories. They cover staged/unstaged differences, unusual paths, renames/deletions, whitespace failures, staged configuration, formatter availability, generated files, symlinks, staged type changes between symlinks and regular Swift source, and preservation of existing hooks configuration, repository hooks, and the Tokensave forwarding chain. Python is used for these checks only; the commit hook and installer do not require it. These are tooling checks, not app or gameplay tests.

## Toolchain and CI

Use the same selected Xcode toolchain locally and in CI. Check availability with `xcrun --find swift-format` and record `xcodebuild -version`; the installed formatter reports `main` as its version, so that string alone does not pin a reproducible formatter. The [foundation](https://github.com/devofthings/sidequest/issues/1) must select and document the app's supported toolchain. Review formatting differences when upgrading it and update the exported configuration deliberately.

The [CI task](https://github.com/devofthings/sidequest/issues/15) must add strict formatting verification for first-party Swift sources alongside the foundation's build/test commands once those sources and verified free execution exist. CI enforcement is pending; this change creates no workflow or runner. Use the bundled formatter without installing another formatting dependency.
