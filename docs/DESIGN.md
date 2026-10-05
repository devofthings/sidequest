# MVP visual and motion baseline

Status: selected by the technical lead on October 5, 2026 under the owner’s explicit #13 authorization. Shared feed/news styling was implemented in #123 / PR #125. Game styling and contained motion were merged in [PR #126](https://github.com/devofthings/sidequest/pull/126) after exact-head CI, fresh review, and focused simulator checks. See [primary-source research](research/mvp-design.md) for evidence, limitations, and the distinction between guidance and design judgment.

## Direction

Bright arcade objects on a calm canvas: vivid lime, lavender, coral, and cyan accents; opaque light/dark surfaces; bold rounded game headings; a restrained serif news heading and readable system body text. Real inactive game boards remain the preview. Keep existing actions, game rules, attribution, cadence, and manual paging.

Use the palette table in the research as the selected starting token set, semantic Dynamic Type styles, an 8-point spacing rhythm, and consistent rounded surfaces. Validate actual contrast and increased-contrast states; calculated opaque color pairs do not certify every rendered state. Maintain accessible control sizes and existing Chess alternate controls.

## Motion

Use brief, purposeful local feedback: button press response; Sudoku selection/value feedback; Memory reveal/match feedback without hidden-answer leaks; Chess selection and successful-move feedback; Bubble committed hit/pop feedback alongside its existing authoritative path. Completion gets a single contained success emphasis. News reading stays still and native paging retains gesture ownership.

Default tuning starts around 120–180 ms for feedback and 180–280 ms for small transitions; these are lead choices to validate, not platform constants. Reduce Motion uses immediate state changes or brief opacity feedback without spatial flips, travel, or particles. Animate content within stable footprints; never animate board/card layout or measured text reservations. Rule mutations, eligibility, reset, cancellation, and completion stay with existing controllers/runtime. No decorative timer loops or new input lock are required.

## Delivery and evidence

Split implementation into shared tokens/feed/news chrome, then game presentation and motion. Preserve iOS 17 deployment support, hexagonal ownership, three routine UI smoke cases and all unit tests. Add only meaningful focused design checks, including both Chess sides, light/dark, large text, Reduce Motion, and interrupted reset. Capture representative simulator screens and inspect actual motion; record actual checks in PRs. The baseline alone establishes no rendered screenshots, physical-device performance, retention, or new release.

Pocket variants/difficulty #117/#118 remain separate specification work; adaptive frequency #119 remains an Idea. Backend, rewards, monetization, paid tooling, and release publication are not introduced.

## Game presentation implementation #124

Sudoku uses lavender cells with dark ink, explicit selected outlines, and local numeric entry feedback. Memory uses coral backs and lime matched cards; answer images change immediately, while only backing/outline colors animate. Chess keeps the original full board and coordinates, with cyan selection and a lime accepted destination; no moving-piece overlay is introduced. Bubble keeps labeled contrasting red/blue/green objects with highlights, and uses a brief removal fade after authoritative shot commits. These are presentation choices, not pocket-variant or difficulty implementation.

Each game resolves propagated contrast and Reduce Motion preferences before system defaults. Local feedback uses 160 ms smooth animation only in visible active/completed attempts. Preview/reset/offscreen transactions disable animation, and restored completed values do not trigger appearance effects. Memory’s answer subtree explicitly disables inherited animations. Bubble flight timing, commit checks, and cancellation remain unchanged; Reduce Motion keeps the in-flight object at its launcher. No animation completion changes rules or eligibility.

The four existing views and game-owned guidance contain the implementation; no new source file, controller state, timer, dependency, sound, or test inventory is added. Actual verification must be recorded in the PR before merge; physical-device performance and retention are unverified.

### Agent-grill self-assessment

| Question | Kind | Settled choice | Evidence and rationale | Verification needed |
| --- | --- | --- | --- | --- |
| Should cells or outer boards animate? | Delegated technical choice | Local values and surfaces only; preview/reset/offscreen disable interpolation. | StableGameRegion owns natural layout reservations; controllers own lifecycle effects. Outer layout interpolation would undermine #108/#88. | Root-owned actual frame comparisons and motion inspection. |
| How can Memory conceal remain immediate? | Delegated technical choice | Disable animation in the answer Image subtree; animate backing/outline only. | The existing mismatch task owns timing and reset clears rules synchronously. A removal transition could retain an outgoing answer. | Actual mismatch conceal and interrupted skip/background checks. |
| Does Chess need a traveling piece? | Delegated technical choice | No; emphasize the accepted destination from attempt.solution. | Existing pure attempts provide the success fact; no extra effect state is required. | Both colors, invalid moves, completion revisit, and reset. |
| Can Bubble effects change shot timing? | Fact and technical choice | Preserve flight/commit code; fade committed removals from shotsFired. | Existing controller checks current attempt after every authoritative pause. Presentation has no rule callback. | Slow-flight interruption, committed removal, Replay, and actual Reduce Motion. |

No human-owned product or spending choice is open for this bounded presentation slice. Source choices are ready; executable and rendered verification remain pending.

## Success feedback #86

Successful game attempts request one standard native success haptic and show a larger readable checkmark/“Nice!” badge centered over the fixed game viewport under owner-approved #193. A 280 ms spring and cyan/coral decorative sparkles supply emphasis; Reduce Motion removes spatial transitions and sparkles, using a 150 ms fade. The decoration lasts 1.5 seconds, never advances the feed, passes input through, never changes board geometry or scrolls away with game controls, and does not replace the game-owned completed result. Hiding/backgrounding or replay cancels it immediately. Bubble losses, stale completions, and restored/revisited results stay quiet. Runtime/controller verification and fresh PR gates remain required; physical vibration is unverified pending device testing.

## Header simplification #191

The owner removes the dedicated newspaper button. Keep app/success identity and the vivid 44-point More options control in the header; News snapshots is a conditional action inside that existing menu. Remove the old button footprint, preserve the success reservation and game geometry, and retain the same import coordinator and source links. The [accepted decision](DECISIONS.md#news-access-191) owns this behavior; native rendering and interaction proof remain PR-specific.
