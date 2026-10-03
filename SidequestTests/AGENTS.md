# Unit tests and resources

This filesystem-synchronized root belongs only to `SidequestTests`. Use XCTest for the foundation's bundle/resource isolation checks; future behavioral tests may use XCTest or Swift Testing when appropriate. Keep tests deterministic and mirror the owning domain/game area. Follow [verification policy](../AGENTS.md#verification).

Fixtures are fictional test inputs loaded from the test bundle, never production resources or live news. Target-wide `*.md` exclusion keeps scoped guidance out of resources. Test target sources do not belong to the app or UI-test target. The app-hosted test bundle verifies actual membership and fixture copying; app behavior tests follow their feature implementation.
