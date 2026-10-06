# Private Tagesschau test #213

The owner selected real Tagesschau news and images for personal testing. This supersedes the normal fictional-news fallback, while historical deterministic fixtures remain unchanged. The official source is https://www.tagesschau.de/infoservices/alle-meldungen-100~rss2.xml. RSS metadata provides headlines, excerpts, dates, original links, images and image credits; no article scraping is used.

## Readiness decisions

Readiness interview: lead with `/root/tagesschau_readiness`, October 6. Implementation and verification remain separate from readiness.

| Question | Kind | Selected answer and evidence | Planned verification |
| --- | --- | --- | --- |
| Feed/images | Fact | Official RSS inspected successfully; images are in content:encoded, including description/agency credit. | Original offline RSS parser fixtures; live metadata sanity check. |
| Cache and rights | Technical choice | Bounded memory-only latest feed and ephemeral image requests. Official [RSS guidance](https://www.tagesschau.de/infoservices/rssfeeds) permits private noncommercial use; [older embedding terms](https://www.tagesschau.de/rssfeed-ts-104.html) exclude archives. No content bundled, archived or published. | Failure retains last valid feed, no persistent writes/cache. |
| Startup and refresh | Technical choice | Start games independently; fetch on initial ready/active state and each foreground reactivation, deduplicate active requests and reject stale results. | Suspended request, failure, cancellation and activation tests. |
| Game preservation | Source-backed choice | News-only synchronous update in the same FeedComposition; never use manual replacement for RSS. | Stable selection/order/runtime/attempt and completion history checks. |
| Initial cadence | Technical choice | While RSS is unavailable show games only. Apply stories at future generated five-game boundaries; an initial eight-game batch can mean first news at game 10. No retroactive insertion/reset. | Empty-pool cadence then refresh test. |
| Manual imports | Technical choice | Preserve saved private bytes. Explicit successful import selects manual source for this session and invalidates live requests; next cold launch uses Tagesschau. | Import/late-response race. |
| Untrusted inputs | Technical choice | Bound streaming bytes/fields/items; reject entities/DTD, validate HTTPS hosts and redirects. Images fail independently without removing readable text. | Offline malformed/unsafe/oversized input tests. |

## Personal test

Build and run using [installation instructions](INSTALL.md). With internet access, scroll through games to a news card. Source links open the original story. Reopening refreshes available stories; games and their history remain in place. Without internet at a fresh launch, only games appear. Once fetched, the latest valid stories remain available in memory if a later refresh fails. Force-quitting discards this cache. Image failures keep the article text usable.

Explicit Files imports remain available under More options → News snapshots, and become the source until the app is restarted. No saved private files are deleted or overwritten by RSS. German content is limited to this selected test. Public pitch, TestFlight, App Store and commercial reuse need separate rights decisions.

## Verification

Implementation verification pending; readiness is not delivery evidence.
