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
      if runtime?.celebrationAttempt != nil {
        celebration
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

  private var celebration: some View {
    Text("✓ Nice!")
      .font(.system(.largeTitle, design: .rounded, weight: .heavy))
      .multilineTextAlignment(.center)
      .foregroundStyle(SidequestTheme.darkInk)
      .padding(.horizontal, 28)
      .padding(.vertical, 18)
      .background(SidequestTheme.lime, in: Capsule())
      .overlay {
        Capsule().strokeBorder(SidequestTheme.darkInk, lineWidth: 2)
      }
      .shadow(color: SidequestTheme.darkInk.opacity(0.2), radius: 12, y: 6)
      .background {
        if !reduceMotion {
          GeometryReader { geometry in
            ForEach(0..<6) { index in
              Image(systemName: "sparkle")
                .font(.system(size: index.isMultiple(of: 2) ? 24 : 16, weight: .bold))
                .foregroundStyle(
                  index.isMultiple(of: 2) ? SidequestTheme.cyan : SidequestTheme.coral
                )
                .position(
                  x: geometry.size.width / 2
                    + cos(Double(index) * .pi / 3) * (geometry.size.width / 2 + 18),
                  y: geometry.size.height / 2
                    + sin(Double(index) * .pi / 3) * (geometry.size.height / 2 + 24)
                )
            }
          }
          .accessibilityHidden(true)
        }
      }
      .accessibilityLabel("\(gameTitle) completed. Well done.")
      .accessibilityIdentifier("game.successCelebration")
  }
}
