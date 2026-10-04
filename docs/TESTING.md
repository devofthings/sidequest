# Faster native verification #90

The owner approved local build reuse and a measured worker comparison, then made testing the immediate priority on October 4, 2026. Ordinary PR verification targets 5–10 minutes on the existing Mac. This is a measurement target, not permission to skip failures. No hosted execution, uploads, recurring runs, services, or paid dependencies are introduced.

## Required coverage and retained scenarios

[scripts/native-test-inventory.json](../scripts/native-test-inventory.json) classifies every native UI method. The required inventory contains 19 UI cases and all 120 deterministic unit cases. An additional 23 UI cases remain available and become required when their recorded source ownership paths change. A newly added unclassified UI case fails verification. Main's full fallback selects every case. Focused development commands never satisfy the CI gate.

| Behavior | Required running-app coverage | Deeper deterministic coverage / retained native scenarios |
| --- | --- | --- |
| Explicit start, input, unfinished skip/reset, completed revisit | Sudoku start/correction and solve/revisit; all three Memory cases; white Chess walkthrough and largest-text solution; Bubble win/replay and direct skip | Each game's rule/controller tests; black Chess, seven-shot Bubble loss, background/stale-flight walkthroughs remain selected for their game changes. |
| Generated production wiring and first five-game/news boundary | `EndlessFlowTests/testGeneratedPreviewInputSkipAndFirstNewsBoundary` | `EndlessFeedTests` covers thousands of advances, frozen identity/configuration, adapter limits, all-game completion restoration and collisions; `FeedNewsCadenceTests` checks varying boundaries and the entire story pool. The four extended endless flows retain multi-batch actual UI, import/history, cadence and actual system-motion checks for relevant generator/feed/news changes. |
| Real Files selection, invalid/empty import, cancellation, relaunch persistence | `IntegrationFlowTests/testNativeImportsReplaceTheMixedDeckPersistAndRejectInvalidFiles` | Actual native selection and cancellation remain required; NewsImport/Transaction/Session tests cover cancellation, save leases, invalid data and replacement. Extended integration modal/background and imported overflow/Settings flows remain available for their affected paths. The same owned device is reused for both benchmark policies to preserve repeated-install behavior. |
| Native direct paging, reverse preview, canceled drag, overflow edges and slider ownership | Pager direct/edge tests and Bubble horizontal/diagonal/short-drag tests | FeedHost and GameLifecycle tests cover pending requests, retirement, delayed callbacks and settled ownership. Extended fast-flick/bounds and other platform variants remain selected for relevant changes. |
| Accessibility and browser handoff | Largest-text controls for all four games, native overflow edge paging, real Settings Reduce Motion, source-link browser return, same-view replacement | Existing controller/model tests cover combinations; additional platform-specific cases remain retained. Simulator accessibility does not prove physical-device VoiceOver. |

The generic demo feed walkthroughs and foundation launch check overlap the required real-game and platform checks. They remain extended, with ownership-based selection. Native assertion bodies are retained; the new short generated scenario covers production integration without repeating deep all-game solves and dozens of paging steps on every tooling PR.

## Build ownership and local commands

Every execution first runs `build-for-testing` against the current checkout, then `test-without-building`. Incremental Debug output is keyed by canonical checkout path, toolchain identity, SDK identity/path, runtime, configuration, scheme/project and explicit unsigned settings. A nonblocking exclusive file lock owns that cache through compilation and all workers; a separate Mac-wide ownership lock serializes native jobs. A failed current build stops before tests. Cached output never supplies a result or a Release product.

Run from the repository root, choosing a new output directory:

```sh
python3 scripts/run-native-tests.py --unit \
  --output /private/tmp/sidequest-unit-check-unique
python3 scripts/run-native-tests.py --ui BubbleFlowTests --ui PagerFlowTests \
  --output /private/tmp/sidequest-ui-check-unique
python3 scripts/run-native-tests.py --required \
  --output /private/tmp/sidequest-required-check-unique
python3 scripts/run-native-tests.py --extended \
  --output /private/tmp/sidequest-all-check-unique
python3 scripts/run-native-tests.py --benchmark \
  --output /private/tmp/sidequest-worker-benchmark-unique
```

