# Shared pure Swift core

This area owns shared values and small replaceable-boundary ports when they are needed. Import no SwiftUI, UIKit, rendering, networking-client, or storage SDK. Core is nonisolated by default under the [application settings](../AGENTS.md); UI isolation belongs to presentation.

The foundation establishes ownership without placeholder types. Issue #2 introduces the shared card/lifecycle contract; feature-specific rules belong to their owning folders under [STRUCTURE.md](../../docs/STRUCTURE.md).
