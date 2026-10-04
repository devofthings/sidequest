import SwiftUI

@MainActor
struct BubbleShooterView: View {
  let controller: BubbleShooterController
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrastOverride ?? systemContrast)
  }
  private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
  private var feedbackAnimation: Animation? {
    guard !reduceMotion, controller.runtime.isVisible else { return nil }
    if case .preview = controller.runtime.phase { return nil }
    return .smooth(duration: 0.16)
  }

  var body: some View {
    VStack(spacing: 12) {
      Text("Match three letters to clear the board.").font(.callout)
      board
        .aspectRatio(10.0 / 12.0, contentMode: .fit)
        .frame(maxWidth: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bubble board")
        .accessibilityValue(boardDescription)
        .accessibilityIdentifier("bubble.board")
      StableGameRegion {
        ZStack {
          ForEach(feedbackMessages, id: \.self) { Text($0) }
        }
      } content: {
        Text(controller.feedback)
          .accessibilityIdentifier("bubble.feedback")
      }
      .monospacedDigit()
      Text("Shots: \(controller.game.shotsFired) of \(BubbleShooterGame.shotLimit)")
        .monospacedDigit()
        .accessibilityIdentifier("bubble.shots")
      StableGameRegion {
        aimingControls.disabled(true)
      } content: {
        if isPlaying {
          aimingControls
        } else {
          Text(controller.game.outcome == .won ? "You won!" : "You lost")
            .font(.headline)
            .accessibilityIdentifier("bubble.outcome")
        }
      }
      Button {
        if isPlaying { controller.fire() } else { controller.replay() }
      } label: {
        StableGameRegion {
          ZStack {
            Text("Fire")
            Text("Replay")
          }
        } content: {
          Text(isPlaying ? "Fire" : "Replay")
        }
        .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(SidequestButtonStyle(prominent: true, compact: true))
      .controlSize(.large)
      .frame(minHeight: 44)
      .disabled(isPlaying ? !controller.canFire : !controller.runtime.isVisible)
      .accessibilityIdentifier(isPlaying ? "bubble.fire" : "bubble.replay")
    }
    .allowsHitTesting(controller.runtime.isVisible)
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private var aimingControls: some View {
    VStack(spacing: 12) {
      StableGameRegion {
        ZStack {
          ForEach(BubbleColor.allCases, id: \.self) { color in
            Text("Next bubble: \(color.name), \(color.symbol)")
          }
        }
      } content: {
        Text(
          "Next bubble: \(controller.game.nextColor.name), \(controller.game.nextColor.symbol)")
      }
      StableGameRegion {
        Text("Aim: −60°")
      } content: {
        Text("Aim: \(controller.aimDegrees, specifier: "%.0f")°")
          .accessibilityIdentifier("bubble.angle")
      }
      .monospacedDigit()
      Slider(
        value: Binding(
          get: { (controller.aimDegrees + 60) / 120 },
          set: { controller.aim(degrees: $0 * 120 - 60) }),
        in: 0...1
      )
      .disabled(!controller.canFire)
      .accessibilityLabel("Aim")
      .accessibilityHint(
        "Aim from 60 degrees left to 60 degrees right of vertical. The angle is shown above."
      )
      .accessibilityIdentifier("bubble.aim")
    }
  }

  private var isPlaying: Bool { controller.game.outcome == .playing }

  private var feedbackMessages: [String] {
    [
      "Clear matching groups of three.", "Shot in flight.",
      "Bubble attached. Try a matching group.",
      "Cleared \(BubbleGeometry.slots.count) matching and \(BubbleGeometry.slots.count) detached bubbles.",
      "Board cleared!", "Challenge ended. Try again.",
      "Could not fire this shot. Adjust your aim and try again.",
      "Could not trace this shot. Adjust your aim and try again.",
    ]
  }

  private var board: some View {
    GeometryReader { geometry in
      let scale = geometry.size.width / BubbleGeometry.width
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 16).fill(theme.surface)
          .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(
              theme.border, lineWidth: theme.borderWidth)
          }
        Path { path in
          let y = BubbleGeometry.center(of: BubbleSlot(row: 4, column: 0)).y * scale
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
        .stroke(theme.secondaryInk, style: StrokeStyle(lineWidth: 2, dash: [4]))
        if controller.canFire {
          Path { path in
            let angle = controller.aimDegrees * .pi / 180
            let launcher = BubbleGeometry.launcher
            path.move(to: CGPoint(x: launcher.x * scale, y: launcher.y * scale))
            path.addLine(
              to: CGPoint(
                x: (launcher.x + sin(angle) * 3) * scale, y: (launcher.y - cos(angle) * 3) * scale))
          }
          .stroke(theme.ink, style: StrokeStyle(lineWidth: 2, dash: [3]))
        }
        ForEach(BubbleGeometry.slots, id: \.self) { slot in
          if let color = controller.game.board[slot] {
            bubble(color, at: BubbleGeometry.center(of: slot), scale: scale)
              .transition(reduceMotion ? .identity : .opacity)
          }
        }
        // Only committed shots animate removal; preview/reset/restoration never animate the board.
        .animation(
          controller.game.shotsFired > 0 ? feedbackAnimation : nil,
          value: controller.game.shotsFired)
        if let flight = controller.flight {
          bubble(
            flight.color, at: reduceMotion ? BubbleGeometry.launcher : flight.position, scale: scale
          )
        } else if controller.game.outcome == .playing {
          bubble(controller.game.nextColor, at: BubbleGeometry.launcher, scale: scale)
        }
      }
    }
  }

  private var boardDescription: String {
    let bubbles = BubbleGeometry.slots.compactMap { slot -> String? in
      guard let color = controller.game.board[slot] else { return nil }
      return "row \(slot.row + 1), position \(slot.column + 1): \(color.name), \(color.symbol)"
    }
    return "\(controller.game.board.count) bubbles remaining. " + bubbles.joined(separator: "; ")
  }

  private func bubble(_ color: BubbleColor, at point: BubblePoint, scale: Double) -> some View {
    Text(color.symbol)
      .font(.system(size: max(12, scale), weight: .bold))
      .foregroundStyle(.white)
      .frame(width: scale * 2, height: scale * 2)
      .background(color.tint, in: Circle())
      .overlay { Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2) }
      .overlay(alignment: .topLeading) {
        Circle().fill(.white.opacity(0.4)).frame(width: scale * 0.45, height: scale * 0.45)
          .padding(scale * 0.3).accessibilityHidden(true)
      }
      .position(x: point.x * scale, y: point.y * scale)
  }
}

extension BubbleColor {
  var symbol: String {
    switch self {
    case .red: "R"
    case .blue: "B"
    case .green: "G"
    }
  }
  var name: String {
    switch self {
    case .red: "red"
    case .blue: "blue"
    case .green: "green"
    }
  }
  var tint: Color {
    switch self {
    case .red: Color(red: 0.72, green: 0.12, blue: 0.12)
    case .blue: Color(red: 0.1, green: 0.28, blue: 0.72)
    case .green: Color(red: 0.0, green: 0.42, blue: 0.2)
    }
  }
}
