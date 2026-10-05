# Sudoku

Own pure Sudoku rules and this game's presentation adapter. Production and historical Debug routes still use 4×4 boards with 2×2 regions; the standard-format foundation below is not yet wired into gameplay. Follow [common game guidance](../AGENTS.md) and [card contract](../../../docs/CONTRACT.md).

## Historical finite Debug policy from issue #5

The implementation agent conducted an agent-grill self-assessment while feed #3 established the concrete presentation boundary. Issues #2 and #3 are merged. `SudokuController(puzzle:runtime:)` consumes the actual retained `GameRuntime`; pure rules remain independent of observation and UI.

| Question | Kind | Decision and rationale | Verification |
| --- | --- | --- | --- |
| How are givens and uniqueness guaranteed? | Delegated technical choice | Validate 16 values in 0…4 and conflict-free givens, then enumerate solutions up to two. Accept exactly one. Two original fixed fixtures avoid generation, hints, or difficulty scope. | Independent Python enumeration found exactly one solution for both; Swift negative ambiguous/conflicting fixtures and solved-board checks follow. |
| Where does selection/reset live? | Delegated technical choice | Pure `SudokuBoard` owns entries/conflicts/completion; presentation owns selected cell/feedback and gates input through the retained runtime. Start initializes without selecting/entering; skip clears selection and entries. | Controller/runtime and running-card tests after the feed boundary lands. |
| How are invalid entries handled? | Delegated technical choice | Permit 1–4 in editable cells and 0 for clearing. Mark row/column/region conflicts and allow correction; given cells are immutable. | Invalid index/value/given attempts, conflict correction, partial/solved boards, and reset. |

The finite Debug routes retain each adapter by CardID so completed boards survive revisiting. Issue #104 supersedes this original fixed-only production scope and retention policy with generated challenges and the bounded adjacent adapter cache below. Keep timers, persisted progress, scoring, hints, and automatic feed advance deferred. UI work must record actual simulator checks before completion.

`SudokuGameView(controller:)` renders the retained board without nesting another scroll view inside the feed. Cells and number/clear controls use 44-point minimum heights; row/column labels, given/value/conflict cues, and decorative central dividers distinguish the four 2×2 regions. The controller binds the runtime weakly once, initializes only on start, clears board/selection on reset, and preserves solved rules on stop. No delayed work is introduced.

Finite Debug composition selects a validated original fixture once for the card, never in a view body. `-sidequest-sudoku-test` selects a deterministic Sudoku-first deck plus one news card for running-app checks. The shared `-sidequest-feed-test` route remains a DEBUG-only generic lifecycle harness; normal and Release Sudoku cards use actual Sudoku rules. Invalid bundled fixtures produce a visible composition failure rather than fabricated gameplay.

Place cell sizing, backgrounds, and rectangular content shapes inside Button labels so the entire visible cell selects it. Put number/clear target sizing inside their labels as well. Verify actual normal-size accessibility dimensions of at least 44×44 points and taps near all four editable-cell corners; outer padding or frames alone do not prove an effective touch area. This corrects the confirmed normal-size touch defect without changing rules or lifecycle.

## Generated challenges #104

Normal production generates uniquely solvable 4×4 challenges with game-owned `SudokuGenerator`: randomize a valid solved grid, then consider each clue once and remove it only if the existing solver still finds exactly one solution. Freeze the puzzle before publishing its card and reset its entries/selection without regenerating. Retain concrete controllers only for previous/current/next cards. On eviction, archive the completed board and selected cell and permanently retire the old runtime; restore completed revisits in a fresh inactive owner. Fixed fixtures and all-controller retention remain dedicated finite Debug regressions. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Stable status #108

Reserve the natural size of all instruction, conflict, and solved status messages at the current width/font/text size. Complete status remains readable below the unchanged grid and number/clear controls. Follow [stable layout](../../../docs/GAME_LAYOUT.md) when changing copy or styles; no fixed text height or truncation belongs here.

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../../docs/GAME_PREVIEWS.md).

## Vivid presentation and contained motion #124

Follow [the researched baseline](../../../docs/DESIGN.md). Animate only the selected cell surface and numeric text for 160 ms. Cells keep their reserved square footprint; fixed givens and inactive boards use explicit opaque ink/accent colors. Conflict feedback remains textual and uses a contrasting error ink. Completion keeps the existing reserved status text. All presentation preferences resolve the propagated override before the system value. Preview, reset, and offscreen transactions disable animation; Reduce Motion supplies no local animation. Completed restoration is static because values are rendered initially, rather than changed by appearance. Keep animations inside existing board/control footprints and leave lifecycle/input/rule mutations with the controller.

Agent-grill self-assessment: Selection and numeric entry is a delegated presentation choice under #124, supported by the existing controller/runtime boundaries and DESIGN.md. Source inspection establishes no new rule or timing owner; exact-head unit/smoke CI and root-owned focused rendered/motion checks remain required before delivery. This record is not rendered verification.

