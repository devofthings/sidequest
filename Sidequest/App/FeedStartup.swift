import Foundation
import Observation

/// Retains one loaded fixture set and one composed session across view recomputation.
@MainActor
@Observable
final class FeedStartup {
  enum State {
    case notStarted
    case loading(UUID)
    case ready(FeedComposition)
    case failed(String)
  }

  private(set) var state: State = .notStarted
  private let loadChess: @Sendable () async throws -> [ChessPuzzle]

  init(
    loadChess: @escaping @Sendable () async throws -> [ChessPuzzle] = {
      try await ChessPuzzleLoader.bundled()
    }
  ) {
    self.loadChess = loadChess
  }

  func prepare() async {
    guard case .notStarted = state else { return }
    let identity = UUID()
    state = .loading(identity)
    do {
      let puzzles = try await loadChess()
      try Task.checkCancellation()
      guard case .loading(let current) = state, current == identity else { return }
      state = .ready(FeedComposition(chessPuzzles: puzzles))
    } catch is CancellationError {
      if case .loading(let current) = state, current == identity { state = .notStarted }
    } catch {
      guard case .loading(let current) = state, current == identity else { return }
      state = .failed("Could not prepare games: \(error.localizedDescription)")
    }
  }

  /// The root task owns cancellation; invalidate results before another appearance can retry.
  func cancelPreparation() {
    if case .loading = state { state = .notStarted }
  }

  func replaceFixtureSession() {
    guard case .ready(let current) = state else { return }
    current.controller?.retire()
    state = .ready(FeedComposition(chessPuzzles: current.chessPuzzles))
  }
}
