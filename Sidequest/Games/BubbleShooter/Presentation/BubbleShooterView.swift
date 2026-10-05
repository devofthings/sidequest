import SwiftUI

@MainActor
struct BubbleShooterView: View {
  let controller: BubbleShooterController
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.sidequestGameLayoutBudget) private var layoutBudget
  @State private var chromeHeight: CGFloat = 0

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrastOverride ?? systemContrast)
  }
  private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
  private var feedbackAnimation: Animation? {
    guard !reduceMotion, controller.runtime.isVisible else { return nil }
    if case .preview = controller.runtime.phase { return nil }
    return .smooth(duration: 0.16)
  }

  private var compact: Bool { !dynamicTypeSize.isAccessibilitySize }
  private var spacing: CGFloat { compact ? 8 : 12 }
  private var boardWidth: CGFloat {
    guard compact else { return min(300, layoutBudget?.width ?? 300) }
    guard let layoutBudget, chromeHeight > 0 else { return 200 }
    return max(
      200, min(300, layoutBudget.width, (layoutBudget.height - chromeHeight - spacing) / 1.2))
  }

  var body: some View {
    VStack(spacing: spacing) {
      instructions
      board.frame(width: boardWidth, height: boardWidth * 1.2)
      status
      feedback
      actionControls
    }
    .frame(maxWidth: .infinity)
    .background(alignment: .top) {
      if compact {
        // Measure full-width stable chrome independently; the board cannot feed back into its budget.
        VStack(spacing: spacing) {
          instructions
          status
          feedback
          actionControls
        }
        .frame(maxWidth: .infinity)
        .hidden().accessibilityHidden(true).allowsHitTesting(false)
        .onGeometryChange(for: CGFloat.self) {
          $0.size.height
        } action: { height in
          if abs(chromeHeight - height) > 0.5 { chromeHeight = height }
        }
      }
    }
    .allowsHitTesting(controller.runtime.isVisible)
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private var instructions: some View {
    Text("Drag to aim · Fire to shoot")
      .font(.callout).fixedSize(horizontal: false, vertical: true)
  }

  private var feedback: some View {
    StableGameRegion {
      ZStack { ForEach(feedbackMessages, id: \.self) { Text($0) } }
    } content: {
      Text(controller.feedback).accessibilityIdentifier("bubble.feedback")
    }
    .font(compact ? .subheadline : .body)
    .monospacedDigit()
  }

  private var status: some View {
    Group {
      if compact {
        HStack(spacing: 12) {
          shots
          Spacer(minLength: 0)
          playingStatus
        }
      } else {
        VStack(spacing: 12) {
          shots
          playingStatus
        }
      }
    }
    .font(compact ? .subheadline : .body)
  }

  private var shots: some View {
    StableGameRegion {
      Text(compact ? "8/8 shots" : "Shots: 8 of 8")
    } content: {
      Text(
        compact
          ? "\(controller.game.shotsFired)/8 shots" : "Shots: \(controller.game.shotsFired) of 8"
      )
      .accessibilityLabel("Shots: \(controller.game.shotsFired) of 8")
      .accessibilityIdentifier("bubble.shots")
    }
    .monospacedDigit()
  }

  private var playingStatus: some View {
    StableGameRegion {
      ZStack {
        nextColor(reservation: true)
        Text("You won!").font(.headline)
        Text("You lost").font(.headline)
      }
    } content: {
      if isPlaying {
        nextColor(reservation: false)
      } else {
        Text(controller.game.outcome == .won ? "You won!" : "You lost")
          .font(.headline).accessibilityIdentifier("bubble.outcome")
      }
    }
  }

  private func nextColor(reservation: Bool) -> some View {
    StableGameRegion {
      ZStack {
        ForEach(BubbleColor.allCases, id: \.self) { color in
          Text(compact ? "Next: \(color.symbol)" : "Next bubble: \(color.name), \(color.symbol)")
        }
      }
    } content: {
      let color = controller.game.nextColor
      Text(compact ? "Next: \(color.symbol)" : "Next bubble: \(color.name), \(color.symbol)")
        .accessibilityLabel("Next bubble: \(color.name), \(color.symbol)")
        .accessibilityIdentifier(reservation ? "" : "bubble.next")
    }
  }

  private var actionControls: some View {
    Group {
      if compact {
        HStack(spacing: 12) {
          aimSlider
          fireButton.frame(width: 96)
        }
      } else {
        VStack(spacing: 12) {
          aimSlider
          fireButton
        }
      }
    }
  }

  private var aimSlider: some View {
    StableGameRegion {
      slider.disabled(true)
    } content: {
      if isPlaying { slider }
    }
  }

  private var slider: some View {
    BubbleAimSlider(controller: controller)
      .frame(minWidth: 44, minHeight: 44)
      .disabled(!controller.canAimOrFire)
  }

  private var fireButton: some View {
    let visibility = controller.runtime.visibilityIdentity
    return Button {
      if isPlaying { controller.fire(visibility: visibility) } else { controller.replay() }
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
    .controlSize(.large).frame(minHeight: 44)
    .disabled(isPlaying ? !controller.canAimOrFire : !controller.runtime.isVisible)
    .accessibilityIdentifier(isPlaying ? "bubble.fire" : "bubble.replay")
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
    ZStack(alignment: .bottom) {
      boardArtwork
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bubble board")
        .accessibilityValue(boardDescription)
        .accessibilityIdentifier("bubble.board")
      BubbleAimControl(controller: controller)
        .frame(height: boardWidth / 10 * BubbleAimMapping.regionHeight)
        .accessibilityHidden(!isPlaying)
    }
  }

  private var boardArtwork: some View {
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
        if let trajectory = controller.aimTrajectory {
          Path { path in
            for (index, point) in trajectory.points.enumerated() {
              let rendered = CGPoint(x: point.x * scale, y: point.y * scale)
              if index == 0 { path.move(to: rendered) } else { path.addLine(to: rendered) }
            }
          }
          .stroke(theme.ink, style: StrokeStyle(lineWidth: 2, dash: [3]))
        }
        ForEach(BubbleGeometry.slots, id: \.self) { slot in
          if let color = controller.game.board[slot] {
            bubble(color, at: BubbleGeometry.center(of: slot), scale: scale)
              .transition(
                reduceMotion ? .identity : .scale(scale: 0.6).combined(with: .opacity))
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
      .clipShape(RoundedRectangle(cornerRadius: 16))
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
      .font(.system(size: max(14, scale), weight: .bold))
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
