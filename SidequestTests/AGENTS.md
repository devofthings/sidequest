# Unit tests and resources

This filesystem-synchronized root belongs only to `SidequestTests`. Use XCTest for the foundation's bundle/resource isolation checks; future behavioral tests may use XCTest or Swift Testing when appropriate. Keep tests deterministic and mirror the owning domain/game area. Follow [verification policy](../AGENTS.md#verification).

Fixtures are fictional test inputs loaded from the test bundle, never production resources or live news. Target-wide `*.md` exclusion keeps scoped guidance out of resources. Test target sources do not belong to the app or UI-test target. The app-hosted test bundle verifies actual membership and fixture copying; app behavior tests follow their feature implementation.

## Standard Sudoku #170

StandardSudokuControllerTests covers9×9 coordinate read-only givens, bounds, digit9/conflicts/clear, skip/reset, real completion and quiet reconstruction; cap sweeps retain exhaustive uniqueness. Root owns actual native execution.

## First meaningful interaction #185

The owner selected first interaction starts and applies the same action, superseding #160's inert tap/hint for real games. Follow [the authoritative preview policy](../docs/GAME_PREVIEWS.md). Validate meaningful input before synchronous runtime preparation; capture visibility identity for held callbacks and preserve attempt/lease cancellation. No appearance/scroll activation, swallowed first action, real-fixture bypass or new lifecycle owner. Keep the static empty chrome reservation and native accessible controls. Actual native/CI proof remains pending in the owning PR.
