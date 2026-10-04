# Shared presentation

This UI-only folder owns the researched semantic palette and local button press style used by feed, news, and game presentation. Follow [the selected design baseline](../../docs/DESIGN.md) and [coding rules](../../docs/CODING.md). Domain/rule types stay independent of these SwiftUI types.

`SidequestTheme` resolves opaque light/dark colors and stronger increased-contrast borders. Accent fills use dark ink, including the lime primary action in dark appearance. Game-specific adapters retain ownership of board state and local effects.

`SidequestButtonStyle` keeps transforms within the control's allocated footprint. Reduce Motion changes press feedback immediately without scaling. Disabled eligibility comes from existing controls/runtime; the style never changes lifecycle. Compact header actions retain their 44-point footprint. Use semantic text styles and preserve measured game regions.

The SDK's contrast and Reduce Motion environment values are read-only. FeedView passes them through the writable optional `sidequestContrast` and `sidequestReduceMotion` presentation keys into separate hosting roots. Consumers resolve an override first, then the system value for standalone/library views. These keys carry preferences; they do not own app state.
