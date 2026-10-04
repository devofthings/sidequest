# MVP visual design and motion research

Research date: October 5, 2026. Prepared for [#13](https://github.com/devofthings/sidequest/issues/13). This is research and a recommended direction, not evidence that the design has been implemented or tested.

The owner authorized a vivid, modern design and animations for all four games, suitable for pitching the MVP, without waiting for further design approval. Existing game rules, explicit Tap to play, manual paging, reset behavior, five-game/news cadence, and stable board geometry remain constraints. Compact variants and difficulty mechanics belong to #117/#118, and adaptive recommendations remain an Idea in #119.

## What primary sources establish

Apple recommends motion with a clear purpose, brief precise feedback, an optional motion experience, and interactions that people can interrupt. Important information must remain understandable without animation. Its game guidance discusses maintaining a consistent 30–60 fps experience; this is a design objective, not a measured result for Sidequest. [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion).

Apple recommends recognizable buttons, a press state for custom buttons, and a general minimum hit region of 44×44 points. One or two prominent actions per view help establish hierarchy. [Apple HIG: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons).

Apple recommends system colors where suitable; custom colors need appearance and increased-contrast variants. Color should communicate consistently without being the sole signal. [Apple HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color).

Apple's accessibility guidance supports scalable text and discusses WCAG AA contrast guidance, including 4.5:1 for smaller text and 3:1 for larger/bold text. Keep textual and symbolic alternatives to color-coded states. [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

System text styles provide hierarchy while supporting Dynamic Type and accessibility text sizes. System fonts and SF Symbols can share weights; the system's serif design is also available without embedding a font file. [Apple HIG: Typography](https://developer.apple.com/design/human-interface-guidelines/typography).

Apple's spring guidance recommends presets as starting points, then tuning duration and bounce for the interaction. It distinguishes perceptual duration from unpredictable settling duration, and explains smooth interruption/retargeting. It recommends a zero-bounce spring when unsure and small bounce for a playful character. [Apple WWDC23: Animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/).

The developer's Pocket Chess listing advertises small, simple boards emphasizing relevant pieces, and puzzles from mate in two to mate in four. That supports a compact visual reference, but does not select Sidequest's board dimensions, rules, artwork, or difficulty policy. [Pocket Chess official Google Play listing](https://play.google.com/store/apps/details?hl=en&id=com.dkxqzbfkjt.pocketchess).

The existing `docs/research/competitors.md` records publisher-advertised swipeable game feeds and short puzzles. Its advertised inventories do not establish actual animation quality, retention, or that any palette is more addictive. No competitor has been installed or played for this research. The recommendation below is a design judgment; enjoyment and desire to reopen still require real testers.

Research access: Apple's HIG pages require JavaScript in the text browser. Their official DocC JSON under `https://developer.apple.com/tutorials/data/design/human-interface-guidelines/` supplied the readable content. Public HIG links above are the canonical references.

## Recommended direction: bright arcade objects, calm reading

Use a coherent family of large, tactile game objects against a quiet canvas. Let a saturated accent, bold title, and real inactive board establish each card at a glance. News should feel like a deliberate reading break using the same card shell, with a quieter hierarchy and fully readable attribution. Aim for satisfying, responsive play; no source establishes that styling will produce retention or addiction.

Prefer opaque surfaces with a restrained border and soft elevation over blur, glass, animated gradients, or multiple nested panels. This gives the games a recognizable personality without competing with pieces, numbers, or article text. Avoid adding marketing illustrations that replace the actual preview. Keep existing labels and actions until copy changes are separately needed.

Suggested tokens are starting values, selected by design judgment rather than an Apple prescribed palette:

| Role | Light appearance | Dark appearance | Use |
| --- | --- | --- | --- |
| Canvas | `#F5F3FF` | `#101427` | Quiet full-page background |
| Surface | `#FFFFFF` | `#1B2037` | Board/control/reading surface |
| Primary text | `#111827` | `#F8FAFC` | Titles, values, article text |
| Secondary text | `#475569` | `#CBD5E1` | Instructions and source metadata |
| Primary action | `#C5F36B` | `#C5F36B` | Tap to play; dark ink label in either appearance |
| Sudoku accent | `#C4B5FD` | `#C4B5FD` | Selected-cell fill with dark ink |
| Memory accent | `#FDA4AF` | `#FDA4AF` | Card backs/highlights with dark ink |
| Chess accent | `#C5F36B` | `#C5F36B` | Selection marker, not piece identity |
| Bubble accent | `#67E8F9` | `#67E8F9` | Launcher/action emphasis; retain distinct bubble identities |

Separate accent decoration from semantic status. Selected, invalid, matched, disabled, and completed states also need outlines, symbols, labels, or shape changes. A bright hue suitable as a fill may be unsuitable as small text on white. Keep article bodies on a solid surface; decoration stays outside their text area.

Computed opaque sRGB contrast examples using relative luminance: primary text on white 17.74:1; secondary text on light canvas 6.91:1; dark-appearance primary/secondary text on its surface 15.34:1/10.81:1. Dark ink on lime, lavender, cyan, and coral fills gives 13.86:1, 9.61:1, 12.24:1, and 9.38:1 respectively. These are calculations for those exact pairs, not verification of translucent overlays, disabled states, adjacent board squares, all bubble colors, or actual rendered screens. Define increased-contrast borders and inspect every final state before delivery.

Use semantic SF text styles: bold rounded titles for game names, ordinary body/callout for instructions, and monospaced digits for changing values. A restrained system-serif news headline can distinguish reading while article body stays the regular system body style. Use an 8-point spacing rhythm, roughly 20-point outer insets, and consistent 16–24-point corner radii as starting values. Do not force fixed text heights, shrink text, or reduce controls to fit a pitch screenshot.

Preserve the board's top anchor and natural measured reservations. Style preview and play using the same board shell; retain the start action's footprint. Completion changes happen in the existing reserved feedback/control region. At accessibility text sizes, use the existing inner scroll and readable alternate controls. Current 8×8 Chess geometry may not allow every square to reach 44 points on small phones: retain its separate accessible piece/coordinate controls, never add overlapping hit regions, and address compact board changes in #117 rather than changing Chess rules during styling.

## Recommended motion specification

Durations below are proposed tuning values, not external best-practice constants. Start with roughly 120–180 ms for press/highlight feedback and 180–280 ms for small object transitions, then inspect on a running app. Use at most a small bounce for decorative success feedback. Motion transforms visual contents inside their allocated regions; it must not animate board layout, text reservation sizes, or the host's height.

| Area | Default motion | Reduce Motion and lifecycle requirements |
| --- | --- | --- |
| Shared buttons | Subtle fill/outline response and at most 0.98 content scale on press, recovering quickly | Immediate fill/outline state; action eligibility remains runtime-owned |
| Sudoku | Selected-cell highlight and a brief value crossfade; invalid-entry feedback adds a static symbol/outline | Instant highlight/value changes and the same explicit feedback; no board shake |
| Memory | Brief tile-local reveal/conceal, using a crossfade first; a restrained flip is optional if it remains readable. Matched pairs get one small local success emphasis | Instant reveal/conceal with matched symbol/style. Preserve existing mismatch delay and rules. Hidden symbols must not leak visually or through accessibility during either transition |
| Chess | Selected-square highlight; a committed successful move may interpolate a presentation-only piece between its original and destination squares inside the fixed board | Instant destination update and static selection/checkmate feedback. Invalid moves never produce a false moving piece; cancel transient overlays on reset/hide |
| Bubble | Preserve existing authoritative shot path and timing; add contained hit/pop emphasis at committed removal and a concise completion accent | No flying or expanding particles; final board and clear-count text communicate outcome. Do not replay a shot, change physics, or extend input locks merely for polish |
| Completion | One short checkmark opacity/scale emphasis in existing feedback space | Immediate visible checkmark and readable result. No repeated celebration or new reward system |
| News/navigation | Native finger-following paging remains the motion. Button press feedback only; article reading is still | Existing nonanimated navigation-menu behavior; no automatic paging, parallax, moving text, or article entrances that delay reading |

Implement motion in game presentation, driven by existing observable values and stable identity. Prefer explicit value-scoped animations or narrow transactions over an animation attached to the full card stack. Avoid new timer loops or view-appearance tasks for decorative feedback. If a transient Chess/Bubble effect needs owned state, bind it to the current attempt/card and clear it when the lifecycle resets/stops; callbacks recheck eligibility after suspension. Animation completion must never own game-rule mutations or completion eligibility.

The local Xcode SDK interfaces expose `Animation.snappy(duration:extraBounce:)`, `Animation.smooth(duration:extraBounce:)`, and `EnvironmentValues.accessibilityReduceMotion`; the preset declarations inspected are usable at the project's iOS 17 deployment floor. Use the existing Reduce Motion environment approach already present in feed/Bubble. New Liquid Glass APIs are unnecessary for this direction; do not raise the deployment target. This is API declaration inspection, not an iOS 17 runtime test. Use [SwiftUI animation documentation](https://developer.apple.com/documentation/swiftui/animations) and the [Reduce Motion environment reference](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion) during implementation.

## Bounded implementation and evidence

1. Record the chosen palette, typography, fixed geometry, and motion policy in the authoritative design document and closest AGENTS guidance. Implement shared presentation tokens and the existing feed/news/preview chrome first, preserving source ownership and inward dependencies.
2. Apply Sudoku and Memory styling/motion without changing their rules, configuration, or mismatch timing. Review hidden-answer accessibility and interrupted reveals.
3. Apply Chess and Bubble styling/motion without changing puzzle dimensions, move depth, shooter physics, or scoring. Review both Chess sides and stale effect cancellation.
4. Run proportional focused visual checks across all four game kinds, both Chess fixtures, and news in light/dark appearances, ordinary/largest text, Reduce Motion, preview/play/feedback/completion, and interrupted skip/reset. Capture before/after board/control geometry; every board stays stable within an unchanged viewport/scroll position.
5. Keep all unit tests and the agreed three-case UI smoke merge gate. Use a bounded focused design pass rather than promoting the entire retained UI suite into routine CI. Inspect screenshots and actual motion; screenshot-only evidence cannot establish cancellation or animation smoothness. Require fresh independent review on the final head. Do not dispatch a second main check or publish a release merely for design verification.

Physical-device appearance, VoiceOver operation, sustained frame rate, and personal enjoyment remain unverified until actually tested. A simulator recording can communicate the MVP pitch, but must be described as simulator footage. No new screenshots, footage, performance, or tester results were produced in this research task.
