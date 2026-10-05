# Sudoku rule and controller tests

Use explicit `.standard` configuration for 81-cell standard puzzles; existing mini constructors and finite fixtures deliberately retain `.mini`. Independently check generated standard rows, columns, and 3×3 regions rather than trusting solver output alone. Test incomplete searches with a found solution as well as none: a partial single solution must never certify uniqueness. Keep deterministic seeds and validate mini random-stream compatibility, so standard support cannot silently alter downstream Memory/Bubble challenges. See [game-owned decisions](../../../Sidequest/Games/Sudoku/AGENTS.md#standard-format-foundation-162--partial-delivery).

These pure tests establish no 9×9 UI fit, accessibility, difficulty classification, physical vibration, or production exposure. Native checks remain lead-owned and the routine three-case smoke gate is unchanged.

## Certified challenges #187

Native tier tests must execute the existing exhaustive Swift solver against original12/13/20-blank examples, actual persisted-candidate classification, invalid/ambiguous/exhausted inputs, seeded transformed givens, and first-action/reset/completed controller restoration. Seeds isolate the opt-in generator from historical random streams. These tests certify technique/workload proxies, not human difficulty or production labels. Root owns actual native execution.

Keep one XCTestCase class per source file: the exact-case native inventory maps file test methods to its class, so separate rule and controller classes to preserve inventory validation. Do not weaken inventory checks to accommodate mixed classes.
