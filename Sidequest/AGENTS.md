# Application boundaries

Follow [source ownership](../docs/STRUCTURE.md), [coding rules](../docs/CODING.md), and [ADR 0003](../docs/adr/0003-hexagonal-architecture.md). `App` owns the SwiftUI entry point and composition root. `Core`, future domain folders, and game rules stay independent of presentation and external SDKs; presentation/adapters depend inward. Foundation creates no unused protocols or shared card types: issue #2 owns the lifecycle contract and actual dependencies introduce their ports.

Use Swift 6 language mode with a nonisolated compiler default and complete concurrency checking. Mark app/UI entry points `@MainActor`; domain behavior remains free of implicit UI isolation. The verified foundation toolchain and minimum deployment target are in [INSTALL.md](../docs/INSTALL.md).

Filesystem-synchronized membership belongs to the `Sidequest` app target only. Target-wide `EXCLUDED_SOURCE_FILE_NAMES = *.md` keeps current and future scoped guidance out of products without per-file project edits. Store redistributable app resources under `Resources`; test inputs belong to their test roots. Keep private captures, credentials, and generated outputs outside all synchronized roots.

## Foundation question review

The implementation agent answered the project-local agent-grill interview from the readiness reviewer before implementation. No human-owned product or spending choice was introduced.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| What minimum OS and isolation settings fit the foundation? | Delegated technical choice | iOS 17.0, Swift 6, nonisolated default, explicit MainActor UI. | Xcode supports iOS 17 simulator/device development; no selected foundation API needs a newer OS. Avoid assigning UI isolation to future domain types. | Xcode 27.0 simulator build and unit/UI tests pass; minimum-OS and physical-device execution are not claimed. |
| Should foundation add unused ports or shared card types? | Delegated technical choice | Establish folder ownership; add actual contracts in issue #2 and ports when used. | STRUCTURE.md and ADR 0003 reject placeholder abstractions and assign the lifecycle contract to its owning issue. | Minimal app runs without invented news/game behavior; fixture tests verify actual target boundaries. |
| How can future scoped guidance avoid resource leakage? | Fact and technical choice | Apply target-wide `*.md` exclusion to all three roots. | Per-file exceptions would require central edits for future game guidance. | The source-discovery verifier adds nested guides, inspects actual app/test bundles, and confirms exclusions without a project edit. |
