import SwiftUI

/// Uses the already reserved start-control space; never moves or covers a game board.
struct SuccessCelebrationView: View {
  let runtime: GameRuntime
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var reduceMotionOverride

  private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

  var body: some View {
    ZStack {
      if runtime.celebrationAttempt != nil {
        Text("✓ Nice!")
          .font(.headline)
          .foregroundStyle(SidequestTheme.darkInk)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(SidequestTheme.lime, in: Capsule())
          .accessibilityLabel("Success! Well done.")
          .accessibilityIdentifier("game.successCelebration")
          .transition(reduceMotion ? .identity : .scale(scale: 0.85).combined(with: .opacity))
      }
    }
    .allowsHitTesting(false)
    .animation(
      runtime.isVisible && !reduceMotion ? .smooth(duration: 0.18) : nil,
      value: runtime.celebrationAttempt
    )
    .transaction { transaction in
      if !runtime.isVisible || reduceMotion { transaction.disablesAnimations = true }
    }
  }
}
