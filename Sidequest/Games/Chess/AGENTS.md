# One-move chess puzzles

Issue #7 owns this bounded game. Use original king-and-queen checkmate-in-one positions, with both colors represented. The initial set excludes pawns, promotion, castling, and en passant. Keep a full opponent, generated positions, scoring, and multistep tactics out of this slice.

Canonical bundled JSON records each FEN, moving side, objective, every legal move, and every accepted mate. The app evaluates these fixed verified sets; it is not a general chess legality engine. Validate each position and enumerate **all** mates with the pinned external tool in [CHESS.md](../../../docs/CHESS.md). Never accept a hand-entered answer list without that evidence. The GPL tool is an isolated development dependency, never linked into or bundled with the app.

Keep rules as pure Swift values. Parsing validates structural fixture requirements; the external validator establishes legal-position and complete-solution correctness. Wrong or illegal moves leave the starting position intact for another attempt. Selecting another moving-side piece changes selection; selecting the same piece clears it. A correct move updates the displayed board and freezes the solved attempt.

Always display White's coordinates: a1 at bottom left and h8 at top right. Label the moving color and checkmate objective explicitly, including for Black. Board cells have accessible piece/color/square labels; provide usable coordinate controls if eight columns cannot maintain 44-point targets on an iPhone. Verify actual layouts and both fixture solutions in the simulator before delivery.

The adapter will use the single retained GameRuntime established by #3: start resets selection and feedback without making a move; reset clears the attempt; completion preserves the solved board. No gameplay input is accepted before start, offscreen, or after completion. Presentation implementation waits for that runtime on main.

## Agent-grill self-assessment

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Are both proposed original positions valid? | Fact | Yes; each has 26 legal moves and four mates. | Actual chess 1.11.2 enumeration on October 3, 2026; FENs and complete sets in canonical JSON. | Hash-required pinned tool install, exhaustive validator, and seven negative fixture mutations passed. |
| Does the app need a general chess engine? | Delegated technical choice | No; evaluate fixture-owned legal/accepted move sets. | Issue #7 requests explicit expected-move evaluation, excludes full matches and generated positions. | Four real app-hosted unit tests passed: all eight solutions, all 44 legal nonmates, illegal moves, selection, fixture validation, and frozen completion. |
| How should Black be oriented? | Delegated technical choice | Keep the same White-oriented coordinates for every puzzle. | Issue requires consistent orientation; no auto-rotation requirement exists. | All 64 display coordinates verified in unit tests; actual UI checks remain planned. |
| Who owns lifecycle and UI state? | Fact and technical choice | A retained controller consumes the single #3 runtime; pure attempt owns selection/feedback/solution. | Shared contract and inward dependencies; completed results survive view recreation. | Controller/UI tests planned once #3 is on main. |

No human-owned decision or spending was introduced. Rule/fixture work is ready; adapter and UI verification remain pending #3.
