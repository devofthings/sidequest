# App composition

`SidequestApp` is the entry point and composition root. The foundation launch view uses standard SwiftUI typography and semantic colors with Dynamic Type, scrolling, and an accessible heading; it starts no feed or game behavior. Inject concrete news/game adapters here when their owning issues establish actual interfaces. Follow [application boundaries](../AGENTS.md).

Use iOS 17.0 as the minimum deployment target: the selected SwiftUI foundation and intended feed need no newer API. Runtime testing on a newer simulator does not establish runtime compatibility on every supported OS or a physical device. Keep personal signing teams and account configuration local; see [INSTALL.md](../../docs/INSTALL.md).
