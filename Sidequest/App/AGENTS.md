# App composition

`SidequestApp` is the entry point and composition root. The launch view uses standard SwiftUI typography, semantic colors, and an accessible heading. Store the fictional sample deck once in app state via `SampleSession.make()`; rendering must not reshuffle it. This verifies the [card contract](../../docs/CONTRACT.md) in the app without starting feed/game behavior. Inject concrete news/game adapters here as their owning issues establish consumers. Follow [application boundaries](../AGENTS.md).

Use iOS 17.0 as the minimum deployment target: the selected SwiftUI foundation and intended feed need no newer API. Runtime testing on a newer simulator does not establish runtime compatibility on every supported OS or a physical device. Keep personal signing teams and account configuration local; see [INSTALL.md](../../docs/INSTALL.md).

`FoundationView` provides the manual-news preview/import sheet from #4 while the feed composition is developed independently. Its news state belongs to `NewsImportModel`; see [news guidance](../News/AGENTS.md). This preview neither starts games nor changes shuffle semantics.
