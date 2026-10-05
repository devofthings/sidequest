# Bubble shooter

Issue #8 owns one original, bounded challenge. Keep its rules/normalized geometry independent of SwiftUI and rendering frameworks. Presentation consumes the merged #3 retained `GameRuntime`; issue #8 owns its compatible completed-visible replay extension, while the lead coordinates app composition. Never start or fire from visibility/appearance or the tap-to-play action.

## Implementation question record

The implementation agent used the project-local agent-grill as a self-assessment; the lead reviewed and approved these delegated technical choices within #8. These choices do not add scoring, a campaign, purchases, assets, or scheduling.

| Question | Kind | Decision and rationale | Verification needed |
| --- | --- | --- | --- |
| How can collisions avoid tunneling? | Delegated technical choice | Unit-radius bubbles in a normalized width-10 board; continuous ray/swept-circle first contact, with side-wall reflection. Snap only into a valid empty front-facing hex neighbor or ceiling slot. This avoids frame-dependent collision detection and overlapping placement. | First-contact/edge/wall/ceiling, nonoverlap, valid bounds and nearest reachable slot tests. |
| What makes the challenge short and attainable? | Delegated technical choice | Nine fixed bubbles in two staggered rows; red/blue/green shots repeat deterministically. Win by clearing all bubbles; lose after eight shots, a dangerous bottom-row attachment, or no valid attachment. Three actual aimed shots must prove the win route before handoff. | Reproducible actual aimed win and legal loss sequences; no fictional success claim. |
| How are detached bubbles handled? | Delegated technical choice | Clear connected groups of at least three; after a clear, also remove every bubble without a path to the ceiling row. | Same-color/anchoring/detached tests. |
| How can delayed shots avoid stale attempts? | Fact and delegated technical choice | Rules return an immutable shot plan tied to the current board revision; commit rejects old plans. Presentation owns a cancellable shot task, checks the runtime token after suspension, and resets on lifecycle effects. Completed-visible replay gets a fresh shared lifecycle/token under #8. | Revision rejection and later adapter reset-during-shot/replay tests; no UI work before feed interfaces merge. |

Angles are radians measured from vertical: negative aims left, positive right. The supported continuous range is ±π/3. Geometry and shot sequences are deterministic; do not use Swift's process-randomized hash as board identity. Rules revision and exact generated plans protect delayed commits; runtime attempt identity remains the presentation boundary.

## Presentation ownership

`BubbleShooterController(runtime:game:pause:)` retains rules and one private cancellable shot task. `fire() -> Bool` acknowledges accepted input without exposing task handles. Its injected main-actor pause is the replaceable animation timing boundary; after every pause check cancellation and the same runtime attempt before changing flight or committing a shot. Reset/stop cancel work first. Reset restores board, aim, flight, and feedback; stop retains win/loss rules and feedback. The start action initializes a challenge without firing.

`BubbleShooterView` uses a continuous -60...60 degree slider, an explicit Fire button, and original circles labeled R/B/G beyond color. Gameplay is plain content inside the native pager's owned `feed.cardScroll`; full-card paging and compact menu navigation follow [feed guidance](../../Feed/AGENTS.md). Preserve the single content scroller and actual horizontal aim input. Completed win/loss offers Replay through the same retained runtime; ordinary revisits retain completion. No scores or campaign are introduced.

Replay replaces the runtime's private lifecycle value only for a visible completed card. Deliver reset with the old token ineligible and phase preview before starting a fresh token. Reject a duplicate injected identity rather than accepting stale callbacks. A reset that hides the card cannot start it. Controllers never own a second lifecycle; root coordinates the common composition and running-app wiring.

Running-app tests use root-owned Debug composition arguments `-sidequest-bubble-fixtures` (bubble first, then another card) and `-sidequest-bubble-slow-shot` (longer injected shot pauses only for cancellation observation). They must not affect Release or normal gameplay timing. The game agent owns BubbleFlowTests; root owns central wiring. The retained app wiring is implemented in the game branch; actual running-app results belong in BUBBLES.md and the PR.

Honor the system `accessibilityReduceMotion` value: keep the pending bubble stationary at the launcher rather than showing interpolated flight positions. Collision physics, bounded timing, cancellation, and final attachment remain identical. Do not override the system preference in production. The Aim slider keeps native range accessibility semantics; a separate labeled angle provides degrees, avoiding a custom value that interferes with normalized assistive/automation adjustment.

The lead delegated central Bubble composition wiring to the game agent in the isolated #8 branch after Sudoku established `ComposedGame`; preserve other adapters when rebasing onto their merged work. Fire and Replay use the native large control size, with running-app checks requiring their actual accessibility frames to measure at least 44 by 44 points. A layout wrapper alone does not establish that touch target.

