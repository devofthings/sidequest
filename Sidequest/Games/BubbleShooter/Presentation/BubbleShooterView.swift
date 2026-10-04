import SwiftUI

@MainActor
struct BubbleShooterView: View {
  let controller: BubbleShooterController
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
      Text(controller.feedback)
        .accessibilityIdentifier("bubble.feedback")
      Text("Shots: \(controller.game.shotsFired) of \(BubbleShooterGame.shotLimit)")
        .accessibilityIdentifier("bubble.shots")
      if controller.game.outcome == .playing {
        Text("Next bubble: \(controller.game.nextColor.name), \(controller.game.nextColor.symbol)")
        Text("Aim: \(controller.aimDegrees, specifier: "%.0f")°")
          .accessibilityIdentifier("bubble.angle")
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
        Button("Fire") { controller.fire() }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .frame(minHeight: 44)
          .disabled(!controller.canFire)
          .accessibilityIdentifier("bubble.fire")
      } else {
        Text(controller.game.outcome == .won ? "You won!" : "You lost")
          .font(.headline)
          .accessibilityIdentifier("bubble.outcome")
        Button("Replay") { controller.replay() }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .frame(minHeight: 44)
          .disabled(!controller.runtime.isVisible)
          .accessibilityIdentifier("bubble.replay")
      }
    }
    .allowsHitTesting(controller.runtime.isVisible)
  }

  private var board: some View {
    GeometryReader { geometry in
      let scale = geometry.size.width / BubbleGeometry.width
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.08))
        Path { path in
          let y = BubbleGeometry.center(of: BubbleSlot(row: 4, column: 0)).y * scale
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
        .stroke(.secondary, style: StrokeStyle(lineWidth: 2, dash: [4]))
        if controller.canFire {
          Path { path in
            let angle = controller.aimDegrees * .pi / 180
            let launcher = BubbleGeometry.launcher
            path.move(to: CGPoint(x: launcher.x * scale, y: launcher.y * scale))
            path.addLine(
              to: CGPoint(
                x: (launcher.x + sin(angle) * 3) * scale, y: (launcher.y - cos(angle) * 3) * scale))
          }
          .stroke(.primary, style: StrokeStyle(lineWidth: 2, dash: [3]))
        }
        ForEach(BubbleGeometry.slots, id: \.self) { slot in
          if let color = controller.game.board[slot] {
            bubble(color, at: BubbleGeometry.center(of: slot), scale: scale)
          }
        }
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
