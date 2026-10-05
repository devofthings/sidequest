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
  private let prepareBatch: GameBatchPreparation
  private let useEndless: Bool
  private var replacementLease: UUID?
  private let loadChess: @Sendable () async throws -> [ChessPuzzle]

  init(
    useEndless: Bool = true,
    prepareBatch: @escaping GameBatchPreparation = { id, sequence, seed, puzzles, ordered in
      try await GameGenerationComposition.prepare(
        sessionID: id, sequence: sequence, seed: seed,
        chessPuzzles: puzzles, ordered: ordered)
    },
    loadChess: @escaping @Sendable () async throws -> [ChessPuzzle] = {
      try await ChessPuzzleLoader.bundled()
    }
  ) {
    self.loadChess = loadChess
    self.useEndless = useEndless
    self.prepareBatch = prepareBatch
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
        news = try await newsModel.loadResolvedSnapshots()
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
        composition = try await makeComposition(news: news, puzzles: puzzles)
      } catch GameCompositionError.reservedNewsID {
        composition = try await makeComposition(news: [], puzzles: puzzles)
        message = "Saved news contains a game ID. Import a file with different snapshot IDs."
      }
      try Task.checkCancellation()
      guard isCurrent(identity) else { return }
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

  private func makeComposition(news: [NewsSnapshot], puzzles: [ChessPuzzle]) async throws
    -> FeedComposition
  {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-sidequest-integration-fixtures"),
        !ProcessInfo.processInfo.arguments.contains("-sidequest-endless-fixtures")
      {
        return try FeedComposition(news: news, chessPuzzles: puzzles)
      }
      if ProcessInfo.processInfo.arguments.contains("-sidequest-endless-fixtures") {
        return try await FeedComposition.endless(
          news: news, chessPuzzles: puzzles,
          sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000104") ?? UUID(), seed: 104,
          ordered: true, prepareBatch: prepareBatch)
      }
    #endif
    if useEndless {
      return try await FeedComposition.endless(
        news: news, chessPuzzles: puzzles, prepareBatch: prepareBatch)
    }
    return try FeedComposition(news: news, chessPuzzles: puzzles)
  }

  /// Capture the origin before readImport/load can suspend. One lease spans save and adoption.
  func beginReplacement() throws -> NewsReplacementRequest {
    guard case .ready(let origin) = state, replacementLease == nil else {
      throw NewsImportError.unavailableStorage
    }
    let identity = UUID()
    return NewsReplacementRequest { [self] news in
      guard case .ready(let current) = state, current === origin, replacementLease == nil else {
        throw CancellationError()
      }
      let candidate = try await makeComposition(news: news, puzzles: origin.chessPuzzles)
      try Task.checkCancellation()
      guard case .ready(let current) = state, current === origin, replacementLease == nil else {
        candidate.controller?.retire()
        throw CancellationError()
      }
      return PreparedNewsReplacement(
        acquire: { [self] in
          guard case .ready(let current) = state, current === origin, replacementLease == nil else {
            throw CancellationError()
          }
          replacementLease = identity
        },
        commit: { [self] in
          // acquire has reserved this boundary; durable success must be adopted even after cancellation.
          origin.controller?.retire()
          candidate.controller?.setHostAvailable(!libraryIsPresented)
          state = .ready(candidate)
        },
        release: { [self] in
          if replacementLease == identity { replacementLease = nil }
        })
    }
  }

  /// Legacy finite fixture/test transaction; production uses beginReplacement.
  /// Fallible preparation runs before persistence; returned commit cannot suspend or fail.
  func prepareReplacement(_ news: [NewsSnapshot]) throws -> @MainActor () -> Void {
    guard !useEndless, replacementLease == nil, case .ready(let current) = state else {
      throw NewsImportError.unavailableStorage
    }
    let candidate: FeedComposition
    do {
      candidate = try FeedComposition(news: news, chessPuzzles: current.chessPuzzles)
    } catch GameCompositionError.reservedNewsID {
      throw NewsImportError.invalid(
        "A snapshot ID is reserved for a game. Choose a different news ID.")
    }
    return { [self] in
      guard replacementLease == nil else { return }
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
        "-sidequest-standard-sudoku-test", "-sidequest-memory-fixtures",
        "-sidequest-chess-white-fixture",
        "-sidequest-chess-black-fixture", "-sidequest-bubble-fixtures",
      ].contains(where: arguments.contains)
    }

    func replaceFixtureSession() {
      guard replacementLease == nil, case .ready(let current) = state else { return }
      current.controller?.retire()
      state = .ready(FeedComposition(chessPuzzles: current.chessPuzzles))
    }
  #endif
}
