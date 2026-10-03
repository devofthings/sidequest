import Foundation
import Observation

@MainActor
@Observable
final class MemoryController {
  let runtime: GameRuntime
  private(set) var rules: MemoryRules?
  @ObservationIgnored private let makeBoard: () -> MemoryRules
  @ObservationIgnored private let delay: @MainActor @Sendable () async throws -> Void
  @ObservationIgnored private var mismatchTask: Task<Void, Never>?

  init(
    runtime: GameRuntime,
    makeBoard: @escaping () -> MemoryRules = {
      var random = SystemRandomNumberGenerator()
      return MemoryRules(using: &random)
    },
    delay: @escaping @MainActor @Sendable () async throws -> Void = {
      try await Task.sleep(for: .milliseconds(700))
    }
  ) {
    self.runtime = runtime
    self.makeBoard = makeBoard
    self.delay = delay
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  deinit { mismatchTask?.cancel() }

  func flip(_ index: Int) {
    guard case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt),
      var board = rules
    else { return }
    let result = board.flip(index)
    guard result != .ignored else { return }
    rules = board
    switch result {
    case .mismatch: concealAfterDelay(attempt: attempt)
    case .completed: runtime.complete(attempt: attempt)
    case .ignored, .revealed, .matched: break
    }
  }

  private func apply(_ effect: GameLifecycleEffect) {
    mismatchTask?.cancel()
    mismatchTask = nil
    switch effect {
    case .start: rules = makeBoard()
    case .reset: rules = nil
    case .stop: break
    }
  }

  private func concealAfterDelay(attempt: GameAttemptID) {
    mismatchTask?.cancel()
    let delay = delay
    mismatchTask = Task { @MainActor [weak self] in
      do { try await delay() } catch {
        // A failed delay must not leave a current mismatch permanently locked.
        // Cancellation and stale attempts remain ineligible below.
      }
      guard !Task.isCancelled, let self, self.runtime.acceptsInput(from: attempt) else { return }
      self.rules?.concealMismatch()
      self.mismatchTask = nil
    }
  }
}
