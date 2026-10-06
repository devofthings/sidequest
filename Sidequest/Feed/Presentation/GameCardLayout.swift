import SwiftUI

/// Measures legacy start chrome independently of the game, leaving one stable viewport budget for consumers.
@MainActor
struct GameCardLayout<Start: View, Content: View>: View {
  let showsStart: Bool
  let start: Start
  let content: Content
  @Environment(\.sidequestCardViewport) private var viewport
  @State private var chromeHeight: CGFloat = 0

  private var budget: GameLayoutBudget? {
    guard let viewport, viewport.width > 0, viewport.height > 0 else {
      return nil
    }
    return GameLayoutBudget(
      viewport: viewport, chromeHeight: showsStart ? chromeHeight : 0,
      chromeSpacing: showsStart ? 20 : 0)
  }

  var body: some View {
    VStack(spacing: 20) {
      if showsStart {
        start
          .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
          } action: { height in
            if abs(chromeHeight - height) > 0.5 { chromeHeight = height }
          }
      }
      content.environment(\.sidequestGameLayoutBudget, budget)
    }
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: viewport?.height, alignment: .center)
  }
}
