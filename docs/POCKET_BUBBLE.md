# Compact game cards and harder Bubble play

Status: owner-authorized outcome on October 5, 2026; implementation pending in [#135](https://github.com/devofthings/sidequest/issues/135). The owner requested that all puzzles be pocket-sized, with better Bubble shooter controls and more difficulty. This supersedes retaining the existing one-shot Bubble production default in the first [pocket specification](pocket-games/README.md); it does not replace the four game kinds or select difficulty tiers in [#118](https://github.com/devofthings/sidequest/issues/118).

## Compact interaction

Audit all four games, rather than assuming that small logical boards establish a compact experience. At normal text on supported iPhones, present the core board and primary start/play controls together with concise instructions and stable geometry. Preserve complete text and usable targets. At larger accessibility sizes, keep the owned content scroller and reachable controls instead of shrinking targets or clipping content. Actual rendered measurements and interaction establish fit; no new layout results are claimed here.

Keep explicit tap-to-play, manual feed navigation, five-game/news cadence, frozen card configurations, unfinished skip/reset and completed revisits. The selected Chess 4×4 focus windows retain standard rules and full-coordinate alternatives through [#132](https://github.com/devofthings/sidequest/issues/132). Do not enlarge Bubble boards to make them harder.

## Bubble controls

A dedicated aiming region, clear launcher, aiming feedback and a large explicit Fire action are the lead's recommended next controls. The owner was asked to choose between drag-to-aim plus Fire and release-to-shoot; no answer is recorded yet. Preserve explicit Fire unless a change to shooting semantics is agreed. Real aiming gestures must not accidentally page the feed, and entering or starting a card must never fire. Keep accessible aiming alternatives and color-independent information. Resolve exact touch arbitration and trajectory rendering through the project-local agent-grill before implementation.

## Meaningful multi-shot challenges

Current `BubbleChallengeGenerator.generate` and `fallback` accept only a replayed single winning shot. This is a source observation, not a difficulty measurement: production has deliberately trivial winning routes. The accepted outcome is a harder compact default requiring meaningful multiple shots while retaining the current eight-shot rules.

Use bounded local preparation and replay a concrete winning witness through the real rules before publishing a card. A padded or needlessly long witness does not prove difficulty. Reject trivial one-shot clears and establish multiple required actions or independently anchored color groups; document the actual verification method and limits. Preserve deterministic fixtures, solvability and preparation bounds. Technical generation strategy, exact shot targets and new tier labels remain unselected until evidence resolves them. Original fixed fixtures may remain historical test routes; normal-production checks must exercise the changed generator.

No timer, score, automatic progression, paid catalog, backend or release is selected. Difficulty tiers remain a separate specification, and adaptive game frequency remains an Idea. Prioritize #135 after the current Chess review, ahead of optional startup animation #91.

## Planned verification

Verify actual normal/largest-text layouts and stable board/control frames for all four games. For Bubble, exercise actual aiming without paging, explicit start/Fire, multi-shot success and wrong shots, input lock, skip during flight, frozen replay and Reduce Motion. Add deterministic generation tests for witnesses, nontriviality and bounded failure. Exact-head native CI and fresh independent review remain required. Physical-device results and enjoyment remain unverified until actually tested.
