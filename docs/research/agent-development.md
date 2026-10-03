# Agent delivery and verification research

Researched October 3, 2026 for [issue #12](https://github.com/devofthings/sidequest/issues/12).

**Status: The delivery loop and testing policy are accepted; remaining tooling recommendations are proposed.** The user wants agents to implement the app, with fresh-agent review and gated automatic merging. Product choices and personal testing remain user decisions. [REVIEW.md](../REVIEW.md) owns the accepted process. CI belongs in the backlog; a server backend is outside the current MVP. On October 3, 2026, the user requested unit and end-to-end tests and declined TDD; [AGENTS.md](../../AGENTS.md#verification) owns the testing rule.

**Accepted architectural direction:** The user chose hexagonal architecture to make future behavior changes easier. This workflow must respect the project’s architecture decision; the detailed module boundaries below are a practical application of that choice.

## Recommendation

Use the accepted issue-to-PR loop: an implementation agent owns one bounded change, a fresh agent uses the personal review skill, all findings are addressed, and another fresh agent reviews the resulting diff. Repeat until no findings remain and verification passes, then merge under the user's standing authorization. Choose checks that could catch a meaningful failure: a build, a focused behavior test, simulator interaction, or visual evidence. Start with GitHub Issues, the existing Project, repository docs, Xcode, and GitHub Actions; add tools only when they solve an observed problem.

These are Sidequest recommendations informed by current first-party guidance, rather than a universal set of “2026 best practices.” Fully agent-implemented development still requires explicit product choices and review; no source establishes infallible autonomous delivery.

Keep Swift game rules and feed logic in a pure core. Introduce stable ports at external or replaceable boundaries, with SwiftUI presentation and local news loading as adapters, wired through a composition root. Test important core behavior directly; test adapter boundaries where integration can fail. Avoid an interface for every type, mandatory separate packages, or a server. An issue that changes a shared port should identify the affected adapters so parallel agents do not work against different contracts.

## What official sources establish

- Codex loads repository instructions from AGENTS.md and supports directory-specific guidance. Keep the root instructions short and link durable scope and decisions instead of copying them into every task. The documentation also recommends concise review rules and leaving mechanical formatting checks to CI. [OpenAI: AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- Git worktrees provide separate checkouts for independent parallel chats. They isolate file edits, but shared integration points still need coordination. [OpenAI: worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees).
- OpenAI’s long-running development experiment used a durable spec, small milestones with acceptance criteria, and repeated verification and repair. The article describes an experiment, not proof that this process guarantees production correctness. Sidequest already has the necessary scope, decisions, issues, and status documents; another parallel planning system would duplicate them. [OpenAI: long-horizon tasks](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex).
- Codex can review GitHub PR diffs using repository guidance. Review rules supplement tests and required approvals. Hosted PR review needs a connected repository and enabled review settings; availability for this repository has not been verified. A separate local review agent is a practical starting point. [OpenAI: GitHub review](https://learn.chatgpt.com/docs/third-party/github).
- Apple recommends Swift Testing for Swift unit tests and XCTest with XCUIAutomation for UI tests. Swift Testing supports parameterized inputs and Swift concurrency. Framework capabilities do not prescribe when tests must be written. [Apple: testing and performance](https://developer.apple.com/documentation/technologyoverviews/testing-and-performance), [Apple: Swift Testing](https://developer.apple.com/documentation/testing).
- GitHub provides hosted macOS runners for private repositories; their use consumes the account’s available minutes and can incur charges afterward. A moving `-latest` label need not match the developer’s newest macOS/Xcode setup. [GitHub: hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Accepted issue-to-PR loop

The user subsequently accepted feature branches only and the fresh-agent review, fix, repeat, and automatic merge loop. Follow [REVIEW.md](../REVIEW.md) for the authoritative steps, commit-bound gates, reviewer skill, and GitHub plan limitations. Agents own code review; the user steers product direction through documents. Provider selection, final product decisions, and the personal enjoyment test retain their issue-specific user acceptance criteria. The current implementation hold and included-usage-only guardrails are recorded in [AGENTS.md](../../AGENTS.md) and the [autonomous plan](../AUTONOMY.md).

A separate reviewer has a different task context, not guaranteed independent reasoning. Both agents may share incorrect assumptions. Tests derived from the same mistaken specification can pass together. Known fixtures, negative cases, simulator evidence, and human judgment remain necessary. Do not equate an agent “looks good” message with a passing build or validated acceptance criteria.

## Risk-based verification

Choose verification from the behavior at risk, rather than enforcing the same process on every issue. Rules and lifecycle transitions often benefit from repeatable automated checks. Gestures, animations, readability, and enjoyment require simulator or device observation. Low-impact documentation and visual changes need proportionate review, not a new test suite. The following are useful checks, not a requirement to write them before implementation or build every case immediately.

| Area | Useful repeatable checks | Simulator/device evidence |
| --- | --- | --- |
| Sudoku | Fixed puzzles: row/column/box conflicts, immutable clues, completion, reset. | Number entry, selection, feedback, completion flow. |
| Memory | Match/mismatch and repeated taps; reset during a delay; advance controlled time and confirm stale work cannot mutate the new attempt. | Timing, card transitions, fast swipes during a mismatch. |
| Chess puzzles | Independently validated fixture answers, wrong moves, reset; relevant legality cases if implementing move validation. Fixture checks do not establish a complete engine’s correctness. | Piece movement and answer feedback. |
| Bubble shooter | Fixed boards: collision/attachment boundaries, connected groups, reset, win/loss; check exact rules only after agreed. | Aim, wall behavior, touch precision, animation, playability. |
| Feed lifecycle | Seeded shuffle, preview before explicit tap-to-play, start tap does not make a move, committed skip resets an unfinished attempt to preview, stale callbacks, rapid transitions. Record unresolved completed-game behavior before treating it as a requirement. | Manual swiping, accessible start action, game gestures versus navigation, news/game transitions. |
| News imports | Valid/malformed snapshots and preserved attribution/link/time. | Readability and opening the attributed link. |
| Visual design | Stable interaction outcomes where worthwhile; avoid assertions for every layout constant or internal view hierarchy. | Screenshots, accessibility, simulator interaction, user design review. |

Meaningful tests assert domain outcomes through small public interfaces and survive internal refactoring. A test that repeats the algorithm, checks private member values, or mocks every internal call can confirm the code’s own assumptions without protecting behavior. Prefer fixtures with independently known answers, boundary cases, and regression examples. Coverage is a diagnostic; a blanket percentage target is not proposed.

The user superseded the earlier optional-TDD recommendation: implement behavior first, then add or update unit tests and end-to-end coverage for critical integrated flows. Use deterministic fixtures and run end-to-end tests through the app's public interactions, including news actions, tap-to-play, game interaction, and skip/reset as those flows become available. Applicable tests must pass before merging. Documentation and visual-only changes still receive proportionate verification.

## CI requirements to implement after the foundation

CI remains planned: there is currently no app target or verified build/test command. Issue #1 must establish a shared scheme, test targets, toolchain requirements, and runnable local verification in README.md before the CI issue can reproduce them.

Propose GitHub Actions on a hosted macOS runner with an explicitly selected installed Xcode version and compatible simulator runtime. Log their actual versions, resolve reproducible dependencies, build the simulator target, run rule/lifecycle tests, and then run a small UI smoke path once the integrated feed exists. Preserve build/test logs and `.xcresult` evidence, including failures. Use timeouts and cancel obsolete PR verification runs. Preserve every main verification and release job under [RELEASES.md](../RELEASES.md). Introduce the minimum checks needed for the current code rather than adding several formatters, security services, and orchestration layers preemptively.

Use ordinary PR checks with minimal token permissions and no signing/distribution credentials. Pin third-party actions to reviewed full commit SHAs. These follow GitHub’s documented token and action security guidance. [GitHub: secure use](https://docs.github.com/en/actions/reference/security/secure-use).

Require successful applicable build/test checks before the orchestrator merges, following [REVIEW.md](../REVIEW.md). The user chose to defer server-enforced main protection and a plan upgrade. Report actual check results against the latest revision; do not claim GitHub enforcement. The CI job must run its intended validation rather than treating a skipped check as a successful build.

Simulator CI does not establish device performance, signing, iPhone deployment, or subjective enjoyment. Test on the user’s iPhone separately through Xcode as agreed. CI should not merge, publish, buy services, or change accepted product scope automatically.

## Proposed practices to record

- Proportionate verification for each issue: repeatable checks for important behavior, simulator evidence for interactions, and device testing for the personal MVP.
- Unit and end-to-end coverage is accepted. Swift Testing for unit tests and XCTest/XCUIAutomation for end-to-end app flows remain proposed framework choices for the foundation to establish.
- One implementation agent per scoped issue; fresh-agent review and repeated fixes under the accepted [review loop](../REVIEW.md); automatic merging after its gates pass.
- GitHub Actions simulator build/test checks after issue #1, with plan/cost/toolchain compatibility verified during CI setup.

The accepted delivery loop and testing decision are recorded in DECISIONS.md, AGENTS.md, and REVIEW.md. Remaining tooling recommendations can be adopted as the foundation and CI issues establish executable verification. The no-TDD decision does not remove the unit or end-to-end test requirements. This research does not select a chess engine or package split, establish CI, or authorize distribution.
