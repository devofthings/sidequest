import SwiftUI

/// Read-only layout context. Native page bounds and independently measured chrome own its inputs.
struct GameLayoutBudget: Equatable, Sendable {
  let width: CGFloat
  let height: CGFloat

  init(viewport: CGSize, chromeHeight: CGFloat, chromeSpacing: CGFloat = 20) {
    width = max(0, viewport.width - 32)
    height = max(0, viewport.height - max(0, chromeHeight) - 32 - max(0, chromeSpacing))
  }

  /// Keep a usable minimum rather than forcing semantic text or touch targets into tiny geometry.
  func squareBoardExtent(chromeHeight: CGFloat, columns: Int) -> CGFloat {
    let minimum = CGFloat(columns) * 44
    return max(minimum, min(width, height - max(0, chromeHeight) - 8))
  }
}

private struct CardViewportKey: EnvironmentKey {
  static let defaultValue: CGSize? = nil
}

private struct GameLayoutBudgetKey: EnvironmentKey {
  static let defaultValue: GameLayoutBudget? = nil
}

extension EnvironmentValues {
  var sidequestCardViewport: CGSize? {
    get { self[CardViewportKey.self] }
    set { self[CardViewportKey.self] = newValue }
  }

  var sidequestGameLayoutBudget: GameLayoutBudget? {
    get { self[GameLayoutBudgetKey.self] }
    set { self[GameLayoutBudgetKey.self] = newValue }
  }
}
