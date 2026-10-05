# Install and run Sidequest

## Verified foundation

`Sidequest.xcodeproj` contains the shared `Sidequest` scheme, iPhone app, app-hosted unit tests, and UI tests. Merged #104 source provides endless generated Sudoku, frozen Memory layouts, attainable Bubble challenges, and repeated validated Chess puzzles. Merged #106 source adds 30 clearly fictional demo stories only when saved news is absent, cycles the active pool after every five games, and removes the bottom counter. Valid saved news stays authoritative, saved empty news permits games only, and storage errors remain recoverable. **News snapshots** opens native Files imports. The immutable `2026.10.14` download and explicit historical Debug routes retain their finite decks; the release evidence below describes that download.

The [2026.10.14 MVP](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) passed 133 native tests and separate installations of freshly built tagged source and the downloaded ARM64 simulator archive. [Verified delivery](#verified-mvp-delivery) records the exact source, checksums, and evidence. [CI](CI.md) uses the same toolchain on a foreground self-hosted Mac runner. Seven older preview downloads were removed; Git tags/source remain. Routine verification runs on PRs; merging starts no automatic main job under #112. Explicit owner-authorized manual release verification/publication follows [RELEASES.md](RELEASES.md).

The owner chose simulator-first delivery in resolved [#79](https://github.com/devofthings/sidequest/issues/79). The owner reported successful iPhone installation and basic play on October 5, 2026; see [the report and its limits](#owner-reported-iphone-test). The documented source-signing route requires your local Apple Account and signing configuration; the simulator archive cannot run on a physical iPhone.

| Setting | Verified value |
| --- | --- |
| Toolchain | Xcode 27.0, build 27A266a; bundled Swift 6.4 |
| SDK/runtime | iOS simulator SDK 27.0; iOS 27.0 runtime, build 24A434, Apple silicon |
| Destination | iPhone 18 Pro simulator |
| Minimum deployment target | iOS 17.0; execution on an iOS 17 runtime/device is not verified |
| Swift isolation | Swift 6 language mode, complete concurrency checking, nonisolated compiler default; UI explicitly `@MainActor` |
| Default app identifier | `dev.devofthings.sidequest`; personal signing overrides stay outside Git |

Use this toolchain for reproducible verification. Other Xcode versions/runtimes need their own checks before being reported as supported. The minimum version avoids requiring a newer OS when the selected SwiftUI foundation needs no newer API.

## Verified MVP delivery

[2026.10.14](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) was published October 4, 2026 at 05:19:00 UTC from `65bd39003a2a22dbb3c19f61cbb4b9e86c3c32b9`. Its manual workflow run `37178518287` was originally created at `2026-10-04T04:58:13Z`; live run number `14` establishes the calendar/build version.

| Check | Actual result |
| --- | --- |
| [Release verification](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111366112952) | 133 tests passed: 96 unit and 37 running-app tests; zero failures, skips, or runtime warnings; Debug/ARM64 Release builds, strict lint, source discovery, and offline tooling passed |
| [Fresh tagged-source installation](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) | Clean checkout of the actual published tag; ARM64 Release build, installation, and normal launch passed on the owned iOS 27 simulator |
| [Downloaded-app installation](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) | All three server asset digests, both `SHA256SUMS` entries, metadata/source/run provenance, and archive safety passed; installation and normal launch passed; installed executable matched the extracted published executable |

Both normal Release launches showed a real game preview with **Tap to play** and five game cards with no saved news or Debug flags. The native integration suite separately verifies mixed news imports, persistence/rejection/cancellation, all game lifecycles, larger text, source links, and actual Reduce Motion. Physical-device signing/install, device VoiceOver, and iOS 17 execution remain unverified; the tested runtime is iOS 27. Release version `2026.10.14` is the tag/metadata identity; the app bundle retains version `0.1.0`, build `1`.

The archive SHA-256 is `5b613f043cd533eabfd9e4d3939dd9fcfe7d9e2f1ae1f2da727784ba7cfa8ad0`. Always verify the downloaded checksum file rather than relying on this prose alone. Fresh local source and published binaries were independently installed; bit-for-bit equality between separate builds is not claimed.

The metadata’s installation URL pins the immutable release-source guide. This current guide adds post-publication proof; later documentation changes do not retarget the release or publish another app. [Issue #9](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) retains commands and evidence; screenshots and private captures stay outside Git.

Current source also corrects feedback/result layout under [#108](https://github.com/devofthings/sidequest/issues/108): game boards and primary controls keep their geometry at a fixed viewport/text size. During personal testing, cause a Memory mismatch, complete Chess, and win/replay Bubble while keeping the scroll position unchanged. Repeat with larger text after revealing the controls. See [the Review checklist](GAME_LAYOUT.md#personal-iphone-review); that specific layout checklist remains unverified on a physical device.

## Owner-reported iPhone test

On October 5, 2026 (Europe/Berlin), the owner confirmed that they installed Sidequest on their iPhone and could play it, then provided [product feedback in #10](https://github.com/devofthings/sidequest/issues/10#issuecomment-5995830255). Installation and basic gameplay are complete by owner report; #79's earlier simulator-first deferral no longer describes these activities as pending. The report is separate from the exact agent-run simulator/release evidence above.

Device model, iOS version, exact installed source/build, and news snapshot dates remain unknown. No detailed per-game/news checks, physical haptic result, or device VoiceOver outcome was supplied. This report certifies no unmerged PR or exact release and does not establish iOS 17 execution. Preserve those limits in later Review handoffs. [The personal-test outcome](MVP.md#personal-test-outcome) records the feedback and refinement priorities; #10 is closed for actual testing and feedback.

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

The shared scheme includes foundation membership/fixture checks, shared contract, news, feed-controller, and Sudoku/Memory/Chess/bubble-shooter rule/controller tests, plus running-app tests for launch, news provenance/importer access, start, skip/reset, completion retention, independent game/navigation gestures, scene changes, empty/end states, and Sudoku/Memory/Chess gameplay. The generic feed harness uses provisional demos independently of game rules; Sudoku checks use validated original fixtures. See [SUDOKU.md](SUDOKU.md#verification) and [MEMORY.md](MEMORY.md#verification) for actual passed checks and live gate references. See [CHESS.md](CHESS.md) for exhaustive original-fixture validation and actual Chess checks. Bubble aim/fire/win/loss/replay/skip checks are described in [BUBBLES.md](BUBBLES.md). Integration #9 adds immutable startup/cancellation and atomic import tests, plus native Files replacement/rejection/empty/cancel/relaunch, modal lifecycle, and imported-news overflow/source-link/Reduce Motion checks. Actual selected-release source and downloaded-app installation passed for `2026.10.14`; see [delivery evidence](#verified-mvp-delivery). Use `-resultBundlePath /absolute/new/path.xcresult` to retain test evidence; Xcode requires a path that does not already exist.

For a local Release simulator build, use the same build command with `-configuration Release`. This produces a local build, not a published GitHub release.

Run the source-discovery verification after changing project membership or exclusions:

```sh
python3 scripts/verify-source-discovery.py \
  --destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0'
```

It copies the app/project/test roots into a disposable directory, injects compilation/resource probes there, and verifies app/test target separation, source addition/removal, fixture copying, and nested Markdown exclusion without changing the source checkout or project file. Expected failing probe builds are checks, not app defects. See [source ownership](STRUCTURE.md#source-discovery).

## Install and launch in the simulator

The app Debug and Release configurations select the original Card S `AppIcon` catalog. Its opaque 1024-pixel source and system-generated dark/tinted treatment are documented in [identity guidance](logo-concepts/README.md). This branch adds the asset; actual built icon metadata and Home Screen appearance checks must pass before delivery. The immutable `2026.10.14` download is unchanged.

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

Open Simulator to see the window. Normal launch shows Sidequest's shuffled news and game feed. Swipe up/down directly on the card or open Feed navigation for Previous card/Next card. Overflowing card content scrolls first; a new outward gesture at its top/bottom edge changes cards. Game cards stay at Tap to play until explicitly started. On Sudoku, select an editable cell and use 1–4 or Clear selected cell; see [SUDOKU.md](SUDOKU.md) for rules and feedback. On Memory, flip two cards to find a matching pair; see [MEMORY.md](MEMORY.md) for rules and feedback. On Chess, the fixed 4×4 focus area shows e5–h8 for White or a1–d4 for Black while standard 8×8 rules remain authoritative. All eight destination files/ranks remain available, including outside that focus area. Normal text uses compact own-piece and File/Rank/Submit rows beside a viewport-budgeted board; accessibility text retains readable vertical controls through the card scroller. Select an own-side piece on the board or through its larger button, choose a destination directly or with file/rank menus and Submit move, and find checkmate in one move. Both original color fixtures appear as separate cards; see [CHESS.md](CHESS.md). For the bubble shooter, drag in the lower-board touch area (including from the visible launcher upward), or use the accessible Aim slider; then explicitly press Fire to clear connected matching letters. Release does not shoot. Production starts contain three differently colored ceiling groups and require multiple clearing shots; the eight-shot limit remains. Win by clearing the board, or replay the same frozen challenge after a win/loss. See [BUBBLES.md](BUBBLES.md) for the challenge and verification. Skipping or backgrounding resets unfinished play. Completed results survive returning to their card. See [FEED.md](FEED.md) for adapter ownership and test-only routes. Simulator builds run on a Mac and cannot be installed on a physical iPhone.

## Download a simulator preview

The verified [2026.10.14 MVP](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) includes its unsigned ARM64 simulator archive, build metadata, and checksums. The download requires an Apple-silicon Mac and the verified iOS 27.0 (24A434) runtime above; it cannot be installed directly on an iPhone. Use the exact selected tag below. Older preview downloads were removed, while their Git tags/source remain available. Physical iPhone installation uses the selected source and local Xcode signing below.

```sh
SIDEQUEST_PREVIEW_TAG='2026.10.14'
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

A normal Apple Account gives you a free **Personal Team** in Xcode for testing on your own device. Paid Apple Developer Program membership is unnecessary for this route. Apple requires rebuilding and reinstalling after the provisioning profile expires, seven days after issuance; see [Personal Team guidance](https://developer.apple.com/help/account/basics/about-your-developer-account). The owner reports successful installation and basic play; [exact device/build details and detailed checks remain unknown](#owner-reported-iphone-test).

For merged features, use a clean checkout of the reviewed main commit. For an app-change PR in Review, use the branch and exact commit named in its handoff; owner-reported earlier play does not verify that PR. A separate checkout preserves your existing work and private news:

```sh
gh repo clone devofthings/sidequest sidequest-iphone
cd sidequest-iphone
git fetch origin
git switch main
open Sidequest.xcodeproj
```

Merged #106 is included in current main; the immutable `2026.10.14` download has the earlier finite deck. The simulator ZIP is built for the Mac simulator and cannot be installed directly on an iPhone.

1. In **Xcode → Settings → Accounts**, add your regular Apple Account. Identify its **Personal Team** and local team ID. Complete account prompts yourself; credentials stay in Xcode.
2. Create the ignored `Sidequest.xcodeproj/LocalSigning.xcconfig` in this checkout with your team ID and a unique identifier, replacing both example values:

   ```xcconfig
   DEVELOPMENT_TEAM = YOUR_PERSONAL_TEAM_ID
   SIDEQUEST_BUNDLE_IDENTIFIER = com.yourname.sidequest.personal
   ```

   The existing `Signing.xcconfig` loads this file for the app and both test targets. Keep personal values out of tracked project files and Git. In the app target's **Signing & Capabilities**, check **Automatically manage signing** and confirm the resolved team is your Personal Team; automatic signing is already configured in the project. A different bundle identifier installs a separate app with its own saved news.
3. Connect your iPhone to the Mac by USB, unlock it, and accept the pairing and **Trust This Computer** prompts. Use an iPhone running iOS 17 or later that your installed Xcode supports. Wait for Xcode to finish preparing the device.
4. On the iPhone, enable **Settings → Privacy & Security → Developer Mode**. Restart and confirm when prompted. Pairing with Xcode makes this option available; follow [Apple's Developer Mode guide](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
5. Select the shared **Sidequest** scheme and your actual iPhone as Xcode's destination. Press **Run (⌘R)**. Complete any signing or device-trust prompts locally. If signing fails, check the actual message, Personal Team ID, unique bundle identifier, and automatic signing; do not substitute the unsigned simulator build command.
6. After seven days, reconnect and press **Run** again to rebuild, reprovision, and reinstall. Keep the same local bundle identifier to use the same app's storage.

For a detailed current-source demo-news check (not established by the basic-play report):

- On an install without saved news, swipe through five game cards and check the next card is visibly labeled **Fictional sample**. Continue another five game cards to reach the next story. The pool contains 30 stories, with truthful sample-placeholder link wording.
- Check that the bottom counter is absent, each game starts only after **Tap to play**, skipping unfinished play resets it, and completed games retain their result when revisited.
- Continue through several stories, return to earlier cards, and try your preferred text size. Report the device/iOS version and actual errors or behavior in the applicable Review issue.

Existing saved news remains authoritative; an empty saved import intentionally gives games only. To try all 30 on an existing installation, AirDrop `Sidequest/Resources/demo-news.json` from the Mac and save it to Files, then choose it through **News snapshots → Import news JSON**. This explicitly replaces the active pool using the normal import transaction. Keep a private copy of prior captures if you want to restore them; see [demo import steps](NEWS.md#try-the-demo-pool-on-an-existing-install).

These steps document the local testing route; the owner report above does not identify its exact signing steps or establish TestFlight distribution. No signing account, membership, or credentials were created by this work.

## Content, versions, and troubleshooting

Keep real personal news captures in ignored `.local-news/` or another directory outside `Sidequest`, `SidequestTests`, and `SidequestUITests`. Use [NEWS.md](NEWS.md) to prepare a version 1 JSON file, import and validate it through the feed’s News snapshots button, and replace the saved set. Only fictional samples/schema are bundled. Fictional test fixtures are isolated in their test bundles.

Normal launch uses your saved snapshots, or the 30 bundled fictional demo stories when the saved document is confirmed absent. It shuffles games and inserts one news card after every five game cards, cycling the news pool in its original order. A saved empty pool intentionally gives games only; a corrupt or unavailable saved document shows a recoverable error and keeps games available. Tap the newspaper button (**News snapshots**) in the feed header, then **Import news JSON** and select the file in native Files. Successful selection replaces the complete news set and starts a new session; invalid input preserves the prior feed and saved bytes. Opening the library resets unfinished play; completed results survive closing or canceling it. See [NEWS.md](NEWS.md) for format, appearance IDs, persistence, and recovery.

For deterministic integration checks, a Debug build can launch with `-sidequest-integration-fixtures -sidequest-integration-reset`. It creates original fictional valid/empty/malformed/reserved-ID JSON under **On My iPhone → Sidequest → Sidequest Fixtures v2** and uses an isolated persistent test store. Remove the reset argument to test persistence across relaunch. Debug exposes Documents to Files; Release excludes these fixture/reset routes and file-sharing keys. To try private captures in the simulator, place your JSON in its Debug Documents directory using the app’s data-container path, select it with Files, and keep the file outside Git. On iPhone, AirDrop or another existing Files location works without enabling app file sharing.

The older standalone Debug fixture route `-sidequest-news-preview` still provides **Read news** for its original tests. The immutable finite MVP release `2026.10.14` did not load fictional news on normal launch. Current source uses the [demo fallback](DEMO_NEWS.md#product-policy) only when the saved document is confirmed absent; all four game kinds remain playable implementations. Release ignores all Debug fixture flags. Simulator runs are separate from the owner-reported installation/basic play above; device VoiceOver and iOS 17 behavior remain unverified until exercised.

Generated output belongs in ignored `DerivedData/`, `build/`, or an external build directory, outside synchronized source roots. Keep scoped `AGENTS.md` guidance in its owning folder; all target Markdown is excluded from built resources.

If Xcode reports no destination, check `xcrun simctl list runtimes` and `xcrun simctl list devices available`; unavailable entries with missing runtime profiles cannot run the app. Install the matching runtime rather than claiming a build or test passed. If simulator access is denied in a sandbox, run the approved build/simulator commands with their required local filesystem access.

Published versions appear in the private [GitHub Releases page](https://github.com/devofthings/sidequest/releases) only after an eligible, explicitly dispatched [release workflow](RELEASES.md). Main verification alone produces no new download. Its initial asset is a simulator archive; source plus local Xcode signing remains the personal-iPhone path.

## Endless source work

Merged #104 source implements endless manual scrolling with generated Sudoku, frozen Memory layouts, bounded attainable Bubble challenges, and reused validated Chess puzzles. Merged #106 source adds 30 labeled demo stories only when saved news is confirmed absent, and cycles the active pool after every five games while removing the bottom counter. Importing an empty set disables news; valid imports replace demos, while corrupt/unavailable storage shows recoverable errors instead. Demos are never automatically saved. Existing valid imports remain authoritative; to explicitly try all 30 stories, transfer `Sidequest/Resources/demo-news.json` to Files and select it through **News snapshots → Import news JSON**. This uses the normal replacement transaction; preserve a private copy of previous captures if you want to restore them. See [demo import steps](NEWS.md#try-the-demo-pool-on-an-existing-install). Build/run commands and local signing remain unchanged. `2026.10.14` is immutable and contains the finite MVP deck; this feature does not create a new downloadable release. See [ENDLESS.md](ENDLESS.md) and [DEMO_NEWS.md](DEMO_NEWS.md) for current behavior and actual delivery evidence.

## Focused and reusable native checks

Issue #90 adds [focused commands and benchmark policy](TESTING.md#build-ownership-and-local-commands). Use `scripts/run-native-tests.py` with `--unit`, repeatable `--ui ClassName`, `--required`, `--extended` or `--benchmark`, and a new absolute `--output` directory. It always compiles current source for testing, then executes the selected cases without rebuilding, on owned simulator devices. Under [#114 cleanup](TESTING.md#owned-simulator-cleanup-114), these temporary devices are shut down and deleted after the run or a handled failure; unrelated devices, logs, results, Debug cache, and Release products are preserved. Cleanup failures fail verification. `--required` selects all unit tests and the three approved pre-design UI smoke cases; `--extended` explicitly selects all retained UI cases plus units. Focused or extended results do not replace exact-head active-gate CI. CI uses one worker until design agreement; changed source ownership does not reactivate deferred UI journeys. Keep unique Release output independent of incremental Debug products. Actual main install/launch remains part of explicitly owner-authorized manual release verification, rather than an automatic second check after merging.


The foreground CI driver also handles SIGINT/SIGTERM under [owned cancellation #102](CI.md#owned-command-cancellation-102): it drains its own command process groups before shutting down/deleting its returned device IDs, retains canceled diagnostics, and emits no passing manifest. Workflow verification uses direct Python exec and a [run-specific finalizer](CI.md#shell-cancellation-recovery-140) that can recover durably recorded returned UUIDs after interrupted cleanup. This applies to foreground CI, not arbitrary manually launched Xcode commands or universal SIGKILL/power-loss recovery. Native coverage and the manual release policy are unchanged.

## Check successful completion feedback on your iPhone

After the #86 implementation PR is reviewed and merged, use the current source and [free Personal Team installation steps](#install-on-your-own-iphone); an Apple Developer Program purchase is unnecessary for this local test. The `2026.10.14` simulator download does not contain later feedback changes and cannot run on an iPhone.

Solve Sudoku, match all Memory pairs, solve either Chess puzzle, or win Bubble shooter. Each success should briefly show a readable checkmark/“Nice!” badge in the fixed app header above the unchanged board and request one short system success haptic. The completed result should remain after the badge disappears. Skip and return, or background and reopen: completion should persist without another celebration or haptic. A Bubble loss should give its normal result without success feedback; Replay can celebrate a newly won attempt.

Turn on Settings → Accessibility → Motion → Reduce Motion and repeat a success: the badge should appear without spatial movement. System settings, device support, and haptic availability determine whether physical feedback plays. Report the iPhone model, iOS version, observed vibration, and any repeat/missing feedback in [#86](https://github.com/devofthings/sidequest/issues/86). Simulator tests establish visible feedback and lifecycle behavior, never physical vibration. Device acceptance remains pending until this check is actually performed.

## Check harder generated Bubble source

Generator #137 merged through reviewed [PR139](https://github.com/devofthings/sidequest/pull/139) after exact-head native CI and actual production play; use current source and the free Personal Team steps above. Normal generated Bubble cards have three differently colored ceiling groups; clearing one cannot detach the other ceiling colors. Preserve explicit Fire, the eight-shot cap, frozen board/reset/Replay and retained completed revisits. The canonical three-shot generation witnesses establish solvability through pure rules, not a user aiming shortcut. The seed104 Debug endless test route has an independently audited alternate 0°,0°,−24° solution with a broad final left-angle window; it uses normal production generation, retains two unchanged straight shots and a genuine final launcher-origin left drag followed by explicit Fire. A normalized Slider request is not a promise of delivered degrees. Physical-device behavior remains unverified. Control/layout improvements are separate #138 work, and no new release is implied.


## Check compact direct Bubble source #138

Use branch `codex/138-bubble-direct-aim` and the exact reviewed commit in its PR handoff; free Personal Team/local ignored signing configuration, pairing, Developer Mode and Xcode Run follow the iPhone steps above. Rebuild/reinstall when the seven-day Personal Team profile expires; the simulator archive cannot install on an iPhone. No paid membership or new release is required. Actual physical-device execution remains unverified.

On a Bubble card, Tap to play must preserve the inactive board. Drag from the launcher upward or horizontally/diagonally in the lower aim area: the angle and real reflected guide change, but the feed, board location and shot count stay still. Fire explicitly launches one shot; moving cards or backgrounding while it flies restores the frozen preview on return. Solve a normal generated three-group challenge, revisit its retained completion, then Replay restores the same challenge without a shot. At normal text check the entire board, direct aiming area, native Slider and Fire together; at larger accessibility text use the owned scroller to reach all complete labels and controls. Check all four games' complete boards/primary controls and stable Start geometry. Root-owned simulator/CI results and physical testing must be reported separately; #138 actual execution is pending at author handoff.

## Cold-launch logo introduction #91

Current #91 source uses the selected Card S PNG in a brief decorative overlay while normal preparation and loading/error/feed access continue independently. Its nominal clock is 80 ms visible plus a 350 ms opacity/scale fade; system Reduce Motion omits it immediately. Background, cancellation, or disappearance consumes it permanently for that cold process launch. Retry, news import, foreground return, and feed changes cannot replay it or start a game. Build commands, signing, and the immutable `2026.10.14` download remain unchanged.

Five deterministic policy tests and two extended `StartupIntroductionFlowTests` cases cover the model and real cold-launch/background/explicit Sudoku input semantics, including actual system Reduce Motion. They do not measure the subsecond decoration; normal/reduced-motion recordings, actual app compilation, current-head CI, and fresh review remain pending lead-owned verification. The three-case routine UI smoke gate is unchanged. Physical-device timing and VoiceOver are unverified. See [the selected policy](DECISIONS.md#logo-opening-introduction-91).
