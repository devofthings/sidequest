import Foundation

struct GameAttemptID: Hashable, Sendable {
  let rawValue: UUID

  init(_ rawValue: UUID = UUID()) {
    self.rawValue = rawValue
  }
}

enum GamePhase: Equatable, Sendable {
  case preview
  case playing(GameAttemptID)
  case completed(GameAttemptID)
}

/// Effects are applied by the game adapter after the lifecycle has changed.
/// A reset cancels delayed work before resetting the challenge's rules/UI.
enum GameLifecycleEffect: Equatable, Sendable {
  case start(GameAttemptID)
  case reset(GameAttemptID)
  case stop(GameAttemptID)
}

struct GameLifecycle: Equatable, Sendable {
  private(set) var phase: GamePhase = .preview
  private(set) var isVisible = false

  /// Visibility means the feed's selected card, not a view appearance callback.
  mutating func setVisible(_ visible: Bool) -> GameLifecycleEffect? {
    isVisible = visible
    guard !visible, case .playing(let attempt) = phase else { return nil }
    // Invalidate the attempt before an adapter cancels its asynchronous work.
    phase = .preview
    return .reset(attempt)
  }

  mutating func start(
    makeAttemptID: () -> GameAttemptID = { GameAttemptID() }
  ) -> GameLifecycleEffect? {
    guard isVisible, case .preview = phase else { return nil }
    let attempt = makeAttemptID()
    phase = .playing(attempt)
    return .start(attempt)
  }

  /// Every move, timer tick, and delayed result must pass this gate immediately
  /// before changing the game, including after an asynchronous suspension.
  func acceptsInput(from attempt: GameAttemptID) -> Bool {
    guard isVisible, case .playing(let current) = phase else { return false }
    return current == attempt
  }

  mutating func complete(attempt: GameAttemptID) -> GameLifecycleEffect? {
    guard acceptsInput(from: attempt) else { return nil }
    phase = .completed(attempt)
    return .stop(attempt)
  }
}
