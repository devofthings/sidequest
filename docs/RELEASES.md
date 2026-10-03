# Private builds and release history

## Accepted delivery policy

The user authorizes a private GitHub Release build for each update merged into `main`, including documentation updates. This covers private simulator previews; spending, App Store publication, and TestFlight distribution require separate approval. The personal-iPhone path remains source plus local Xcode signing in [INSTALL.md](INSTALL.md).

Issue #31 established the executable workflow after foundation #1 and CI #15 and is complete. Actual private previews retain earlier merged commits, including [Sudoku](https://github.com/devofthings/sidequest/releases/tag/preview-fb02ebb45bb20a12308138b6ad39236b6fc11e25) and [Memory](https://github.com/devofthings/sidequest/releases/tag/preview-d2d1d3cc358af94b5d667cbabdb8cb6261c1df96). Check the private [release history](https://github.com/devofthings/sidequest/releases) for each later version; a draft or unmerged implementation is not a published download.

## Verify and publish

PR verification remains in `.github/workflows/verification.yml`. Every main push, including documentation changes, runs `.github/workflows/releases.yml` instead: its `Sidequest / verification` job runs the same full checks and an unsigned ARM64 Release build, then a publishing job uses the retained local output. Both use the pinned official checkout action and the unique foreground-Mac runner label. There is no duplicate main build, hosted fallback, artifact/cache upload, service, or recurring schedule.

Each main run uses its exact event SHA, even after newer merges arrive. The concurrency group includes that SHA and never cancels older main runs; obsolete PR checks have a separate cancellation policy. An offline runner leaves work queued. See [CI.md](CI.md) for starting, handing off, and stopping the foreground runner.

The publishing job alone receives `contents: write`; `actions: read` and `checks: read` let it validate GitHub's actual verification job/check metadata. It requires the same main event commit, successful native `Sidequest / verification`, the same registered runner ID, and a matching local manifest. Missing output, a different host, failed checks/builds, or mismatched identity stops publication before creating release data.

The verified Release build uses `ARCHS=arm64` with Xcode 27.0 (27A266a), iOS simulator SDK 27.0, and runtime iOS 27.0 (24A434). The publisher verifies the executable architecture, rejects signing/test/guidance files, and archives only `Sidequest.app`. Personal captures and signing configuration remain outside Git and all synchronized source roots. The `.app` is a Mac simulator build, not an iPhone-installable IPA.

On October 4, 2026, the user selected `year.month.build` release versions, implemented by [issue #85](https://github.com/devofthings/sidequest/issues/85). New runs using this publisher use `YYYY.MM.build` as both their tag and display name, for example `2026.10.24`. UTC year and zero-padded month come from the exact live workflow run’s original `created_at`; build is its positive `run_number`, which increases across this workflow’s runs and does not reset each month. Neither the current clock, rerun start time, run attempt, nor a custom version environment variable selects a version. GitHub documents [run-number stability on reruns](https://docs.github.com/en/actions/reference/workflows-and-actions/variables) and [workflow run timestamps](https://docs.github.com/en/rest/actions/workflow-runs).

Each version retains the full source SHA in metadata and its Git tag target. Rerunning the same workflow run preserves its version even across a month boundary. A distinct workflow run receives its own version, including if it verifies the same source again. Historical `preview-<full-40-character-SHA>` tags/releases remain unchanged; retrying their original source executes their historical publisher. Never rename, renumber, or overwrite historical releases to migrate the format. New format publication remains pending until a successful merged workflow actually publishes it.

Notes link source installation and the original verification job/workflow. Three assets make the build reviewable:

- `Sidequest-simulator-arm64.zip`: the unsigned app, preserving executable permissions.
- `build-metadata.json`: full source SHA, version, original run ID/attempt, live run number/creation timestamp, app identifier/minimum OS, toolchain/runtime/architecture, original build/check URLs, and archive SHA-256.
- `SHA256SUMS`: SHA-256 for the archive and metadata.

The release is created as a draft; metadata, checksums, and archive are uploaded without overwriting existing assets. The publisher downloads and checks the complete asset set before publishing it as a prerelease. Failed/interrupted uploads leave an incomplete draft, never a successful release. Build diagnostics and original package bytes remain on the Mac under `sidequest-diagnostics/<run-id>-<attempt>/release/`.

## Retry and investigate

To retry an existing workflow, rerun the entire run so verification and publishing share the same new attempt:

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

The agent-grill readiness interview resolved the following technical choices within approved #31; it does not certify code or claim published releases.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| How do main releases preserve PR check semantics? | Delegated choice | PR-only verification workflow; main-only verification plus publishing workflow. | The review gate rejects skipped checks; separate events avoid a skipped PR publisher and duplicate main builds. | Exact check name/head/URL; actual main releases after merge. |
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

The plan is ready within approved scope; local offline publication and CI-handoff checks pass. No new workflow, app bundle version, signing scheme, schedule, hosting, payment, or publishing destination is introduced. Actual new-format release proof remains pending until merge and successful main publication.
