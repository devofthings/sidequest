# Private builds and release history

## Accepted delivery policy

On October 4, 2026, the user instructed: “only release the next thing when we are done with the mvp also cleanup the older preview builds.” This supersedes automatic publication after each merged update. Main updates still receive native verification and a local unsigned Release build; **publication is held until the actual MVP integration is complete**. Spending, App Store publication, and TestFlight distribution remain separately gated. The personal-iPhone path remains source plus local Xcode signing in [INSTALL.md](INSTALL.md).

[Issue #92](https://github.com/devofthings/sidequest/issues/92) introduced the tracked publication hold with no environment bypass. Integration readiness [PR #101](https://github.com/devofthings/sidequest/pull/101) enabled `PUBLICATION_ENABLED = True` only after functional/native/source-install proof, fresh independent review, and successful exact-head CI. Its partial contribution left #9 open for actual final-tag proof. After gated merge and successful main verification, explicit manual dispatch published [2026.10.14](https://github.com/devofthings/sidequest/releases/tag/2026.10.14); [selected-source/download installation proof](INSTALL.md#verified-mvp-delivery) passed. Closing an issue or setting an environment value does not establish readiness. Automatic per-update publishing remains disabled.

Issue #31 established private release history. The user-authorized cleanup removed seven older preview release objects and 21 assets, including the last development download only after the MVP proof passed. All Git tags/source remain, including `2026.10.7` for README statistics. Only the verified MVP download remains in the private [release history](https://github.com/devofthings/sidequest/releases). Cleanup was coordinated by the lead; the publisher itself never deletes or retargets history.

## Verify and publish

PR verification remains in `.github/workflows/verification.yml`. Every main push, including documentation changes, runs `.github/workflows/releases.yml` instead: its `Sidequest / verification` job runs the same full checks and an unsigned ARM64 Release build, and publication is skipped. The same workflow accepts an explicit `workflow_dispatch` on main, verifies that exact event SHA, and then attempts the manual publisher using the retained local output. Both use the pinned official checkout action and the unique foreground-Mac runner label. There is no duplicate main build, hosted fallback, artifact/cache upload, service, or recurring schedule.

Each main run uses its exact event SHA, even after newer merges arrive. The concurrency group includes that SHA and never cancels older main runs; obsolete PR checks have a separate cancellation policy. An offline runner leaves work queued. See [CI.md](CI.md) for starting, handing off, and stopping the foreground runner.

The publishing job alone receives `contents: write`; `actions: read` and `checks: read` let it validate GitHub's actual verification job/check metadata. It first requires manual main dispatch and the tracked readiness flag. Then it requires the same manual event commit, successful native `Sidequest / verification`, the same registered runner ID, and a matching local manifest. Missing output, a different host, failed checks/builds, or mismatched identity stops publication before creating release data.

The verified Release build uses `ARCHS=arm64` with Xcode 27.0 (27A266a), iOS simulator SDK 27.0, and runtime iOS 27.0 (24A434). The publisher verifies the executable architecture, rejects signing/test/guidance files, and archives only `Sidequest.app`. Personal captures and signing configuration remain outside Git and all synchronized source roots. The `.app` is a Mac simulator build, not an iPhone-installable IPA.

On October 4, 2026, the user selected `year.month.build` release versions, implemented by [issue #85](https://github.com/devofthings/sidequest/issues/85). New runs using this publisher use `YYYY.MM.build` as both their tag and display name, for example `2026.10.24`. UTC year and zero-padded month come from the exact live workflow run’s original `created_at`; build is its positive `run_number`, which increases across this workflow’s runs and does not reset each month. Neither the current clock, rerun start time, run attempt, nor a custom version environment variable selects a version. GitHub documents [run-number stability on reruns](https://docs.github.com/en/actions/reference/workflows-and-actions/variables) and [workflow run timestamps](https://docs.github.com/en/rest/actions/workflow-runs).

Each version retains the full source SHA in metadata and its Git tag target. Rerunning the same workflow run preserves its version even across a month boundary. A distinct workflow run receives its own version, including if it verifies the same source again. Historical `preview-<full-40-character-SHA>` tags remain unchanged; explicitly authorized cleanup may remove older release objects/assets without rewriting source history. Never rename, renumber, or overwrite a retained release to migrate the format. The historical `2026.10.7` publication first demonstrated the format; the current `2026.10.14` MVP demonstrates verified manual publication. Its source tag remains after old-download cleanup.

Notes link source installation and the original verification job/workflow. Three assets make the build reviewable:

- `Sidequest-simulator-arm64.zip`: the unsigned app, preserving executable permissions.
- `build-metadata.json`: full source SHA, version, original run ID/attempt, live run number/creation timestamp, app identifier/minimum OS, toolchain/runtime/architecture, original build/check URLs, and archive SHA-256.
- `SHA256SUMS`: SHA-256 for the archive and metadata.

The release is created as a draft; metadata, checksums, and archive are uploaded without overwriting existing assets. The publisher downloads and checks the complete asset set before publishing it as a prerelease. Failed/interrupted uploads leave an incomplete draft, never a successful release. Build diagnostics and original package bytes remain on the Mac under `sidequest-diagnostics/<run-id>-<attempt>/release/`.

## Manual publication and retries

While held, do not dispatch publication or rerun historical push-release workflows: their original code predates this hold. The lead canceled the outstanding publication retry and temporarily disabled the workflow during the transition. Reenable the workflow only after the reviewed hold configuration lands, so main verification resumes safely. Reenabling the workflow does not enable publication.

After integration #9's reviewed readiness change enables the tracked flag, merge and verify main first. Then the lead can explicitly request publication:

```sh
gh workflow run releases.yml --ref main --repo devofthings/sidequest
```

This has no custom version input. [GitHub's dispatch contract](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch) binds the event SHA to the selected ref; this workflow accepts main only and performs full verification before publication. Feature-branch/tag dispatches cannot run the release jobs. A held main dispatch fails the publisher before repository/source access or release writes. A push never publishes, even after readiness enablement.

To retry an eligible **manual** workflow after the hold is lifted, rerun the entire run so verification and publishing share the same new attempt:

```sh
gh run rerun <run-id> --repo devofthings/sidequest
```

Do not use `--failed` to bypass the current attempt's full verification. A published retry validates the original tag/display name, full source SHA, original run-number/date provenance, actual successful native verification, server/download digests, and complete asset set, then leaves the release identity and bytes unchanged. It does not replace assets with a newly rebuilt app.

A draft retry checks its already uploaded assets and resumes missing uploads using the original retained package. If no metadata was uploaded, a fully verified retry may choose its new package for the same workflow run and source commit; the unpublished draft notes are reconciled with the selected metadata before publication. A version collision, different run identity, conflicting metadata/checksums, different tag target/display name, incomplete server uploads, missing original bytes, or unavailable original verification evidence requires investigation; the publisher preserves existing history and fails. Recover the exact original package when needed. Never use `--clobber`, retarget a version tag, or silently replace a published release.

Actions shows the failed command and local diagnostic path; the verification summary lists results and the publishing summary links the completed release. Keep enough private GitHub/local evidence to associate every version with its source and checks. [Completed issue #31](https://github.com/devofthings/sidequest/issues/31) retains first/second release demonstrations; [installation guidance](INSTALL.md#download-a-simulator-preview) gives download/check/install commands once a version exists.

## Execution and storage costs

On October 3, 2026, [GitHub's billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions) makes self-hosted execution free and meters Actions artifacts/caches and Packages, none of which this route uses. Existing hardware, the installed Xcode/runtime, and foreground execution follow [CI.md](CI.md).

[GitHub's Release documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas) allows up to 1000 assets per release, each under 2 GiB, without a total release-size or bandwidth quota. Combined with the documented metered products above, the lead's current no-metered-release-storage conclusion is an inference from official limits and billing documentation; GitHub Releases are used directly, with no LFS, Packages, or Actions artifact storage. No plan, payment method, or paid activation is changed.

Recheck these official terms before a new publication session or infrastructure/storage change. If zero-cost execution/storage cannot be supported, keep publication pending under the [spending rule](../AGENTS.md#spending-approval) and continue independent work. A budget alert alone is not evidence that charges are prevented.

## Implementation question record

Historical #31 planning is retained below; #92 supersedes its publication trigger. The agent-grill readiness interview resolved the following technical choices within approved #31; it does not certify code or claim published releases.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| How do main releases preserve PR check semantics? | Delegated choice; trigger superseded by #92 | PR-only verification; main pushes verify without publishing; eligible manual main dispatch verifies then publishes. | The review gate rejects skipped checks; separate events avoid a skipped PR publisher and duplicate main builds. | Exact check name/head/URL; actual main releases after merge. |
| How can build output cross jobs without metered uploads? | Delegated choice | Same unique foreground runner and checked local directory/manifest. | Existing Mac and CI diagnostics are local; no artifact/cache storage is approved. | API runner IDs, native green check, exact event/manifest, missing/different-host rejection tests. |
| How should retries preserve source and bytes? | Delegated choice; version format superseded by #85 | Immutable run-derived tag plus full SHA provenance, draft-first complete assets, published validation without overwrite; draft recovery from original bytes. | Accepted traceability/idempotency criteria and the user’s October 4 version-format choice. Historical full-SHA tags remain unchanged. | Offline interrupted/corrupt/conflicting/missing-package tests; actual first/second historical releases and retry evidence. |
| What architecture should archives declare? | Fact and delegated choice | Explicit ARM64 Release build and `lipo` assertion. | Default Release output can be universal; the verified runtime and machine are ARM64. | Real local ARM64 build/archive; repeat in CI. |
| Is release storage metered? | Fact/inference | Current official limits/billing support direct non-metered Releases; recheck before publication. | Official sources above distinguish Releases from Actions artifacts, cache, Packages, and LFS. | No metered uploads/activation; pricing review before publication sessions. |

### Versioning readiness self-assessment (#85)

Interviewee: `/root/review_gates_66`; agent-grill self-assessment within the user’s explicit numbering request.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Which date and build identify a release? | Accepted format + delegated technical choice | UTC `created_at` year/month plus live workflow `run_number`; `YYYY.MM.build`. | User chose year.month.build; GitHub’s run API exposes original creation time and run number, and its variables reference documents stable run numbers on reruns. | Offline month-boundary and rerun regressions; current native CI and actual new-format publication after merge remain required. |
| Can environment inputs pick another version? | Delegated technical choice | No custom override. Exact run ID/head/workflow are verified live; environment and local manifest run numbers must match the live run. Metadata binds original run ID, number, and creation timestamp. | The same-runner manifest already binds tested source/attempt. Version claims need the same live provenance instead of trusting arbitrary environment text. | Malformed date/number, wrong run/workflow, environment/manifest mismatch, and uploaded provenance collision tests. |
| How do history and empty drafts migrate? | Delegated technical choice | Preserve historical SHA tags. New runs use the new version; same-run drafts recover exact bytes once metadata exists. An empty draft must identify this source and workflow run before adopting a newly verified package. | Accepted immutable history and interrupted-draft policy; another run cannot silently inherit a colliding empty version. | Published no-write retry, empty-draft same-run recovery, conflicting-run rejection, historical-tag preservation, and later-run history tests. |

The plan is ready within approved scope; local offline publication and CI-handoff checks pass. No new workflow, app bundle version, signing scheme, schedule, hosting, payment, or publishing destination is introduced. The historical 2026.10.7 publication demonstrated the new format. Actual `2026.10.14` MVP publication followed the reviewed integration readiness and explicit manual main sequence above; old downloads were subsequently cleaned up without changing tags/source.

### Release-hold readiness self-assessment (#92)

Interviewee: `/root/review_gates_66`; agent-grill self-assessment. The user owns the accepted hold; the active lead approved the bounded source flag and manual-dispatch implementation.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| What proves publication can resume? | Accepted hold + delegated choice | A reviewed integration #9/readiness change enables the tracked flag only after actual MVP criteria and dependencies pass; then an explicit main dispatch. | Early issue closure or an environment string cannot establish actual integration readiness. No automatic publishing is restored. | Actual held/manual/push denial tests; fresh review/native CI and later lead-recorded MVP evidence before enabling. |
| Can every merge still be verified? | Delegated choice | Preserve main push verification and local unsigned Release builds; skip publishing on push. Manual main events use the same exact-SHA driver. | Existing free foreground workflow and native check contract remain authoritative. | Offline actual Git history proves queued push/manual SHA checks; CI handoff fixtures preserve event/run provenance. Actual main verification/publisher-skipped proof follows merge. |
| Does manual publication preserve source, version, and bytes? | Delegated choice | Bind live workflow_dispatch/main/head, native same-attempt success, matching manual manifest, same registered runner, UTC run-created version, and existing immutable draft/retry rules. | #85 provenance and #31 package gates apply to the manual event without external override. | Future-enabled offline fixtures explicitly patch only the flag; actual tracked hold is tested separately. Current native CI and fresh independent review remain required. |

No cleanup operation, spending, schedule, hosted fallback, or app feature is introduced here. Historical workflows retain old code and must not be rerun during the hold. Actual publication after enablement remains a later lead action, not a claim from passing fixtures.

### Integration readiness evidence (#9)

The October 4 author run at `0f11d673277e10a71f421a75cc7bc64c5e5365ad` passed all 133 native tests: 96 unit and 37 running-app tests, zero failures/skips/runtime warnings. It verifies real-game play/start/skip/revisit, atomic news replacement and rejection, native Files cancellation and persistence, modal/scene cancellation, largest text, news scrolling/source return, and actual system Reduce Motion. ARM64 Release and source-discovery checks also passed. A fresh clean checkout at `35b31890f1d371d8d71f6bdf6c4262f3d9d9b664` built, installed, and launched its Release product; app/project source is identical at the later held candidate. Issue #9 retains the detailed author evidence. These author results do not replace final-target review or CI.

Readiness enables only explicit manual publication from reviewed main. Offline regressions separately force the disabled source to prove denial without network/source access or environment bypass, and test the actual enabled source's rejection of push, PR, branch, and tag events. Existing native-job, manifest, package, provenance, retry, and checksum gates remain unchanged. Actual `2026.10.14` publication and final selected-tag source/checksum/install proof passed after gated merge, main verification, and manual dispatch; see the evidence below. Physical-device signing/install remains deferred under #79.

### Published MVP evidence

[2026.10.14](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) was published October 4 at 05:19:00 UTC from `65bd39003a2a22dbb3c19f61cbb4b9e86c3c32b9`. Manual run `37178518287`, attempt `1`, was created at `2026-10-04T04:58:13Z` with live run number `14`. [Native verification](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111366112952) passed all 133 tests (96 unit, 37 UI), zero failures/skips/runtime warnings, Debug/ARM64 Release builds, strict formatting, source discovery, and offline tooling. The [publisher](https://github.com/devofthings/sidequest/actions/runs/37178518287/job/111369040433) succeeded on the same foreground runner. The preceding [main push](https://github.com/devofthings/sidequest/actions/runs/37177526471) verified successfully and actually skipped publication.

[Final delivery proof](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508) independently built, installed, and launched a fresh checkout of the actual tag, then downloaded/checksummed the three published assets and installed/launched the published app. The installed executable matched the extracted archive. Both normal launches showed real Tap-to-play game previews with the five-card empty-news deck. No private captures or Debug flags entered the release or proof. Physical-iPhone signing/install, device VoiceOver, and iOS 17 execution remain deferred/unverified. See [INSTALL.md](INSTALL.md#verified-mvp-delivery) for the actual download/source-signing route.

Seven older preview objects and 21 assets were deleted under the user’s explicit cleanup request; the last development preview was retained until this proof passed. Deleted IDs returned HTTP 404, all tags/source stayed intact, and current MVP asset IDs/digests remained unchanged. Screenshots stay outside Git. No automatic publishing, historical publisher retry, paid upload, plan/payment change, or recurring execution was introduced. Later documentation updates do not publish a second app.
