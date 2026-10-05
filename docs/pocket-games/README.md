# Selected pocket-sized games

Status: accepted first revision for [#117](https://github.com/devofthings/sidequest/issues/117) on October 5, 2026. After the lead's pending-choice handoff, the owner replied “go ahead,” selecting the recommended standard-board Chess focus windows and retention of current Sudoku/Memory/Bubble configurations. [The approval record](https://github.com/devofthings/sidequest/issues/117#issuecomment-5990514369) defines the bounded scope; [#132](https://github.com/devofthings/sidequest/issues/132) implements Chess. The source audit below used commit `449bfab29c96dd360a2a3978f5dc7ceb8be48e76`. Session ranges remain unmeasured usability targets, not timers. The subsequent harder-Bubble instruction under [#135](https://github.com/devofthings/sidequest/issues/135) supersedes retention of the one-shot generator: child #137 changes generation, while #138 owns controls/layout. The original audit/examples below remain historical baseline evidence, not the updated production default.

## Selected first revision

The first revision retained compact mini Sudoku and six-pair Memory. Owner-approved #162/#170 supersedes the Sudoku production default with standard 9×9, at most 12 editable cells and full-size coordinate alternatives; see [current Sudoku controls and evidence](../SUDOKU.md). The mini audit/examples below remain historical. Retain six-pair Memory. Bubble’s original one-shot configuration below is the pre-#137 baseline; the approved harder compact follow-up owns its replacement. Give Chess a fixed 4×4 focus window over its existing standard-board fixtures, preserving standard legality and all coordinate controls. This produces a smaller visual puzzle without introducing a new chess engine or opponent. Treat difficulty [#118](https://github.com/devofthings/sidequest/issues/118) separately; adaptive frequency [#119](https://github.com/devofthings/sidequest/issues/119) remains an Idea.

Target roughly 15–90 seconds of active play per card. The game-specific ranges below are selected usability targets, not measured completion times, timers, pass/fail limits, or retention claims. Evaluate them through personal testing in [#10](https://github.com/devofthings/sidequest/issues/10).

| Game | Historical audited configuration | Selected first revision | Active-play target (unmeasured) |
| --- | --- | --- | --- |
| Sudoku | 4×4 grid, digits 1–4, four 2×2 regions; generated puzzles require one solution. | Retain the existing puzzle and uniqueness policy. | 30–90 seconds |
| Memory | Six symbols, exactly two of each, 12 tiles; three columns normally, two at accessibility text sizes. | Retain six pairs and the existing 700 ms mismatch delay. | 30–90 seconds |
| Chess | Two original three-piece, king-and-queen mate-in-one positions on a full 8×8 display. Move tables are independently validated. | Display a fixed 4×4 focus window with original coordinates, all three pieces, and all accepted destinations; retain full-board coordinate alternatives. | 15–60 seconds |
| Bubble shooter | Five staggered rows with 5/4/5/4/5 slots; generated starts occupy only the first two rows and have a replayed one-shot winning witness, within the existing eight-shot limit. | Retain small generated challenges, three colors, angle/Fire controls, eight-shot rules, and Replay. | 15–45 seconds |

These audits come from the game-owned sources: [Sudoku](../../Sidequest/Games/Sudoku/Rules/SudokuPuzzle.swift), [Sudoku generation](../../Sidequest/Games/Sudoku/Rules/SudokuGenerator.swift), [Memory](../../Sidequest/Games/Memory/Rules/MemoryRules.swift), [Memory layout](../../Sidequest/Games/Memory/Presentation/MemoryGameView.swift), [Chess](../../Sidequest/Games/Chess/Domain/ChessPuzzle.swift), [Bubble geometry](../../Sidequest/Games/BubbleShooter/Rules/BubbleGeometry.swift), and [Bubble generation](../../Sidequest/Games/BubbleShooter/Rules/BubbleChallengeGenerator.swift). The historical fixed Bubble challenge differs from normal generated challenges; the small example below illustrates an existing valid generated fallback shape.

## Concrete examples

### Sudoku: finish a 4×4 grid

An existing original fixture uses the following givens, where a dot means editable:

```text
1 2 | . 4
. 4 | 1 .
----+----
. 1 | 4 .
4 . | . 1
```

Its unique solution is `1234 / 3412 / 2143 / 4321`. Keep all seven editable cells rather than inventing a different completion objective. Incorrect entries remain correctable; selecting a given never changes it. A future shorter target or clue-count policy belongs to the separately agreed difficulty specification.

### Memory: six pairs

An illustrative frozen layout contains:

```text
star  heart moon
sun   leaf  bolt
moon  star  leaf
heart bolt  sun
```

Using zero-based row-major tile indices, matching pairs are `(0,7), (1,9), (2,6), (3,11), (4,8), (5,10)`. Twelve correct flips complete it. This is a documentation example, not a replacement production layout. Previews and reset tiles remain face down, including spoken labels; skipped attempts restore the same frozen layout. At the largest text size, the same 12 tiles reflow into two columns without changing identity or revealing answers.

### Chess: focused standard-board mate in one

The [original fixtures](../../Sidequest/Resources/chess-puzzles.json) already contain only three pieces. Selected windows are fixed by fixture metadata, before any selection or attempt; they never follow the solution or selected destination.

```text
White to move: focus e5–h8       Black to move: focus a1–d4
8  . . . k                     4  . . . .
7  . K . .                     3  . q . .
6  . . Q .                     2  . . k .
5  . . . .                     1  K . . .
   e f g h                        a b c d
```

`K/Q` are White king/queen; `k/q` are Black king/queen. Keep White's orientation for both sides. The White fixture accepts `g6g7`, `g6g8`, `g6h5`, and `g6h6`; Black accepts `b3a3`, `b3a4`, `b3b1`, and `b3b2`. Display every accepted destination without highlighting a solution before completion. Each window also includes every adjacent square of the defending king. Neither window removes a piece or creates a new board edge.

Suggested copy: “White to move · Mate in one” and “Focus area e5–h8 · Standard 8×8 rules.” Preserve full-width own-piece selection, all eight file/rank menu choices, and separate Submit move. Destinations outside the focus window remain available through those controls; wrong or illegal moves preserve the starting board and show the existing distinct feedback. The window, move tables, and challenge identity stay unchanged after start, reset, and completed restoration.

The full 8×8 position remains the authority for legality and mate, including possible escape squares outside any future focus window. The current app checks supplied, independently validated tables; it does not calculate arbitrary chess legality. A future fixture with off-window pieces, accepted destinations, or relevant escape squares requires a wider window or explicit full-board presentation, with independent validation. It cannot silently clip that information. For this bounded revision, accept only the two existing fixtures and stated windows.

### Historical Bubble baseline: one compact clearing shot

An existing valid small shape has two red bubbles at zero-based slots `(row:0,column:2)` and `(row:0,column:3)`. Its shot sequence begins red, blue, green. A red shot at 0° attaches, makes a group of three, and clears the board under the existing pure rules. Leave the angle slider and explicit Fire action available, including wrong shots; do not auto-aim or fire on entry. Keep the existing eight-shot maximum, danger-row and blocked-attachment losses, delayed-shot cancellation, completed result, and Replay behavior.

## Chess alternatives and their costs

| Choice | Rules and content implications | Recommendation |
| --- | --- | --- |
| Fixed 4×4 focus over standard 8×8 positions | Reuse validated fixtures and original coordinates. Keep outside destinations available through coordinate controls; explain that the focus window is not a wall. | Selected first revision. Small presentation change with unchanged puzzle validity. |
| Genuine 4×4 ruleset | Requires an agreed ruleset: four-file/rank coordinates or original-coordinate subsets, board-edge behavior, legal king adjacency/check/escape, sliding ranges, and independent complete move/mate enumeration. Existing FEN/table validation assumes 8×8. | Defer until the owner prefers changed rules over a focused standard-board puzzle. |
| Mate in two or more with an opponent reply | Requires a full solution tree or validated reply policy, move-depth accounting, branching legal nonmates, stateful intermediate positions, failure/retry behavior, and opponent timing/reset cancellation. The current one-move attempt is insufficient. | Defer to a separately agreed revision rather than bundle into compact presentation. |

For a genuine reduced board, a plausible *proposal* is a 4×4 board with two kings plus one queen, one attacking move, no pawns, and no special moves. Kings would have to remain nonadjacent and may not enter check; checkmate would require checking every legal defender escape within the new board. Those new edges can turn existing nonmates into mates, so existing answers cannot certify the variant. Pawns would additionally require explicit movement direction, starting ranks, double-step policy, promotion edge and pieces, and en passant policy. None of these choices is selected here.

The owner's reference, [Pocket Chess's official listing](https://play.google.com/store/apps/details?hl=en&id=com.dkxqzbfkjt.pocketchess), describes small, simple boards and mate-in-two through mate-in-four content. It does not specify a board size, pawn rules, or whether displayed boundaries redefine legality. The selected standard-board focus is our bounded interpretation for Sidequest, not a claim about Pocket Chess's engine. No competitor puzzles or artwork are copied.

## Layout, accessibility, and lifecycle validation plan

Apply the existing [design baseline](../DESIGN.md), [stable-layout contract](../GAME_LAYOUT.md), [preview contract](../GAME_PREVIEWS.md), and [endless challenge ownership](../ENDLESS.md). Keep a single runtime per active card, explicit Tap to play, immutable configuration per card, unfinished skip/reset, and lightweight completed revisits.

At normal text sizes, four Chess columns make a 44-point cell feasible at a content width of at least 176 points; actual spacing and padding must be measured in the rendered view. Retain the existing larger coordinate controls when direct cells cannot provide a usable target. This follows [Apple's touch-target guidance](https://developer.apple.com/design/tips/), not an assertion that a drawn cell already passes. At the largest Dynamic Type setting, wrap instructions and coordinate headings fully; keep the board above controls, with the feed-owned scroller providing reachability. Preserve all reserved instruction, start, result, and feedback footprints during transitions. Memory's two-column layout remains longer vertically and scrollable rather than forcing tiny tiles.

Verify light/dark and increased contrast, color-independent selection/error/result labels, Reduce Motion, usable corner taps, all required controls, and meaningful accessibility labels. Chess announces original square, piece, and side; empty cells announce their square; Memory hidden labels disclose no symbol. Device VoiceOver and physical performance need actual device evidence before being claimed. Apple recommends Dynamic Type and suitable interaction sizing in its [accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility).

Implementation checks for #132 are:

- Pure fixture/window checks for exact coordinates, all pieces and all accepted destinations, orientation, unsupported windows, and no dependence on selected moves. Revalidate complete standard-board legal/mate tables with the pinned development tool.
- Running-app checks for both Chess sides, every equivalent mate, a legal nonmate and illegal destination, coordinate submission outside the window, explicit start, skip/reset, background interruption, completed revisit, and largest-text reachability. Assert stable board geometry across selection/status/start/completion/reset.
- Preserve existing Sudoku uniqueness, Memory pair/mismatch cancellation, Bubble winning-witness/flight/reset, and endless frozen-challenge behavior. Use all unit tests and the three routine UI smoke cases, plus bounded relevant focused checks; preserve [the testing policy](../TESTING.md).

## Evidence gathered before selection

On October 5, 2026, the existing pinned `chess` 1.11.2 environment ran `scripts/validate-chess-fixtures.py` against unchanged canonical JSON: both positions valid, 26 legal moves and four accepted mates each. A separate read-only crop check confirmed all initial pieces, all accepted move endpoints, and all adjacent defending-king squares fit the two proposed windows. This validates the examples' standard-board answers, not a reduced-board engine or a rendered interface. Reproduction of the independent validator is documented in [CHESS.md](../CHESS.md#reproduce-fixture-validation).

A disposable host-only Swift probe compiled the unchanged `SudokuPuzzle`, `MemoryRules`, `BubbleGeometry`, and `BubbleShooterGame` sources outside Git. The existing Sudoku solver returned exactly `1234 / 3412 / 2143 / 4321`; the illustrated six pairs completed after 12 flips; the illustrated red Bubble board won at 0°. The probe introduced no app feature, prototype, fixture change, simulator, or Xcode app build. No session times, screenshots, new layout, device accessibility, or gameplay preference were measured in this specification task.

## Owner selection and handoff

The owner selected the focused standard-board first revision on October 5, 2026, with current Sudoku/Memory configurations retained; the initially retained Bubble baseline is subsequently superseded by harder-play children #137/#138 under #135. Genuine reduced-board rules, new catalogs, and multiple-move puzzles remain deferred. The active-play ranges are accepted usability targets with no measured-time claim or enforced timer. Chess implementation belongs to #132; difficulty #118 remains a separate decision and adaptive frequency #119 remains an Idea.
