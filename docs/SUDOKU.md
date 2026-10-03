# Play mini Sudoku

Sudoku is a 4×4 challenge with four 2×2 regions. Each row, column, and region must contain the numbers 1–4 exactly once. The app selects one of two original validated fixtures when composing the card; it does not generate puzzles or change the selected fixture during rendering.

## Controls and feedback

1. Navigate to Sudoku and choose **Tap to play**. Starting initializes the board without selecting a cell or entering a number.
2. Select an editable cell, then choose **1**, **2**, **3**, or **4**. Given cells stay fixed. **Clear selected cell** removes your entry from that cell.
3. Correct conflicts using another number or clearing the entry. Row/column/region conflicts are marked on the cells and described in their accessible values; the status also says that conflicts need correction.
4. Fill the board without conflicts to see **Sudoku solved!**. Completion stays in the card and does not advance the feed. Leaving and returning preserves the completed board.

Skipping or backgrounding an unfinished puzzle clears player entries and selection. Returning shows the preview and requires another explicit start; it uses the same fixture selected for that card. No scores, timers, hints, difficulty settings, puzzle generation, replay, or saved progress are added in this slice.

The board uses row/column labels, given-cell cues, central region dividers, selected-cell feedback, and accessible conflict values. It renders inside the feed's own scroll surface. Normal setup and simulator/iPhone instructions are in [INSTALL.md](INSTALL.md); the lifecycle and ownership are in [FEED.md](FEED.md).

## Deterministic checks

The DEBUG-only `-sidequest-sudoku-test` launch argument selects a Sudoku-first deck, the first validated fixture, and one news card. `-sidequest-large-text` requests the largest accessibility text size for running-app checks. These routes are ignored by Release builds. Production selects a validated fixture once during composition.

The separate `-sidequest-feed-test` route deliberately uses generic demos, including for Sudoku, to verify host behavior without depending on individual game rules. It is not the playable Sudoku route. Pure Sudoku rules, controller behavior, and running-app flows each have their own tests.

## Verification

Targeted simulator verification passed ten tests: seven Sudoku rule/controller tests and three running-app flows. These cover start without input, conflict correction/clearing, skip/reset, solved feedback, completed revisit, and cell selection/number entry with reachable navigation at the largest accessibility text size. The largest-text test brings a cell fully into view before tapping, verifies selection and an enabled number control, then confirms the entered value; clipped hit-test visibility alone is insufficient. Sudoku delivery subsequently passed the [exact-head CI](https://github.com/devofthings/sidequest/actions/runs/37154400261/job/111294678678), including Debug/Release builds and the full deterministic test suite, before [#80](https://github.com/devofthings/sidequest/pull/80) merged. No aggregate test count for later features is claimed here. Physical-iPhone and iOS 17 runtime execution remain unverified.

Each fixture is checked for valid givens and exactly one solution. Invalid, conflicting, or ambiguous fixtures are rejected; construction failures produce visible composition feedback. The implementation introduces no external puzzle service or dependency. Local decisions and source ownership are recorded in [Sudoku guidance](../Sidequest/Games/Sudoku/AGENTS.md).
