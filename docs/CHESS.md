# Chess puzzle contract and validation

Issue #7's initial set uses two original king-and-queen checkmate-in-one positions, one for each moving color. There are no pawns, promotion, castling, en passant, full opponents, generated positions, scoring, or multistep tactics. The rules and validated fixtures are implemented; the controller and playable card remain pending the feed runtime on main. This document does not claim simulator gameplay verification.

`Sidequest/Games/Chess/chess-puzzles.json` is the canonical fixture source. Each record contains a stable `id`, FEN, `sideToMove` (`white` or `black`), `objective` (`checkmate-in-one`), every legal UCI move, and every accepted mate. UCI moves are four lowercase coordinate characters, for example `g6g7`. Promotion suffixes are explicitly excluded. Board orientation is consistent: a1 is bottom left and h8 is top right for both colors.

`ChessPuzzleLoader` validates structural requirements and loads original bundled fixtures. `ChessPuzzle` exposes immutable board and move sets; it is not a general chess legality engine. `ChessAttempt.tap(square)` selects only the moving side, supports reselection/deselection, and evaluates a destination against the verified sets. Wrong legal moves and illegal moves give distinct feedback and preserve the starting board. A correct move updates the derived board, records the solution, and ignores later input. A new attempt clears selection and feedback.

## Reproduce fixture validation

The independent development-only [python-chess tool](https://python-chess.readthedocs.io/en/latest/) (`chess` package 1.11.2) validates legal positions and enumerates all legal moves and checkmates. Its [GPL-3.0-or-later license](https://github.com/niklasf/python-chess/blob/v1.11.2/LICENSE.txt) applies to the tool; the app bundles no tool code or dependency. Fixture data is original, rather than imported puzzles or licensed artwork. Package version and official PyPI source archive hash are pinned in `scripts/chess-validation-requirements.txt`.

Use a disposable environment outside Git. This downloads a free local tool, with no account or service:

```sh
python3 -m venv /private/tmp/sidequest-chess-validation-venv
/private/tmp/sidequest-chess-validation-venv/bin/python -m pip install \
  --no-deps --require-hashes -r scripts/chess-validation-requirements.txt
/private/tmp/sidequest-chess-validation-venv/bin/python scripts/validate-chess-fixtures.py
```

The validator rejects invalid/already-finished positions, unsupported pieces/special moves, moving-side mismatches, duplicate IDs/moves, and any mismatch between the recorded legal/accepted sets and exhaustive engine results. It never changes fixtures or contacts a puzzle service. After fixture changes, rerun it and retain the actual output before review; unit tests alone do not establish chess legality.

Actual October 3, 2026 validation: both positions are valid and have 26 legal moves. White's complete accepted set is `g6g7`, `g6g8`, `g6h5`, `g6h6`; Black's is `b3a3`, `b3a4`, `b3b1`, `b3b2`. These complete sets deliberately accept equivalent solutions. Seven negative fixture mutations were rejected (missing mate, accepted nonmate, missing legal move, wrong side, adjacent kings, unsupported pawn, duplicate ID). Four real app-hosted unit tests passed for all eight solutions, all 44 legal nonmates, illegal moves, selection/coordinates/frozen completion, and malformed fixture data. Bundled fixture discovery passed through the actual app target. These checks prove the pure slice; playable UI and lifecycle checks remain pending.

The future presentation adapter will retain one controller/attempt per card, bind the shared GameRuntime, and gate each input through its current attempt and visibility. Start only initializes; skipping resets unfinished state; completed results persist. Accessible board labels and 44-point coordinate alternatives, both fixture solutions, and skip/reset require actual simulator proof before issue completion. Root app composition owns card-to-fixture wiring.
