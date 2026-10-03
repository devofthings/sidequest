# Project and signing ownership

The foundation owns this project and the shared `Sidequest` scheme. App, unit, and UI roots use filesystem-synchronized membership with separate target ownership; ordinary new source files require no project-file edit. Target-wide Markdown exclusion is recorded in [application guidance](../Sidequest/AGENTS.md) and verified by [source-discovery checks](../docs/INSTALL.md#build-and-test).

`Signing.xcconfig` provides the default app identifier and optionally includes ignored `LocalSigning.xcconfig`. Personal teams and unique local app identifiers stay in that ignored override. All app/test identifiers derive from `SIDEQUEST_BUNDLE_IDENTIFIER`; no team or signing identity is committed. Simulator verification disables signing without changing device signing settings. Follow [installation guidance](../docs/INSTALL.md#install-on-your-own-iphone); actual physical-device execution is unverified.
