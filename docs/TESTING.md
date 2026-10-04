# Faster native verification #90

The owner approved local build reuse and a measured worker comparison, then made testing the immediate priority on October 4, 2026. Ordinary PR verification targets 5–10 minutes on the existing Mac. This is a measurement target, not permission to skip failures. No hosted execution, uploads, recurring runs, services, or paid dependencies are introduced.

## Approved temporary gate and retained scenarios

On October 4, 2026, the owner selected "Tiny UI smoke suite plus all unit tests (Recommended)" until the design is agreed. The active `pre_design_smoke` gate runs all 120 deterministic unit cases and these three existing running-app cases on one owned simulator:

- `FoundationLaunchTests/testLaunchShowsAccessibleHeading`: launch and accessible heading.
- `PagerFlowTests/testDirectCardDragTracksAndCommitsThenReverseReturnsToPreview`: native direct paging, committed selection, and reverse preview.
- `SudokuFlowTests/testTapStartsOnlyAndCorrectionsResetAfterSkipping`: real start/input, correction, and unfinished skip/reset.

The approved complete gate is 123 cases. Main's fallback runs this same active gate. Ownership-path changes do not reactivate longer UI journeys before design agreement. Activating broader coverage requires a recorded decision and reviewed source PR. This temporary choice defers comprehensive UI coverage; the smoke gate does not prove all games, native imports, accessibility variants, browser return, or deep integration journeys.

[scripts/native-test-inventory.json](../scripts/native-test-inventory.json) continues to classify all 42 UI methods. The earlier 19-case required inventory and 23 extended cases, including their ownership mapping, remain available through explicit `--extended` execution with all unit tests. They are retained evidence and a future coverage map, not active automatic CI selection. New unclassified UI cases still fail inventory validation. Focused and extended local commands never replace the approved exact-head CI gate.

The following matrix describes the retained broader coverage available through explicit extended execution.

| Behavior | Retained running-app coverage | Deeper deterministic coverage / retained native scenarios |
| --- | --- | --- |
| Explicit start, input, unfinished skip/reset, completed revisit | Sudoku start/correction and solve/revisit; all three Memory cases; white Chess walkthrough and largest-text solution; Bubble win/replay and direct skip | Each game's rule/controller tests; black Chess, seven-shot Bubble loss, background/stale-flight walkthroughs remain available explicitly. |
| Generated production wiring and first five-game/news boundary | `EndlessFlowTests/testGeneratedPreviewInputSkipAndFirstNewsBoundary` | `EndlessFeedTests` covers thousands of advances, frozen identity/configuration, adapter limits, all-game completion restoration and collisions; `FeedNewsCadenceTests` checks varying boundaries and the entire story pool. The four extended endless flows retain multi-batch actual UI, import/history, cadence and actual system-motion checks for explicit extended execution. |
| Real Files selection, invalid/empty import, cancellation, relaunch persistence | `IntegrationFlowTests/testNativeImportsReplaceTheMixedDeckPersistAndRejectInvalidFiles` | The retained case proves actual native selection and cancellation; NewsImport/Transaction/Session tests cover cancellation, save leases, invalid data and replacement. Extended integration modal/background and imported overflow/Settings flows remain available explicitly. The same owned device is reused for both benchmark policies to preserve repeated-install behavior. |
| Native direct paging, reverse preview, canceled drag, overflow edges and slider ownership | Pager direct/edge tests and Bubble horizontal/diagonal/short-drag tests | FeedHost and GameLifecycle tests cover pending requests, retirement, delayed callbacks and settled ownership. Extended fast-flick/bounds and other platform variants remain available explicitly. |
| Accessibility and browser handoff | Largest-text controls for all four games, native overflow edge paging, real Settings Reduce Motion, source-link browser return, same-view replacement | Existing controller/model tests cover combinations; additional platform-specific cases remain retained. Simulator accessibility does not prove physical-device VoiceOver. |

The generic demo feed walkthroughs overlap the broader real-game and platform checks. They remain retained for explicit extended runs. The foundation launch check is now part of the temporary smoke gate. Native assertion bodies are retained; the retained short generated scenario covers a production boundary for explicit extended execution.

## Build ownership and local commands

Every execution first runs `build-for-testing` against the current checkout, then `test-without-building`. Incremental Debug output is keyed by canonical checkout path, toolchain identity, SDK identity/path, runtime, configuration, scheme/project and explicit unsigned settings. A nonblocking exclusive file lock owns that cache through compilation and all workers; a separate Mac-wide ownership lock serializes native jobs. A failed current build stops before tests. Cached output never supplies a result or a Release product.

