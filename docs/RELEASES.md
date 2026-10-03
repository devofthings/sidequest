# Private builds and release history

## Accepted delivery policy

The user authorizes a private GitHub Release build for each update merged into `main`, including documentation updates, once the executable app and release automation exist. Publish successful builds in the private [release history](https://github.com/devofthings/sidequest/releases) so each version can be traced to its source and verification. This authorization covers private GitHub Releases; spending, App Store publication, and TestFlight distribution require separate approval.

The app and automation are not implemented yet. [Issue #31](https://github.com/devofthings/sidequest/issues/31) depends on the [foundation](https://github.com/devofthings/sidequest/issues/1) and [CI](https://github.com/devofthings/sidequest/issues/15). There is currently no build or release to download.

## Build and publish

- Build the Release configuration of the foundation's shared scheme from the exact merged commit. Complete the relevant verification before publication; a successful PR review alone is not a successful release build.
- Give each successful build a unique version/tag, full commit SHA, workflow-run link, release notes, asset checksums, toolchain/runtime requirements, and a link to [installation instructions](INSTALL.md).
- Publish private preview releases with a simulator `.app` archive. State the supported architecture and runtime. Keep personal news captures and signing material out of release assets. Physical-device installation initially uses source and local Xcode signing.
- Preserve a release for every successful merged update. Do not cancel an older main release job because a newer update arrives. Retries must keep the commit identity and avoid silently replacing published versions or assets.
- Leave failures visible in Actions and report missing prerequisites; publish no successful release for a failed or unverified build. Keep enough history to associate each release with its source and checks.
- Update installation instructions when setup, toolchain, imports, or signing behavior changes. Record development choices in the applicable `AGENTS.md`.

## Execution costs

Apply the [spending approval rule](../AGENTS.md#spending-approval) before enabling or running the workflow. Verify that runner execution and retained storage cannot incur charges, or obtain explicit approval first. Included private-repository Actions usage is limited, and usage beyond those allowances can be billed. A verified macOS self-hosted runner is another option; no runner is registered in this repository yet. See [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) and [budget controls](https://docs.github.com/en/billing/how-tos/set-up-budgets).

Keep the repository private and make no plan upgrades or paid-service activations as part of release setup. An alert by itself is not evidence that chargeable usage is prevented. Until free execution or explicit spending approval is established, keep release execution pending while completing other work.
