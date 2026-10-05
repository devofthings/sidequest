# Compact game cards and harder Bubble play

Status: owner-authorized outcome on October 5, 2026; implementation is split into separately reviewed children under [#135](https://github.com/devofthings/sidequest/issues/135). The owner requested that all puzzles be pocket-sized, with better Bubble shooter controls and more difficulty. This supersedes retaining the existing one-shot Bubble production default in the first [pocket specification](pocket-games/README.md); it does not replace the four game kinds or select difficulty tiers in [#118](https://github.com/devofthings/sidequest/issues/118).

## Compact interaction

Audit all four games, rather than assuming that small logical boards establish a compact experience. At normal text on supported iPhones, present the core board and primary start/play controls together with concise instructions and stable geometry. Preserve complete text and usable targets. At larger accessibility sizes, keep the owned content scroller and reachable controls instead of shrinking targets or clipping content. Actual rendered measurements and interaction establish fit; no new layout results are claimed here.

Keep explicit tap-to-play, manual feed navigation, five-game/news cadence, frozen card configurations, unfinished skip/reset and completed revisits. The selected Chess 4×4 focus windows retain standard rules and full-coordinate alternatives through [#132](https://github.com/devofthings/sidequest/issues/132). Do not enlarge Bubble boards to make them harder.

## Bubble controls

[Control child #138](https://github.com/devofthings/sidequest/issues/138) owns this implementation separately from [generator child #137](https://github.com/devofthings/sidequest/issues/137).

A dedicated aiming region, clear launcher, aiming feedback and a large explicit Fire action are the lead's recommended next controls. The owner was asked to choose between drag-to-aim plus Fire and release-to-shoot; no answer is recorded yet. Preserve explicit Fire unless a change to shooting semantics is agreed. Real aiming gestures must not accidentally page the feed, and entering or starting a card must never fire. Keep accessible aiming alternatives and color-independent information. Resolve exact touch arbitration and trajectory rendering through the project-local agent-grill before implementation.

## Meaningful multi-shot challenges

The pre-#137 source baseline accepted a replayed single winning shot in `BubbleChallengeGenerator.generate` and `fallback`. That observation explains the harder-play request; it is not a measured difficulty result. [Generator child #137](https://github.com/devofthings/sidequest/issues/137) replaces that baseline with compact three-color ceiling-anchored groups and real-rule replayed three-shot witnesses, independently of control/layout child #138. It merged through [PR139](https://github.com/devofthings/sidequest/pull/139) after fresh review, exact-head137-test native CI and a real production three-shot/reset/revisit flow; merging a reviewed child does not imply all parent #135 outcomes are complete.

Use bounded local preparation and replay a concrete winning witness through the real rules before publishing a card. A padded or needlessly long witness does not prove difficulty. Reject trivial one-shot clears and establish multiple required actions or independently anchored color groups; document the actual verification method and limits. Preserve deterministic fixtures, solvability and preparation bounds. The #137 constructive generation strategy and bounds are recorded in [Bubble guidance](BUBBLES.md); control/layout choices remain with #138, while new tier labels remain unselected. Original fixed fixtures may remain historical test routes; normal-production checks must exercise the changed generator.

No timer, score, automatic progression, paid catalog, backend or release is selected. Difficulty tiers remain a separate specification, and adaptive game frequency remains an Idea. Prioritize #135 after the current Chess review, ahead of optional startup animation #91.

## Planned verification

Verify actual normal/largest-text layouts and stable board/control frames for all four games. For Bubble, exercise actual aiming without paging, explicit start/Fire, multi-shot success and wrong shots, input lock, skip during flight, frozen replay and Reduce Motion. Add deterministic generation tests for witnesses, nontriviality and bounded failure. Exact-head native CI and fresh independent review remain required. Physical-device results and enjoyment remain unverified until actually tested.


## Child integration status

Compact Chess/shared viewport child142 merged through [PR143](https://github.com/devofthings/sidequest/pull/143) after seven focused cases passed on both small375×667 and larger simulators, fresh review and exact-head140-test native CI. Generator137's merged evidence is recorded above. Control child138 consumes that seam with direct lower-board aiming, a real reflected guide, explicit Fire/native Slider and compact stable chrome; its changed behavior and the new all-game whole-frame normal-size audit require actual verification before parent135 is complete. See [Bubble implementation/verification](BUBBLES.md#compact-direct-aiming-138). No new release or tier is implied.


## Owner refinement: simplified aiming #163

The October 5 owner request accepts horizontal drag with the real dotted trajectory instead of visible numeric angle text. Map left/center/right across the existing lower-board region to the unchanged −60°/0°/+60° range, independently of vertical position. Preserve explicit Fire, native 44-point Slider as assistive/keyboard precision alternative, narrow touch ownership, originating lease invalidation and frozen lifecycle. No rule, generation, tier or release change is included. See [implementation and pending verification](BUBBLES.md#simplified-horizontal-aiming-163); earlier #138 evidence remains historical rather than certification of this refinement.