CI also requires the exact expected HEAD and a clean tracked/untracked checkout before native work and before emitting a successful manifest. This binds the compiled source to its commit; focused local commands can test uncommitted changes without claiming exact-commit CI evidence.

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

The temporary three-case UI gate uses one worker. The earlier two-worker benchmark proves speedup only for its recorded 139-case inventory and does not select workers for the smoke gate. A future worker change requires passing, faster evidence for its actual inventory. Timing and exact commands remain in local diagnostics. Release compilation uses fresh unique per-run DerivedData, independent of the Debug cache.

## Main inheritance

The complete approved unit and UI smoke gate runs on the exact reviewed PR head. Main may inherit it only when the live merged same-repository PR identifies this main event, the actual main commit has the historical audit receipt's reviewed base as its sole parent, and its entire Git tree equals the successful PR tree. The receipt must establish a distinct independent reviewer, no unresolved findings and exact CI provenance. Do not use a merged PR's mutable `base.sha` as the captured base.

The resolver checks the original successful native PR run, attempt, head, repository, workflow, job/check identity and the matching local schema-2 manifest with actual worker coverage. It derives gate, selected UI identifiers and complete unit identifiers from committed Git source, requiring exact same-gate selection and execution coverage. Missing, stale, failed, unsupported, ambiguous or inaccessible evidence causes full active-gate verification. The original manifest must name the same `pre_design_smoke` gate and exact unit/smoke inventory; old 139-case or unlabeled records do not authorize inheritance. Schema-1 manifests lack the necessary evidence and cannot supply inheritance. Main still compiles its actual source, installs/launches its Debug app on an owned simulator, verifies the running process, performs source discovery and builds a new ARM64 Release product.

Schema-2 verification and release metadata distinguish `full` tests from `inherited` tests and name `tests.gate = pre_design_smoke`. Here `full` means the complete approved gate, not comprehensive UI coverage. Explicit extended runs use `mode = extended`, `gate = extended_ui`; focused runs use `mode = focused`, `gate = focused`. Release notes explicitly state all-unit/three-smoke coverage and the deferred broader UI journeys. Inherited records retain original head, run/attempt, inventory, PR, captured base, tree and audit reference; they never claim that tests executed on main. Publication revalidates inherited provenance, keeps same-attempt main-native and same-runner gates, and remains manual. Uploaded historical schema-1 release metadata remains immutable and valid for original-byte retries; a new package requires schema 2 and fresh main smoke evidence.

## Agent-grill self-assessment

| Question | Kind | Answer and evidence | Verification |
| --- | --- | --- | --- |
| Where is the bottleneck? | Fact | Exact baseline `f3dc1620b675a0d0e90119855a55f8326609d8eb`, native run `37196691566`: 120 unit cases in 6.004 seconds, 41 UI cases in 1762.941 seconds, total native 1794.432 seconds. Four endless cases used 726.134 seconds; three integration cases used 265.877 seconds. | Original successful result bundle and exported per-case profile retained outside Git. |
| Which coverage can move out of ordinary walkthroughs? | Delegated choice | Deterministic lower layers verify deep rule/lifecycle/history/cadence combinations. The owner subsequently approved all units plus three launch/paging/input-reset UI cases until design agreement; broader platform journeys remain available explicitly. | Inventory/gate regression, historical broader benchmark, and final smoke-gate CI. |
| How can two workers actually execute independently? | Fact and delegated choice | The scheme and old driver force serial testing. Partition selected cases between two separate serial processes, unique device IDs and result paths, sharing only read-only compiled products under one build owner. | Actual device and test inventories plus one/two timings; no policy switch without passing speedup. |
| How can main avoid duplicate tests honestly? | Delegated choice under owner direction | Captured independent audit base, actual sole-parent/tree equality, live successful PR provenance and local coverage manifest; otherwise full fallback. | Disposable Git/API regressions, smoke-failure regressions, release legacy/retry regressions, actual main after gated merge. |

Xcode verbose post-failure sysdiagnose is disabled with its documented `-collect-test-diagnostics never` option. Actual failed XCTest results, screenshots and logs remain; this changes diagnostic collection rather than assertions or test outcomes. A focused cold Files failure demonstrated an automatic collector with a 600-second timeout.

## Measurements