The benchmark compiles once before timing, then compiles the current source again before each policy. Both policies use the same inventory, source and incremental cache. One worker runs serially on the first owned simulator; two workers run explicitly partitioned serial `xcodebuild` processes on two distinct owned simulators. The scheme stays nonparallelizable: enabling worker flags alone would not establish actual concurrency. Each worker has a unique result bundle/log and its actual test inventory/device/counts are checked with `xcresulttool`; missing, duplicate, skipped, failed or unexpected cases fail verification. All created devices are shut down on exit and retained for diagnostics; user/CI devices are preserved.

The bounded two-worker policy may be enabled only after the same-inventory benchmark passes and is faster. Keep one worker if that evidence fails. Timing and exact commands remain in local diagnostics. Release compilation uses fresh unique per-run DerivedData, independent of the Debug cache.

## Main inheritance

The full required suite runs on the exact reviewed PR head. Main may inherit it only when the live merged same-repository PR identifies this main event, the actual main commit has the historical audit receipt's reviewed base as its sole parent, and its entire Git tree equals the successful PR tree. The receipt must establish a distinct independent reviewer, no unresolved findings and exact CI provenance. Do not use a merged PR's mutable `base.sha` as the captured base.

The resolver checks the original successful native PR run, attempt, head, repository, workflow, job/check identity and the matching local schema-2 manifest with actual worker coverage. Missing, stale, failed, unsupported, ambiguous or inaccessible evidence causes full verification. Schema-1 manifests lack the necessary evidence and cannot supply inheritance. Main still compiles its actual source, installs/launches its Debug app on an owned simulator, verifies the running process, performs source discovery and builds a new ARM64 Release product.

Schema-2 verification and release metadata distinguish `full` tests from `inherited` tests. Inherited records retain original head, run/attempt, inventory, PR, captured base, tree and audit reference; they never claim that tests executed on main. Publication revalidates inherited provenance, keeps same-attempt main-native and same-runner gates, and remains manual. Uploaded historical schema-1 release metadata remains immutable and valid for original-byte retries; a new package requires schema 2 and fresh main smoke evidence.

## Agent-grill self-assessment

| Question | Kind | Answer and evidence | Verification |
| --- | --- | --- | --- |
| Where is the bottleneck? | Fact | Exact baseline `f3dc1620b675a0d0e90119855a55f8326609d8eb`, native run `37196691566`: 120 unit cases in 6.004 seconds, 41 UI cases in 1762.941 seconds, total native 1794.432 seconds. Four endless cases used 726.134 seconds; three integration cases used 265.877 seconds. | Original successful result bundle and exported per-case profile retained outside Git. |
| Which coverage can move out of ordinary walkthroughs? | Delegated choice | Deterministic lower layers already verify deep rule/lifecycle/history/cadence combinations. Required native cases retain all four games and actual platform assertions; explicit extended inventory preserves relevant scenarios. | Inventory regression, required-suite benchmark and affected extended native CI. |
| How can two workers actually execute independently? | Fact and delegated choice | The scheme and old driver force serial testing. Partition selected cases between two separate serial processes, unique device IDs and result paths, sharing only read-only compiled products under one build owner. | Actual device and test inventories plus one/two timings; no policy switch without passing speedup. |
| How can main avoid duplicate tests honestly? | Delegated choice under owner direction | Captured independent audit base, actual sole-parent/tree equality, live successful PR provenance and local coverage manifest; otherwise full fallback. | Disposable Git/API regressions, smoke-failure regressions, release legacy/retry regressions, actual main after gated merge. |

Xcode verbose post-failure sysdiagnose is disabled with its documented `-collect-test-diagnostics never` option. Actual failed XCTest results, screenshots and logs remain; this changes diagnostic collection rather than assertions or test outcomes. A focused cold Files failure demonstrated an automatic collector with a 600-second timeout.

## Measurements

The original serial baseline above is observed. Compact one/two-worker measurements and the complete ordinary verification duration must be recorded before claiming the 5–10-minute target is met. Exact-head CI and fresh independent review remain required before merge. Physical-device execution remains deferred under #79.

Initial compact attempt: 120 unit and 19 UI cases executed; 138 passed and the native import case failed at its Locations assertion. UI time was 512.698 seconds, but this failed run cannot choose a worker policy or establish the target. A focused cold-picker attempt failed its initial provider-existence assertion in 20.759 seconds. Both failed bundles/logs remain outside Git. Targeted retest and a complete same-inventory worker comparison remain pending; the policy stays at one worker.
