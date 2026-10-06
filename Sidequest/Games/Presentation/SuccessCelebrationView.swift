import SwiftUI

/// Viewport-owned decoration: it never changes game geometry or intercepts input.
struct SuccessCelebrationView: View {
  let runtime: GameRuntime?
  let gameTitle: String
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var reduceMotionOverride

  private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

  var body: some View {
    ZStack {
      if let attempt = runtime?.celebrationAttempt, let style = runtime?.celebrationStyle {
        celebration(style)
          .id(attempt)
          .transition(reduceMotion ? .opacity : .scale(scale: 0.7).combined(with: .opacity))
      }
    }
    .allowsHitTesting(false)
    .animation(
      runtime?.isVisible == true
        ? (reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.28, bounce: 0.25))
        : nil,
      value: runtime?.celebrationAttempt
    )
    .transaction { transaction in
      if runtime?.isVisible != true { transaction.disablesAnimations = true }
    }
  }

  private func celebration(_ style: SuccessCelebrationStyle) -> some View {
    Text("✓ \(style.message)")
      .font(.system(.largeTitle, design: .rounded, weight: .heavy))
      .multilineTextAlignment(.center)
      .foregroundStyle(SidequestTheme.darkInk)
      .padding(.horizontal, 28)
      .padding(.vertical, 18)
      .background(style.accent, in: Capsule())
      .overlay {
        Capsule().strokeBorder(SidequestTheme.darkInk, lineWidth: 2)
      }
      .shadow(color: SidequestTheme.darkInk.opacity(0.2), radius: 12, y: 6)
      .background {
        if !reduceMotion {
          CelebrationParticles(style: style)
            .accessibilityHidden(true)
        }
      }
      .accessibilityLabel("\(gameTitle) completed. \(style.message)")
      .accessibilityIdentifier("game.successCelebration")
  }
}
