# Difficulty research and proposed classification

Status: **Proposed**, partial contribution to [#118](https://github.com/devofthings/sidequest/issues/118), researched October 5, 2026. Multiple difficulties are approved; these tier definitions and thresholds are not selected implementation. This note adds no gameplay, classified fixture catalog, settings, progression, or verified completion-time claim. The owner’s feed-mix versus manual-selection decision remains [pending in #118](https://github.com/devofthings/sidequest/issues/118#issuecomment-5998722336). [#117](https://github.com/devofthings/sidequest/issues/117) still owns varied Chess rules and presentation.

## Evidence and scope

The original rule audit uses source `acd8933`; this integration follows merged source `2f66275`. Production now supplies standard 9×9 Sudoku with digits 1–9, coordinate controls, and a maximum of 12 editable cells; historical mini fixtures remain separate. These rules and controls are implemented, while a human-difficulty classifier is not. The current Chess contract accepts exactly two kings and the moving side’s queen, standard 8×8 coordinates, and checkmate in one. Bubble has three colors, eight shots, five staggered rows, and generated three-clear witnesses. Memory has twelve cards with six distinct pairs. See [Sudoku](../SUDOKU.md), [Chess](../CHESS.md), [Bubble](../BUBBLES.md), and [Memory](../MEMORY.md) for their actual delivery evidence.

Sudoku publisher Conceptis bases difficulty on logical decisions, complexity, and bottlenecks rather than clue count. That supports measuring a reasoning trace, but does not establish Sidequest thresholds or session times. [Conceptis’s first-party explanation](https://www.conceptispuzzles.com/index.aspx?uri=info/article/2).

A research evaluation against human Sudoku solving identifies both step complexity and dependencies between steps as useful predictors. This supports tracking alternatives at each step; it is not validation of this proposal against our players. [Pelánek, *Difficulty Rating of Sudoku Puzzles: An Overview and Evaluation*](https://arxiv.org/abs/1403.7373).

## Sudoku: technique first, workload separately

Propose an independent deterministic human-strategy classifier, separate from the existing bounded uniqueness solver. Its supported techniques are naked singles, hidden singles, naked pairs, and locked candidates of the pointing type. A naked single leaves one candidate in a cell; a hidden single leaves one possible cell for a digit within a unit. Pairs and pointing eliminate candidates without guessing. These definitions come from publisher tutorials: [naked singles](https://sudoku.com/sudoku-rules/obvious-singles/), [hidden singles](https://sudoku.com/sudoku-rules/hidden-singles/), [naked pairs](https://sudoku.com/sudoku-rules/obvious-pairs/), [pointing pairs](https://sudoku.com/sudoku-rules/pointing-pairs/).

| Proposed tier | Reproducible eligibility |
| --- | --- |
| Easy | Naked-single-only replay solves the complete puzzle. |
| Medium | Naked-only replay stalls; naked plus hidden singles solves completely. |
| Hard | Both single-only replays stall; adding naked pairs and pointing eliminations solves completely, with at least one effective elimination required. |
| Unclassified | The supported logical replay cannot finish, input is invalid, uniqueness is unproven, or the work budget expires. Do not label it Hard as a fallback. |

Order techniques from simplest to strongest; within a technique use ascending row, column, digit, then unit index. Recompute candidates after placements, preserve effective elimination state, and retain every justified placement/elimination. A fixed trace is an algorithmic classification, not proof that every human must use that strategy. Record the number of placements, effective advanced eliminations, and single-choice bottlenecks alongside the tier. Treat blank count as workload metadata; a long Easy puzzle may still be unsuitable for a short card.

Original reproducible example configuration: define solved digit at zero-based `(row, column)` as `1 + ((3 * row + row / 3 + column) % 9)`, with integer division. For an Easy candidate, remove exactly `(0,0), (0,4), (1,1), (1,5), (2,2), (2,6), (3,3), (3,7), (4,4), (5,5), (6,6), (7,7)`. A dependency-free development replay filled all 12 blanks using naked singles. This is an independent example check, not execution of the app’s uniqueness solver or an implemented classifier; the canonical rule and trace checks remain planned. For Medium/Hard, start from the same original solved-grid family, use deterministic clue removal, and accept only puzzles satisfying the replay table and exhaustive uniqueness proof. Do not publish a candidate merely because a desired clue count was reached; no concrete Medium/Hard puzzle is certified by this document.

The implemented standard production baseline in [#170](https://github.com/devofthings/sidequest/issues/170) limits each puzzle to at most 12 editable cells as a technical pocket-size default, independently of tiers. Its size alone cannot supply an Easy label. Current rules can establish valid givens and uniqueness; the strategy trace and eligible Medium/Hard corpus still need bounded implementation and tests. Standard 9×9 and mini 4×4 must retain explicit format identities; do not compare their blank counts as a common difficulty scale.

## Chess: legal alternatives within the current envelope

Checkmate requires check with no legal response, not merely attacking the king. Standard king safety and legal movement remain authoritative if a board is cropped. [FIDE Laws, Articles 1, 3, and 5](https://handbook.fide.com/chapter/e012023).

For a first mate-in-one classification, propose counting **all** legal moves, accepted mates, and legal checking moves that fail to mate. These are reproducible search-choice measures, not established human ratings. Keep the full position and every equivalent accepted solution; never manufacture difficulty by rejecting a valid mate.

| Proposed tier | Candidate eligibility within king/queen mate in one |
| --- | --- |
| Easy | At least three mating moves, and no checking move that fails to mate. |
| Medium | At least two mating moves, with one or more checking nonmates. |
| Hard | Exactly one mating move, with one or more checking nonmates. |

These disjoint bins are an exploratory proposal. It is not established that the current three-piece envelope provides a varied eligible catalog for all three bins. Reject empty/unproven bins rather than advertise three levels. The existing original White example has FEN `7k/5K2/6Q1/8/8/8/8/8 w - - 0 1`, 26 recorded legal moves, and four accepted mates: `g6g7`, `g6g8`, `g6h5`, `g6h6`. The Black example has FEN `8/8/8/8/8/1q6/2k5/K7 b - - 0 1`, 26 legal moves, and four mates: `b3a3`, `b3a4`, `b3b1`, `b3b2`. Checking-nonmate counts have not been measured here, so neither receives a proposed label.

Future candidates should be original positions verified with the existing exhaustive fixture validator, with provenance and complete move sets retained. A candidate Hard example would have one accepted queen mate and at least one plausible checking nonmate; this is an eligibility configuration, not an invented validated FEN. True smaller-board rules, additional piece kinds, and multistep solutions need their separately recorded decisions and rule support. Different focus-window sizes do not establish difficulty. Current code can validate recorded mate-one sets; computing checking decoys and building a catalog remain future work.

## Bubble: attainable routes and aim tolerance

Retain current colors, geometry, explicit Fire, actual collision/attachment rules, and eight-shot cap as the baseline. Propose classifying original challenges by the shortest winning route **on a declared finite angle grid**, together with the least tolerant step on a winning route. Use integer degrees from −60 through +60 inclusive for an initial reproducible development probe. A discrete search cannot prove that a shorter continuous-angle route is impossible; label the metric accordingly.

For each state on a witness route, vary that step over the grid and replay the remaining witness. Count the largest contiguous successful interval containing the witness angle. Its width measures sampled aim forgiveness. Use the minimum width across the route. A valid witness is necessary; one successful narrow endpoint is insufficient evidence of usable controls.

| Proposed tier | Initial eligibility targets, requiring actual rule replay |
| --- | --- |
| Easy | Shortest sampled win is two clearing shots; minimum successful interval spans at least 20 degrees. |
| Medium | Shortest sampled win is three clearing shots; minimum interval spans at least 12 degrees. |
| Hard | Shortest sampled win is four or five shots; minimum interval spans at least 6 degrees, and there is a verified route within eight shots. |

Thresholds are proposed engineering targets, not research-derived player ratings. All other candidates stay unclassified. For the search, bound explored states and reject incomplete shortest-route claims; deduplicate full board/shot-index states, retain the exact angle grid and rule version, and replay witnesses with the app’s pure rules. Record required wall reflections and nonclearing setup shots as separate strategy metadata. Do not make tiny touch targets, faster animations, or removed accessible controls the source of difficulty.

A concrete original current candidate is the generator’s unreflected pattern 7 with color permutation red/blue/green: ceiling row `[red, red, blue, blue, green]`, second row `[red, red, blue, green]`, queue beginning red/blue/green, and witness `[-55, -60, -60]` degrees. The generator replays its witness before publishing. This is a three-shot baseline example, **not** a Medium certification: its shortest sampled route and tolerance metrics are unmeasured here. Easy/Hard candidate construction would need different original arrangements and queue configurations; do not relabel the same baseline three ways. Existing rules can replay routes; the bounded grid search, tolerance measurement, and diverse eligible catalog remain future implementation.

## Memory: layout burden without changing the rules

Retain six pairs, existing symbol identities, face-down preview, and the current mismatch delay. Propose measuring pair separation on the frozen three-column/four-row logical board, independently of its accessibility presentation. Let separation be Manhattan distance between a pair’s two logical positions; calculate mean and maximum across the six pairs. This is a layout proxy, not a demonstrated memory-difficulty scale.

| Proposed tier | Layout proxy candidates |
| --- | --- |
| Easy | Maximum pair distance ≤2. |
| Medium | Maximum distance ≥3 and mean distance <3. |
| Hard | Mean distance ≥3. |

The bins partition layouts, but equal distance may still produce very different recognition/memory experiences. Require comparison through personal testing before treating them as player-facing levels. Use the same original six symbols; do not shorten mismatch exposure, reshuffle mid-attempt, introduce a timer, or increase the pair count to force difficulty.

Concrete candidate sequences in row-major order, using `S=star, H=heart, M=moon, U=sun, L=leaf, B=bolt`:

- Neighboring: `S H M / S H M / U L B / U L B`.
- Interleaved: `S H M / U L B / S M H / U B L`.
- Separated: `S H M / U L B / B L U / M H S`.

All have exactly two of each symbol. A dependency-free development calculation checked the row-major distances: Neighboring has maximum 1 and mean 1; Interleaved maximum 3 and mean 8/3; Separated maximum 5 and mean 10/3. They land in the proposed Easy/Medium/Hard proxy bins, respectively; this is mathematical layout evidence, not app classification or comparative human validation. Existing rules validate pair multiplicity and frozen layout. A pure metric and deterministic boundary tests remain future work; the owner’s latest priority is Sudoku, Bubble, and Chess.

## Frozen cards and verification plan

Proposed implementation seam: a game-owned immutable classification result contains tier, classifier version, measured metrics, and the original frozen challenge. Attach it during off-main batch preparation before publishing a card, not while rendering or starting. Keep the card ID, challenge payload, and classification together in lightweight history; reset, Bubble replay, and completed restoration must preserve them. A future selected preference affects only future generated cards, never an existing card. It does not alter game/news preference or phase-two scores.

Planned verification, not executed app evidence:

1. Validate original candidate provenance, complete structural validity, and exactly one Sudoku solution; reject search exhaustion and ambiguous/unsatisfiable input. Reproduce each accepted classification from its stored strategy/search version.
2. Test every tier boundary, effective versus ineffective eliminations, unsupported strategy and budget failures. Keep classification independent of generation randomness so neighboring game configurations do not change unexpectedly.
3. Exhaustively verify each new Chess fixture and equivalent mate set through the existing development validator. Fail on invalid king safety, unsupported pieces, missing mates, or clipped important information.
4. Replay Bubble witnesses and sampled shorter-route/tolerance probes through the actual geometry and rules. Check the declared search domain, deterministic work bounds, reflection, shot cap, and cancellation. Incomplete search must remain unclassified.
5. Check all Memory example metrics, pair invariants, deterministic selection, and normal versus accessibility reflow independence.
6. Verify frozen difficulty through preview/start, unfinished skip/reset, completion/eviction/revisit, and Bubble replay in unit/controller tests. After distribution is selected, verify visible and spoken tier labels, stable geometry, and any chosen controls through focused running-app checks; preserve the tiny routine smoke gate.

## Readiness record

| Question | Kind | Answer / status | Evidence / remaining validation |
| --- | --- | --- | --- |
| Can clue count or window size alone define difficulty? | Fact | No defensible human-difficulty proof. | Sudoku primary research; current Chess legality versus presentation. |
| Where should classification run? | Proposed technical choice | Pure game-owned classifier during frozen batch preparation. | Existing `GeneratedGameBatch` boundary; implementation and lifecycle tests pending. |
| Are the proposed three tiers populated and valid? | Fact still open | Not established; no catalog is certified here. | Original candidate proof, deterministic classifier, and bounded generation tests required. |
| How are levels exposed? | Human-owned decision | Pending: mixed feed versus manual selection. | Existing assigned #118 request; no settings or progression selected. |
| What rules govern varied pocket Chess? | Human-owned decision | Pending #117 boundary and multistep scope. | Current standard king/queen mate-one envelope only. |

This partial research is ready for independent documentation review. Full #118 implementation is not ready: choose exposure policy, record the selected definitions, verify eligible examples, and then split bounded game-owned implementation tickets without expanding into Ideas or paid catalogs.
