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

The actual bounded transport/parser read 40 valid RSS articles with 40 image metadata entries on October 6, without storing article captures. Initial integration unit verification passed all 219 cases. The first native build caught a missing `try` in a test fixture; focused image/foreground tests subsequently exposed the cold-launch captured-scene-phase race. Both were corrected. Independent review also identified request cleanup during a failed leased import; cleanup now runs on every matching-request exit with a controlled regression test. Final focused verification passed all 220 unit tests and both native news flows (222 cases, zero failures/skips). The Debug test build took 32.9 seconds and test execution 70.3 seconds using one owned simulator, subsequently shut down and deleted. The UI flows verify original image rendering/credits/source link, foreground refresh without moving the selected card, and readable cached text after refresh/image failure. Exact-head CI and fresh independent review must pass before merging; their evidence is recorded on [PR #220](https://github.com/devofthings/sidequest/pull/220). Physical-device news/image execution remains for the owner’s next personal test.

Repeatable tests inject original RSS/image data and suspended transports. Debug test-host detection makes the live source unavailable without substituting fictional production news; deterministic fixture arguments explicitly select their own source. Network errors appear in News snapshots rather than changing the gameplay viewport.
