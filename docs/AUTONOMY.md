# Autonomous delivery plan

Prepared October 3, 2026 for [issue #33](https://github.com/devofthings/sidequest/issues/33). The user explicitly authorized implementation on October 3, 2026: "Start the actual implementation. Good Luck Have fun!" Execute the confirmed MVP sequence. No scheduled task was created. Start authorization and usage rules are authoritative in [AGENTS.md](../AGENTS.md).

## Ownership and start condition

The agent acts as technical lead: selects ready work, resolves routine implementation choices within accepted decisions, coordinates implementation and fresh reviews, verifies results, fixes findings, and merges through [REVIEW.md](REVIEW.md). The user provides product direction in repository documents and does not need to review code.

The explicit user start lifts the prior app-development hold for the confirmed MVP and its approved tickets. Scheduling will be decided separately; this plan creates no ongoing background execution. Spending and new feature ideas retain their separate approval boundaries.

The lead asks for steering when a choice changes confirmed product scope or a ticket explicitly requires a user decision, such as backend selection, final branding, or the personal enjoyment test. Ask before spending, collecting credentials, or publishing outside authorized scope. Resolve routine code and verification choices autonomously and record development decisions in the applicable AGENTS.md.

## Readiness checks

Before the first implementation issue, confirm start authorization, the latest MVP and decisions, the issue's prerequisites, the clean feature checkout, and available included Codex usage. Confirm that the personal review skill is available and a capable lead can receive the [review handoff](REVIEW.md#review-handoff-queue). After start authorization, an implementation chat without subagents may complete a bounded feature and queue its PR; it cannot certify its own change or merge without independent review. Follow [agent setup](AGENT_SETUP.md) for implementation ownership and verification. Local application receipts are available before CI under [REVIEW_GATES.md](REVIEW_GATES.md); hosted execution remains subject to the zero-cost/spending check.

Build and test commands must come from the executable foundation, not invented placeholders. Verify free CI execution or obtain spending approval before enabling chargeable jobs. Keep the repository private and main protection deferred as accepted; enforce the agent process without claiming a GitHub server lock.

## Implementation sequence after authorization

| Stage | Work | Evidence before proceeding |
| --- | --- | --- |
| Structure | #29: source ownership, game grouping, scoped guidance, source discovery | Concrete layout documented and reviewed; planned paths labeled honestly. |
| Foundation | #1: SwiftUI app, test target, setup and device instructions | Verified simulator build and launch, executable test command, local signing instructions. |
| Verification | #15: reproduce foundation checks in CI when free execution is verified | Actual successful and failing check evidence, safe permissions, known runner/toolchain. Keep this work visible if a cost prerequisite delays it. |
| Shared contract | #2: cards, deck, visibility, explicit start, completion and reset | Deterministic contract checks; published interfaces for feature agents. |
| Features | #3–#8: feed, news, Sudoku, memory, chess, bubble shooter | Separate ownership; rules and adapters verified; tap-to-play and skip reset preserved. Parallel work needs isolated feature checkouts and enough included usage for implementation and reviews. |
| Integration | #9: mixed session and installable personal build | Integrated build/tests, interaction and accessibility evidence, verified installation guide. |
| Personal test | #10: enjoyment and product steering | The user's actual feedback; keep open until the test occurs. |

The shared design baseline and wireframes in #13 follow the MVP and personal test under the accepted [design timing](MVP.md#deferred-work). Use simple, consistent presentation for the initial MVP; design approval is not a prerequisite for its feature work. Logo #14 retains its existing user-choice and implementation prerequisites. Phase-two backend #18 and gamification #19 remain outside MVP implementation. The design task stays open for the user's later choice; this sequence does not select a design tool, branding, or backend provider.

## Repeatable issue loop

1. Read the latest documents and one issue, verify dependencies, and record its Project status. Check included usage before starting an issue or reviewer.
2. Implement the bounded criteria on a feature branch, updating scoped guidance and affected installation instructions when behavior changes.
3. Run proportionate actual verification. Record commands, results, environment, and checks that could not run; never replace evidence with an agent's assertion.
4. Follow the complete fresh-agent review/fix loop in REVIEW.md. Preserve head/base-bound evidence; another review is needed after either changes. The user is not the fallback code reviewer.
5. Merge only after the gates pass. Verify the merge, close only completed issues, update the board, and promote dependents.
6. Leave a short checkpoint with the current issue, branch/commit or PR, completed evidence, unresolved blockers, and next bounded action. Report completion, failures, or required product steering; avoid repetitive unchanged updates.

If review cannot run or validation fails, keep the PR open and continue independent authorized work where useful. If included usage is low or unknown, checkpoint and stop instead. A future run resumes from the checkpoint only when its authorization and allowance are valid.

## Included-usage boundary

Apply the no-credits/no-resets rule and the owner-selected 1% reserve in root AGENTS.md. On October 4, 2026, the owner instructed "lets continue and keep the hold at 1%", superseding the earlier 10% reserve so authorized work can continue with ordinary included usage. Stop when any reported included window has 1% or less remaining, a limit is reached, or the allowance cannot be verified. Check all reported included windows, not just credit availability or a monthly spending allowance. A missing limit is unknown, not unlimited. Leave usage resets untouched and wait for the ordinary allowance renewal; do not switch to API-key billing, another paid provider, or credit-backed execution.

This is an operational guardrail, not a hard billing guarantee. OpenAI documents that available credits can extend usage after included limits, and limits are shared across work. A running turn or another chat can consume allowance between checks. No account billing switch was changed, and the available tools here do not set an account-wide credit-spending prohibition. Before enabling unattended scheduling, verify an account-level configuration that prevents credit fallback. [Official OpenAI pricing and usage guidance](https://learn.chatgpt.com/docs/pricing).

## Documentation audit

The local repository snapshot audited for this preparation is main commit `f71db4cb002991f357d7627422785637516fbb41`. All 17 tracked Markdown files were checked; local file links resolved. The working tree was clean, and there was no app source, target, or workflow to remove. Remote changes made by other chats need a fresh check before this PR merges.

| Finding | Treatment in this preparation |
| --- | --- |
| No explicit app-development hold or scheduling decision in persistent guidance | Added the user-selected hold and no scheduling yet. |
| No included-usage-only or no-reset rule | Added the standing prohibition, preflight check, reserve, and account-control limitation. |
| Research describes human code review as an available part of delivery | Clarified that agents own reviews and the user provides product steering. Product-choice acceptance remains intact. |
| CI research suggests protection where an eligible plan permits it and unrestricted run cancellation | Aligned with deferred protection and orchestrator gates; restricted cancellation to PR verification and preserved main release jobs. |
| Feed verification research omits the newly accepted start gate | Added preview, explicit start, and skip back to preview checks. |

Preserved the accepted ADRs, competitor/backend research snapshots, logo proposal, and templates. Their dates, proposal labels, and no-app-yet statements are useful and remain accurate for this snapshot. No files were deleted. App builds and gameplay tests remain unavailable until the foundation is implemented.
