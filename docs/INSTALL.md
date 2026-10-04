# Install and run Sidequest

## Verified foundation

`Sidequest.xcodeproj` contains the shared `Sidequest` scheme, iPhone app, app-hosted unit tests, and UI tests. The feed uses fictional sample news, playable mini Sudoku, memory pairs, one-move chess puzzles, and a bubble shooter. Manual news imports are available in the standalone Debug preview while imported-news feed integration follows #9. Local simulator builds, tests, installation, and launch are verified; [Sudoku verification](SUDOKU.md#verification) records its passed delivery checks; [Memory verification](MEMORY.md#verification) records its passed focused checks and points to live PR gates. The owner chose simulator-first delivery in resolved [#79](https://github.com/devofthings/sidequest/issues/79); physical-iPhone signing and installation are deferred and unverified. The documented source-signing route requires your local Apple Account and signing configuration. [CI](CI.md) uses the same verified toolchain on a foreground self-hosted Mac runner. The retained [2026.10.7 development preview](https://github.com/devofthings/sidequest/releases/tag/2026.10.7) is an ARM64 simulator build, not the finished MVP. Older preview downloads were cleaned up at the user’s request; Git tags/source remain. Next publication is held until actual MVP readiness under [RELEASES.md](RELEASES.md).

| Setting | Verified value |
| --- | --- |
| Toolchain | Xcode 27.0, build 27A266a; bundled Swift 6.4 |
| SDK/runtime | iOS simulator SDK 27.0; iOS 27.0 runtime, build 24A434, Apple silicon |
| Destination | iPhone 18 Pro simulator |
| Minimum deployment target | iOS 17.0; execution on an iOS 17 runtime/device is not verified |
| Swift isolation | Swift 6 language mode, complete concurrency checking, nonisolated compiler default; UI explicitly `@MainActor` |
| Default app identifier | `dev.devofthings.sidequest`; personal signing overrides stay outside Git |

Use this toolchain for reproducible verification. Other Xcode versions/runtimes need their own checks before being reported as supported. The minimum version avoids requiring a newer OS when the selected SwiftUI foundation needs no newer API.

## Get the source and tools

You need access to the private repository. Use your existing checkout or clone it into a new directory:

```sh
gh repo clone devofthings/sidequest
cd sidequest
```

Install commit checks explicitly with `bash scripts/install-git-hooks.sh`; the installer preserves recognized existing hooks and refuses unknown configurations. Agents follow [agent setup](AGENT_SETUP.md) and [review gates](REVIEW_GATES.md) before edits or merging. Git, Python 3, authenticated `gh`, and the Xcode-bundled formatter are used by the local tooling; the app has no third-party dependencies.

Check Xcode and available runtimes:

```sh
xcodebuild -version
xcrun swift -version
xcrun simctl list runtimes
```

If the iOS 27.0 runtime is missing, use Xcode > Settings > Components, or Apple's included runtime installer:

```sh
xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS -buildVersion 27.0 -architectureVariant arm64
```

The verified Apple-silicon download was approximately 8.05 GB. Check free disk space before installation; download and installed runtime storage both need room. Apple's [component-installation guide](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components) documents these commands. No paid service, Developer Program membership, or billing setup is needed for simulator execution. Follow the project spending rule for any potentially chargeable alternative.

## Build and test

Run from the repository root. Xcode also supports opening `Sidequest.xcodeproj`, selecting `Sidequest`, and choosing the available iPhone simulator.

```sh
xcodebuild -project Sidequest.xcodeproj -scheme Sidequest \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

xcodebuild -project Sidequest.xcodeproj -scheme Sidequest \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test

xcrun swift-format lint --strict --recursive --configuration .swift-format \
  Sidequest SidequestTests SidequestUITests
```

