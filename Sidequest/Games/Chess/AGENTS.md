# One-move chess puzzles

Issue #7 owns this bounded game. Use original king-and-queen checkmate-in-one positions, with both colors represented. The initial set excludes pawns, promotion, castling, and en passant. Keep a full opponent, generated positions, scoring, and multistep tactics out of this slice.

Canonical bundled `Sidequest/Resources/chess-puzzles.json` records each FEN, moving side, objective, every legal move, and every accepted mate. Keep fixture assets in Resources while this area owns their contract and validation. The app evaluates these fixed verified sets; it is not a general chess legality engine. Validate each position and enumerate **all** mates with the pinned external tool in [CHESS.md](../../../docs/CHESS.md). Never accept a hand-entered answer list without that evidence. The GPL tool is an isolated development dependency, never linked into or bundled with the app.

Keep rules as pure Swift values. Parsing validates structural fixture requirements; the external validator establishes legal-position and complete-solution correctness. Wrong or illegal moves leave the starting position intact for another attempt. Selecting another moving-side piece changes selection; selecting the same piece clears it. A correct move updates the displayed board and freezes the solved attempt.

Always display White's coordinates: a1 at bottom left and h8 at top right. Label the moving color and checkmate objective explicitly, including for Black. Board cells have accessible piece/color/square labels; provide usable coordinate controls if eight columns cannot maintain 44-point targets on an iPhone. Verify actual layouts and both fixture solutions in the simulator before delivery.

`ChessController(puzzle:runtime:)` uses the single retained GameRuntime established by #3. Composition retains one controller per card and binds its runtime exactly once; the controller's synchronous effect handler captures it weakly. Start creates a fresh attempt without making a move; reset clears the attempt and destination choices; completion preserves the solved board. Every board tap, coordinate choice, and submission is rejected before start, offscreen, or after completion. There are no tasks or timers.

Render `ChessPuzzleView(controller:)` inside the feed's native scrolling game card. The #87 pager owns navigation and its `feed.cardScroll` owns overflow; Chess introduces no nested ScrollView or paging gesture. The compact spatial board has piece/color/square labels; full-width own-piece buttons and destination file/rank menus with a separate Submit move action provide 44-point alternatives. Choosing coordinates never makes a move. Explicit submission onto an occupied own-piece square reports an illegal move, rather than silently changing selection. Keep selection and feedback visible as text, beyond color. App composition owns fixture-to-card wiring and DEBUG-only fixture routes; this game owns no feed lifecycle or launch-argument parsing.

## Agent-grill self-assessment

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Are both proposed original positions valid? | Fact | Yes; each has 26 legal moves and four mates. | Actual chess 1.11.2 enumeration on October 3, 2026; FENs and complete sets in canonical JSON. | Hash-required pinned tool install, exhaustive validator, and seven negative fixture mutations passed. |
| Does the app need a general chess engine? | Delegated technical choice | No; evaluate fixture-owned legal/accepted move sets. | Issue #7 requests explicit expected-move evaluation, excludes full matches and generated positions. | Four real app-hosted unit tests passed: all eight solutions, all 44 legal nonmates, illegal moves, selection, fixture validation, and frozen completion. |
| How should Black be oriented? | Delegated technical choice | Keep the same White-oriented coordinates for every puzzle. | Issue requires consistent orientation; no auto-rotation requirement exists. | All 64 display coordinates verified in unit tests; both original fixture routes solved in the running app with the same orientation. |
| Who owns lifecycle and UI state? | Fact and technical choice | A retained controller consumes the single #3 runtime; pure attempt owns selection/feedback/solution. | Shared contract and inward dependencies; completed results survive view recreation. | Four controller tests passed through the actual runtime, including every accepted mate and stale/reset gates; running-app flows verify both colors, skip/revisit, and background reset. |
| How is startup file I/O kept off the UI actor? | Fact and delegated technical choice | Await an explicitly `@concurrent` bundled adapter once, then synchronously compose from its immutable cache. | CODING.md prohibits blocking UI I/O; review exposed duplicate reads in composition. News already uses the supported toolchain isolation mechanism. | Suspended-loader ordering, cache reuse, stale completion, failure, and focused running-app checks; new exact-head CI and fresh review are required. |
| How are eight board columns usable on an iPhone? | Delegated technical choice | Provide 44-point own-piece and file/rank controls alongside the labeled spatial board. | Coding guidance requires usable touch targets; native menus allow each destination coordinate without squeezing eight controls into one row. | Both normal fixtures solve through coordinate controls; largest text passed three consecutive actual solution/revisit runs with fully visible controls. |

For UI verification, bring the full control frame inside the feed's scrolling viewport before tapping; a clipped control can report hittable without providing a usable target. Scroll through native menus with an immediate drag, rather than a press dwell that can activate a menu instead. Preserve selected coordinates, move/result assertions, and passing screenshot evidence; never weaken these assertions to accept a partially visible target.

Apply the 44-point minimum and rectangular content shape inside each alternative control's label; an outer button frame alone can leave only the text tappable. Check actual accessibility dimensions and lower-right edge actions for own-piece selection, File, Rank, and Submit move. These checks must prove the intended selection and completed move, beyond reporting a frame or hittability.

Allow the destination heading to wrap to its full vertical size at accessibility text sizes. Inspect the actual largest-text screenshot for truncation as well as asserting control visibility and the completed move.

No human-owned decision or spending was introduced. Rules, retained composition, both-color gameplay, and largest-text interaction have local evidence. Current exact-head CI and fresh independent review remain required; no physical-iPhone validation is claimed.

After #87, Chess running-app tests reveal controls within the active `feed.cardScroll` and navigate through the compact Feed navigation menu. Wait for the settled position before checking reset/completion; menu dismissal alone does not prove the native animation committed. Preserve the generic feed/replacement routes' original six-card/four-demo membership alongside the seven-card production deck.

`ChessPuzzleLoader.bundled(in:)` is an explicitly `@concurrent` async file/decoding adapter. Main-actor composition must await it through retained startup, then use the immutable decoded values; calling synchronous disk reads from a UI constructor violates CODING.md. In-memory `decode(_:)` remains synchronous. App startup owns cancellation, visible loading/error state, and one cached fixture set; the game adapter owns no duplicate session task.

## Endless reuse policy #104

The stated first implementation default reuses the two validated original White/Black puzzles. Repeated Chess cards have new card identities but do not claim generated positions. Archive solved attempts and restore them in fresh inactive controllers after eviction; fixture validation remains unchanged. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Stable selection and completion #108

Reserve all own-piece selection and feedback/result text variants with their actual styles. Retain the alternative piece and coordinate controls after checkmate, visibly disabled through the existing input gates, to preserve board/control positions and scroll extent. Read [stable layout](../../../docs/GAME_LAYOUT.md) before changing completion composition. Native regression anchors use an unselected square, not its enlarged selected outline.

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../../docs/GAME_PREVIEWS.md).
