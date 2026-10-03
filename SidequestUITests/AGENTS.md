# UI tests

This filesystem-synchronized root belongs only to `SidequestUITests`. XCTest UI tests launch and interact with the running app through accessibility. The foundation verifies launch and the accessible heading; critical news/game/start/skip flows are added when their owning issues implement them. Follow [verification policy](../AGENTS.md#verification).

Load deterministic fictional inputs from this target's `Fixtures`, isolated from app and unit-test resources. Target-wide `*.md` exclusion keeps scoped guidance out of products. Mark UI-test methods `@MainActor` instead of changing the pure-core isolation defaults.
