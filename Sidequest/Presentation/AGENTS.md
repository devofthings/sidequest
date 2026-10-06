# Shared presentation

This UI-only folder owns the researched semantic palette and local button press style used by feed, news, and game presentation. Follow [the selected design baseline](../../docs/DESIGN.md) and [coding rules](../../docs/CODING.md). Domain/rule types stay independent of these SwiftUI types.

`SidequestTheme` resolves opaque light/dark colors and stronger increased-contrast borders. Accent fills use dark ink, including the lime primary action in dark appearance. Game-specific adapters retain ownership of board state and local effects.

`SidequestButtonStyle` keeps transforms within the control's allocated footprint. Reduce Motion changes press feedback immediately without scaling. Disabled eligibility comes from existing controls/runtime; the style never changes lifecycle. Compact header actions retain their 44-point footprint. Use semantic text styles and preserve measured game regions.

The SDK's contrast and Reduce Motion environment values are read-only. FeedView passes them through the writable optional `sidequestContrast` and `sidequestReduceMotion` presentation keys into separate hosting roots. Consumers resolve an override first, then the system value for standalone/library views. These keys carry preferences; they do not own app state.

## Implementation question review #123

The implementation author conducted this agent-grill self-assessment; the lead's fresh readiness review confirmed the bounded scope.

| Question | Kind | Answer and evidence | Verification |
| --- | --- | --- | --- |
| Where do shared colors/styles belong? | Delegated technical choice | A UI-only `Presentation` folder keeps feed/news/game styling reusable while preserving the inward dependencies in STRUCTURE.md. | Strict Swift lint passed; exact-head app compilation and source discovery remain with lead CI. |
| Can system contrast and Reduce Motion be written into a hosted SwiftUI environment? | Fact and technical choice | Xcode 27.0 SwiftUICore SDK declares both preferences getter-only. Optional writable presentation keys carry the parent values, with system fallback outside feed hosting. | Lead will inspect ordinary/largest light/dark/increased-contrast surfaces and Reduce Motion behavior in the running simulator. |
| How is the canvas preserved during native paging? | Delegated technical choice | Transparent UIKit pager/hosting roots expose the opaque SwiftUI canvas; existing gesture and scroll containment is unchanged. | Lead will verify actual light/dark paging and preview/start geometry; source review alone is not rendered evidence. |

## Read-only game layout context #142

Shared UI-only layout values carry actual native card viewport and the remaining game-content budget. Rules/controllers/Core do not consume geometry. Independent stable chrome measurements may size a normal board; measure chrome at the fixed content width, excluding that board, to prevent feedback cycles. Empty/unavailable measurements use a safe minimum fallback until actual layout settles. Genuine viewport/Dynamic Type changes may relayout, but selection/start/feedback/completion must not change settled board extent. All44-point minimum targets and full readable semantic text remain; accessibility sizes use natural owned scrolling.


For #138, the shared native control marker carries touch ownership only. It lets both feed pans exclude a dedicated game input without importing game rules; it does not own gestures, game state, or eligibility. Bubble consumes the existing rectangular budget directly for its 10:12 board; the square-grid minimum is not a Bubble touch-target rule.

## Selected private design translation #182

The owner's October 5 request selects the saved private Foundations/News visual direction for bounded native refinement; see [the adoption record](../../docs/design/PRIVATE_FIGMA.md#selected-shared-native-refinement-182). `SidequestButtonStyle` accepts an optional accent fill from existing tokens. Its default remains unchanged for all existing game controls; accent fills use dark ink and an outline in both appearances, without changing eligibility, target size, or motion. Preserve existing palette values and the 44-point header controls. Native rendering remains a separate verification gate.

For #194, GameLayoutBudget subtracts 32 points of outer padding and an explicit chrome gap (20 by default for legacy start chrome; zero for real first-interaction cards). Absent chrome consumes no height. Header changes never derive budget from game state.

## Neutral app surroundings #210

The owner authorized clean utility styling on October 6. Use `SidequestTheme.utilityCanvas` and `utilitySurface` for the feed backdrop, news, and import library, and `SidequestButtonStyle(neutral: true)` for their actions. Keep existing game accent and game surface tokens unchanged. More options uses a plain ellipsis inside its existing 44-point outlined footprint; actions, eligibility, measured header geometry, source attribution, and Reduce Motion behavior retain their current owners.

Agent-grill self-assessment by `/root/neutral210`:

| Question | Kind | Answer and evidence | Verification needed |
| --- | --- | --- | --- |
| Which colors implement the supplied direction? | Delegated technical choice | Opaque light gray `F7F7F8` / dark charcoal `111114` canvas; white / `242424` utility surface. Existing semantic ink and increased-contrast borders remain. Dedicated tokens preserve the game palette in SidequestTheme and match the selected static launch canvas under #215. | Actual light/dark/increased-contrast screenshots and source review. |
| Can menu styling change interaction or geometry? | Fact / technical choice | FeedView already owns a 44-point menu with semantic More options and preserved action IDs. Retain those dimensions and actions while selecting neutral styling and a plain ellipsis. | Existing normal/largest-text menu-reset UI case and required smoke suite. |
| Does this add settings or change reading behavior? | Fact | Issue #210 concerns utility styling only. NewsCardContent and NewsLibraryView retain provenance, picker, text selection, and import/reset behavior. | Existing news/menu checks, exact-head compilation, and visual inspection; no new feature or game-rule tests. |

Implementation is ready within the owner-approved scope; executable and rendered validation remain with the lead.
