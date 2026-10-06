import SwiftUI

extension SuccessCelebrationStyle {
  var accent: Color {
    switch self {
    case .pop: SidequestTheme.lime
    case .confetti: SidequestTheme.coral
    case .orbit: SidequestTheme.cyan
    case .rays: SidequestTheme.lavender
    }
  }
}

/// One interruptible decorative animation, removed with its runtime-owned attempt.
struct CelebrationParticles: View {
  let style: SuccessCelebrationStyle
  @State private var progress: CGFloat = 0
  @State private var finished = false

  var body: some View {
    GeometryReader { geometry in
      if !finished {
        ForEach(0..<12) { index in
          particle(index)
            .foregroundStyle(index.isMultiple(of: 2) ? style.accent : SidequestTheme.cyan)
            .modifier(
              CelebrationParticleMotion(
                style: style, index: index, size: geometry.size, progress: progress))
        }
      }
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.85)) {
        progress = 1
      } completion: {
        // Remove invisible geometry as well as pixels; decoration cannot enlarge the AX badge.
        finished = true
      }
    }
  }

  @ViewBuilder private func particle(_ index: Int) -> some View {
    switch style {
    case .pop:
      Circle().frame(width: index.isMultiple(of: 2) ? 12 : 8, height: 12)
    case .confetti:
      RoundedRectangle(cornerRadius: 2).frame(width: 7, height: 15)
    case .orbit:
      Image(systemName: "sparkle").font(.system(size: 18, weight: .bold))
    case .rays:
      Capsule().frame(width: 5, height: 22)
    }
  }

}

/// Evaluate the curved orbit at each animation frame rather than interpolating its endpoints.
private struct CelebrationParticleMotion: AnimatableModifier {
  let style: SuccessCelebrationStyle
  let index: Int
  let size: CGSize
  nonisolated var progress: CGFloat
  nonisolated var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(rotation))
      .scaleEffect(style == .pop ? 1.4 - progress : 1)
      .opacity(Double(1 - progress))
      .position(position)
  }

  private var rotation: Double {
    switch style {
    case .pop, .orbit: 0
    case .confetti: Double(index * 30) + Double(progress) * 240
    case .rays: Double(index) * 30 + 90
    }
  }

  private var position: CGPoint {
    let baseAngle = Double(index) * .pi / 6
    let angle = baseAngle + (style == .orbit ? Double(progress) * .pi : 0)
    let travel = Double(progress) * (style == .rays ? 25 : 45)
    let horizontalRadius = Double(size.width) / 2 + 8 + travel
    let verticalRadius = Double(size.height) / 2 + 8 + travel
    return CGPoint(
      x: Double(size.width) / 2 + cos(angle) * horizontalRadius,
      y: Double(size.height) / 2 + sin(angle) * verticalRadius)
  }
}
