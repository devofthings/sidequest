# Local daily streak #217

The owner approved implementation on October 6, 2026, selecting current local calendar days and **physical swipes only**. A successful game solve also qualifies. The first qualifying day counts 1; qualifying activity the following day increments by 1; a missed calendar day breaks the run and the next qualifying day starts at 1. Opening, menu navigation, canceled gestures, in-card scrolling, automatic advancement, losses, and quietly revisiting completed games do not qualify. This daily measure is separate from consecutive game wins and has no account, cloud, notification, or grace mechanism.

| Question | Kind | Selected answer and evidence | Verification |
| --- | --- | --- | --- |
| Calendar and equivalent accessible navigation? | Human | Owner selected local days and only physical swipes; menu Previous/Next does not qualify. | Calendar and navigation-origin units; focused running-app gesture/menu test. |
| Which event owns a physical swipe? | Fact/technical | Native pager records its physical drag, then passes explicit origin to FeedController only after settled adjacent selection; rejected reconstruction and unchanged selection emit nothing. | Canceled/successful native paging and failed-window unit check. |
| Which event owns a solve? | Fact/technical | GameRuntime accepts current visible success, after synchronous stop effects; a separate once-installed observer leaves the single effect owner intact. | Success/loss/stale/duplicate/restoration units and real Sudoku solve. |
| Persistence and clock changes? | Technical | Validated local UserDefaults JSON record, injected clock/calendar, Gregorian local-day labels. Preserve latest credited day on clock rollback; earlier/equal labels never increment. Missing/unreadable storage is distinguished and unreadable bytes stay intact. | Reopen, gap, DST, leap/year boundary, backward clock and corrupt/save-error units. |
| Display and rollover? | Technical | Noninteractive semantic flame/count; neutral chrome with tiny orange active flame. Reserve four count glyphs and show999+ after 999; speech retains the exact count. Yesterday/today stays active; a missed day shows 0. Foreground and cancellable midnight/60-second recheck do not qualify. | Native header stability/large text/relaunch and injected-clock expiry tests. |

The model is app-retained across feed/import replacement. App composition binds every newly reconstructed runtime, preserving completed history and game attempt ownership. Production preference key is `sidequest.dailyStreak.v1`; Debug `-sidequest-streak-fixtures` selects its own suite and `-sidequest-streak-reset` clears only that fixture key. Historical deterministic feed fixtures remain real input paths. No test loads live news.

Storage failures leave gameplay usable. The indicator's accessible value identifies temporary state; the existing More options menu provides its explanation. UserDefaults uses normal OS-managed persistence. Neither returning a saved value nor simulator tests proves cloud/device durability.

[PR #223](https://github.com/devofthings/sidequest/pull/223) records the actual native/build/CI results and independent review for its verified source commit. Release publication and physical-iPhone acceptance remain separate from that evidence.