The system Reduce Motion running-app test changes only its destination simulator through native Settings, checks the observed switch value, and restores the original value in deferred cleanup. Relaunch Settings and query its current foreground hierarchy before restoring; stale coordinates after switching apps can miss. Keep temporary repair probes, original-fixture screenshots, and result bundles outside delivery claims and Git.

## Native pager adaptation

The implementation agent reassessed #8 after merged #87: use shared UI menu-navigation and system Reduce Motion helpers, reveal controls fully within the owned inner scroller, and verify native horizontal/diagonal Slider drags change the angle without advancing or firing. Normalized slider automation alone does not establish gesture arbitration. Short board drags preserve an attempt; committed direct skips reset pending shots before reverse navigation restores the preview. The complete 26-test focused run on the rebased native pager passed; see [verification](../../../docs/BUBBLES.md#verification) for actual results and remaining final-base review/CI gates. DEBUG slow-flight pauses are 250ms per frame (six seconds total), permitting actual native paging and stationary-board inspection; Release keeps 20ms pauses. The actual 44-point frame checks use the pager suite’s 0.001-point floating-point tolerance.

## Generated challenges #104

The initial #104 one-shot generation policy is superseded by harder compact generation #137 below. Accept only replayed three-shot witnesses within the existing eight-shot bound; failure remains explicit. Freeze geometry/colors/shot sequence per card. Skip/reset and Replay restore that configuration. Completed win/loss archives include game, aim, feedback, and lifecycle identity. Rehydration binds one fresh inactive runtime; old owners retire permanently. See [ENDLESS.md](../../../docs/ENDLESS.md).

## Stable feedback and Replay #108

Reserve supported feedback, next-color, angle, and Fire/Replay text using the shared measured region. Use monospaced digits plus the bounded slot count for numeric feedback widths. On completion, replace the actual aiming subtree with a hidden, inaccessible, disabled reservation; opacity alone leaves native Slider accessibility alive. Keep Replay in Fire's measured position and fully readable outcome/feedback. Read [stable layout](../../../docs/GAME_LAYOUT.md) before changing these regions.

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../../docs/GAME_PREVIEWS.md).

## Vivid presentation and contained motion #124

Follow [the researched baseline](../../../docs/DESIGN.md). Fade removed board bubbles for 160 ms only when the authoritative shotsFired value increments. There is no independent particle state or animation completion callback. The existing 24-step flight and physics remain controller-owned; the flight reads sidequestReduceMotion override before the system preference. Reduce Motion retains the stationary launcher presentation and uses immediate removal. The #124 full-width Fire/Replay footprint is superseded only in width by the accepted compact #138 composition below; retain its 44-point height and stable Replay reservation. All presentation preferences resolve the propagated override before the system value. Preview, reset, and offscreen transactions disable animation; Reduce Motion supplies no local animation. Completed restoration is static because values are rendered initially, rather than changed by appearance. Keep animations inside existing board/control footprints and leave lifecycle/input/rule mutations with the controller.

Agent-grill self-assessment: Committed pop feedback is a delegated presentation choice under #124, supported by the existing controller/runtime boundaries and DESIGN.md. Source inspection establishes no new rule or timing owner; exact-head unit/smoke CI and root-owned focused rendered/motion checks remain required before delivery. This record is not rendered verification.

## Success feedback routing #86

Mark runtime completion successful only for won; terminal lost still completes silently. Consume the shared runtime feedback boundary in [common game guidance](../AGENTS.md); keep rules, timing, retained results, and reset semantics unchanged. Appearance or restored completed values never emit success.

## Better controls and harder compact play #135

The owner authorized improved aiming controls and more difficult compact Bubble challenges on October 5. Follow [the bounded outcome](../../../docs/POCKET_BUBBLE.md). Keep existing explicit Fire until changed shooting semantics are agreed. Replace one-shot-only production generation with bounded, real-rule-validated multi-shot challenges; a longer witness alone cannot establish difficulty. Preserve the eight-shot rules, frozen replay, single-flight cancellation, manual paging and Reduce Motion. Resolve exact control/generation choices through agent-grill before code; no implementation or verification is claimed by this decision.

## Harder compact generation #137

The owner's October 5 request for harder pocket Bubble play authorizes #137 under #135, superseding the easy one-shot production default. Keep the same geometry/eight-shot rules and explicit Fire. This slice owns generation, not new controls or difficulty tiers.

Agent-grill self-assessment: Three distinct colors have independent ceiling anchors, so matching one color cannot detach the other ceiling colors. At least three color-clearing actions are required; a longer witness alone is insufficient evidence. Construct eight original two-row patterns by retaining five ceiling bubbles (two/two/one color groups), one required partner for the single-bubble group, and three optional same-group lower bubbles. Color permutations and horizontal reflection vary challenges without adding rows. Derive fixed three-shot witnesses from a bounded offline real-rule audit, then replay every selected witness during production preparation; retry at most four candidates and use the independently replayed full-pattern fallback. Each candidate requires only three shot evaluations, no recursive search. Failure remains explicit. Freeze the result per card; reset/Replay restore it unchanged.