## Success feedback routing #86

Mark runtime completion successful only after the board reports isComplete. Consume the shared runtime feedback boundary in [common game guidance](../AGENTS.md); keep rules, timing, retained results, and reset semantics unchanged. Appearance or restored completed values never emit success.


## Standard-format foundation #162 — partial delivery

The owner approved standard 9×9 boards, digits 1–9, nine 3×3 regions, and meaningful difficulty levels. This compatible pure-rule slice supports explicit `SudokuConfiguration.standard`; `.mini` remains the default for existing constructors, generated production cards, presentation, and finite smoke fixtures. Do not pass a standard puzzle to the current hardcoded mini view. Full game exposure, 44-point coordinate entry with a readable overview, native usability proof, and #118's tier/distribution decisions remain pending. This slice does not complete #162 or select a difficulty.

Agent-grill self-assessment with lead `/root`: Format is a fact-owned configuration on the immutable puzzle, so board/reset/completed-result values preserve it without changing shared feed contracts. The default mini generator keeps its existing random operations and clue-removal order; explicit mini generation delegates to it, preserving the production random stream. Standard generation permutes a valid original solved grid, attempts each clue removal once, retains at least 40 clues, and accepts removal only with an exhaustive uniqueness proof. Forty clues is a bounded-work safeguard, not evidence of human difficulty. No puzzle catalog or external service is introduced.

Use minimum-remaining-values search with row/column/region masks, capped at two solutions and 100,000 visited nodes for puzzle validation. Reject an exhausted node budget with `searchLimitReached`; never accept a partial single solution as a uniqueness proof. Standard generation limits each removal search to 10,000 nodes and keeps the clue when a proof is incomplete. Check cancellation before standard generation and between clue attempts; the existing `GeneratedGameBatch.prepare` boundary runs production preparation away from the UI actor. A synchronous rule call does not itself establish thread placement. UI and tier work must record native verification before delivery.

Verification planned: deterministic generated standard puzzles, independent row/column/region checks, immutable givens and digit 9 correction/completion/reset, ambiguous/conflicting/invalid formats, incomplete search with and without a found solution, unchanged mini random stream, existing mini/endless/Bubble witness regressions. Formatting and offline checks are not native gameplay or performance evidence.

## Entry feedback #161

Only a changed, accepted editable-cell entry or clear requests the shared interaction haptic; selection, repeated values, invalid input, and inactive attempts stay quiet. Conflicting entries remain permitted and visibly marked for correction by existing pure rules. A solving entry receives only existing success feedback. Preserve contained 160 ms numeric feedback and immediate Reduce Motion; add no timer, score, rule, or automatic navigation. Native and physical feedback verification remain separately pending.

## Standard pocket presentation #170

Accepted technical baseline under owner-approved #162: production cards use standard9×9 puzzles with3×3 regions and at most12 editable cells. This bounds session length; it is not a difficulty tier, human difficulty proof, hint or automatic progression. Generalized standard generation retains its prior default41-removal cap; each removal still requires exhaustive uniqueness proof. Historical finite mini routes/results retain4×4 rules and layout.

The standard overview reserves216–300 points at normal text from independently measured stable nonboard chrome; accessibility text uses300 points and card-owned vertical overflow. Its24–33point secondary squares are not44point controls. Native Row/Column menus and1–9/Clear actions supply44point alternatives; accessibility text stacks coordinates. Fixed17point overview digits retain legible spatial context while surrounding labels use Dynamic Type. Actual legibility/fit requires root-owned native checks. Region dividers are distinct beyond color. Status reserves every message; no mutation changes the board/control footprint. Motion follows the existing160ms contained selection/entry policy and propagated Reduce Motion.

Coordinate focus belongs to the retained controller, resets with unfinished attempts, and permits read-only given coordinates without selecting an editable square. Entry remains impossible for givens/offscreen/preview/completed attempts. Valid direct editable selection synchronizes coordinates. Restored completed board/selection reconstructs coordinate focus without feedback.

Agent-grill with lead: existing40-clue standard foundation would leave41 blanks; lead selected12 editable cells for the first bounded pocket baseline. Standard cards use stable seed/index integer arithmetic with a separate RNG. Consume historical mini generation on the legacy batch RNG solely to preserve neighboring Memory/Bubble and shuffle draws; regression tests compare real generated neighbors. No Swift randomized hash, remote generation, tier labels or feed selector. Dedicated DEBUG standard fixture uses12 original blanks and real1–9 completion; historical mini fixtures remain unchanged. #118 owns pending tier policy.

GameGenerationComposition explicitly selects mini only for the existing DEBUG endless fixture route, preserving its historical4×4 completion assertions. GeneratedGameBatch takes an explicit configuration with standard as its default; normal/Release production uses standard. The new standard route exercises the same9×9 rules/controller/view through deterministic original input.
