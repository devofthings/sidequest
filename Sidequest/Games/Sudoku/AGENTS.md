# Mini Sudoku

Own pure 4×4 rules with 2×2 regions and this game's presentation adapter. Follow [common game guidance](../AGENTS.md) and [card contract](../../../docs/CONTRACT.md).

## Issue #5 question review

The implementation agent conducted an agent-grill self-assessment while feed #3 established the concrete presentation boundary. Issues #2 and #3 are merged. `SudokuController(puzzle:runtime:)` consumes the actual retained `GameRuntime`; pure rules remain independent of observation and UI.

| Question | Kind | Decision and rationale | Verification |
| --- | --- | --- | --- |
| How are givens and uniqueness guaranteed? | Delegated technical choice | Validate 16 values in 0…4 and conflict-free givens, then enumerate solutions up to two. Accept exactly one. Two original fixed fixtures avoid generation, hints, or difficulty scope. | Independent Python enumeration found exactly one solution for both; Swift negative ambiguous/conflicting fixtures and solved-board checks follow. |
| Where does selection/reset live? | Delegated technical choice | Pure `SudokuBoard` owns entries/conflicts/completion; presentation owns selected cell/feedback and gates input through the retained runtime. Start initializes without selecting/entering; skip clears selection and entries. | Controller/runtime and running-card tests after the feed boundary lands. |
| How are invalid entries handled? | Delegated technical choice | Permit 1–4 in editable cells and 0 for clearing. Mark row/column/region conflicts and allow correction; given cells are immutable. | Invalid index/value/given attempts, conflict correction, partial/solved boards, and reset. |

Keep each adapter retained by CardID in composition so completed boards survive revisiting. Introduce no timer, persisted progress, puzzle generation, scoring, hints, or automatic feed advance. UI work must record actual simulator checks before completion.

`SudokuGameView(controller:)` renders the retained board without nesting another scroll view inside the feed. Cells and number/clear controls use 44-point minimum heights; row/column labels, given/value/conflict cues, and decorative central dividers distinguish the four 2×2 regions. The controller binds the runtime weakly once, initializes only on start, clears board/selection on reset, and preserves solved rules on stop. No delayed work is introduced.

App composition selects a validated original fixture once for the card, never in a view body. `-sidequest-sudoku-test` selects a deterministic Sudoku-first deck plus one news card for running-app checks. The shared `-sidequest-feed-test` route remains a DEBUG-only generic lifecycle harness; normal and Release Sudoku cards use actual Sudoku rules. Invalid bundled fixtures produce a visible composition failure rather than fabricated gameplay.

Place cell sizing, backgrounds, and rectangular content shapes inside Button labels so the entire visible cell selects it. Put number/clear target sizing inside their labels as well. Verify actual normal-size accessibility dimensions of at least 44×44 points and taps near all four editable-cell corners; outer padding or frames alone do not prove an effective touch area. This corrects the confirmed normal-size touch defect without changing rules or lifecycle.
