import SwiftUI

/// Measures title/start independently of the game, leaving one stable viewport budget for consumers.
@MainActor
struct GameCardLayout<Start: View, Content: View>: View {
  let title: String
  let start: Start
  let content: Content
  @Environment(\.sidequestCardViewport) private var viewport
  @State private var chromeHeight: CGFloat = 0

  private var budget: GameLayoutBudget? {
    guard let viewport, viewport.width > 0, viewport.height > 0, chromeHeight > 0 else {
      return nil
    }
    return GameLayoutBudget(viewport: viewport, chromeHeight: chromeHeight)
  }

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 20) {
        Text(title)
          .font(.system(.title, design: .rounded, weight: .bold))
          .accessibilityAddTraits(.isHeader)
        start
      }
      .onGeometryChange(for: CGFloat.self) { geometry in
        geometry.size.height
      } action: { height in
        if abs(chromeHeight - height) > 0.5 { chromeHeight = height }
      }
      content.environment(\.sidequestGameLayoutBudget, budget)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}
