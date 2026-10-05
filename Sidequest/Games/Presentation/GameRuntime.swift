import Observation

/// A retained presentation owner for one card's lifecycle, never a view's local state.
@MainActor
@Observable
final class GameRuntime {
  private var lifecycle: GameLifecycle
  private var isRetired = false
  private(set) var celebrationAttempt: GameAttemptID?
  @ObservationIgnored private var celebrationTask: Task<Void, Never>?
  @ObservationIgnored private let successHaptic: @MainActor () -> Void
  @ObservationIgnored private let celebrationDelay: @MainActor @Sendable () async throws -> Void
  @ObservationIgnored private var effectHandler: ((GameLifecycleEffect) -> Void)?
  @ObservationIgnored private let makeAttemptID: () -> GameAttemptID

  var phase: GamePhase { lifecycle.phase }
  var isVisible: Bool { lifecycle.isVisible }

  init(
    completed: GameAttemptID? = nil,
    successHaptic: @escaping @MainActor () -> Void = SuccessHaptic.play,
    celebrationDelay: @escaping @MainActor @Sendable () async throws -> Void = {
      try await Task.sleep(for: .milliseconds(1500))
    },
    makeAttemptID: @escaping () -> GameAttemptID = { GameAttemptID() }
  ) {
    lifecycle = GameLifecycle(completed: completed)
    self.makeAttemptID = makeAttemptID
    self.successHaptic = successHaptic
    self.celebrationDelay = celebrationDelay
  }

  deinit { celebrationTask?.cancel() }

  /// Composition binds exactly once before exposing this runtime to interaction.
  /// Controllers retain the runtime; the handler must capture its controller weakly.
  func installEffectHandler(_ handler: @escaping (GameLifecycleEffect) -> Void) {
    precondition(effectHandler == nil, "A game runtime has exactly one effect owner.")
    effectHandler = handler
  }

  func setVisible(_ visible: Bool) {
    guard !isRetired else { return }
    if !visible { cancelCelebration() }
    deliver(lifecycle.setVisible(visible))
  }

  func start() {
    guard !isRetired else { return }
    precondition(effectHandler != nil, "Composition must bind game effects before interaction.")
    deliver(lifecycle.start(makeAttemptID: makeAttemptID))
  }

  /// Bubble-shooter replay replaces this owner's value; controllers never own a second lifecycle.
  @discardableResult
  func replay() -> Bool {
    guard !isRetired, isVisible, case .completed(let old) = phase else { return false }
    let fresh = makeAttemptID()
    guard fresh != old else { return false }
    cancelCelebration()
    lifecycle = GameLifecycle()
    _ = lifecycle.setVisible(true)
    deliver(.reset(old))
    // Reset may synchronously make the card ineligible; start still uses the core gate.
    deliver(lifecycle.start(makeAttemptID: { fresh }))
    return true
  }

  func acceptsInput(from attempt: GameAttemptID) -> Bool {
    !isRetired && lifecycle.acceptsInput(from: attempt)
  }

  /// Controllers distinguish a solved/won attempt from terminal failure. Rendering never emits feedback.
  func complete(attempt: GameAttemptID, successful: Bool = false) {
    guard acceptsInput(from: attempt), let effect = lifecycle.complete(attempt: attempt) else {
      return
    }
    deliver(effect)
    // A synchronous stop handler may hide or retire this card before feedback is delivered.
    guard successful, !isRetired, isVisible, phase == .completed(attempt) else { return }
    celebrationAttempt = attempt
    let delay = celebrationDelay
    celebrationTask = Task { @MainActor [weak self] in
      do { try await delay() } catch {
        // An eligible failed presentation delay removes the decoration; game results are unchanged.
      }
      guard !Task.isCancelled, let self, self.isVisible,
        self.celebrationAttempt == attempt, self.phase == .completed(attempt)
      else { return }
      self.celebrationAttempt = nil
      self.celebrationTask = nil
    }
    successHaptic()
  }

  private func cancelCelebration() {
    celebrationTask?.cancel()
    celebrationTask = nil
    celebrationAttempt = nil
  }

  /// Evicted owners never accept visibility, replay, or input again, even through stale views.
  func retire() {
    guard !isRetired else { return }
    cancelCelebration()
    deliver(lifecycle.setVisible(false))
    isRetired = true
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
