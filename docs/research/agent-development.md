# Agent delivery and verification research

Researched October 3, 2026 for [issue #12](https://github.com/devofthings/sidequest/issues/12).

**Status: Proposed delivery practices, pending user review.** This note does not change AGENTS.md or accepted product scope. The user wants agents to implement the app while they review code and make product decisions. CI belongs in the backlog; a server backend is outside the current MVP. The user has not selected a test-driven development policy.

**Accepted architectural direction:** The user chose hexagonal architecture to make future behavior changes easier. This workflow must respect the project’s architecture decision; the detailed module boundaries below are a practical application of that choice.

## Recommendation

Use a small issue-to-PR loop: an implementation agent owns one bounded change, a separate agent reviews the diff against the issue, risk-based verification provides evidence, and the user reviews the result. Choose checks that could catch a meaningful failure: a build, a focused behavior test, simulator interaction, or visual evidence. Start with GitHub Issues, the existing Project, repository docs, Xcode, and GitHub Actions; add tools only when they solve an observed problem.

These are Sidequest recommendations informed by current first-party guidance, rather than a universal set of “2026 best practices.” Fully agent-implemented development still requires explicit product choices and review; no source establishes infallible autonomous delivery.

Keep Swift game rules and feed logic in a pure core. Introduce stable ports at external or replaceable boundaries, with SwiftUI presentation and local news loading as adapters, wired through a composition root. Test important core behavior directly; test adapter boundaries where integration can fail. Avoid an interface for every type, mandatory separate packages, or a server. An issue that changes a shared port should identify the affected adapters so parallel agents do not work against different contracts.

## What official sources establish

- Codex loads repository instructions from AGENTS.md and supports directory-specific guidance. Keep the root instructions short and link durable scope and decisions instead of copying them into every task. The documentation also recommends concise review rules and leaving mechanical formatting checks to CI. [OpenAI: AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- Git worktrees provide separate checkouts for independent parallel chats. They isolate file edits, but shared integration points still need coordination. [OpenAI: worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees).
- OpenAI’s long-running development experiment used a durable spec, small milestones with acceptance criteria, and repeated verification and repair. The article describes an experiment, not proof that this process guarantees production correctness. Sidequest already has the necessary scope, decisions, issues, and status documents; another parallel planning system would duplicate them. [OpenAI: long-horizon tasks](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex).
- Codex can review GitHub PR diffs using repository guidance. Review rules supplement tests and required approvals. Hosted PR review needs a connected repository and enabled review settings; availability for this repository has not been verified. A separate local review agent is a practical starting point. [OpenAI: GitHub review](https://learn.chatgpt.com/docs/third-party/github).
- Apple recommends Swift Testing for Swift unit tests and XCTest with XCUIAutomation for UI tests. Swift Testing supports parameterized inputs and Swift concurrency. Framework capabilities do not prescribe when tests must be written. [Apple: testing and performance](https://developer.apple.com/documentation/technologyoverviews/testing-and-performance), [Apple: Swift Testing](https://developer.apple.com/documentation/testing).
- GitHub provides hosted macOS runners for private repositories; their use consumes the account’s available minutes and can incur charges afterward. A moving `-latest` label need not match the developer’s newest macOS/Xcode setup. [GitHub: hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Proposed issue-to-PR loop

1. **Select a Ready issue.** Read its dependencies, acceptance criteria, applicable instructions, and confirmed MVP scope. Resolve prerequisite work before starting. If the issue cannot produce an independently reviewable result, split it and link the prerequisites.
2. **Prepare a bounded implementation.** Set In progress and use `codex/<issue-number>-<short-description>`. For parallel edits, give each implementation agent a separate worktree. Agree on the shared card/lifecycle contract before parallel game work. Avoid concurrent edits to the Xcode project file; an integration agent can coordinate target membership after modules exist.
3. **Implement and verify.** Identify likely failures and choose proportionate checks. Add behavior tests where they protect rules, boundaries, or regressions; write them before or after implementation as useful. Run the repository’s verified commands, repair failures, and exercise changed interactions in the simulator. Use deterministic news fixtures, puzzle inputs, random seeds, and controllable time for repeatable checks. Do not retrieve live news during tests.
4. **Create a reviewable PR.** Explain resulting behavior, link the issue, include `Closes #N` when complete, and record commands, outcomes, toolchain/destination, relevant screenshots, and material limitations. Mark unchecked acceptance criteria honestly. Move to Review only when evidence and a reviewable result exist.
5. **Request a separate review pass.** Give a reviewer agent the issue, docs, base revision, and diff. Ask it to check specification compliance, boundary cases, lifecycle/cancellation, and whether tests could miss the same mistake as the implementation. Review findings need evidence and severity. The implementer addresses findings; rerun affected checks after changes.
6. **User reviews and accepts.** The user reviews code and product behavior without writing implementation code. Merging remains a user action or separately authorized action. After merge or explicit acceptance, close completed issues, set Done, and promote dependents whose prerequisites are complete.

A separate reviewer has a different task context, not guaranteed independent reasoning. Both agents may share incorrect assumptions. Tests derived from the same mistaken specification can pass together. Known fixtures, negative cases, simulator evidence, and human judgment remain necessary. Do not equate an agent “looks good” message with a passing build or validated acceptance criteria.

## Risk-based verification

Choose verification from the behavior at risk, rather than enforcing the same process on every issue. Rules and lifecycle transitions often benefit from repeatable automated checks. Gestures, animations, readability, and enjoyment require simulator or device observation. Low-impact documentation and visual changes need proportionate review, not a new test suite. The following are useful checks, not a requirement to write them before implementation or build every case immediately.

| Area | Useful repeatable checks | Simulator/device evidence |
| --- | --- | --- |
| Sudoku | Fixed puzzles: row/column/box conflicts, immutable clues, completion, reset. | Number entry, selection, feedback, completion flow. |
| Memory | Match/mismatch and repeated taps; reset during a delay; advance controlled time and confirm stale work cannot mutate the new attempt. | Timing, card transitions, fast swipes during a mismatch. |
| Chess puzzles | Independently validated fixture answers, wrong moves, reset; relevant legality cases if implementing move validation. Fixture checks do not establish a complete engine’s correctness. | Piece movement and answer feedback. |
| Bubble shooter | Fixed boards: collision/attachment boundaries, connected groups, reset, win/loss; check exact rules only after agreed. | Aim, wall behavior, touch precision, animation, playability. |
| Feed lifecycle | Seeded shuffle, committed skip resets the unfinished attempt, fresh return, stale callbacks, rapid transitions. Record unresolved completed-game behavior before treating it as a requirement. | Manual swiping, game gestures versus navigation, news/game transitions. |
| News imports | Valid/malformed snapshots and preserved attribution/link/time. | Readability and opening the attributed link. |
| Visual design | Stable interaction outcomes where worthwhile; avoid assertions for every layout constant or internal view hierarchy. | Screenshots, accessibility, simulator interaction, user design review. |

Meaningful tests assert domain outcomes through small public interfaces and survive internal refactoring. A test that repeats the algorithm, checks private member values, or mocks every internal call can confirm the code’s own assumptions without protecting behavior. Prefer fixtures with independently known answers, boundary cases, and regression examples. Coverage is a diagnostic; a blanket percentage target is not proposed.

TDD is an optional technique: a failing example can clarify an ambiguous rule or reproduce a bug before a fix. Use it when it improves a particular task; there is no recommendation to mandate test-first implementation or require a separate TDD decision before development starts.

## CI requirements to implement after the foundation

CI remains planned: there is currently no app target or verified build/test command. Issue #1 must establish a shared scheme, test targets, toolchain requirements, and runnable local verification in README.md before the CI issue can reproduce them.

Propose GitHub Actions on a hosted macOS runner with an explicitly selected installed Xcode version and compatible simulator runtime. Log their actual versions, resolve reproducible dependencies, build the simulator target, run rule/lifecycle tests, and then run a small UI smoke path once the integrated feed exists. Preserve build/test logs and `.xcresult` evidence, including failures. Use timeouts and cancel obsolete runs. Introduce the minimum checks needed for the current code rather than adding several formatters, security services, and orchestration layers preemptively.

Use ordinary PR checks with minimal token permissions and no signing/distribution credentials. Pin third-party actions to reviewed full commit SHAs. These follow GitHub’s documented token and action security guidance. [GitHub: secure use](https://docs.github.com/en/actions/reference/security/secure-use).

Require the successful build/test check before merge where the repository’s plan supports enforcement. Private-repository branch protection requires an eligible paid GitHub plan; verify access before claiming the gate is enforced. Required checks need appropriate configuration for the latest revision, and skipped/neutral checks can satisfy protection, so the workflow itself must actually run its intended validation. [GitHub: protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [GitHub: required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).

Simulator CI does not establish device performance, signing, iPhone deployment, or subjective enjoyment. Test on the user’s iPhone separately through Xcode as agreed. CI should not merge, publish, buy services, or change accepted product scope automatically.

## Proposed practices to record

- Proportionate verification for each issue: repeatable checks for important behavior, simulator evidence for interactions, and device testing for the personal MVP.
- When automated tests add value, use Swift Testing for Swift unit tests and XCTest/XCUIAutomation for a small integration smoke suite.
- One implementation agent per scoped issue; separate review pass for substantive implementation changes; human acceptance before merge.
- GitHub Actions simulator build/test checks after issue #1, with plan/cost/toolchain compatibility verified during CI setup.

If accepted, record the delivery practices in DECISIONS.md and update the existing workflow/instructions once. Development does not depend on choosing a TDD policy. This research does not select a chess engine or package split, establish CI, or authorize automatic merging or distribution.