The shared scheme includes foundation membership/fixture checks, shared contract, news, feed-controller, and Sudoku/Memory/Chess/bubble-shooter rule/controller tests, plus running-app tests for launch, news provenance/importer access, start, skip/reset, completion retention, independent game/navigation gestures, scene changes, empty/end states, and Sudoku/Memory/Chess gameplay. The generic feed harness uses provisional demos independently of game rules; Sudoku checks use validated original fixtures. See [SUDOKU.md](SUDOKU.md#verification) and [MEMORY.md](MEMORY.md#verification) for actual passed checks and live gate references. See [CHESS.md](CHESS.md) for exhaustive original-fixture validation and actual Chess checks. Bubble aim/fire/win/loss/replay/skip checks are described in [BUBBLES.md](BUBBLES.md). Imported-news feed integration follows #9. Use `-resultBundlePath /absolute/new/path.xcresult` to retain test evidence; Xcode requires a path that does not already exist.

For a local Release simulator build, use the same build command with `-configuration Release`. This produces a local build, not a published GitHub release.

Run the source-discovery verification after changing project membership or exclusions:

```sh
python3 scripts/verify-source-discovery.py \
  --destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0'
```

It copies the app/project/test roots into a disposable directory, injects compilation/resource probes there, and verifies app/test target separation, source addition/removal, fixture copying, and nested Markdown exclusion without changing the source checkout or project file. Expected failing probe builds are checks, not app defects. See [source ownership](STRUCTURE.md#source-discovery).

## Install and launch in the simulator

Find the available iPhone 18 Pro UDID and assign it to the task-specific variable below. Use the UDID from your Mac, not another machine's identifier:

```sh
xcrun simctl list devices available
SIDEQUEST_SIMULATOR_ID='paste-your-iPhone-18-Pro-UDID-here'
```

If that device is Shutdown, boot it; skip the boot command if already Booted:

```sh
xcrun simctl boot "$SIDEQUEST_SIMULATOR_ID"
xcrun simctl bootstatus "$SIDEQUEST_SIMULATOR_ID" -b
xcrun simctl install "$SIDEQUEST_SIMULATOR_ID" \
  DerivedData/Build/Products/Debug-iphonesimulator/Sidequest.app
xcrun simctl launch "$SIDEQUEST_SIMULATOR_ID" dev.devofthings.sidequest
```

Open Simulator to see the window. Normal launch shows Sidequest's shuffled sample feed. Swipe up/down directly on the card or open Feed navigation for Previous card/Next card. Overflowing card content scrolls first; a new outward gesture at its top/bottom edge changes cards. Game cards stay at Tap to play until explicitly started. On Sudoku, select an editable cell and use 1–4 or Clear selected cell; see [SUDOKU.md](SUDOKU.md) for rules and feedback. On Memory, flip two cards to find a matching pair; see [MEMORY.md](MEMORY.md) for rules and feedback. On Chess, select an own-side piece on the board or through its larger button, choose a destination directly or with file/rank menus and Submit move, and find checkmate in one move. Both original color fixtures appear as separate cards; see [CHESS.md](CHESS.md). For the bubble shooter, use Aim and Fire to clear connected matching letters; win by clearing the board, or replay after a win/loss. See [BUBBLES.md](BUBBLES.md) for the challenge and verification. Skipping or backgrounding resets unfinished play. Completed results survive returning to their card. See [FEED.md](FEED.md) for adapter ownership and test-only routes. Simulator builds run on a Mac and cannot be installed on a physical iPhone.

## Download a simulator preview

Publication is currently held until reviewed MVP readiness; local source builds remain available. For an existing download, select its exact release tag (`YYYY.MM.build` for new publisher runs, or historical `preview-<full-SHA>`) from the private [release history](https://github.com/devofthings/sidequest/releases). The ARM64 simulator archive requires an Apple-silicon Mac and the verified iOS 27.0 (24A434) runtime above. It cannot be installed directly on an iPhone.

```sh
SIDEQUEST_PREVIEW_TAG='paste-exact-published-release-tag-here'
SIDEQUEST_PREVIEW_DIRECTORY="$(mktemp -d /private/tmp/sidequest-preview.XXXXXX)"
gh release download "$SIDEQUEST_PREVIEW_TAG" --repo devofthings/sidequest \
  --pattern 'Sidequest-simulator-arm64.zip' --pattern 'build-metadata.json' \
  --pattern 'SHA256SUMS' --dir "$SIDEQUEST_PREVIEW_DIRECTORY"
cd "$SIDEQUEST_PREVIEW_DIRECTORY"
shasum -a 256 -c SHA256SUMS
ditto -x -k Sidequest-simulator-arm64.zip "$SIDEQUEST_PREVIEW_DIRECTORY"
```

Require both checksums to pass before extracting/installing. Inspect `build-metadata.json` for the full commit, original verification link, runtime, and app identifier. New-format metadata also binds the original workflow run number and UTC creation timestamp to the selected tag; do not invent a tag from today’s date or treat an example version as available. Assign `SIDEQUEST_SIMULATOR_ID` from the available devices as above, boot it if needed, then install and launch:

```sh
xcrun simctl install "$SIDEQUEST_SIMULATOR_ID" "$SIDEQUEST_PREVIEW_DIRECTORY/Sidequest.app"
xcrun simctl launch "$SIDEQUEST_SIMULATOR_ID" dev.devofthings.sidequest
```

For that version's source, use a fresh clone to preserve any existing work, fetch its tag, and check out the tag before opening Xcode:

```sh
gh repo clone devofthings/sidequest sidequest-preview-source
cd sidequest-preview-source
git fetch origin "refs/tags/$SIDEQUEST_PREVIEW_TAG:refs/tags/$SIDEQUEST_PREVIEW_TAG"
git checkout --detach "$SIDEQUEST_PREVIEW_TAG"
```

Use the local signing steps below for a physical iPhone. [RELEASES.md](RELEASES.md) explains retry, traceability, and the first/second release demonstrations; an unmerged workflow or draft is not an available build.

## Install on your own iPhone

These steps are documented but have not been verified with a physical Sidequest device:

1. Sign in to your Apple Account in Xcode > Settings > Accounts. Choose a free Personal Team for your own-device testing; no paid membership is required. Apple's [account guidance](https://developer.apple.com/help/account/basics/about-your-developer-account) describes its limits, including seven-day provisioning profiles.
2. Create the ignored file `Sidequest.xcodeproj/LocalSigning.xcconfig`. Set `DEVELOPMENT_TEAM` to your local team identifier. If the default app identifier is unavailable for your team, also set `SIDEQUEST_BUNDLE_IDENTIFIER` to a unique identifier. The tracked `Signing.xcconfig` includes these local overrides; all app/test identifiers derive from the same base. Keep this file outside Git and review `git status` before committing anything.
3. Connect and pair an iPhone running iOS 17 or later. Enable Developer Mode following [Apple's guide](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. Open `Sidequest.xcodeproj`, select the shared `Sidequest` scheme and your iPhone, and use Run. Xcode manages local development signing using your ignored configuration. Follow account/device prompts yourself; agents do not collect account credentials or signing secrets.

After a Personal Team profile expires, rebuilding and reinstalling may be necessary. A device signing or runtime failure needs its actual error investigated; simulator success is not proof of physical-device installation. App Store and TestFlight distribution remain separately authorized work.

## Content, versions, and troubleshooting

Keep real personal news captures in ignored `.local-news/` or another directory outside `Sidequest`, `SidequestTests`, and `SidequestUITests`. Use [NEWS.md](NEWS.md) to prepare a version 1 JSON file, import and validate it through the feed’s News snapshots button, and replace the saved set. Only fictional samples/schema are bundled. Fictional test fixtures are isolated in their test bundles.

Normal launch mixes your saved snapshots with Sudoku, Memory, two Chess puzzles, and Bubble shooter. Tap the newspaper button (**News snapshots**) in the feed header, then **Import news JSON** and select the file in native Files. Successful selection replaces the complete news set and starts a new shuffled session. Missing or empty news leaves the real games available; invalid input preserves the prior deck and saved bytes. Opening the library resets unfinished play; completed results survive closing or canceling it. See [NEWS.md](NEWS.md) for reserved IDs, format, persistence, and recovery.

For deterministic integration checks, a Debug build can launch with `-sidequest-integration-fixtures -sidequest-integration-reset`. It creates original fictional valid/empty/malformed/reserved-ID JSON under **On My iPhone → Sidequest → Sidequest Fixtures** and uses an isolated persistent test store. Remove the reset argument to test persistence across relaunch. Debug exposes Documents to Files; Release excludes these fixture/reset routes and file-sharing keys. To try private captures in the simulator, place your JSON in its Debug Documents directory using the app’s data-container path, select it with Files, and keep the file outside Git. On iPhone, AirDrop or another existing Files location works without enabling app file sharing.

The older standalone Debug fixture route `-sidequest-news-preview` still provides **Read news** for its original tests. Production does not use fictional news or demo games. Release ignores all fixture flags. A successful simulator run establishes neither physical signing/install nor device VoiceOver/iOS17 behavior; those remain unverified until exercised.

Generated output belongs in ignored `DerivedData/`, `build/`, or an external build directory, outside synchronized source roots. Keep scoped `AGENTS.md` guidance in its owning folder; all target Markdown is excluded from built resources.

If Xcode reports no destination, check `xcrun simctl list runtimes` and `xcrun simctl list devices available`; unavailable entries with missing runtime profiles cannot run the app. Install the matching runtime rather than claiming a build or test passed. If simulator access is denied in a sandbox, run the approved build/simulator commands with their required local filesystem access.

Published versions appear in the private [GitHub Releases page](https://github.com/devofthings/sidequest/releases) only after an eligible, explicitly dispatched [release workflow](RELEASES.md). Main verification alone produces no new download. Its initial asset is a simulator archive; source plus local Xcode signing remains the personal-iPhone path.
