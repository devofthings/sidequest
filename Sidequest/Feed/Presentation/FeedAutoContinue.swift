import Foundation
import Observation

/// Session-owned countdown; successful attempt identity survives cancellation and quiet revisits.
@MainActor
@Observable
final class FeedAutoContinue {
  struct Origin: Equatable {
    let cardID: CardID
    let attempt: GameAttemptID
  }

  private(set) var enabled = true
  private(set) var remaining: Int?
  private(set) var origin: Origin?
  private(set) var advanceRequested: UUID?
  @ObservationIgnored private var seen = Set<GameAttemptID>()
  @ObservationIgnored private var task: Task<Void, Never>?
  @ObservationIgnored private var request: UUID?
  @ObservationIgnored private let pause: @MainActor @Sendable () async throws -> Void

  init(
    pause: @escaping @MainActor @Sendable () async throws -> Void = {
      try await Task.sleep(for: .seconds(1))
    }
  ) { self.pause = pause }

  deinit { task?.cancel() }

  func setEnabled(_ value: Bool) {
    enabled = value
    if !value { cancel() }
  }

  func start(cardID: CardID, attempt: GameAttemptID) {
    guard seen.insert(attempt).inserted else { return }
    cancel()
    guard enabled else { return }
    origin = Origin(cardID: cardID, attempt: attempt)
    remaining = 3
    let identity = UUID()
    request = identity
    let pause = pause
    task = Task { [weak self] in
      do {
        for tick in [2, 1, 0] {
          try await pause()
          try Task.checkCancellation()
          guard let self, request == identity, enabled else { return }
          remaining = tick
        }
        guard let self, request == identity else { return }
        advanceRequested = identity
        task = nil
      } catch {
        guard let self, request == identity else { return }
        cancel()
      }
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
    request = nil
    remaining = nil
    origin = nil
    advanceRequested = nil
  }
}
