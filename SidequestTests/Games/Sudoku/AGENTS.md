# Sudoku rule and controller tests

Use explicit `.standard` configuration for 81-cell standard puzzles; existing mini constructors and finite fixtures deliberately retain `.mini`. Independently check generated standard rows, columns, and 3×3 regions rather than trusting solver output alone. Test incomplete searches with a found solution as well as none: a partial single solution must never certify uniqueness. Keep deterministic seeds and validate mini random-stream compatibility, so standard support cannot silently alter downstream Memory/Bubble challenges. See [game-owned decisions](../../../Sidequest/Games/Sudoku/AGENTS.md#standard-format-foundation-162--partial-delivery).

These pure tests establish no 9×9 UI fit, accessibility, difficulty classification, physical vibration, or production exposure. Native checks remain lead-owned and the routine three-case smoke gate is unchanged.
