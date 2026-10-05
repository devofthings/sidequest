# Phase-two results and rankings

Status: **proposed; owner selection pending**. Prepared October 5, 2026 for [#19](https://github.com/devofthings/sidequest/issues/19). Accounts, synced preferences, high scores, and shared leaderboards are accepted phase-two directions; the mechanics below are unselected. This documentation changes no app behavior or backend configuration.

## Recommendation and owner choice

Begin phase two with synced **personal results and challenge-specific personal bests**, then add an opt-in shared board when its credibility model is selected. Rank each game using its own efficiency metric. Show elapsed time as personal context without using it to break ranking ties: touch speed, assistive input, and animation settings should not decide an efficiency tie.

The owner can select this personal-first sequence, or request shared casual rankings alongside the first account release. Both preserve the accepted phase-two leaderboard direction. A public validated leaderboard requires a separate implementation and verified operating-cost decision. The metrics, identity, eligibility, and timing below must be selected or revised before implementation; reviewing or merging this proposal does not select them.

No streaks, currency, lives, purchases, rewards for news reading, or universal points are included. Completing a short game remains useful on its own; news cards retain their existing cadence and attribution.

## Current source facts

The current source has no persistent high-score system or shared ranking. The following facts anchor this proposal:

- [Sudoku](../../Sidequest/Games/Sudoku/Rules/SudokuBoard.swift) accepts edits to empty-given cells, reports current conflicts, and completes a filled conflict-free 4×4 board. It stores no historical mistake count.
- [Memory](../../Sidequest/Games/Memory/Rules/MemoryRules.swift) uses twelve tiles/six pairs. Each accepted second flip yields a match, mismatch, or completion; ignored flips have no rule effect. It stores matched pairs, not a turn counter.
- [Chess](../../Sidequest/Games/Chess/Domain/ChessAttempt.swift) solves supplied one-move mate fixtures through validated legal/accepted move tables. Selection and destination controls precede submission. It stores feedback, not a rejected-move counter; it is not a general chess engine.
- [Bubble](../../Sidequest/Games/BubbleShooter/Rules/BubbleShooterGame.swift) counts committed shots and has an eight-shot limit. Win and loss both end play; only clearing the board is a win. A traced/canceled shot is not committed.
- [Lifecycle](../CONTRACT.md) starts only after an explicit tap; skipping or backgrounding resets unfinished attempts, while completed revisits retain results. Only Bubble currently exposes completed replay. [Endless challenge generation](../ENDLESS.md) freezes configuration per card but can repeat equivalent challenges.

The [pocket proposal](../pocket-games/README.md) and difficulty specification #118 remain separate decisions. These metrics assume existing game rules and introduce no new board dimensions or difficulty labels.

## Proposed metric definitions

“Best” compares **successful completed attempts at the exact same challenge configuration and rules version**. Lower is better for every metric below. Count a rule event once after the rule accepts it; preview taps, disabled input, repeated callbacks, and mere view updates count zero.

| Game | Primary metric / personal best | Exact counting rule | Example |
| --- | --- | --- | --- |
| Sudoku | Fewest conflict entries | Count one when an accepted edit changes a cell to a nonzero value and that edited cell belongs to the resulting conflict set. Clearing, unchanged assignments, and rejected edits count zero. A correct edit elsewhere does not count because another conflict remains. | Completed with 2 conflict entries improves an earlier result of 3. |
| Memory | Fewest pair turns | Count one for each accepted second flip resulting in match, mismatch, or completion. The first flip and ignored inputs count zero. Six matches plus two mismatches yield 8 turns. | 8 turns improves an earlier result of 10. Minimum is 6. |
| Chess | Fewest rejected moves | Count one for a submitted origin/destination pair resulting in illegal move or legal-but-not-mate feedback. Missing selection, coordinate editing, piece selection/deselection, and the successful mate count zero. Board taps and coordinate submission follow the same rule. | Mate after 1 rejected move improves an earlier result of 2. |
| Bubble shooter | Fewest committed shots in a win | Use the game’s committed-shot counter, including unmatched shots preceding a win. Canceled/incomplete flight counts zero. Loss is an outcome with its shot count, never a high score. | Clearing in 3 shots improves an earlier winning result of 4. |

Sudoku conflict entries are observable rule conflicts, not a claim about every logically wrong answer. Chess allows repeated failed submissions but does not count extra navigation taps. Memory completion includes its final matching turn. Bubble has no bonus for matching versus detached bubbles: those are different ways to clear the same objective.

Do not compare Bubble boards with different starting colors or shot sequences, different Memory layouts, different Sudoku givens, or the two Chess fixtures as though they have equal difficulty. Equivalent board appearances can share a challenge key only when their full game-relevant configuration is identical. There is no all-game total or ranking by raw completion count: endless generated quantity would reward swiping and practice rather than comparable play.

## Attempt, timing, and replay rules

These are proposed phase-two result rules; accepted MVP lifecycle behavior stays intact.

1. On the explicit accepted start, create a new attempt identity, zero its counters, and record monotonic start time. The start tap makes no move. Preview reading has no score or timer.
2. Elapsed time runs continuously during the attempt, including thinking, card-internal scrolling, mismatch delay, and Bubble flight. Stop it at successful rule completion or loss, before any success celebration. Record milliseconds; show whole seconds rounded down as personal context. Inject a clock for deterministic tests; never use wall-clock changes to compute duration.
3. On unfinished skip, background, or another lifecycle reset, discard ranking eligibility and active counters. A return starts fresh from the existing preview; it cannot resume a suspended ranked attempt. No partial high score, failure penalty, automatic submission, or swipe penalty is produced.
4. Freeze a completed result once per attempt identity. A revisit, adapter restoration, animation callback, or app recomputation does not create another submission. Phase-two durable storage is new work; current session retention is not cross-launch sync.
5. Bubble Replay is a fresh attempt at the same challenge. Mark every restart after that account's first accepted start of this exact challenge as **Practice**, including unfinished skipped starts and equivalent later feed appearances. If prior-history sync is unresolved offline, keep shared eligibility pending instead of assuming first exposure. Practice may improve a labeled personal best but is excluded from the proposed shared first-attempt board. Other games gain no replay button from this proposal.
6. A previous completed personal result remains when a later attempt is skipped or loses. Resetting an active attempt cannot erase a prior personal best. An equal primary metric is **Tied personal best** regardless of elapsed time.

“First attempt” limits ranked practice; it does not prove the player has never seen a challenge elsewhere. First-start recording and concurrent-device conflicts require the selected backend, and a modified client can bypass casual declarations. Preview exposure itself is allowed and untimed, so this is an efficiency board, not a speed competition.

## Reviewable result screens

These static text wireframes are proposal examples, not running-app screenshots. Values are illustrative and assume a prior personal result. A fixed result footprint keeps the board and controls stable under [the selected design](../DESIGN.md) and [stable-layout rules](../GAME_LAYOUT.md). Color is supplementary; text supplies outcome, comparison, and credibility. Dynamic Type, VoiceOver reading order, Reduce Motion, and actual geometry require implementation verification.

```text
SUDOKU — RESULT                 MEMORY — RESULT
Solved                         All six pairs found
2 conflict entries             8 pair turns
Personal best · previous 3      Personal best · previous 10
Time: 42 s · personal context   Time: 31 s · personal context
Personal result                Personal result
[View my results]               [View my results]
```

```text
CHESS — RESULT                  BUBBLE — RESULT
Checkmate                       Board cleared
1 rejected move                 3 shots
Personal best · previous 2      Personal best · previous 4
Time: 18 s · personal context   Time: 24 s · personal context
Personal result                Practice · personal result
[View my results]               [View my results]  [Replay]
```

Loss example: **Challenge ended · 8 shots · No new best**, with the existing Bubble Replay action. No prior result example: **First personal result**. Unfinished resets show the ordinary tap-to-play preview, not a score screen. Local-only sync failure reads **Saved on this device · Sync pending**; successful account sync reads **Personal result · Synced**. “View my results” is a proposed phase-two action, not a current feature.

## Proposed shared ranking and identity

Provide a separate optional shared-board screen reached explicitly from personal results. Joining requires an authenticated account, explicit opt-in, and a public alias separate from email, real name, provider ID, and private preferences. Display **alias + nonidentifying disambiguation code** when needed; backend user IDs stay internal. Proposed initial read is a paginated top 20 for one exact challenge/rules key, plus the user's own eligible result. There is no unsolicited feed leaderboard card or global exact-rank promise.

```text
MEMORY · CHALLENGE M-042 · RULES 1
Shared first-attempt results
Self-reported · not server-validated
Rank   Alias               Pair turns
1      QuietFox#4G          7
1      BlueLeaf#9K          7
3      You                 8
[Previous]  [Next]          [Leave shared board]
```

Competition ranking uses 1, 1, 3 for ties. Pagination uses a stable internal secondary key without breaking displayed ties; showing a top page does not imply computing everyone's exact global rank. Alias change, account deletion, removal from shared visibility, and stale cached entries require explicit phase-two privacy behavior. Proposed default is personal-only; leaving removes shared entries but preserves private results unless the account is deleted. Public aliases introduce moderation/abuse work that must be scoped before public rollout.

## Credibility and backend needs

| Mode | What can be claimed | Required phase-two work |
| --- | --- | --- |
| Personal | A result recorded for this account/device; no independent honesty guarantee | Owned private records, deterministic metric calculation, sync/outbox, idempotency, conflict resolution, deletion/export. |
| Casual shared | Authenticated, schema/range-checked **self-reported** result | Explicit opt-in/alias, ownership rules, immutable challenge keys, duplicate protection, first-start history/conflicts, bounded queries, and rate/abuse limits. Authentication does not validate play. |
| Validated shared | A server independently replayed accepted action history and verified the stated outcome/metric | Trusted versioned challenge catalog, server rule verifier, ordered transcript, authoritative first-start reservation, nonce/replay prevention, atomic result acceptance, operations and cost approval. |

Even action replay validates rule consistency, not human skill or absence of bots, answer lookup, or altered timers. This is why elapsed time remains unranked. A server verifier must accept all valid solutions, not only one recorded solution; copied client counters are not validation. Casual and validated entries appear in separate boards with persistent credibility labels.

Link these needs to the [backend comparison](../research/backend-options.md) and [#18](https://github.com/devofthings/sidequest/issues/18). Provider selection, authentication methods, deployed functions, quota verification, billing prerequisites, moderation, and public distribution are pending. This proposal provisions none of them and makes no free-hosting claim. The accepted [hexagonal architecture](../adr/0003-hexagonal-architecture.md) keeps game metrics pure and adds result storage/submission adapters only during approved phase-two implementation.

Suggested neutral result fields: attempt ID, account owner, canonical challenge/configuration key, game kind, rules version, primary metric with unit, outcome, elapsed milliseconds, first-attempt/practice status, credibility status, and sync status. Rules/challenge version changes create a new comparison group. Server-assigned validation status is separate from client assertions. Retain only the transcript needed for the selected validation mode, with its privacy/retention decision recorded first.

## Readiness self-assessment

The project-local agent-grill was applied as a self-assessment; this is not independent review or owner approval.

| Question | Kind | Answer/status | Evidence / rationale | Verification needed |
| --- | --- | --- | --- | --- |
| Are persistent metrics implemented? | Fact | No; only Bubble has a committed-shot counter. | Current rules/controllers linked above. | Future metric instrumentation unit tests. |
| Can one score compare all generated puzzles? | Fact/assessment | Current generation has no validated equivalence tiers; exact configuration is the proposed comparison boundary. | ENDLESS.md and the separate pending difficulty scope. | Canonical-key equivalence and version tests. |
| Should personal and shared ranks use time? | Human-owned | Proposed no; display personal time only. | Limits input-speed and accessibility bias. | Owner selection; injected-clock lifecycle tests later. |
| Can client ownership rules prove honest play? | Fact | No; distinguish self-report from trusted rule replay. | Backend comparison's leaderboard boundary. | Backend attack/replay tests after provider selection. |
| Which rollout, metrics, alias, and credibility should ship? | Human-owned | Pending; recommended personal-first, then opt-in appropriately labeled shared boards. | Accepted phase-two direction does not select mechanics. | Explicit owner decision recorded in #19 and durable decisions. |

Proposal preparation is complete when all four metrics, lifecycle edge cases, screen examples, and unresolved owner choices are documented and independently reviewed. **Implementation readiness remains pending** until the owner selects these rules and prerequisite backend work is authorized. Planned verification covers counting/ignored input, wrong-versus-winning outcomes, skip/background/reset, replay eligibility, restored completion, duplicate/offline submissions, ties, account separation, and version partitions. These checks have not run because this PR implements documentation only.
