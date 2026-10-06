# Install and run Sidequest

## Verified foundation

`Sidequest.xcodeproj` contains the shared `Sidequest` scheme, iPhone app, app-hosted unit tests, and UI tests. Merged #104 source provides endless generated Sudoku, frozen Memory layouts, attainable Bubble challenges, and repeated validated Chess puzzles. Merged #106 source adds 30 clearly fictional demo stories only when saved news is absent, cycles the active pool after every five games, and removes the bottom counter. Valid saved news stays authoritative, saved empty news permits games only, and storage errors remain recoverable. **News snapshots** opens native Files imports. The historical `2026.10.14` source tag and explicit Debug routes retain their finite decks; the evidence below describes the formerly available download.

The [historical 2026.10.14 source](https://github.com/devofthings/sidequest/tree/2026.10.14) passed 133 native tests and separate installations of freshly built tagged source and the downloaded ARM64 simulator archive. [Verified delivery](#verified-mvp-delivery) records the exact source, checksums, and evidence. [CI](CI.md) uses the same toolchain on a foreground self-hosted Mac runner. All GitHub releases and their assets were removed at the owner’s request on October 6, 2026; Git tags/source remain. Build current source for installation. Routine verification runs on PRs; merging starts no automatic main job under #112. Explicit owner-authorized manual release verification/publication follows [RELEASES.md](RELEASES.md).

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

[2026.10.14 source tag](https://github.com/devofthings/sidequest/tree/2026.10.14) was published October 4, 2026 at 05:19:00 UTC from `65bd39003a2a22dbb3c19f61cbb4b9e86c3c32b9`. Its manual workflow run `37178518287` was originally created at `2026-10-04T04:58:13Z`; live run number `14` establishes the calendar/build version.

| Check | Actual result |
| --- | --- |
| [Release verification](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111366112952) | 133 tests passed: 96 unit and 37 running-app tests; zero failures, skips, or runtime warnings; Debug/ARM64 Release builds, strict lint, source discovery, and offline tooling passed |
| [Fresh tagged-source installation](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) | Clean checkout of the actual published tag; ARM64 Release build, installation, and normal launch passed on the owned iOS 27 simulator |
| [Downloaded-app installation](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) | All three server asset digests, both `SHA256SUMS` entries, metadata/source/run provenance, and archive safety passed; installation and normal launch passed; installed executable matched the extracted published executable |

Both normal Release launches showed a real game preview with **Tap to play** and five game cards with no saved news or Debug flags. The native integration suite separately verifies mixed news imports, persistence/rejection/cancellation, all game lifecycles, larger text, source links, and actual Reduce Motion. Physical-device signing/install, device VoiceOver, and iOS 17 execution remain unverified; the tested runtime is iOS 27. Release version `2026.10.14` is the tag/metadata identity; the app bundle retains version `0.1.0`, build `1`.

The archive SHA-256 is `5b613f043cd533eabfd9e4d3939dd9fcfe7d9e2f1ae1f2da727784ba7cfa8ad0`. Always verify the downloaded checksum file rather than relying on this prose alone. Fresh local source and published binaries were independently installed; bit-for-bit equality between separate builds is not claimed.

The metadata’s installation URL pins the immutable release-source guide. This current guide adds post-publication proof; later documentation changes do not retarget the release or publish another app. [Issue #9](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) retains commands and evidence; screenshots and private captures stay outside Git.

Current source also corrects feedback/result layout under [#108](https://github.com/devofthings/sidequest/issues/108): game boards and primary controls keep their geometry at a fixed viewport/text size. During personal testing, cause a Memory mismatch, complete Chess, and win/replay Bubble while keeping the scroll position unchanged. Repeat with larger text after revealing the controls. See [the Review checklist](GAME_LAYOUT.md#personal-iphone-review); that specific layout checklist remains unverified on a physical device.

## Verified source refinements October 5

These merged source refinements have their own simulator, independent-review and exact-head CI evidence. They do not rewrite the historical `2026.10.14` evidence above. No downloadable build is currently available. Publication remains held under [release policy](RELEASES.md). Each CI job passed repository checks, Debug compilation, all unit tests plus the three routine UI smoke cases, unsigned ARM64 Release compilation, and owned-simulator cleanup. The final PR source was verified before merge; no second main test was run.

| Refinement | Exact reviewed/tested head and base | Actual focused execution | Independent review and CI |
| --- | --- | --- | --- |
| Committed feedback, [PR169](https://github.com/devofthings/sidequest/pull/169), partial #161 | Head `333d70606bab4aa671c883001a8b477915e8f3a9`; base `bed111c694c47a22113dea67580bca2e2ebe4d65` | 163 units and six UI checks passed: Debug 25.527 seconds, tests 227.092 seconds. Bubble completion/Replay and system Reduce Motion; Memory matching, mismatch/reset, largest text, background and system Reduce Motion were exercised. | Fresh full review had no findings; [audit](https://github.com/devofthings/sidequest/pull/169#issuecomment-5999801988), [successful job](https://github.com/devofthings/sidequest/actions/runs/37348352431/job/111892589527). |
| Original Memory/Chess art, [PR173](https://github.com/devofthings/sidequest/pull/173), #171 | Head `7dfdfcdfa028ffeea2ec9640108eba24392bb4e2`; base `2427f2eeb35f073dc25297448ff8a74a0f0f3294` | After the disabled-label opacity correction, two 375-point iPhone SE simulator checks in queried dark appearance passed (Debug 17.844 seconds, tests 55.890 seconds), followed by two largest-text checks (Debug 5.552 seconds, tests 76.393 seconds). Actual captures show opaque Chess preview pieces and all six matched Memory faces. Real Memory completion/revisit, full Chess controls and largest-text coordinate solve/navigation passed. | Fresh full round two had no findings; [audit](https://github.com/devofthings/sidequest/pull/173#issuecomment-6000242339), [successful job](https://github.com/devofthings/sidequest/actions/runs/37352043510/job/111905206740). |
| Standard 9×9 Sudoku, [PR172](https://github.com/devofthings/sidequest/pull/172), #170 | Head `b6fd3fe72b531aa20b70976f4273c75e09405d0d`; base `b32ed97ef49af8f68165bddf6975176622ed3ae6` | Final-head normal and largest-text checks passed on the 375-point iPhone SE simulator in queried dark appearance (Debug 13.696 seconds, tests 72.820 seconds). Complete overview/44-point controls, inert start/reset, row/column 9 entry, Clear/reentry, owned overflow and stable status geometry passed. Actual captures show opaque readable givens. | Fresh full round two had no findings; [audit](https://github.com/devofthings/sidequest/pull/172#issuecomment-6000440303), [successful job](https://github.com/devofthings/sidequest/actions/runs/37353816161/job/111911029095). |

Historical focused coverage remains source-specific. The earlier six artwork flows passed at `7542b2c6255d1e8e3cb8b584bbaa6e44d1e9c118`; the final artwork run repeated four targeted opacity/layout flows, not all six. Unit/UI assertions were unchanged; final app changes were local label-preserving button styles and guidance, without controller/rule/runtime changes. The earlier three standard Sudoku flows passed at `49b3db9c587d5f9964be5ac8117fe5cb74e7be24` (Debug 17.678 seconds, tests 172.447 seconds), including real twelve-entry completion and quiet revisit. A source comparison established unchanged Sudoku/composition and owning test code at the final head; the final run repeated normal/largest checks, not the completion flow. Every owned simulator was shut down and deleted.

#170 and #171 are complete for their bounded source acceptance. #161 remains open for actual iPhone vibration; simulator output cannot certify physical haptics. #162 remains open for difficulty implementation in #118. The owner selected mixed games with difficulty labels and standard Chess rules with varying visible areas; #118/#117 still track their unimplemented scope. Physical 9×9/artwork accessibility, device VoiceOver and iOS 17 execution remain unverified. Use the free Personal Team steps below to test current source on an iPhone; the owner's earlier installation/basic-play report does not certify these exact refinements.

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

Open Simulator to see the window. Normal launch shows Sidequest's shuffled news and game feed. Swipe up/down directly on the card or open More options for Previous card/Next card. Overflowing card content scrolls first; a new outward gesture at its top/bottom edge changes cards. Game cards stay at Tap to play until explicitly started. On production Sudoku, use the compact 9×9 overview or full-size Row/Column menus to select an editable cell, then use 1–9 or Clear selected cell (historical mini fixtures retain 1–4); see [SUDOKU.md](SUDOKU.md) for rules and feedback. On Memory, flip two cards to find a matching pair; see [MEMORY.md](MEMORY.md) for rules and feedback. On Chess, the fixed 4×4 focus area shows e5–h8 for White or a1–d4 for Black while standard 8×8 rules remain authoritative. All eight destination files/ranks remain available, including outside that focus area. Normal text uses compact own-piece and File/Rank/Submit rows beside a viewport-budgeted board; accessibility text retains readable vertical controls through the card scroller. Select an own-side piece on the board or through its larger button, choose a destination directly or with file/rank menus and Submit move, and find checkmate in one move. Both original color fixtures appear as separate cards; see [CHESS.md](CHESS.md). For the bubble shooter, drag in the lower-board touch area (including from the visible launcher upward), or use the accessible Aim slider; then explicitly press Fire to clear connected matching letters. Release does not shoot. Production starts contain three differently colored ceiling groups and require multiple clearing shots; the eight-shot limit remains. Win by clearing the board, or replay the same frozen challenge after a win/loss. See [BUBBLES.md](BUBBLES.md) for the challenge and verification. Skipping or backgrounding resets unfinished play. Completed results survive returning to their card. See [FEED.md](FEED.md) for adapter ownership and test-only routes. Simulator builds run on a Mac and cannot be installed on a physical iPhone.

## Download a simulator preview

There are currently **no downloadable GitHub releases**. On October 6, 2026, the owner requested deleting all releases and their assets, including `2026.10.14`. Git tags and source history remain; the [verified delivery record](#verified-mvp-delivery) below is historical evidence, not a currently available download.

Build current source using [Build and test](#build-and-test) for a simulator or [Install on your own iPhone](#install-on-your-own-iphone) for your device. Simulator products cannot be installed on a physical iPhone. Future downloads require separately authorized publication under [RELEASES.md](RELEASES.md).

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

Keep real personal news captures in ignored `.local-news/` or another directory outside `Sidequest`, `SidequestTests`, and `SidequestUITests`. Use [NEWS.md](NEWS.md) to prepare a version 1 JSON file, import and validate it through More options → News snapshots, and replace the saved set. Only fictional samples/schema are bundled. Fictional test fixtures are isolated in their test bundles.

Normal launch uses your saved snapshots, or the 30 bundled fictional demo stories when the saved document is confirmed absent. It shuffles games and inserts one news card after every five game cards, cycling the news pool in its original order. A saved empty pool intentionally gives games only; a corrupt or unavailable saved document shows a recoverable error and keeps games available. Open **More options → News snapshots** in the feed header, then **Import news JSON** and select the file in native Files. Successful selection replaces the complete news set and starts a new session; invalid input preserves the prior feed and saved bytes. Opening the library resets unfinished play; completed results survive closing or canceling it. See [NEWS.md](NEWS.md) for format, appearance IDs, persistence, and recovery.

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

Solve Sudoku, match all Memory pairs, solve either Chess puzzle, or win Bubble shooter. Each success should briefly show a readable checkmark badge centered over the unchanged game viewport and request one short system success haptic. Current source cycles Nice!, Brilliant!, Nailed it!, and Well played! with distinct pop, confetti, orbit, and ray effects; Reduce Motion retains varied wording and a restrained fade. The completed result should remain after the badge disappears. Skip and return, or background and reopen: completion should persist without another celebration or haptic. A Bubble loss should give its normal result without success feedback; Replay can celebrate a newly won attempt.

Turn on Settings → Accessibility → Motion → Reduce Motion and repeat a success: the badge should appear without spatial movement. System settings, device support, and haptic availability determine whether physical feedback plays. Report the iPhone model, iOS version, observed vibration, and any repeat/missing feedback in [#86](https://github.com/devofthings/sidequest/issues/86). Simulator tests establish visible feedback and lifecycle behavior, never physical vibration. Device acceptance remains pending until this check is actually performed.

## Check harder generated Bubble source

Generator #137 merged through reviewed [PR139](https://github.com/devofthings/sidequest/pull/139) after exact-head native CI and actual production play; use current source and the free Personal Team steps above. Normal generated Bubble cards have three differently colored ceiling groups; clearing one cannot detach the other ceiling colors. Preserve explicit Fire, the eight-shot cap, frozen board/reset/Replay and retained completed revisits. The canonical three-shot generation witnesses establish solvability through pure rules, not a user aiming shortcut. The seed104 Debug endless test route has an independently audited alternate 0°,0°,−24° solution with a broad final left-angle window; it uses normal production generation, retains two unchanged straight shots and a genuine final launcher-origin left drag followed by explicit Fire. A normalized Slider request is not a promise of delivered degrees. Physical-device behavior remains unverified. Control/layout improvements are separate #138 work, and no new release is implied.


## Check compact direct Bubble source #138

Use branch `codex/138-bubble-direct-aim` and the exact reviewed commit in its PR handoff; free Personal Team/local ignored signing configuration, pairing, Developer Mode and Xcode Run follow the iPhone steps above. Rebuild/reinstall when the seven-day Personal Team profile expires; the simulator archive cannot install on an iPhone. No paid membership or new release is required. Actual physical-device execution remains unverified.

On a Bubble card, Tap to play must preserve the inactive board. Drag from the launcher upward or horizontally/diagonally in the lower aim area: the angle and real reflected guide change, but the feed, board location and shot count stay still. Fire explicitly launches one shot; moving cards or backgrounding while it flies restores the frozen preview on return. Solve a normal generated three-group challenge, revisit its retained completion, then Replay restores the same challenge without a shot. At normal text check the entire board, direct aiming area, native Slider and Fire together; at larger accessibility text use the owned scroller to reach all complete labels and controls. Check all four games' complete boards/primary controls and stable Start geometry. Root-owned simulator/CI results and physical testing must be reported separately; #138 actual execution is pending at author handoff.

## Cold-launch logo introduction #91

Current #91 source uses the selected Card S PNG in a brief decorative overlay while normal preparation and loading/error/feed access continue independently. Owner-approved #192 updates its nominal clock to 150 ms visible plus a 450 ms ease-in-out opacity fade without zoom (600 ms total); system Reduce Motion omits it immediately. Background, cancellation, or disappearance consumes it permanently for that cold process launch. Retry, news import, foreground return, and feed changes cannot replay it or start a game. Build commands, signing, and the immutable `2026.10.14` download remain unchanged.

Historical #91 used five deterministic introduction policy tests and two extended cold-launch/foreground UI cases. #215 removes that obsolete timed owner; current static launch checks are documented below.

## Branded launch canvas #181

Before rebuilding for an iPhone, confirm the checkout actually contains the selected branding assets and record its commit with `git rev-parse HEAD`. The owner's October 5 missing-icon/black-startup report exposed a clean Documents checkout still at `f3dc162` (October4), before the selected icon and introduction were merged. Root fast-forwarded it to reviewed `9b76c54` while preserving ignored signing and private captures. The connected app reports `0.1.0`, build `1`, which does not identify its source; this is a likely stale-source explanation, not verified physical-device repair. Synchronize a clean installation checkout to reviewed source before Xcode Run, preserving other work and local inputs. Never uninstall the app to clear icon caches without separately considering its saved news.

The launch-feature source `b01ff1e` passed all 168 units and two startup UI flows on iPhone 18 Pro (Debug 22.312 s, tests 82.106 s), then the same two flows on a 375-point iPhone SE simulator with queried dark appearance (Debug 5.902 s, tests 70.203 s). Root recorded the actual normal/dark launches and native system Reduce Motion flows; owned devices were shut down/deleted. Actual Debug metadata resolves `UILaunchScreen.UIColorName = LaunchCanvas`, retains the selected `AppIcon`, and contains compiled assets. An unsigned iPhoneOS Debug build also passed with generated AppIcon PNGs, compiled assets, and the same launch dictionary. These checks do not prove physical-device appearance or the final PR's independent review/CI gates.

Current #181 source configures both Debug and Release with an explicit `UILaunchScreen` background named `LaunchCanvas`. The root SwiftUI background uses the same catalog color in loading, failure, and ready states; the selected Card S icon and existing 430 ms introduction are preserved. No extra wait, onboarding, signing requirement, or release publication is added. See [launch rationale and verification checklist](design/LAUNCH.md).

At author handoff, source plist/asset validation, strict Swift lint, documentation checks, and byte-identity checks passed. Root-owned actual Debug/Release compilation, named-color resolution, cold-launch recordings, existing startup UI checks, all unit tests, required smoke, and exact-head CI remain pending. Physical-device, iOS 17, and VoiceOver appearance/timing remain unverified.

## Mixed difficulty verification #201

The integration is not yet certified by native execution. Planned focused command: `python3 scripts/run-native-tests.py --unit --ui MixedDifficultyFlowTests --output /private/tmp/sidequest-201-native`. This covers the complete unit suite and two extended mixed-tier journeys, without changing the three required smoke cases. The DEBUG route `-sidequest-mixed-difficulties-test` uses ordered seed201 and a dedicated fictional-news test store; Release ignores the route. Normal production opts into the same certified generation. Use the existing free Personal Team installation steps to test the reviewed branch after its exact-head CI and independent review pass.

## Private Tagesschau personal test #213

Current source replaces normal fake articles with a live German Tagesschau RSS feed. Reopen the app to refresh; network access is optional for games. The latest valid articles are cached only for the running session, and source images load when displayed. No news/image assets are archived or bundled in Git. See [personal test steps and limitations](TAGESSCHAU.md#personal-test). This source change does not create a new release download. Build on your iPhone using the existing free Personal Team signing instructions above.

## Static system logo launch #215

Current source replaces the custom logo introduction with the system-owned static LaunchScreen storyboard: existing centered 120-point logo, full-screen logo purple (#653BE8) under the owner's #226 correction, and direct transition to neutral preparation/feed content. There is no app-owned logo hold/fade. Both Debug and Release name the storyboard; signing and Debug Files configuration stay intact. [Launch guidance](design/LAUNCH.md) records readiness, compiled-resource checks and personal-iPhone steps. StaticLaunchBundleTests and three extended StaticLaunchFlowTests cover resources, cold launch/foreground, largest text, and actual Reduce Motion; purple correction evidence is recorded in [PR #227](https://github.com/devofthings/sidequest/pull/227), while [PR #222](https://github.com/devofthings/sidequest/pull/222) verified the earlier neutral treatment. Historical #91/#181/#192 evidence above belongs to earlier source.