The author pure-rule probe on October 5 solved all eight unreflected base patterns in three shots. All reflected/color variants, structural lower bound, fallback, deterministic diversity and actual native production play require further verification before delivery. The historical fixed Debug fixture remains unchanged. All pending native/app verification belongs to the lead.


## Compact direct aiming #138

The lead accepted the agent-grill readiness interview and bounded composition on October 5, after shared viewport seam #142/#143. Normal text uses one concise status row with complete accessible shot/color/angle labels, reserved full feedback, and native Slider plus Fire/Replay in one row. Fire/Replay is at least 96 points wide and 44 points high; this narrowly supersedes #124's full-width action to keep board and primary controls together. Accessibility text uses full stacked text and the existing owned scroller. Size the normal 10:12 board from the actual shared budget minus independent stable chrome; initially retain at least 200 points of width and readable letters of at least 14 points. These are delegated implementation choices, not rendered-fit evidence; the lead verifies normal small/larger viewports and may make a bounded readability adjustment from actual results.

A dedicated transparent native control covers the lower board (normalized y=7...12), at least 100 points high at the minimum board width. Both feed and card pans exclude gestures beginning on this narrow UI-only control or native Slider. Other board/card areas retain manual paging and owned overflow; do not exempt all buttons or replace recognizer delegates. Map finite points above the launcher through uniform board scale, reject zero/downward/invalid points, and clamp the existing ±60-degree angle. Acquire the eligible originating lease even when a touch begins on the launcher or below it; ignore that invalid initial ray and accept later upward movement. Rejecting the initial ray must not permanently refuse an intuitive launcher-origin drag. Drag changes aim only. Explicit Fire remains selected; release-to-shoot is pending owner choice.

The controller owns one originating drag lease containing a unique interaction identity and the current attempt. Begin/update require current eligible input. Accepted Fire, native Slider aim, all lifecycle effects, cancellation, disabling/window detachment and dismantling invalidate it. A held old finger cannot resume after a nonterminal shot ends. Derive the guide from nonmutating real traceShot geometry, including reflections/contact; never retain a commit plan, auto-aim, add a timing owner, or change rules/generation. Preserve frozen Replay, completed restoration, motion behavior and stable footprints.

Source-backed readiness: [#138](https://github.com/devofthings/sidequest/issues/138) and [compact scope](../../../docs/POCKET_BUBBLE.md); Apple [game interaction guidance](https://developer.apple.com/videos/play/wwdc2024/10085/) supports readable layouts and 44-point controls. Meaningful mapping/lease tests and real gestures, all-game normal containment, largest-text reachability and system Reduce Motion are required before delivery. Native verification belongs to the lead and remains pending until recorded.


The first actual small-phone #138 run found the SwiftUI Slider's wrapper at44 points while its native accessibility/touch bounds remained31.001 points. Use a native UISlider representable with44-point intrinsic/allocated bounds; keep native normalized range semantics, full Aim/hint labels and controller aim callbacks. Do not weaken the actual-control frame check to a wrapper. The same run passed launcher/horizontal/vertical/diagonal direct ownership in22.891 seconds; that earlier result does not certify the new adapter. Remove the completed aiming UIControl while retaining its fixed native touch-exclusion region; Replay restores accessible inputs. Actual updated small/larger/native Slider checks remain required.


The larger #138 run established that hiding only native direct-control accessibility still left an identified element after completion; the precise native-control versus wrapper identity was unverified. The attempted whole-representable hiding also failed in r3 and is superseded by structural removal of the aiming child below. Keep fixed region geometry/native pan ownership and existing win/loss/Replay assertions; updated actual completion checks are required before claiming removal. Production-route native proof now uses a genuine launcher-to-upward-left direct ray near−24 degrees instead of treating a normalized Slider request as a delivered angle; retain independent native Slider coverage and the observed audited window/actual win obligations.


Completed direct aiming uses a persistent metadata-free native touch-exclusion region with the actual aiming UIControl removed on win/loss. Cancel its lease before removal; Replay creates the real control again inside the same bounds. Keep the region's FeedPanExcludingControl conformance while completed and keep the disabled real control during preview/pending flight so lower-board touches never become feed pans. The larger r3 run still found the identified native control after both UIKit and SwiftUI accessibility hiding; structural removal avoids retaining an obsolete input's accessibility metadata without changing geometry or touch ownership. This is a source correction awaiting native verification, not a VoiceOver claim.
