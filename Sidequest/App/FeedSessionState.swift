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
  private let loadLiveNews: (@Sendable () async throws -> [NewsSnapshot])?
  private var liveNewsEnabled: Bool
  private var liveNewsTask: Task<Void, Never>?
  private var liveNewsRequest: UUID?
  private var newsSceneIsActive = false
  var usesLiveNews: Bool { liveNewsEnabled }

  private let bidirectional: Bool
  private let loadChess: @Sendable () async throws -> [ChessPuzzle]

  init(
    useEndless: Bool = true, bidirectional: Bool = true,
    loadLiveNews: (@Sendable () async throws -> [NewsSnapshot])? = nil,
    prepareBatch: @escaping GameBatchPreparation = { id, sequence, seed, puzzles, ordered in
      try await GameGenerationComposition.prepare(
        sessionID: id, sequence: sequence, seed: seed,
        chessPuzzles: puzzles, ordered: ordered)
    },
    loadChess: @escaping @Sendable () async throws -> [ChessPuzzle] = {
      try await ChessPuzzleLoader.bundled()
    }
  ) {
    self.loadLiveNews = loadLiveNews
    liveNewsEnabled = loadLiveNews != nil
    self.loadChess = loadChess
    self.useEndless = useEndless
    self.bidirectional = bidirectional
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
        news = liveNewsEnabled ? [] : try await newsModel.loadResolvedSnapshots()
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
      if ProcessInfo.processInfo.arguments.contains("-sidequest-mixed-difficulties-test") {
        return try await FeedComposition.endless(
          news: news, chessPuzzles: puzzles,
          sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000201") ?? UUID(),
          seed: 201, ordered: true, prepareBatch: prepareBatch)
      }
      if ProcessInfo.processInfo.arguments.contains("-sidequest-integration-fixtures"),
        !ProcessInfo.processInfo.arguments.contains("-sidequest-endless-fixtures")
      {
        return try FeedComposition(news: news, chessPuzzles: puzzles)
      }
      if ProcessInfo.processInfo.arguments.contains("-sidequest-endless-fixtures") {
        return try await FeedComposition.endless(
          news: news, chessPuzzles: puzzles,
          sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000104") ?? UUID(), seed: 104,
          ordered: true,
          bidirectional: ProcessInfo.processInfo.arguments.contains(
            "-sidequest-bidirectional-test"),
          prepareBatch: prepareBatch)
      }
    #endif
    if useEndless {
      return try await FeedComposition.endless(
        news: news, chessPuzzles: puzzles, bidirectional: bidirectional, prepareBatch: prepareBatch)
    }
    return try FeedComposition(news: news, chessPuzzles: puzzles)
  }

  /// Activation owns the request; news adoption never replaces the game session.
  func setNewsSceneActive(_ active: Bool, newsModel: NewsImportModel) {
    let becameActive = active && !newsSceneIsActive
    newsSceneIsActive = active
    if !active { stopLiveNews() }
    if becameActive { refreshLiveNews(newsModel: newsModel) }
  }

  @discardableResult
  func refreshLiveNews(newsModel: NewsImportModel) -> Task<Void, Never>? {
    if let liveNewsTask { return liveNewsTask }
    guard liveNewsEnabled, newsSceneIsActive, liveNewsTask == nil,
      replacementLease == nil, let loadLiveNews, case .ready(let origin) = state
    else { return nil }
    let identity = UUID()
    liveNewsRequest = identity
    liveNewsTask = Task { [weak self] in
      defer {
        if let self, liveNewsRequest == identity {
          liveNewsTask = nil
          liveNewsRequest = nil
        }
      }
      do {
        let snapshots = try await loadLiveNews()
        try Task.checkCancellation()
        guard let self, liveNewsRequest == identity, liveNewsEnabled,
          newsSceneIsActive, replacementLease == nil,
          case .ready(let current) = state, current === origin
        else { return }
        if origin.refreshNews(snapshots) {
          newsModel.adoptRestored(snapshots)
        }
      } catch is CancellationError {
        // Cancellation preserves the last valid feed.
      } catch {
        guard let self, !Task.isCancelled, liveNewsRequest == identity,
          liveNewsEnabled, newsSceneIsActive, replacementLease == nil,
          case .ready(let current) = state, current === origin
        else { return }
        newsModel.showLiveRefreshError()
      }
    }
    return liveNewsTask
  }

  private func stopLiveNews() {
    liveNewsRequest = nil
    liveNewsTask?.cancel()
    liveNewsTask = nil
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
          stopLiveNews()
          liveNewsEnabled = false
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

    nonisolated static var usesHistoricalGeneration: Bool {
      let arguments = ProcessInfo.processInfo.arguments
      return arguments.contains("-sidequest-endless-fixtures")
        || arguments.contains("-sidequest-integration-fixtures")
        || usesLegacyHarness
    }

    nonisolated static var usesLegacyHarness: Bool {
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
