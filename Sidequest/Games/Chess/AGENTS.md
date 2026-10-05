# One-move chess puzzles

Issue #7 owns this bounded game. Use original king-and-queen checkmate-in-one positions, with both colors represented. The initial set excludes pawns, promotion, castling, and en passant. Keep a full opponent, generated positions, scoring, and multistep tactics out of this slice.

Canonical bundled `Sidequest/Resources/chess-puzzles.json` records each FEN, moving side, objective, every legal move, and every accepted mate. Keep fixture assets in Resources while this area owns their contract and validation. The app evaluates these fixed verified sets; it is not a general chess legality engine. Validate each position and enumerate **all** mates with the pinned external tool in [CHESS.md](../../../docs/CHESS.md). Never accept a hand-entered answer list without that evidence. The GPL tool is an isolated development dependency, never linked into or bundled with the app.

Keep rules as pure Swift values. Parsing validates structural fixture requirements; the external validator establishes legal-position and complete-solution correctness. Wrong or illegal moves leave the starting position intact for another attempt. Selecting another moving-side piece changes selection; selecting the same piece clears it. A correct move updates the displayed board and freezes the solved attempt.

Always retain White-oriented standard coordinates, with files increasing left to right and ranks increasing bottom to top. Label the moving color and checkmate objective explicitly, including for Black. Board cells have accessible piece/color/square labels; provide usable coordinate controls if eight columns cannot maintain 44-point targets on an iPhone. Verify actual layouts and both fixture solutions in the simulator before delivery.

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

## Vivid presentation and contained motion #124

Follow [the researched baseline](../../../docs/DESIGN.md). Animate square fills and the accepted destination piece emphasis for 160 ms. Derive success only from the pure attempt’s solution; illegal/nonmate moves create no success effect. No traveling overlay, task, timer, or view-owned solution state is introduced. Both moving sides retain White-oriented coordinates and full-width alternative controls. All presentation preferences resolve the propagated override before the system value. Preview, reset, and offscreen transactions disable animation; Reduce Motion supplies no local animation. Completed restoration is static because values are rendered initially, rather than changed by appearance. Keep animations inside existing board/control footprints and leave lifecycle/input/rule mutations with the controller.

Agent-grill self-assessment: Selection and accepted destination is a delegated presentation choice under #124, supported by the existing controller/runtime boundaries and DESIGN.md. Source inspection establishes no new rule or timing owner; exact-head unit/smoke CI and root-owned focused rendered/motion checks remain required before delivery. This record is not rendered verification.

## Success feedback routing #86

Mark runtime completion successful only after an accepted mating move solves the attempt. Consume the shared runtime feedback boundary in [common game guidance](../AGENTS.md); keep rules, timing, retained results, and reset semantics unchanged. Appearance or restored completed values never emit success.

## Selected pocket focus #132

The owner's October 5 “go ahead” selects [the first pocket revision](../../../docs/pocket-games/README.md). Display White's original fixture in e5–h8 and Black's in a1–d4, both fixed 4×4 windows. Keep the immutable full-board puzzle and legal/accepted move sets authoritative. A window edge is not a wall; all eight destination files/ranks remain available through existing controls. Explain the displayed range and standard 8×8 rules in visible and accessible copy. Never follow a selection or move by shifting the window.

Agent-grill self-assessment (implementation readiness, not verification):

| Question | Kind | Answer and evidence | Verification needed |
| --- | --- | --- | --- |
| Can all existing pieces and mates fit? | Fact | Original JSON and the selected specification place all three pieces, every accepted endpoint, and defending-king neighbors in the stated windows. | Pure mapping/containment tests and both-color rendered checks. |
| Who owns the window? | Delegated technical choice | A pure immutable `ChessBoardWindow` derives from the original puzzle, never attempt state. Only the two original fixture IDs/FENs receive the compact mapping; unsupported content falls back to full-board presentation to avoid clipping. No rule or fixture changes. | Unknown/changed fixture fallback and unchanged-window checks after wrong and accepted moves. |
| Are off-window moves still usable? | Fact and technical choice | Existing coordinate menus and controller validate all eight files/ranks against the full-board tables. Retain these unchanged. | Both-color off-window legal nonmate submissions, input/reset/completion regressions, normal/largest text and Reduce Motion checks. |

Keep board dimensions constant across preview, selection, wrong moves, completion, and reset. Retain the existing start, selection, and feedback regions, disabled completed controls, success routing, and contained motion. Lead-owned native checks and exact-head CI remain pending until actually recorded; source inspection does not establish layout usability or physical-device behavior.

## Compact controls #142

Root actual SE3 standard-text evidence places the original board inside the375×579 viewport but own-piece/File/Rank/Submit controls below it. The lead accepts concise objective/range copy, a normal own-piece row and File/Rank/Submit row, with complete color/kind/square AX labels and all eight menu options. Derive a square4×4 board extent from the read-only game budget minus independently measured stable nonboard chrome. Keep44-point cell/control floors; size decorative glyphs within cells instead of shrinking semantic text. Default Dynamic Type.large must fit375×667 and larger; other nonaccessibility sizes may scroll when minimum geometry cannot fit. Accessibility1+ retains natural vertical full-label controls/owned scrolling. Preserve original rules/window, explicit Start/Submit, fixed-header success and settled geometry across every phase. Record actual fit/gameplay only after root verification.

## Accepted-move feedback #161

Current one-move fixtures accept only a solving mate, so an accepted move uses the existing success haptic and visible checkmate/destination emphasis without a duplicate interaction haptic. Selection, coordinate edits, illegal moves, and legal nonmates stay quiet. Preserve contained 160 ms emphasis and immediate Reduce Motion. Future multistep rules must select their own event policy through approved scope; this slice adds no rule or attempt state.

## Selected original pieces #171

The lead selects #159's original King cross and Queen crown for both current sides under the owner's autonomous #13 design authority; see [native game art](../../../docs/design/NATIVE_GAME_ART.md). Native presentation-only Shapes translate the original64-point geometry, keeping White fill/dark outline and Black fill/light outline with stronger increased-contrast strokes. Decorative artwork and equal-sized empty regions use the existing computed piece extent; the square's coordinate/piece/side label remains semantic. Keep stable board/window geometry, all coordinate alternatives, selected/destination cues, current contained motion and Reduce Motion. No new piece kind, rule, font asset, task or behavior belongs to this artwork replacement. Root-owned native both-side appearance and interaction checks remain pending until actually recorded.

Readiness question review: Native Shapes avoid an external conversion/asset dependency and preserve original vector geometry. Current `ChessPieceKind` has only King and Queen, so exhaustive artwork cases cannot invent additional pieces. Existing squares already own semantic labels and touch/input gates. Validation requires strict lint, exact-head CI, fresh independent review and focused normal/dark/small/largest rendered checks of both sides; source readiness is not native proof.

Use the local opaque-label board ButtonStyle to retain full artwork and coordinate contrast in preview, matched, and completed states. Native PlainButtonStyle was observed dimming these disabled labels in actual simulator captures. Keep `.disabled` eligibility and controller/runtime input guards unchanged; rendering at full opacity never enables interaction. The style adds no press transform, animation, layout or state. The original #171 six focused native flows passed before this correction; corrected rendered contrast requires a new root-owned native check.
