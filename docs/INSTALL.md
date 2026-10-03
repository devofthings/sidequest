# Install and run Sidequest

## Current status

Sidequest currently contains planning documents and [Swift formatting tools and commit checks](FORMATTING.md). There is no Xcode app project, executable scheme, simulator build, or iPhone package to install. The [app foundation](https://github.com/devofthings/sidequest/issues/1) will supply verified project paths and commands; [integration](https://github.com/devofthings/sidequest/issues/9) will verify the complete news-and-games experience. The steps below describe the installation workflow and have not yet been verified with a Sidequest app.

## Get the source

You need access to the private repository. Use your existing checkout, or clone it from a directory where you want a new checkout:

```sh
gh repo clone devofthings/sidequest
```

After cloning, follow [FORMATTING.md](FORMATTING.md#install-commit-checks) to enable the tracked commit checks explicitly in that clone.

For a specific published version, open the private [GitHub Releases page](https://github.com/devofthings/sidequest/releases) and use its tagged source. The release notes will identify the full commit, build, required toolchain, and simulator compatibility. Preserve your local signing settings and news imports when switching versions.

## Run in the iPhone simulator

After the foundation is implemented:

1. Install the Xcode version and simulator runtime listed in the verified setup instructions.
2. Open the Xcode project or workspace identified in README.md and select the shared app scheme.
3. Select a compatible iPhone simulator and use Xcode's Run action.

The foundation must add the exact project path, scheme, supported OS versions, and verified command-line build, test, install, and launch commands here. A GitHub simulator download will require a matching architecture and runtime; its release notes must identify them. Simulator builds run on a Mac, not on a physical iPhone. See [Apple's device-running guide](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices).

## Install on your own iPhone

After the foundation's local signing instructions are available:

1. Sign in to your Apple Account in Xcode and use the local signing configuration documented by the foundation. Keep personal team identifiers, signing material, and account credentials outside Git.
2. Connect and pair your iPhone with the Mac, following Xcode's prompts.
3. Enable Developer Mode when prompted. Apple documents the confirmation and restart steps in its [Developer Mode guide](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. Choose your iPhone as the app's run destination and use Xcode's Run action to build, sign, install, and launch it.

A free Personal Team supports testing on your own device. Its provisioning profiles expire after seven days, so rebuilding and reinstalling may be necessary. This workflow does not require purchasing an Apple Developer Program membership. See [Apple's account guidance](https://developer.apple.com/help/account/basics/about-your-developer-account).

GitHub's initial release asset will be a simulator build. An iPhone-installable signed package requires its own signing and distribution setup; [release automation](https://github.com/devofthings/sidequest/issues/31) will not claim that a simulator archive can be installed on your phone.

## News and troubleshooting

The [news-import task](https://github.com/devofthings/sidequest/issues/4) will add the supported local snapshot format, import location, and replacement steps here. Real personal captures stay outside Git and release assets; bundled examples must be labeled as samples.

If Xcode cannot run the app, check that the release's required runtime is installed, that the selected destination matches the build, and that local signing and Developer Mode are configured for a physical device. The foundation and integration tasks must replace general guidance with verified Sidequest troubleshooting and report device results only when actually tested.
