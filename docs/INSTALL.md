# Install and run Sidequest

## Verified foundation

`Sidequest.xcodeproj` contains the shared `Sidequest` scheme, iPhone app, app-hosted unit tests, and UI tests. The minimal launch screen is implemented; news, games, and their integrated flows follow their owning issues. Local simulator builds, tests, installation, and launch are verified. Physical-iPhone installation remains unverified and requires your local Apple Account and signing configuration. [CI](CI.md) uses the same verified toolchain on a foreground self-hosted Mac runner. Downloadable releases remain pending.

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

The shared scheme runs two unit checks for host identity and fixture isolation and one UI check that launches the app and reads its accessible heading. These verify the foundation; gameplay and critical integrated-flow tests are added after their behavior exists. Use `-resultBundlePath /absolute/new/path.xcresult` to retain test evidence; Xcode requires a path that does not already exist.

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

Open Simulator to see the window. After the first launch renders, the screen displays “Sidequest” and “A little news. A little play.” Simulator builds run on a Mac and cannot be installed on a physical iPhone.

## Install on your own iPhone

These steps are documented but have not been verified with a physical Sidequest device:

1. Sign in to your Apple Account in Xcode > Settings > Accounts. Choose a free Personal Team for your own-device testing; no paid membership is required. Apple's [account guidance](https://developer.apple.com/help/account/basics/about-your-developer-account) describes its limits, including seven-day provisioning profiles.
2. Create the ignored file `Sidequest.xcodeproj/LocalSigning.xcconfig`. Set `DEVELOPMENT_TEAM` to your local team identifier. If the default app identifier is unavailable for your team, also set `SIDEQUEST_BUNDLE_IDENTIFIER` to a unique identifier. The tracked `Signing.xcconfig` includes these local overrides; all app/test identifiers derive from the same base. Keep this file outside Git and review `git status` before committing anything.
3. Connect and pair an iPhone running iOS 17 or later. Enable Developer Mode following [Apple's guide](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. Open `Sidequest.xcodeproj`, select the shared `Sidequest` scheme and your iPhone, and use Run. Xcode manages local development signing using your ignored configuration. Follow account/device prompts yourself; agents do not collect account credentials or signing secrets.

After a Personal Team profile expires, rebuilding and reinstalling may be necessary. A device signing or runtime failure needs its actual error investigated; simulator success is not proof of physical-device installation. App Store and TestFlight distribution remain separately authorized work.

## Content, versions, and troubleshooting

Keep real personal news captures in ignored `.local-news/` or another directory outside `Sidequest`, `SidequestTests`, and `SidequestUITests`. News import format and replacement commands follow [issue #4](https://github.com/devofthings/sidequest/issues/4); no import is implemented in the foundation. Fictional test fixtures are isolated in their test bundles.

Generated output belongs in ignored `DerivedData/`, `build/`, or an external build directory, outside synchronized source roots. Keep scoped `AGENTS.md` guidance in its owning folder; all target Markdown is excluded from built resources.

If Xcode reports no destination, check `xcrun simctl list runtimes` and `xcrun simctl list devices available`; unavailable entries with missing runtime profiles cannot run the app. Install the matching runtime rather than claiming a build or test passed. If simulator access is denied in a sandbox, run the approved build/simulator commands with their required local filesystem access.

Published versions will appear in the private [GitHub Releases page](https://github.com/devofthings/sidequest/releases) after [release automation](RELEASES.md) exists. Its initial asset is a simulator archive; source plus local Xcode signing remains the personal-iPhone path.
