import SwiftUI

/// Reserves the badge footprint even when quiet, in the viewport-owned header title slot.
struct SuccessCelebrationView: View {
  let runtime: GameRuntime?
  let gameTitle: String
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var reduceMotionOverride

  private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

  var body: some View {
    ZStack(alignment: .leading) {
      badge.hidden().accessibilityHidden(true)
      if runtime?.celebrationAttempt != nil {
        badge
          .accessibilityLabel("Sidequest. \(gameTitle) completed. Well done.")
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("game.successCelebration")
          .transition(reduceMotion ? .identity : .scale(scale: 0.85).combined(with: .opacity))
      }
    }
    .allowsHitTesting(false)
    .animation(
      runtime?.isVisible == true && !reduceMotion ? .smooth(duration: 0.18) : nil,
      value: runtime?.celebrationAttempt
    )
    .transaction { transaction in
      if runtime?.isVisible != true || reduceMotion { transaction.disablesAnimations = true }
    }
  }

  private var badge: some View {
    Text("✓ Nice!")
      .font(.headline)
      .foregroundStyle(SidequestTheme.darkInk)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(SidequestTheme.lime, in: Capsule())
  }
}
