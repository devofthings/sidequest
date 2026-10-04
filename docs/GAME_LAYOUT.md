# Stable game layout

Approved bug [#108](https://github.com/devofthings/sidequest/issues/108) corrects movement caused by changing text inside the existing four games. It does not implement the deferred visual redesign or new previews.

## Presentation boundary

Playable game cards anchor at the top of the existing full-card host. Previews retain their existing centered layout and explicit **Tap to play**. News, pager geometry, game rules, attempt lifecycle, and five-game/news cadence remain unchanged.

`StableGameRegion` reserves the natural size of the supported text alternatives at the current width, font, and Dynamic Type setting. Reservations are invisible, inaccessible, and noninteractive. Actual messages remain fully readable; no fixed text height, line limit, or shrinking text hides feedback. When changing message copy or styling, update the corresponding reservation. The existing card scroller owns overflow on smaller viewports and at larger text sizes.

Sudoku reserves its instruction/conflict/completion status; Memory reserves mismatch/completion feedback and each tile’s natural symbol footprint across the question mark and six symbols; symbol changes at accessibility text sizes cannot resize rows. Chess reserves selection and feedback/completion text and retains disabled piece/coordinate controls after checkmate. Bubble reserves feedback, next-color, angle, and primary-button text; its completed result replaces aiming content without changing that content's footprint, and Replay occupies Fire's position. Completed aiming content is hidden from accessibility and cannot accept input. Bubble numeric feedback uses monospaced digits and its bounded slot count to reserve all possible count widths.

## Agent-grill self-assessment

| Question | Kind | Answer | Evidence and rationale | Verification needed |
| --- | --- | --- | --- | --- |
| Is actual game movement caused by state/text changes? | Fact | Old-source native probes measured Memory mismatch −16 pt, Bubble win +37 pt, and Chess checkmate +84.17 pt. Normal Sudoku conflict and the first committed Bubble feedback did not move in that viewport. | Xcode 27.0/iOS 27.0 probes against source `f3dc1620b675a0d0e90119855a55f8326609d8eb`; logs and bundles remain outside Git. A selected Chess square's enlarged outline was excluded as an AX measurement artifact; an incorrect Sudoku solution did not establish completion evidence. | Repeat the minimized actual triggers after correction and verify the actual correct Sudoku completion. |
| Where should the correction live? | Delegated technical choice | Top-anchor playable feed content and introduce one small measured game-region view under `Games/Presentation`. | The host constrains intrinsic content to at least viewport height; centered stacks move when their intrinsic height changes. Game-owned text/control regions must also retain extent when content overflows, to avoid scroll-offset clamping. Rules and lifecycle need no change. | Actual board/control frames, current-card identity, and scroller-offset observations before/after text-changing actions. |
| How should completion preserve controls and feedback? | Delegated technical choice | Retain disabled Chess alternatives and reserve Bubble aiming/Fire-to-Replay geometry; fully render completion messages in measured regions. | Removing whole control groups changes the host's extent. Hidden reservations must not appear in accessibility or accept input. | Running-app completion/replay/revisit, disabled-input checks, and all four games at larger text; physical-device execution remains unverified. |

## Personal iPhone review

Use the source branch linked in the Review PR and the [free Personal Team installation guide](INSTALL.md#install-on-your-own-iphone). On one card, keep the phone orientation and text size fixed while selecting cells, causing feedback, completing puzzles, and replaying Bubble. Boards and primary controls should keep their positions; longer messages should stay readable. At larger text, scroll to the required control before checking, then leave the scroll position unchanged during the action. Also check Tap to play, skipping/reset, and completed revisits. This guide is a checklist, not evidence of actual physical-device execution.

## Verification

At source `41c18295bda5b444a17af19b2c1cd47bfb4a4fba` on Xcode 27.0/iOS 27.0, all eight native geometry flows passed on both an owned iPhone 18 Pro and a smaller iPhone 13 mini (375-point width), including each game at normal and largest text. All 136 nonempty board/control frame comparisons had exactly zero position/size delta. All 120 unit tests and 26 existing gameplay/accessibility/pager tests also passed, with zero failures, skips, or runtime warnings. Explicit Debug and ARM64 Release builds passed. Logs, result bundles, original failures, screenshots, and the exact final source receipt remain outside Git and are linked through the issue/PR handoff. Exact-head CI and fresh independent review remain required before merge. The existing published simulator MVP is immutable; this source correction publishes no new release.

The resumed branch preserves identical app, unit-test, geometry-test, and supporting fixture source from that measured commit. Rebase changes are verification policy and unrelated retained UI coverage, so the 16-flow results remain explicitly bound to the original source rather than claimed as a new execution. Exact-current-head PR CI still runs all units and the three approved pre-design smoke cases. All eight geometry cases remain available through explicit focused or extended runs under [TESTING.md](TESTING.md). Routine main verification is controlled by the current [CI policy](CI.md); this correction adds no second main check.
