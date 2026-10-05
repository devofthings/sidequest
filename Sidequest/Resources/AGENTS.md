# Redistributable application resources

Keep only original assets and fictional, redistributable samples here. `sample-news.json` and `news-snapshot.schema.json` belong to the manual news importer; both may appear in simulator/release products. Personal news captures stay in ignored `.local-news/` or the app's local storage, outside synchronized source roots and Git. Scoped Markdown is excluded from target resources by the foundation. Follow [news guidance](../News/AGENTS.md) when changing these inputs.

`chess-puzzles.json` contains original redistributable king-and-queen fixtures for #7. Chess owns the schema, structural loader, and exhaustive legal-move/mate validation; follow [chess guidance](../Games/Chess/AGENTS.md) and [CHESS.md](../../docs/CHESS.md) when changing this asset. The development-only validation engine and generated evidence remain outside app resources and Git.

`demo-news.json` contains 30 original English fictional stories for normal nil-only startup under #106. Keep the legacy two-story sample asset unchanged. Preserve explicit sample flags, fictional publisher, fixed authored capture timestamp, and example.com placeholder URLs without invented publication dates. Actual bundled decoding and content checks own its provenance evidence; see [demo policy](../../docs/DEMO_NEWS.md).

## Selected app icon #14

`Assets.xcassets/AppIcon.appiconset` owns the original Card S selected by the owner on October 5, 2026. [Identity guidance](../../docs/logo-concepts/README.md) links approval, editable SVG, provenance, and the local rendering command. Keep its 1024-pixel Any PNG opaque and unmasked; dark/tinted styles use Apple's automatic system treatment. Preserve the app's `AppIcon` build-setting name, signing configuration, and target membership. Actual Home Screen checks for light/dark/tinted are a merge requirement, not established by the bitmap proof.
