import Foundation
import Observation

/// One owner for startup, retained fixtures, the current deck, and modal availability.
@MainActor
@Observable
final class FeedSessionState {
  enum State {
    case notStarted
    case loading(UUID)
    case ready(FeedComposition)
    case failed(String)
  }

  private(set) var state: State = .notStarted
  private(set) var libraryIsPresented = false
  private let loadChess: @Sendable () async throws -> [ChessPuzzle]

  init(
    loadChess: @escaping @Sendable () async throws -> [ChessPuzzle] = {
      try await ChessPuzzleLoader.bundled()
    }
  ) {
    self.loadChess = loadChess
  }

  func prepare(newsModel: NewsImportModel) async {
    guard case .notStarted = state else { return }
    let identity = UUID()
    state = .loading(identity)
    do {
      let puzzles = try await loadChess()
      try Task.checkCancellation()
      guard isCurrent(identity) else { return }
      #if DEBUG
        if Self.usesLegacyHarness {
          state = .ready(FeedComposition(chessPuzzles: puzzles))
          return
        }
      #endif
      let news: [NewsSnapshot]
      var message: String?
      do {
        news = try await newsModel.loadSavedSnapshots() ?? []
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        try Task.checkCancellation()
        guard isCurrent(identity) else { return }
        news = []
        message = "Could not load local news. Retry loading or import a valid JSON file."
      }
      try Task.checkCancellation()
      guard isCurrent(identity) else { return }
      let composition: FeedComposition
      do {
        composition = try FeedComposition(news: news, chessPuzzles: puzzles)
      } catch GameCompositionError.reservedNewsID {
        composition = try FeedComposition(news: [], chessPuzzles: puzzles)
        message = "Saved news contains a game ID. Import a file with different snapshot IDs."
      }
      // No suspension between validated adoption and publishing this generation.
      newsModel.adoptRestored(message == nil ? news : [], message: message)
      state = .ready(composition)
    } catch is CancellationError {
      if isCurrent(identity) { state = .notStarted }
    } catch {
      guard isCurrent(identity) else { return }
      if Task.isCancelled {
        state = .notStarted
        return
      }
      state = .failed("Could not prepare games: \(error.localizedDescription)")
    }
  }

  func cancelPreparation() {
    if case .loading = state { state = .notStarted }
  }

  func retryPreparation() {
    if case .failed = state { state = .notStarted }
  }

  func setLibraryPresented(_ presented: Bool) {
    guard case .ready(let composition) = state else { return }
    libraryIsPresented = presented
    composition.controller?.setHostAvailable(!presented)
  }

  /// Fallible preparation runs before persistence; returned commit cannot suspend or fail.
  func prepareReplacement(_ news: [NewsSnapshot]) throws -> @MainActor () -> Void {
    guard case .ready(let current) = state else { throw NewsImportError.unavailableStorage }
    let candidate: FeedComposition
    do {
      candidate = try FeedComposition(news: news, chessPuzzles: current.chessPuzzles)
    } catch GameCompositionError.reservedNewsID {
      throw NewsImportError.invalid(
        "A snapshot ID is reserved for a game. Choose a different news ID.")
    }
    return { [self] in
      if case .ready(let previous) = state { previous.controller?.retire() }
      candidate.controller?.setHostAvailable(!libraryIsPresented)
      state = .ready(candidate)
    }
  }

  private func isCurrent(_ identity: UUID) -> Bool {
    guard case .loading(let current) = state else { return false }
    return current == identity
  }

  #if DEBUG
    func fixturePreparationFailed() {
      state = .failed("Could not prepare test files. Check local storage and retry.")
    }

    static var usesLegacyHarness: Bool {
      let arguments = ProcessInfo.processInfo.arguments
      return [
        "-sidequest-news-preview", "-sidequest-feed-test", "-sidequest-feed-empty",
        "-sidequest-feed-games-only", "-sidequest-feed-replacement-test", "-sidequest-sudoku-test",
        "-sidequest-memory-fixtures", "-sidequest-chess-white-fixture",
        "-sidequest-chess-black-fixture", "-sidequest-bubble-fixtures",
      ].contains(where: arguments.contains)
    }

    func replaceFixtureSession() {
      guard case .ready(let current) = state else { return }
      current.controller?.retire()
      state = .ready(FeedComposition(chessPuzzles: current.chessPuzzles))
    }
  #endif
}
