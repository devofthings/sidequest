# Swift formatting

Use the official [swift-format](https://github.com/swiftlang/swift-format) bundled with Xcode. SwiftUI source is Swift and uses the same formatter. The committed [.swift-format](../.swift-format) is the default configuration exported from the installed Xcode 27.0 (build 27A266a) toolchain on October 3, 2026. It currently specifies two-space indentation and a 100-character line length.

## Format and check changes

From the repository root, run these commands with explicit paths to changed first-party Swift files:

```sh
xcrun swift-format format --in-place --configuration .swift-format <changed.swift> [<another.swift> ...]
xcrun swift-format lint --strict --configuration .swift-format <changed.swift> [<another.swift> ...]
```

Replace the angle-bracket arguments with actual file paths; quote paths containing spaces. Include application and test sources. Exclude generated files, dependencies, and build output. Format before committing, inspect the resulting diff, then require strict lint to exit successfully. Strict lint reports formatting and enabled style-rule violations; it does not build the app or verify gameplay.

The repository has no Swift sources yet. The commands above were verified against a temporary SwiftUI-shaped fixture outside Git; they are not a Sidequest app build or test result.

## Toolchain and CI

Use the same selected Xcode toolchain locally and in CI. Check availability with `xcrun --find swift-format` and record `xcodebuild -version`; the installed formatter reports `main` as its version, so that string alone does not pin a reproducible formatter. The [foundation](https://github.com/devofthings/sidequest/issues/1) must select and document the app's supported toolchain. Review formatting differences when upgrading it and update the exported configuration deliberately.

The [CI task](https://github.com/devofthings/sidequest/issues/15) must add strict formatting verification for first-party Swift sources alongside the foundation's build/test commands once those sources and verified free execution exist. CI enforcement is pending; this change creates no workflow or runner. Use the bundled formatter without installing another formatting dependency.
