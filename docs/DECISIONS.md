# Project decisions

Record lightweight choices here. Use an ADR for consequential architectural or scope tradeoffs. GitHub Issues track the work needed to implement them.

| Decision | Status | Basis |
| --- | --- | --- |
| Sidequest as the working project name | Accepted | User choice; public naming availability remains unresolved. |
| Private GitHub repository | Accepted | User requested a private repository. |
| iPhone MVP before other platforms | Accepted | User chose iOS first; see [ADR 0001](adr/0001-private-ios-mvp.md). |
| News and games in the same feed | Accepted | User identified the news habit as central to the idea. |
| GitHub Issues for tasks, Markdown for agent guidance and decisions | Accepted | User requested issues and agent Markdown files. |
| Development decisions carried in scoped AGENTS.md files | Accepted | User requires agent guidance for decisions made by either the user or agents. See the [recording and ownership rule](../AGENTS.md#development-decisions-and-scoped-guidance). Source layout is pending issue #29. |
| Private GitHub Project for workflow status | Accepted | User approved Ideas, Backlog, Ready, In progress, Review, and Done; Ideas was added at the user's request on October 3, 2026. See [task workflow](WORKFLOW.md). |
| Agent-created bug tickets; user agreement before feature ideas | Accepted | User authorized bug-fix tickets on October 3, 2026 and requires new features to stay in Ideas until explicitly agreed. Follow [ticket authorization](WORKFLOW.md#ticket-authorization); previously approved scope remains accepted. |
| Native SwiftUI implementation | Accepted | User choice; see [ADR 0002](adr/0002-native-swiftui.md). |
| Hexagonal architecture from the start | Accepted | User chose replaceable boundaries to accommodate change; see [ADR 0003](adr/0003-hexagonal-architecture.md). |
| Agent-led delivery with fresh-agent review and gated automatic merging | Accepted | User delegates technical delivery and code review to agents and steers product direction through documents. Follow [REVIEW.md](REVIEW.md) and the prepared [autonomous plan](AUTONOMY.md). |
| App development on hold; scheduling undecided | Accepted | User requested preparation and a stale-file audit before development. Explicit start authorization is required; see [AGENTS.md](../AGENTS.md#autonomous-delivery-and-current-hold). |
| Included Codex usage only; no credits or resets | Accepted | User prohibits credit spending and agent redemption of resets. Follow the [usage guardrail](../AGENTS.md#spending-approval), including its reserve and account-control limitation. |
| Durable PR handoff when the author cannot dispatch reviewers | Accepted workflow | Lead implementation choice addressing the user's stranded-review concern on October 3, 2026. Use the [review queue](REVIEW.md#review-handoff-queue); active leads check it before new work. No recurring monitoring was enabled. |
| Check chat steering after every resolved ticket | Accepted | User requested a checkpoint before continuing to another task. Follow the [after-ticket chat checkpoint](../AGENTS.md#after-ticket-chat-checkpoint). |
| Assigned issues for unanswered user requests | Accepted | User wants missed chat requests tracked for approval or refusal. Follow the [decision-request workflow](WORKFLOW.md#unanswered-decision-requests); record outcomes and update scoped agent guidance. |
| Feature branches only; defer GitHub main protection | Accepted | User chose to proceed without a plan upgrade or branch protection. Use the review and verification gates with agent-controlled merging in [REVIEW.md](REVIEW.md); see issue #23. |
| Explicit user approval before spending | Accepted | User requires approval before any purchase or action that may incur charges; see the spending approval rule in [AGENTS.md](../AGENTS.md). |
| TDD as an optional technique | Accepted | User has not chosen TDD and asked to keep it a minor consideration, rather than a project requirement. |
| CI in the backlog; no server backend for now | Accepted | User clarified the request as CI planning; see issue #15. |
| Phase-two backend for accounts and synced preferences | Accepted direction | User requested a backend once users join; Firebase and alternatives will be compared in issue #18. Provider selection remains open. |
| Gamification as an important product direction | Accepted direction | User emphasized gamification. Specific mechanics and scoring rules remain open. |
| High scores and leaderboards in phase two | Accepted | User confirmed delivery alongside accounts; the private first MVP remains unchanged. |
| English news for the first test | Accepted | User choice; documentation is also written in US English. |
| Validate enjoyment of the mixed feed first | Accepted | User chose enjoyment and willingness to reopen as the initial hypothesis. |
| Sudoku, memory, chess puzzles, and a bubble shooter | Accepted | User selected four game types and clarified the ball game as a bubble shooter. |
| Manually imported news snapshots | Accepted | User chose real snapshot content before automatic refreshing. |
| Shuffle news and games; reset skipped unfinished games | Accepted | User chose shuffled cards and fresh attempts. |
| Tap to play before starting each game | Accepted | User requested an explicit tap to start. Game cards show a preview until tapped; gameplay stays inside the card. See [MVP.md](MVP.md) for the start and skip behavior. |
| Simulator and the user's own iPhone via Xcode | Accepted | User choice; TestFlight is deferred. |
| Installation and run documentation kept current | Accepted | User requested setup guidance. [INSTALL.md](INSTALL.md) records the workflow; executable commands depend on the app foundation. |
| Private Release builds after each merged update | Accepted direction | User requested GitHub release history. Follow [RELEASES.md](RELEASES.md); automation depends on the app, CI, and verified free execution or explicit spending approval in issue #31. |
| Defer accounts, ads, payments, licensed catalogs, and social integrations | Accepted | User confirmed the bounded private prototype scope. |

## Research context

Publisher APIs, news licensing, and game catalogs were discussed as possible inputs, not selected dependencies. Previous price examples are research snapshots and should be rechecked before purchase or integration.

- [The Guardian access options](https://open-platform.theguardian.com/access/)
- [GNews pricing](https://gnews.io/) and [terms](https://gnews.io/legal/terms-of-service)
- [dpa WebLines](https://www.dpa.com/de/inhalte-websites-apps)
- [Famobi game licensing](https://famobi.com/famobi-publishing-service/?locale=en)
- [TikTok Display API](https://developers.tiktok.com/docs/en/display-api-overview)
