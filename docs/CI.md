# Sidequest verification

Issue #15 uses a repository-specific self-hosted runner on this Apple-silicon Mac. Run it in the foreground only while an authorized lead is working. An offline runner leaves jobs queued and merging pending; there is no hosted fallback, service installation, or recurring Codex schedule.

## Execution and cost boundary

On October 3, 2026, [GitHub's runner documentation](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners) states self-hosted Actions execution is free. The correction at the top of [GitHub's pricing announcement](https://github.com/resources/insights/2026-pricing-changes-for-github-actions) postpones its proposed self-hosted charge. This route uses existing hardware, Xcode, and an installed free simulator runtime. Hosted usage beyond included quotas can incur charges and is not approved.

The workflow uploads no artifacts, caches, or Packages. [GitHub's billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions) excludes logs and job summaries from Actions storage usage. Build logs and XCTest results remain on this Mac. Recheck pricing before a new execution session or changing storage/runner behavior; if zero cost cannot be confirmed, leave execution pending under the [spending rule](../AGENTS.md#spending-approval).

## Register and run

Use the [verified toolchain/runtime](INSTALL.md#verified-foundation), Python 3, Git, and an existing `gh` login with repository administration access. Runner registration requires access, not a new paid account or authentication-scope refresh.

```sh
python3 scripts/configure-ci-runner.py --directory /private/tmp/sidequest-actions-runner
cd /private/tmp/sidequest-actions-runner
./run.sh
```

The installer downloads official ARM64 runner **2.337.0**, checks SHA-256 `5a2cd92908a93d7276a194e1de6008099f3e7946f3f8e14aa7a1a7b4a31fdec2`, confirms the repository is private, and registers `Sidequest-Mac-foreground`. Tokens are parsed in memory and configuration output is suppressed. The private directory and credentials must stay outside every Git checkout, including linked worktrees and symlink destinations; the installer rejects these locations before downloads or registration. Preserve an existing directory rather than overwriting it. No `svc.sh` or launchd installation is used.

Required labels are `self-hosted`, `macOS`, `ARM64`, `sidequest`, `xcode-27`, and unique `sidequest-mac-foreground`. Automatic runner updates are disabled to keep the runner version explicit; GitHub [requires prompt manual updates](https://docs.github.com/en/actions/reference/runners/self-hosted-runners#runner-software-updates-on-self-hosted-runners). Update the pinned version/digest through a reviewed PR before GitHub stops assigning jobs. Never work around an unsupported runner with hosted compute.

Leave the foreground process running during build/review/merge work, and give the next active lead its session identifier. When the authorized session ends, allow its current job to finish, then press Ctrl-C; queued jobs wait for a later authorized session. Disconnecting does not unregister the runner. To retire this exact runner, stop it and remove `Sidequest-Mac-foreground` in the repository's Settings > Actions > Runners before deleting its private directory. Preserve other runners, devices, and diagnostic files unless their owner authorizes cleanup.

## Verification contract

PR verification runs for same-repository PRs; the main-only [release workflow](RELEASES.md) runs the same verification job for every push to main without publishing. Explicit manual main dispatch also verifies its exact event, but publication stays blocked until reviewed MVP readiness enables the tracked source flag. The repository is private and its agents use trusted feature branches. Fork PRs cannot execute; same-repository contributors can execute code on this Mac, so repository write access must stay trusted. `pull_request_target` is not used. The workflow has only `contents: read`, and checkout is pinned to the reviewed official revision with credentials not persisted.

`Sidequest / verification` checks out the explicit PR head rather than the generated merge ref, fetches history, and requires the current base to be its ancestor. A stale feature branch fails and needs rebase/reverification. Main runs verify their exact event commit and its own parent-to-commit change; a newer main tip cannot invalidate an older queued event. Obsolete PR runs may be canceled; main runs have unique SHA groups and are never canceled by a newer main update.

`scripts/ci-verify.py` checks:

- The actual commit, PR current-base ancestry, whitespace, and absence of local signing/personal news inputs. Recheck exact HEAD and a clean tracked/untracked checkout before native compilation and before a successful manifest.
- The verified Xcode 27.0 (27A266a), offline Markdown links/heading anchors, strict first-party Swift formatting, and local tooling regression suites.
- An unsigned current Debug build-for-testing, all deterministic unit tests and the three approved pre-design UI smoke cases, filesystem-synchronized source/resource discovery, and an unsigned ARM64 Release build (`ARCHS=arm64`).

`scripts/test-ci.py` uses actual disposable Git history to prove older queued main commits pass, stale PRs fail, wrong commits/events fail, and current PRs pass. Actual changed-path regressions preserve both ownership paths of renames and filenames with newlines; dirty tracked or untracked native files cannot supply exact-commit evidence. Stubbed network calls prove Git-owned runner locations are rejected before registration and existing private configuration is preserved.

Issue #90 replaces duplicate native walkthroughs with an explicit required/extended inventory and always-current incremental `build-for-testing` followed by `test-without-building`. Follow [testing policy](TESTING.md) for coverage mapping, exclusive cache/native ownership, focused commands, worker benchmark and measured timing. Both native workflow budgets retain their 45-minute failure bound; the ordinary target is 5–10 minutes, not an arbitrary timeout. Every failed command fails the job.

PR checks run the complete `pre_design_smoke` gate on one owned simulator until design agreement. Changed ownership paths do not reactivate deferred UI suites; explicit extended commands retain them. Broader activation requires a recorded decision and reviewed source PR. Main may inherit only proven identical reviewed squash-tree test evidence; all missing or unverifiable provenance falls back to the complete active gate. Inheritance requires matching gate identity and exact unit/smoke inventory. Actual main source compilation, owned-simulator install/launch/process smoke, source discovery and a separate fresh ARM64 Release build remain required. Read-only Actions/checks/PR API access and an explicit token are scoped to main provenance; verification receives no write permissions. [Schema-2 metadata](TESTING.md#main-inheritance) records inherited evidence against its original PR head/run.

Unique per-worker logs/results and per-run Release products/manifests stay under `sidequest-diagnostics/<run-id>-<attempt>/` outside the checkout. Only incrementally compiled Debug products live in the separately locked local cache. No artifact/cache upload is introduced. The summary retains actual command outcomes and elapsed times; keep original failed diagnostics too.

Before merging, [review gates](REVIEW_GATES.md) require a successful check run named `Sidequest / verification` whose actual `head_sha` is the reviewed head and whose `details_url` matches the receipt. A successful older run or local assertion cannot substitute. A changed head/base needs fresh independent review and matching CI evidence. Failed, pending, canceled, or skipped checks block merging.

The main-only [release workflow](RELEASES.md) verifies exact merged commits and keeps main pushes verification-only. Once reviewed integration readiness lifts the tracked hold, explicit manual main dispatch publishes only after matching native success and a same-runner local handoff. Issue #31’s historical release proof is complete; #92 supersedes its automatic trigger. CI does not install on a physical iPhone or verify gameplay that has not been implemented.

## Implementation question record

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Which execution route avoids GitHub charges? | Fact and delegated choice | Existing Mac, repository-only foreground self-hosted runner; no hosted fallback or uploads. | Current official free-execution docs above and approved issue #15. | Verify runner registration/labels and actual workflow execution; recheck pricing before future sessions. |
| Which commit and simulator should tests use? | Delegated choice | Explicit PR head with current-base ancestry; dedicated iOS 27.0 simulator. | Review gate requires exact head/base; dedicated device avoids interference with local development. | Inspect actual check-run SHA/URL; run build, unit/UI, source-discovery, and Release checks. |
| How are failures and release prerequisites preserved? | Delegated choice | Fail on every required check, retain local diagnostics, cancel only obsolete PR runs. | Issue #15 acceptance and private release policy. | Demonstrate an intentionally broken documentation link, then remove it and run successful verification. |
