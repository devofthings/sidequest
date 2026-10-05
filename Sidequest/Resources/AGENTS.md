# Redistributable application resources

Keep only original assets and fictional, redistributable samples here. `sample-news.json` and `news-snapshot.schema.json` belong to the manual news importer; both may appear in simulator/release products. Personal news captures stay in ignored `.local-news/` or the app's local storage, outside synchronized source roots and Git. Scoped Markdown is excluded from target resources by the foundation. Follow [news guidance](../News/AGENTS.md) when changing these inputs.

`chess-puzzles.json` preserves the two original redistributable king-and-queen fixtures for #7. `chess-challenges.json` adds the separately loaded, metadata-required original varied-focus catalog for #177. Chess owns the schema, structural loader, and exhaustive legal-move/mate validation; follow [chess guidance](../Games/Chess/AGENTS.md) and [CHESS.md](../../docs/CHESS.md) when changing this asset. The development-only validation engine and generated evidence remain outside app resources and Git.

`demo-news.json` contains 30 original English fictional stories for normal nil-only startup under #106. Keep the legacy two-story sample asset unchanged. Preserve explicit sample flags, fictional publisher, fixed authored capture timestamp, and example.com placeholder URLs without invented publication dates. Actual bundled decoding and content checks own its provenance evidence; see [demo policy](../../docs/DEMO_NEWS.md).

## Selected app icon #14

`Assets.xcassets/AppIcon.appiconset` owns the original Card S selected by the owner on October 5, 2026. [Identity guidance](../../docs/logo-concepts/README.md) links approval, editable SVG, provenance, and the local rendering command. Keep its 1024-pixel Any PNG opaque and unmasked; dark/tinted styles use Apple's automatic system treatment. Preserve the app's `AppIcon` build-setting name, signing configuration, and target membership. Actual Home Screen checks for light/dark/tinted are a merge requirement, not established by the bitmap proof.

## Startup logo #91

`Assets.xcassets/StartupLogo.imageset/CardS.png` is a byte-identical copy of the selected `AppIcon.appiconset/AppIcon.png`, exposed as a normal image for the brief decorative startup introduction. Preserve that provenance when changing the selected artwork; do not redesign or rerender it independently. [App guidance](../App/AGENTS.md) owns introduction timing, cancellation, accessibility, and Reduce Motion behavior.

## Launch canvas #181

`LaunchCanvas.colorset` supplies the static system launch and SwiftUI root background: Any `#F5F3FF`, Dark `#101427`, matching the current shared palette. Update both appearances and the shared palette together if that design decision changes. Preserve selected AppIcon/StartupLogo bytes. [Launch guidance](../../docs/design/LAUNCH.md) owns rationale and compiled-resource checks.
