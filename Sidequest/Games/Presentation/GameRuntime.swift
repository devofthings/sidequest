import Observation

/// A retained presentation owner for one card's lifecycle, never a view's local state.
@MainActor
@Observable
final class GameRuntime {
  private var lifecycle = GameLifecycle()
  @ObservationIgnored private var effectHandler: ((GameLifecycleEffect) -> Void)?
  @ObservationIgnored private let makeAttemptID: () -> GameAttemptID

  var phase: GamePhase { lifecycle.phase }
  var isVisible: Bool { lifecycle.isVisible }

  init(makeAttemptID: @escaping () -> GameAttemptID = { GameAttemptID() }) {
    self.makeAttemptID = makeAttemptID
  }

  /// Composition binds exactly once before exposing this runtime to interaction.
  /// Controllers retain the runtime; the handler must capture its controller weakly.
  func installEffectHandler(_ handler: @escaping (GameLifecycleEffect) -> Void) {
    precondition(effectHandler == nil, "A game runtime has exactly one effect owner.")
    effectHandler = handler
  }

  func setVisible(_ visible: Bool) {
    deliver(lifecycle.setVisible(visible))
  }

  func start() {
    precondition(effectHandler != nil, "Composition must bind game effects before interaction.")
    deliver(lifecycle.start(makeAttemptID: makeAttemptID))
  }

  /// Bubble-shooter replay replaces this owner's value; controllers never own a second lifecycle.
  @discardableResult
  func replay() -> Bool {
    guard isVisible, case .completed(let old) = phase else { return false }
    let fresh = makeAttemptID()
    guard fresh != old else { return false }
    lifecycle = GameLifecycle()
    _ = lifecycle.setVisible(true)
    deliver(.reset(old))
    // Reset may synchronously make the card ineligible; start still uses the core gate.
    deliver(lifecycle.start(makeAttemptID: { fresh }))
    return true
  }

  func acceptsInput(from attempt: GameAttemptID) -> Bool {
    lifecycle.acceptsInput(from: attempt)
  }

  func complete(attempt: GameAttemptID) {
    deliver(lifecycle.complete(attempt: attempt))
  }

  private func deliver(_ effect: GameLifecycleEffect?) {
    guard let effect else { return }
    guard let effectHandler else {
      preconditionFailure("Composition must bind the effect owner before a transition.")
    }
    // The core has already invalidated an ended attempt before cancellation/reset.
    effectHandler(effect)
  }
}
