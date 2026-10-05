# Difficulty research and selected criteria

Status: **Accepted product exposure and selected first-pass criteria for all four games**, partial contribution to [#118](https://github.com/devofthings/sidequest/issues/118), researched October 5, 2026. Sudoku technique, Chess mate-count, Memory pair-count, and Bubble attempt-budget criteria are selected. No classifier or tier catalog is implemented by this document. This note adds no gameplay, classified fixture catalog, settings, progression, or verified completion-time claim. On October 5, the owner selected a [mixed feed with an Easy, Medium, or Hard label on each game](https://github.com/devofthings/sidequest/issues/118#issuecomment-6000642597), and [differently sized cropped Chess focus areas under standard 8×8 rules](https://github.com/devofthings/sidequest/issues/117#issuecomment-6000644787). Shared mixed-feed labels remain pending under #201; game-owned source and verification status are recorded separately under #177/#178/#187/#188. No manual level selector, automatic progression, or true smaller-board rule system is selected.

## Evidence and scope

The original rule audit uses source `acd8933`; this integration follows merged source `2f66275`. Production now supplies standard 9×9 Sudoku with digits 1–9, coordinate controls, and a maximum of 12 editable cells; historical mini fixtures remain separate. These rules and controls are implemented, while a human-difficulty classifier is not. The current Chess contract accepts exactly two kings and the moving side’s queen, standard 8×8 coordinates, and checkmate in one. Bubble has three colors, eight shots, five staggered rows, and generated three-clear witnesses. Memory has twelve cards with six distinct pairs. See [Sudoku](../SUDOKU.md), [Chess](../CHESS.md), [Bubble](../BUBBLES.md), and [Memory](../MEMORY.md) for their actual delivery evidence.

Sudoku publisher Conceptis bases difficulty on logical decisions, complexity, and bottlenecks rather than clue count. That supports measuring a reasoning trace, but does not establish Sidequest thresholds or session times. [Conceptis’s first-party explanation](https://www.conceptispuzzles.com/index.aspx?uri=info/article/2).

A research evaluation against human Sudoku solving identifies both step complexity and dependencies between steps as useful predictors. This supports tracking alternatives at each step; it is not validation of this proposal against our players. [Pelánek, *Difficulty Rating of Sudoku Puzzles: An Overview and Evaluation*](https://arxiv.org/abs/1403.7373).

## Sudoku: technique first, workload separately

Selected under #187: an independent deterministic technique classifier, separate from the existing bounded uniqueness solver. Its supported techniques are naked singles, hidden singles, naked pairs, and locked candidates of the pointing type. A naked single leaves one candidate in a cell; a hidden single leaves one possible cell for a digit within a unit. Pairs and pointing eliminate candidates without guessing. These definitions come from publisher tutorials: [naked singles](https://sudoku.com/sudoku-rules/obvious-singles/), [hidden singles](https://sudoku.com/sudoku-rules/hidden-singles/), [naked pairs](https://sudoku.com/sudoku-rules/obvious-pairs/), [pointing pairs](https://sudoku.com/sudoku-rules/pointing-pairs/).

| Selected tier | Reproducible eligibility |
| --- | --- |
| Easy | Naked-single-only replay solves the complete puzzle. |
| Medium | Naked-only replay stalls; naked plus hidden singles solves completely. |
| Hard | Both single-only replays stall; adding naked pairs and pointing eliminations solves completely, with at least one effective elimination required. |
| Unclassified | The supported logical replay cannot finish, input is invalid, uniqueness is unproven, or the work budget expires. Do not label it Hard as a fallback. |

Order techniques from simplest to strongest; within a technique use ascending row, column, digit, then unit index. Recompute candidates after placements, preserve effective elimination state, and retain every justified placement/elimination. A fixed trace is an algorithmic classification, not proof that every human must use that strategy. Record the number of placements, effective advanced eliminations, and single-choice bottlenecks alongside the tier. Treat blank count as workload metadata; a long Easy puzzle may still be unsuitable for a short card.

Original reproducible example configuration: define solved digit at zero-based `(row, column)` as `1 + ((3 * row + row / 3 + column) % 9)`, with integer division. For an Easy candidate, remove exactly `(0,0), (0,4), (1,1), (1,5), (2,2), (2,6), (3,3), (3,7), (4,4), (5,5), (6,6), (7,7)`. A dependency-free development replay filled all 12 blanks using naked singles. This is an independent example check, not execution of the app’s uniqueness solver or an implemented classifier; the canonical rule and trace checks remain planned. For Medium/Hard, start from the same original solved-grid family, use deterministic clue removal, and accept only puzzles satisfying the replay table and exhaustive uniqueness proof. Do not publish a candidate merely because a desired clue count was reached. The later #187 record below selects concrete original13/20 candidates; their actual-givens certification implementation was integrated through [PR190](https://github.com/devofthings/sidequest/pull/190), independently reviewed with exact-head CI. This is separate from human calibration and future mixed-feed presentation.

The implemented standard production baseline in [#170](https://github.com/devofthings/sidequest/issues/170) limits each puzzle to at most 12 editable cells as a technical pocket-size default, independently of tiers. Its size alone cannot supply an Easy label. Opt-in #187 supplies actual-givens technique certificates and original13/20-blank Medium/Hard examples under the implementation record below; preserve the default12-blank path until mixed integration. Standard 9×9 and mini 4×4 must retain explicit format identities; do not compare their blank counts as a common difficulty scale.

## Chess: legal alternatives within the current envelope

Checkmate requires check with no legal response, not merely attacking the king. Standard king safety and legal movement remain authoritative if a board is cropped. [FIDE Laws, Articles 1, 3, and 5](https://handbook.fide.com/chapter/e012023).

The lead selects first-pass mate-in-one tiers based on the number of accepted mating moves. Count **all** legal moves, accepted mates, and legal checking moves that fail to mate, retaining checking nonmates as a separate measurement. These are transparent search-choice proxies, not established human ratings. Keep the full position and every equivalent accepted solution; never manufacture difficulty by rejecting a valid mate. Crop size remains independent of classification.

| Selected first-pass tier | Eligibility within king/queen mate in one |
| --- | --- |
| Easy | At least three accepted mating moves. |
| Medium | Exactly two accepted mating moves. |
| Hard | Exactly one accepted mating move. |
| Unclassified | Invalid/unsupported position, no accepted mate, incomplete move sets, or proof budget exhausted. |

The earlier proposed requirement of zero checking nonmates for Easy is superseded. A development readiness probe, independently rerun during integration with the existing pinned `chess==1.11.2`, enumerated 2,100 valid nonterminal White-king/queen versus Black-king states: the defending king occupied a1, h1, a8, or h8; the moving king was within Chebyshev distance three; the queen occupied each distinct square. Enumerating every legal move produced zero Easy, 416 Medium, and 328 Hard under the old proposal. The selected mate-count bins instead produced 152 Easy, 264 Medium, and 328 Hard. The lead accepted the latter because all three bins have concrete candidates within the current piece envelope. This bounded sample establishes candidate availability, not global completeness or human calibration. It did not execute the app or canonical fixture validator.

Local development evidence: `/private/tmp/sidequest-118-chess-probe.py` and `/private/tmp/sidequest-118-readiness.json`; reproduction used `/private/tmp/sidequest-chess-validation-venv/bin/python /private/tmp/sidequest-118-chess-probe.py`. These temporary files are handoff evidence, not tracked app dependencies. Before rollout, curated original fixtures must pass the existing pinned development-only validator with complete legal, mating, and checking-nonmate sets, plus frozen focus windows that retain required information. Add reproducible classifier/fixture checks in that bounded implementation ticket.

The existing original White example has FEN `7k/5K2/6Q1/8/8/8/8/8 w - - 0 1`, 26 recorded legal moves, and four accepted mates: `g6g7`, `g6g8`, `g6h5`, `g6h6`. The Black example has FEN `8/8/8/8/8/1q6/2k5/K7 b - - 0 1`, 26 legal moves, and four mates: `b3a3`, `b3a4`, `b3b1`, `b3b2`. Their recorded mate counts satisfy selected Easy eligibility; production labels are not implemented, and checking-nonmate completeness still needs the rollout audit.

Future candidates must be original and independently validated, retaining provenance and every equivalent solution. Preserve the current two-kings/one-queen subset, standard 8×8 rules, and mate-in-one lifecycle; introduce no new runtime engine or piece kinds. True smaller-board rules and multistep solutions are not selected. Different focus-window sizes do not establish difficulty. Computing checking decoys and adopting a curated catalog remain bounded implementation work.

## Bubble: selected attempt allowance #188

The lead selects actual maximum shots of **Easy8 / Medium5 / Hard3** for the existing original three-color challenges, each carrying an actual three-clearing-shot witness. This supersedes the earlier proposed finite-angle shortest-route and sampled-tolerance classifier for this first rollout. The same original geometry can be reused because the cap changes the losing rules, rather than attaching three labels to identical rules. Preserve the legacy eight-shot default until shared feed integration.

Three differently colored ceiling anchors establish this envelope's three-clearing-action bound; replay every canonical witness with the actual rules. Do not generalize the bound to arbitrary boards or claim measured continuous-angle optimality. The extra5/2/0 shots represent available attempts, not guaranteed recoverable mistakes: danger-row or blocked-attachment failure can occur sooner. Win is resolved before cap exhaustion on the final permitted shot.

Freeze cap, optional tier, board, and full historical eight-color queue per card across start/reset/replay/completed restoration. Keep the generator's existing four-attempt fallback budget, RNG draws, colors, physics, explicit Fire, native precision controls, first-action guards and stable layout. Validate configuration and actual attainable routes before rollout. Native evidence and feed labels remain pending in the owning PR; these technical criteria are not calibrated human ratings.

## Memory: selected pair-count workload

The lead selects first-pass workload tiers of three, four, and six distinct pairs for Easy, Medium, and Hard respectively. Pair count measures a concrete increase in the amount to remember; it is not a calibrated claim about every player's experience. Use a subset of the existing six original symbol identities, exactly two tiles per included symbol, an answer-free preview, and the existing mismatch delay. Freeze pair count, layout, and tier together per card. Do not change mismatch exposure, reshuffle mid-attempt, or introduce a timer.

Production currently enforces six pairs. Rollout requires an explicit bounded generalization of that contract, layout/generator/validation support for 3/4/6 pairs, and dynamic instructions/completion copy reflecting the actual pair count. Validate all counts, completion, cancellation, accessibility reflow, reset, and completed restoration before exposing labels. This document does not implement the generalization.

### Historical proposed six-pair layout alternative

The earlier unselected alternative retains six pairs and proposes measuring pair separation on the frozen three-column/four-row logical board, independently of its accessibility presentation. Let separation be Manhattan distance between a pair’s two logical positions; calculate mean and maximum across the six pairs. This is a layout proxy, not a demonstrated memory-difficulty scale.

| Proposed tier | Layout proxy candidates |
| --- | --- |
| Easy | Maximum pair distance ≤2. |
| Medium | Maximum distance ≥3 and mean distance <3. |
| Hard | Mean distance ≥3. |

These historical proposed bins partition layouts, but equal distance may still produce very different recognition/memory experiences. Require comparison through personal testing before treating them as player-facing levels. Use the same original six symbols; do not shorten mismatch exposure, reshuffle mid-attempt, introduce a timer, or increase the pair count to force difficulty.

Concrete candidate sequences in row-major order, using `S=star, H=heart, M=moon, U=sun, L=leaf, B=bolt`:

- Neighboring: `S H M / S H M / U L B / U L B`.
- Interleaved: `S H M / U L B / S M H / U B L`.
- Separated: `S H M / U L B / B L U / M H S`.

All have exactly two of each symbol. A dependency-free development calculation checked the row-major distances: Neighboring has maximum 1 and mean 1; Interleaved maximum 3 and mean 8/3; Separated maximum 5 and mean 10/3. They land in the proposed Easy/Medium/Hard proxy bins, respectively; this is mathematical layout evidence, not app classification or comparative human validation. Existing rules validate pair multiplicity and frozen layout. A pure metric and deterministic boundary tests remain future work; the owner’s latest priority is Sudoku, Bubble, and Chess.

## Frozen cards and verification plan

Proposed implementation seam: a game-owned immutable classification result contains tier, classifier version, measured metrics, and the original frozen challenge. Attach it during off-main batch preparation before publishing a card, not while rendering or starting. Keep the card ID, challenge payload, and classification together in lightweight history; reset, Bubble replay, and completed restoration must preserve them. The accepted mixed-feed policy freezes each card’s challenge and tier together across preview, start, unfinished reset, Bubble replay, and completed revisit. New generated cards may use a different tier; an existing card never changes tier during its lifecycle. Exact mix proportions remain a technical implementation choice to record with bounded validation. It does not alter game/news preference or phase-two scores.

Planned verification, not executed app evidence:

1. Validate original candidate provenance, complete structural validity, and exactly one Sudoku solution; reject search exhaustion and ambiguous/unsatisfiable input. Reproduce each accepted classification from its stored strategy/search version.
2. Test every tier boundary, effective versus ineffective eliminations, unsupported strategy and budget failures. Keep classification independent of generation randomness so neighboring game configurations do not change unexpectedly.
3. Exhaustively verify each new Chess fixture and equivalent mate set through the existing development validator. Fail on invalid king safety, unsupported pieces, missing mates, or clipped important information.
4. Replay every Bubble canonical three-shot witness through actual geometry and rules under each selected8/5/3 cap, including Hard last-shot win precedence. Check invalid metadata, exhaustion, earlier danger loss, unchanged RNG/queues, cancellation and frozen reset/restoration/replay. Sampled shortest-route/tolerance probes are superseded for this rollout.
5. Validate selected Memory 3/4/6 pair contracts, exactly two tiles per symbol, dynamic instructions/results, deterministic selection, completion/reset/restoration, and accessibility reflow. Historical spread metrics are not the selected classifier.
6. Verify frozen difficulty through preview/start, unfinished skip/reset, completion/eviction/revisit, and Bubble replay in unit/controller tests. For the accepted mixed feed, verify visible and spoken tier labels and stable geometry through focused running-app checks; preserve the tiny routine smoke gate.

## Readiness record

| Question | Kind | Answer / status | Evidence / remaining validation |
| --- | --- | --- | --- |
| Can clue count or window size alone define difficulty? | Fact | No defensible human-difficulty proof. | Sudoku primary research; current Chess legality versus presentation. |
| Where should classification run? | Proposed technical choice | Pure game-owned classifier during frozen batch preparation. | Existing `GeneratedGameBatch` boundary; implementation and lifecycle tests pending. |
| Are all game tiers exposed in production? | Fact still open | No. All four technical criteria are selected; game-owned catalogs/configurations and their exact verification are distinct from shared rollout. | #177 Chess catalog and #187 Sudoku certification are integrated; #178 Memory and #188 Bubble proof follow their owning PRs. Mixed-feed labels/distribution under #201 remain pending. |
| How are levels exposed? | Accepted owner decision, October 5 | Mix Easy, Medium, and Hard game cards; label each game. | [Owner choice](https://github.com/devofthings/sidequest/issues/118#issuecomment-6000642597); no manual selector or automatic progression. Implementation remains pending. |
| What rules govern varied pocket Chess? | Accepted owner decision, October 5 | Differently sized cropped focus areas over standard 8×8 rules. | [Owner choice](https://github.com/devofthings/sidequest/issues/117#issuecomment-6000644787); full-board legality and semantic coordinates remain authoritative. New piece or multistep rules are not selected. |

All four first-pass technical criteria are selected. Full #118 completion still requires exact game-owned verification and coordinated shared mixed-feed labels/distribution under #201. Preserve the owning PR evidence and calibration limits; do not expand into Ideas, new progression, or paid catalogs.

## Sudoku certification implementation #187

The lead accepted the Sudoku technique criteria above for opt-in implementation. Original13-blank Medium and20-blank Hard examples from bounded seed118162 development search revise the prior12-blank technical limit for classified challenges. Easy retains at most12 blanks. Each actual givens array must pass canonical exhaustive uniqueness and match the stored complete solution; naked-only, singles, and advanced persisted-candidate replays select the first completing tier. Invalid/ambiguous/unsupported/exhausted results stay unclassified. Deterministic order is ascending cells/digits and row/column/box units, with at most81 placements/729 effective removals per replay. One seeded digit-permutation attempt is recertified before use; failure falls back to the freshly certified original of the same tier. Default generators/production selection are unchanged. Native proof and human calibration are distinct and remain unclaimed here; see [scoped readiness](../../Sidequest/Games/Sudoku/AGENTS.md#certified-opt-in-tiers-187).
