# Project decisions

Record lightweight choices here. Use an ADR for consequential architectural or scope tradeoffs. GitHub Issues track the work needed to implement them.

| Decision | Status | Basis |
| --- | --- | --- |
| Sidequest as the working project name | Accepted | User choice; public naming availability remains unresolved. |
| Private GitHub repository | Accepted | User requested a private repository. |
| iPhone MVP before other platforms | Accepted | User chose iOS first; see [ADR 0001](adr/0001-private-ios-mvp.md). |
| News and games in the same feed | Accepted | User identified the news habit as central to the idea. |
| GitHub Issues for tasks, Markdown for agent guidance and decisions | Accepted | User requested issues and agent Markdown files. |
| Private GitHub Project for workflow status | Accepted | User approved Backlog, Ready, In progress, Review, and Done; see [task workflow](WORKFLOW.md). |
| Native SwiftUI implementation | Accepted | User choice; see [ADR 0002](adr/0002-native-swiftui.md). |
| Hexagonal architecture from the start | Accepted | User chose replaceable boundaries to accommodate change; see [ADR 0003](adr/0003-hexagonal-architecture.md). |
| Agent implementation with fresh-agent review and gated automatic merging | Accepted | User authorized the loop in [REVIEW.md](REVIEW.md); developer review remains available without blocking verified implementation PRs. |
| Feature branches only; protect private main | Accepted | User requires PR integration. GitHub protection setup and its plan prerequisite are tracked in issue #23. |
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
| Simulator and the user's own iPhone via Xcode | Accepted | User choice; TestFlight is deferred. |
| Defer accounts, ads, payments, licensed catalogs, and social integrations | Accepted | User confirmed the bounded private prototype scope. |

## Research context

Publisher APIs, news licensing, and game catalogs were discussed as possible inputs, not selected dependencies. Previous price examples are research snapshots and should be rechecked before purchase or integration.

- [The Guardian access options](https://open-platform.theguardian.com/access/)
- [GNews pricing](https://gnews.io/) and [terms](https://gnews.io/legal/terms-of-service)
- [dpa WebLines](https://www.dpa.com/de/inhalte-websites-apps)
- [Famobi game licensing](https://famobi.com/famobi-publishing-service/?locale=en)
- [TikTok Display API](https://developers.tiktok.com/docs/en/display-api-overview)
