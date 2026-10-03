# App composition

`SidequestApp` is the entry point and composition root. The feed uses standard SwiftUI typography, semantic colors, and an accessible heading. Store the fictional sample deck once in retained composition via `SampleSession.make()`; rendering must not reshuffle it. Follow the [card contract](../../docs/CONTRACT.md) for explicit start/reset/completion. Inject concrete news/game adapters here as their owning issues establish consumers. Follow [application boundaries](../AGENTS.md).

Use iOS 17.0 as the minimum deployment target: the selected SwiftUI foundation and intended feed need no newer API. Runtime testing on a newer simulator does not establish runtime compatibility on every supported OS or a physical device. Keep personal signing teams and account configuration local; see [INSTALL.md](../../docs/INSTALL.md).

`FoundationView` preserves the standalone Debug manual-news preview/import sheet from #4 until #9 connects imports to the normal feed. Its news state belongs to `NewsImportModel`; see [news guidance](../News/AGENTS.md). This preview neither starts games nor changes shuffle semantics.

Issue #3 retains `FeedComposition` in app state. It owns the stored sample deck, feed controller, and one game controller/runtime per stable card ID; render closures only read those retained owners. Provisional game surfaces are explicitly labeled demos until #5–#8/#9 connect actual game rules. They verify start/input/completion/reset without implementing scoring or a new game.

Debug-only launch arguments select deterministic feed order (`-sidequest-feed-test`), an empty deck (`-sidequest-feed-empty`), games-only content (`-sidequest-feed-games-only`), or the largest accessibility text size (`-sidequest-large-text`) for running-app tests. `-sidequest-news-preview` preserves the foundation view for the separately owned news tests. Release builds ignore all these test routes. Normal launch uses the once-shuffled sample session and system text size; no user-facing test setting or auto-reshuffle is introduced.
