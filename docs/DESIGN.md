# MVP visual and motion baseline

Status: selected by the technical lead on October 5, 2026 under the owner’s explicit #13 authorization. Implementation and rendered validation are pending. See [primary-source research](research/mvp-design.md) for evidence, limitations, and the distinction between guidance and design judgment.

## Direction

Bright arcade objects on a calm canvas: vivid lime, lavender, coral, and cyan accents; opaque light/dark surfaces; bold rounded game headings; a restrained serif news heading and readable system body text. Real inactive game boards remain the preview. Keep existing actions, game rules, attribution, cadence, and manual paging.

Use the palette table in the research as the selected starting token set, semantic Dynamic Type styles, an 8-point spacing rhythm, and consistent rounded surfaces. Validate actual contrast and increased-contrast states; calculated opaque color pairs do not certify every rendered state. Maintain accessible control sizes and existing Chess alternate controls.

## Motion

Use brief, purposeful local feedback: button press response; Sudoku selection/value feedback; Memory reveal/match feedback without hidden-answer leaks; Chess selection and successful-move feedback; Bubble committed hit/pop feedback alongside its existing authoritative path. Completion gets a single contained success emphasis. News reading stays still and native paging retains gesture ownership.

Default tuning starts around 120–180 ms for feedback and 180–280 ms for small transitions; these are lead choices to validate, not platform constants. Reduce Motion uses immediate state changes or brief opacity feedback without spatial flips, travel, or particles. Animate content within stable footprints; never animate board/card layout or measured text reservations. Rule mutations, eligibility, reset, cancellation, and completion stay with existing controllers/runtime. No decorative timer loops or new input lock are required.

## Delivery and evidence

Split implementation into shared tokens/feed/news chrome, then game presentation and motion. Preserve iOS 17 deployment support, hexagonal ownership, three routine UI smoke cases and all unit tests. Add only meaningful focused design checks, including both Chess sides, light/dark, large text, Reduce Motion, and interrupted reset. Capture representative simulator screens and inspect actual motion; record actual checks in PRs. No implementation, screenshots, physical-device performance, retention, or release is established by this baseline alone.

Pocket variants/difficulty #117/#118 remain separate specification work; adaptive frequency #119 remains an Idea. Backend, rewards, monetization, paid tooling, and release publication are not introduced.
