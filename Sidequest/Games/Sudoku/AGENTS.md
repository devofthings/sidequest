# Mini Sudoku

Own pure 4×4 rules with 2×2 regions and this game's presentation adapter. Follow [common game guidance](../AGENTS.md) and [card contract](../../../docs/CONTRACT.md).

## Issue #5 question review

The implementation agent conducted an agent-grill self-assessment while feed #3 established the concrete presentation boundary. Issue #2 is merged; UI/runtime integration waits for #3's actual retained `GameRuntime` API on main.

| Question | Kind | Decision and rationale | Verification |
| --- | --- | --- | --- |
| How are givens and uniqueness guaranteed? | Delegated technical choice | Validate 16 values in 0…4 and conflict-free givens, then enumerate solutions up to two. Accept exactly one. Two original fixed fixtures avoid generation, hints, or difficulty scope. | Independent Python enumeration found exactly one solution for both; Swift negative ambiguous/conflicting fixtures and solved-board checks follow. |
| Where does selection/reset live? | Delegated technical choice | Pure `SudokuBoard` owns entries/conflicts/completion; presentation owns selected cell/feedback and gates input through the retained runtime. Start initializes without selecting/entering; skip clears selection and entries. | Controller/runtime and running-card tests after the feed boundary lands. |
| How are invalid entries handled? | Delegated technical choice | Permit 1–4 in editable cells and 0 for clearing. Mark row/column/region conflicts and allow correction; given cells are immutable. | Invalid index/value/given attempts, conflict correction, partial/solved boards, and reset. |

Keep each adapter retained by CardID in composition so completed boards survive revisiting. Introduce no timer, persisted progress, puzzle generation, scoring, hints, or automatic feed advance. UI work must record actual simulator checks before completion.
