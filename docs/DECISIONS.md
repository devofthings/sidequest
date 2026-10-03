# Project decisions

Record lightweight choices here. Use an ADR for consequential architectural or scope tradeoffs. GitHub Issues track the work needed to implement them.

| Decision | Status | Basis |
| --- | --- | --- |
| Sidequest as the working project name | Accepted | User choice; public naming availability remains unresolved. |
| Private GitHub repository | Accepted | User requested a private repository. |
| iPhone MVP before other platforms | Accepted | User chose iOS first; see [ADR 0001](adr/0001-private-ios-mvp.md). |
| News and games in the same feed | Accepted | User identified the news habit as central to the idea. |
| GitHub Issues for tasks, Markdown for agent guidance and decisions | Accepted | User requested issues and agent Markdown files. |
| Native SwiftUI implementation | Accepted | User choice; see [ADR 0002](adr/0002-native-swiftui.md). |
| English news for the first test | Accepted | User choice; documentation is also written in US English. |
| Validate enjoyment of the mixed feed first | Accepted | User chose enjoyment and willingness to reopen as the initial hypothesis. |
| Initial game selection, news acquisition, session behavior, testing route | Open | To be resolved in the planning interview. |

## Research context

Publisher APIs, news licensing, and game catalogs were discussed as possible inputs, not selected dependencies. Previous price examples are research snapshots and should be rechecked before purchase or integration.

- [The Guardian access options](https://open-platform.theguardian.com/access/)
- [GNews pricing](https://gnews.io/) and [terms](https://gnews.io/legal/terms-of-service)
- [dpa WebLines](https://www.dpa.com/de/inhalte-websites-apps)
- [Famobi game licensing](https://famobi.com/famobi-publishing-service/?locale=en)
- [TikTok Display API](https://developers.tiktok.com/docs/en/display-api-overview)
