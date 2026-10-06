# Project and signing ownership

The foundation owns this project and the shared `Sidequest` scheme. App, unit, and UI roots use filesystem-synchronized membership with separate target ownership; ordinary new source files require no project-file edit. Target-wide Markdown exclusion is recorded in [application guidance](../Sidequest/AGENTS.md) and verified by [source-discovery checks](../docs/INSTALL.md#build-and-test).

`Signing.xcconfig` provides the default app identifier and optionally includes ignored `LocalSigning.xcconfig`. Personal teams and unique local app identifiers stay in that ignored override. All app/test identifiers derive from `SIDEQUEST_BUNDLE_IDENTIFIER`; no team or signing identity is committed. Simulator verification disables signing without changing device signing settings. Follow [installation guidance](../docs/INSTALL.md#install-on-your-own-iphone); actual physical-device execution is unverified.

Integration #9 enables `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` only in the app Debug configuration so native Files can select owned fictional Documents fixtures. Release omits these keys and all fixture/reset code. No team, signing identity, personal capture, or file path is committed.

Xcode27’s generated Info omitted the file-sharing key despite the build setting. Debug therefore merges the minimal `DebugInfo.plist` containing both Boolean keys with generated application metadata. Release does not reference that file. Verify the actual Debug/Release built Info dictionaries; build settings alone do not establish Files visibility.


Selected identity #14 adds `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` only to the app Debug/Release configurations. The filesystem-synchronized resource catalog owns the bitmap and slot; this requires no new explicit target membership, test setting, signing identity, or bundle-identifier change. Follow [identity guidance](../docs/logo-concepts/README.md) for source/provenance and automatic dark/tinted treatment; validate actual built icon metadata and appearance before merging.

## Static system launch #215

Both app configurations merge UILaunchStoryboardName = LaunchScreen instead of the prior UILaunchScreen dictionary. Debug retains Files keys; metadata generation/signing/icon settings stay intact. The synchronized app resource root owns the storyboard. Validate actual compiled Debug/Release metadata and storyboard/assets under [launch guidance](../docs/design/LAUNCH.md).