The original serial baseline above is observed. The earlier compact one/two-worker comparison is recorded below. Actual temporary-gate CI measurements are recorded below; they are independent of the broader benchmark. The recorded main runs used full fallback; [#90](https://github.com/devofthings/sidequest/issues/90) tracks subsequent workflow-token inheritance proof. Exact-head CI and fresh independent review remain required before merge. Physical-device execution remains deferred under #79.

Initial compact attempt: 120 unit and 19 UI cases executed; 138 passed and the native import case failed at its Locations assertion. UI time was 512.698 seconds, but this failed run cannot choose a worker policy or establish the target. A focused cold-picker attempt failed its initial provider-existence assertion in 20.759 seconds. Both failed bundles/logs remain outside Git. At that checkpoint, targeted retest and a complete same-inventory worker comparison were pending; the policy stayed at one worker.

Focused Files retest passed on a fresh owned simulator after the native Browse-state correction: 160.436 seconds for the unchanged test, 186.845 seconds for native execution, and 54.288 seconds for the cold Debug compile. The picker became available during its 10-second readiness wait, and repeated valid/rejected/empty selection, native cancellation and terminate/relaunch persistence assertions all passed. The owned device shut down successfully.

The complete comparison also runs offline tooling, strict format/whitespace, source discovery and a unique cold ARM64 Release build for each worker policy. `ordinary_verification_seconds` measures those required checks together with current compilation and native execution. Device creation/toolchain inspection are separately recorded; both policies start with the same warmed Debug cache and booted owned devices. Record this boundary when reporting the target and retain cold-start overhead separately.

The completed October 4 comparison at `cbbe733d6c23af85e7afcf58977388e8272606eb` used the same 120 unit and 19 UI cases, Xcode 27.0 (27A266a), iOS 27.0 (24A434), and native source fingerprint `165886f1558ba8ce84768c9838c21819c173f12d006606db988a428a7b26e6fe`. Both policies passed every case with zero failures or skips:

| Policy | Current incremental Debug compile | Tests and result validation | Complete ordinary pipeline |
| --- | --- | --- | --- |
| One owned simulator | 3.608 seconds | 664.053 seconds | 738.603 seconds (12 minutes 19 seconds) |
| Two owned simulators | 1.781 seconds | 327.398 seconds | 398.434 seconds (6 minutes 38 seconds) |

The two-worker inventory was disjoint: worker 1 ran 120 units and 9 UI cases in 325.997 native seconds; worker 2 ran 10 UI cases in 310.418 native seconds. Their actual device IDs were `8EEA5694-3F2B-4B37-83B0-72D5C97E1A09` and `45D608EC-EFF8-45B9-A8E2-1F07CA227170`. Both shut down successfully. Results, commands, logs, and fresh Release products remain at `/private/tmp/sidequest-90-benchmark-4` on the verification Mac.

The measured complete pipeline improved by 46.1% and met the target for this inventory under the stated warm boundary. Toolchain inspection, device creation/initial boot, and initial Debug compile took another 142.728 seconds, including 53.937 seconds for compilation; they were outside both timed policies. The second policy reused the first simulator after the serial run. Cold Actions wall time, broader source-affected selections, and main's full fallback have not been measured by this comparison. Do not claim every app change or cold run meets 5–10 minutes. The owner's subsequent accepted pre-design smoke decision supersedes this inventory as the routine gate. This comparison remains historical evidence and does not certify the new gate's timing.


## Measured temporary-gate CI

The exact reviewed PR head `3c38e09b52a3f683bcbe46f7815c1f43fdeafe7d` passed [native CI run 37230539581](https://github.com/devofthings/sidequest/actions/runs/37230539581/job/111519076360) in 225 seconds (3 minutes 45 seconds). All 123 cases passed: 120 unit tests and three UI smoke cases, with no failures or skips. The same job compiled current Debug source, performed source discovery and strict formatting/tooling checks, and built a fresh ARM64 Release product. PR #110 merged as `e153d25f6150c85fd90a8b8cccfeb8651b241166`.

The first [main verification, run 37230931516 attempt 1](https://github.com/devofthings/sidequest/actions/runs/37230931516/job/111520206084), passed in 221 seconds (3 minutes 41 seconds) at that exact merged commit. It safely reran the complete active 123-case gate, then freshly installed/launched the app, checked its running process, terminated it, and built its unique ARM64 Release product. This was full active-gate verification, not inherited execution; main push publication remained skipped.

A [retry of the same main run, attempt 2](https://github.com/devofthings/sidequest/actions/runs/37230931516/job/111521213604), also passed in 217 seconds (3 minutes 37 seconds) with full active-gate fallback and actual install/launch/process/terminate, discovery and ARM64 Release checks. It did not establish inherited execution.

The original workflow omitted `statuses: read`, which the private historical-review-status API requires. The follow-up adds that read scope in verification and the publisher's explicit permission override, and reports sanitized fallback categories. The two recorded main runs establish full-fallback coverage, rather than inherited execution. [Issue #90](https://github.com/devofthings/sidequest/issues/90) tracks subsequent workflow-token proof; a personal-token read-only resolver success cannot substitute for that execution. The earlier 139-case warm one/two-worker benchmark remains historical evidence and does not choose workers for this serial smoke policy.
