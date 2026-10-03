import Observation
import SwiftUI

/// An explicitly provisional surface for validating the host, not game rules.
@MainActor
@Observable
final class PlaceholderGameController {
  let runtime: GameRuntime
  private(set) var interactions = 0
  private var attempt: GameAttemptID?

  init(runtime: GameRuntime) {
    self.runtime = runtime
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  func interact() {
    guard let attempt, runtime.acceptsInput(from: attempt) else { return }
    interactions += 1
  }

  func complete() {
    guard let attempt else { return }
    runtime.complete(attempt: attempt)
  }

  private func apply(_ effect: GameLifecycleEffect) {
    switch effect {
    case .start(let attempt):
      self.attempt = attempt
      interactions = 0
    case .reset:
      attempt = nil
      interactions = 0
    case .stop:
      attempt = nil
    }
  }
}

@MainActor
struct PlaceholderGameView: View {
  let controller: PlaceholderGameController

  var body: some View {
    VStack(spacing: 16) {
      Text("Game preview demo")
      Text(
        "The game is being built. This simple surface checks playing and moving through the feed."
      )
      .font(.callout)
      .foregroundStyle(.secondary)
      Text("Interactions: \(controller.interactions)")
        .accessibilityIdentifier("game.interactions")
      if case .completed = controller.runtime.phase {
        Text("Demo completed")
          .accessibilityIdentifier("game.completed")
      } else {
        Button("Interact", action: controller.interact)
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .accessibilityIdentifier("game.interact")
        Button("Complete demo", action: controller.complete)
          .buttonStyle(.bordered)
          .controlSize(.large)
          .accessibilityIdentifier("game.complete")
      }
    }
    .allowsHitTesting(controller.runtime.isVisible)
  }
}
