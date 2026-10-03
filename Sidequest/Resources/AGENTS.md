# Redistributable application resources

Keep only original assets and fictional, redistributable samples here. `sample-news.json` and `news-snapshot.schema.json` belong to the manual news importer; both may appear in simulator/release products. Personal news captures stay in ignored `.local-news/` or the app's local storage, outside synchronized source roots and Git. Scoped Markdown is excluded from target resources by the foundation. Follow [news guidance](../News/AGENTS.md) when changing these inputs.

`chess-puzzles.json` contains original redistributable king-and-queen fixtures for #7. Chess owns the schema, structural loader, and exhaustive legal-move/mate validation; follow [chess guidance](../Games/Chess/AGENTS.md) and [CHESS.md](../../docs/CHESS.md) when changing this asset. The development-only validation engine and generated evidence remain outside app resources and Git.
