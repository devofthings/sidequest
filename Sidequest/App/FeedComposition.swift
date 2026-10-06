import SwiftUI

@MainActor
final class FeedComposition {
  let chessPuzzles: [ChessPuzzle]
  let session: SampleSession
  let controller: FeedController?
  private(set) var games: [CardID: ComposedGame]
  private var reconstruct: GameReconstruction = { try ComposedGame.generated($0, completed: $1) }
  private var descriptors: [CardID: GeneratedGameDescriptor] = [:]
  private var completed: [CardID: CompletedGameState] = [:]
  private var nextSequence = 0
  private var backwardSequence = 0
  private var backwardSessionID: UUID?
  private var backwardCadence: FeedNewsCadence?
  private var adoptingBatch = false
  private var generatedSessionID = UUID()
  private var generationSeed: UInt64 = 0
  private var orderedGeneration = false
  private var prepareBatch: GameBatchPreparation = { id, sequence, seed, puzzles, ordered in
    try await GameGenerationComposition.prepare(
      sessionID: id, sequence: sequence, seed: seed,
      chessPuzzles: puzzles, ordered: ordered)
  }
  private var generationTask: Task<Void, Never>?
  private var generationRequest: UUID?
  private var knownIDs = Set<CardID>()
  private var newsCadence: FeedNewsCadence?
  private var streak: DailyStreakModel?
  private var celebrations = SuccessCelebrationSequence(
    startingWith: GameFeedbackComposition.initialCelebrationStyle)

  var cachedAdapterCount: Int { games.count }
  var generatedDescriptors: [CardID: GeneratedGameDescriptor] { descriptors }

  deinit { generationTask?.cancel() }

  /// The app retains participation across imports; every newly reconstructed runtime binds once.
  func installStreak(_ streak: DailyStreakModel) {
    if let existing = self.streak {
      precondition(existing === streak)
      return
    }
    self.streak = streak
    controller?.physicalSwipeDidCommit = { [weak streak] in streak?.qualify() }
  }

  private func bindCompletion(to runtime: GameRuntime) {
    runtime.installSuccessfulCompletionHandler(
      { [weak self, weak runtime] in
        guard let self, let runtime else { return }
        streak?.qualify()
        guard let controller, controller.canNavigate, !controller.pagingIsBusy,
          case .game(let card) = controller.selectedCard,
          controller.runtimes[card.id] === runtime,
          case .completed(let attempt) = runtime.phase
        else { return }
        controller.autoContinue.start(cardID: card.id, attempt: attempt)
      }, chooseCelebration: { [weak self] in self?.celebrations.next() ?? .pop })
  }

  /// Adopt the latest story pool without rebuilding a game or changing feed history identity.
  @discardableResult
  func refreshNews(_ snapshots: [NewsSnapshot]) -> Bool {
    guard controller?.refreshNews(snapshots) == true else { return false }
    newsCadence?.refreshNews(snapshots)
    backwardCadence?.refreshNews(snapshots)
    return true
  }

  @MainActor static func endless(
    news: [NewsSnapshot], chessPuzzles: [ChessPuzzle],
    sessionID: UUID = UUID(), seed: UInt64 = UInt64.random(in: .min ... .max),
    ordered: Bool = false, bidirectional: Bool = false,
    prepareBatch: @escaping GameBatchPreparation = { id, sequence, seed, puzzles, ordered in
      try await GameGenerationComposition.prepare(
        sessionID: id, sequence: sequence, seed: seed,
        chessPuzzles: puzzles, ordered: ordered)
    },
    reconstruct: @escaping GameReconstruction = { try ComposedGame.generated($0, completed: $1) }
  ) async throws -> FeedComposition {
    let batch = try await prepareBatch(sessionID, 0, seed, chessPuzzles, ordered)
    try Task.checkCancellation()
    let cadence = FeedNewsCadence(pool: news, sessionID: sessionID)
    let prepared = try cadence.preparing(batch.descriptors.map(\.card))
    let backwardID = bidirectional ? UUID() : nil
    let backwardBatch: GeneratedGameBatch?
    let backwardPrepared: (cards: [FeedCard], next: FeedNewsCadence)?
    if let backwardID {
      backwardBatch = try await prepareBatch(backwardID, 0, seed ^ 0xBACC, chessPuzzles, ordered)
      try Task.checkCancellation()
      backwardPrepared = try FeedNewsCadence(pool: news, sessionID: backwardID)
        .preparingBackward(backwardBatch?.descriptors.map(\.card) ?? [])
    } else {
      backwardBatch = nil
      backwardPrepared = nil
    }
    let cards = (backwardPrepared?.cards ?? []) + prepared.cards
    var seen = Set<CardID>()
    for card in cards {
      guard seen.insert(card.id).inserted else {
        throw DeckConstructionError.duplicateCardID(card.id)
      }
    }
    for descriptor in batch.descriptors + (backwardBatch?.descriptors ?? []) {
      try PreparedGameReconstruction.validate(descriptor, completed: nil)
    }
    return try FeedComposition(
      cards: cards, chessPuzzles: chessPuzzles, batch: batch, cadence: prepared.next,
      sessionID: sessionID, seed: seed, ordered: ordered, prepareBatch: prepareBatch,
      reconstruct: reconstruct, backwardBatch: backwardBatch,
      backwardCadence: backwardPrepared?.next, backwardSessionID: backwardID,
      initialIndex: backwardPrepared?.cards.count ?? 0)
  }

  private init(
    cards: [FeedCard], chessPuzzles: [ChessPuzzle], batch: GeneratedGameBatch,
    cadence: FeedNewsCadence,
    sessionID: UUID, seed: UInt64, ordered: Bool, prepareBatch: @escaping GameBatchPreparation,
    reconstruct: @escaping GameReconstruction,
    backwardBatch: GeneratedGameBatch?, backwardCadence: FeedNewsCadence?,
    backwardSessionID: UUID?, initialIndex: Int
  ) throws {
    self.chessPuzzles = chessPuzzles
    session = .loaded(cards)
    games = [:]
    descriptors = Dictionary(
      uniqueKeysWithValues: (batch.descriptors + (backwardBatch?.descriptors ?? [])).map {
        ($0.card.id, $0)
      })
    self.backwardSessionID = backwardSessionID
    self.backwardCadence = backwardCadence
    backwardSequence = backwardBatch?.nextSequence ?? 0
    nextSequence = batch.nextSequence
    newsCadence = cadence
    generatedSessionID = sessionID
    generationSeed = seed
    self.prepareBatch = prepareBatch
    self.reconstruct = reconstruct
    orderedGeneration = ordered
    knownIDs = Set(cards.map(\.id))
    let feed = FeedController(
      cards: cards, runtimes: [:], isEndless: true, initialIndex: initialIndex)
    controller = feed
    feed.windowDidChange = { [weak self] cards in
      self?.prepareWindow(cards) ?? .failure(.preparationFailed)
    }
    feed.demandDidChange = { [weak self] in self?.replenishIfNeeded() }
    feed.retryReplenishment = { [weak self] in
      guard let self else { return }
      controller?.replenishmentMessage = nil
      guard controller?.reconcileWindow() != false else { return }
      replenishIfNeeded()
    }
    guard feed.reconcileWindow() else { throw PreparedGameReconstruction.Failure.invalidDescriptor }
  }

  private func prepareWindow(_ cards: [FeedCard]) -> Result<[CardID: GameRuntime], FeedWindowError>
  {
    let required = Set(cards.map(\.id))
    var staged: [CardID: ComposedGame] = [:]
    do {
      for card in cards {
        guard case .game = card, games[card.id] == nil else { continue }
        guard let descriptor = descriptors[card.id] else {
          throw PreparedGameReconstruction.Failure.invalidDescriptor
        }
        staged[card.id] = try reconstruct(descriptor, completed[card.id])
      }
    } catch {
      for game in staged.values { game.runtime.retire() }
      return .failure(.preparationFailed)
    }
    var archives = completed
    for (id, game) in games where !required.contains(id) {
      archives[id] = game.completedState
    }
    // Only a fully prepared invisible window may replace existing owners.
    for (id, game) in games where !required.contains(id) {
      game.runtime.retire()
      games[id] = nil
    }
    completed = archives
    games.merge(staged) { existing, _ in existing }
    for game in staged.values { bindCompletion(to: game.runtime) }
    return .success(games.mapValues(\.runtime))
  }

  private func adoptBatch(_ batch: GeneratedGameBatch, backward: Bool) throws {
    adoptingBatch = true
    defer { adoptingBatch = false }
    let sequence = backward ? backwardSequence : nextSequence
    guard batch.nextSequence > sequence, !batch.descriptors.isEmpty else {
      throw PreparedGameReconstruction.Failure.invalidDescriptor
    }
    var batchIDs = Set<CardID>()
    for descriptor in batch.descriptors {
      try PreparedGameReconstruction.validate(descriptor, completed: nil)
      guard batchIDs.insert(descriptor.card.id).inserted else {
        throw DeckConstructionError.duplicateCardID(descriptor.card.id)
      }
    }
    guard let cadence = backward ? backwardCadence : newsCadence else {
      throw PreparedGameReconstruction.Failure.invalidDescriptor
    }
    let prepared =
      try backward
      ? cadence.preparingBackward(batch.descriptors.map(\.card))
      : cadence.preparing(batch.descriptors.map(\.card))
    var additionIDs = knownIDs
    for card in prepared.cards {
      guard additionIDs.insert(card.id).inserted else {
        throw DeckConstructionError.duplicateCardID(card.id)
      }
    }
    let previousDescriptors = descriptors
    for descriptor in batch.descriptors { descriptors[descriptor.card.id] = descriptor }
    let accepted =
      backward
      ? controller?.prepend(prepared.cards) : controller?.append(prepared.cards)
    guard accepted == true else {
      descriptors = previousDescriptors
      throw PreparedGameReconstruction.Failure.invalidDescriptor
    }
    knownIDs = additionIDs
    if backward {
      backwardCadence = prepared.next
      backwardSequence = batch.nextSequence
    } else {
      newsCadence = prepared.next
      nextSequence = batch.nextSequence
    }
  }

  private func replenishIfNeeded() {
    guard let controller, controller.isEndless, !adoptingBatch else { return }
    guard controller.canNavigate else {
      generationTask?.cancel()
      generationTask = nil
      generationRequest = nil
      return
    }
    guard generationTask == nil, controller.replenishmentMessage == nil else { return }
    let backward = backwardSessionID != nil && (controller.selectedIndex ?? 0) <= 4
    guard backward || controller.count - (controller.selectedIndex ?? 0) - 1 <= 4 else { return }
    let request = UUID()
    generationRequest = request
    let sessionID = backward ? (backwardSessionID ?? generatedSessionID) : generatedSessionID
    let sequence = backward ? backwardSequence : nextSequence
    let seed = backward ? generationSeed ^ 0xBACC : generationSeed
    let puzzles = chessPuzzles
    let ordered = orderedGeneration
    let prepare = prepareBatch
    generationTask = Task { [weak self] in
      do {
        let batch = try await prepare(sessionID, sequence, seed, puzzles, ordered)
        try Task.checkCancellation()
        guard let self, generationRequest == request, controller.canNavigate else { return }
        // UIKit tracking starts before its drag delegate callback; consult the native owner too.
        while backward, controller.pagingIsBusy {
          try await Task.sleep(for: .milliseconds(16))
          try Task.checkCancellation()
          guard generationRequest == request, controller.canNavigate else { return }
        }
        try adoptBatch(batch, backward: backward)
        generationTask = nil
        generationRequest = nil
      } catch {
        guard let self, generationRequest == request else { return }
        generationTask = nil
        generationRequest = nil
        if !(error is CancellationError), !Task.isCancelled {
          controller.replenishmentMessage = "Could not prepare more games. Retry to continue."
        }
      }
    }
  }

  static let gameIDs: Set<String> = [
    "sample-game-sudoku", "sample-game-memory", "sample-game-bubbleShooter",
    "sample-game-chess-white", "sample-game-chess-black",
  ]

  /// Prepare the complete inactive replacement before the news store commits any bytes.
  convenience init(
    news: [NewsSnapshot], chessPuzzles: [ChessPuzzle],
    shuffle: ([FeedCard]) throws -> [FeedCard] = { cards in
      var random = SystemRandomNumberGenerator()
      return try DeckBuilder.shuffled(cards, using: &random)
    }
  ) throws {
    for snapshot in news where Self.gameIDs.contains(snapshot.id.rawValue) {
      throw GameCompositionError.reservedNewsID
    }
    let gameSpecs: [(String, GameKind)] = [
      ("sample-game-sudoku", .sudoku), ("sample-game-memory", .memory),
      ("sample-game-chess-white", .chess), ("sample-game-chess-black", .chess),
      ("sample-game-bubbleShooter", .bubbleShooter),
    ]
    let cards =
      try news.map(FeedCard.news)
      + gameSpecs.map { id, kind in
        FeedCard.game(GameCard(id: try CardID(id), kind: kind))
      }
    // Duplicate checks also apply when deterministic tests supply their own shuffle.
    var seen = Set<CardID>()
    for card in cards {
      guard seen.insert(card.id).inserted else {
        throw DeckConstructionError.duplicateCardID(card.id)
      }
    }
    let deck: [FeedCard]
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-sidequest-integration-fixtures") {
        deck = cards.sorted { $0.id.rawValue < $1.id.rawValue }
      } else {
        deck = try shuffle(cards)
      }
    #else
      deck = try shuffle(cards)
    #endif
    try self.init(cards: deck, chessPuzzles: chessPuzzles, useDemoGames: false)
  }

  private init(cards: [FeedCard], chessPuzzles: [ChessPuzzle], useDemoGames: Bool) throws {
    var games: [CardID: ComposedGame] = [:]
    for card in cards {
      if case .game(let game) = card {
        let runtime = GameFeedbackComposition.makeRuntime()
        #if DEBUG
          if useDemoGames {
            games[game.id] = .placeholder(PlaceholderGameController(runtime: GameRuntime()))
            continue
          }
        #endif
        switch game.kind {
        case .sudoku:
          let puzzles = try SudokuPuzzle.fixtures()
          guard !puzzles.isEmpty else {
            throw GameCompositionError.missingSudokuFixture
          }
          let index: Int
          #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sidequest-sudoku-test") {
              index = 0
            } else {
              index = Int.random(in: puzzles.indices)
            }
          #else
            index = Int.random(in: puzzles.indices)
          #endif
          let puzzle: SudokuPuzzle
          #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sidequest-standard-sudoku-test") {
              puzzle = try SudokuPuzzle.standardFixture()
            } else {
              puzzle = puzzles[index]
            }
          #else
            puzzle = puzzles[index]
          #endif
          games[game.id] = .sudoku(SudokuController(puzzle: puzzle, runtime: runtime))
        case .memory:
          #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-sidequest-memory-fixtures"),
              arguments.contains("-sidequest-memory-three-pairs")
                || arguments.contains("-sidequest-memory-four-pairs")
            {
              let difficulty: GameDifficulty =
                arguments.contains("-sidequest-memory-three-pairs") ? .easy : .medium
              let challenge = MemoryChallenge(difficulty: difficulty, seed: 178)
              games[game.id] = .memory(try MemoryController(runtime: runtime, challenge: challenge))
            } else if arguments.contains("-sidequest-memory-fixtures")
              || arguments.contains("-sidequest-integration-fixtures")
            {
              let board = try MemoryRules(
                symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
              games[game.id] = .memory(
                MemoryController(
                  runtime: runtime, makeBoard: { board },
                  delay: { try await Task.sleep(for: .seconds(2)) }))
            } else {
              games[game.id] = .memory(MemoryController(runtime: runtime))
            }
          #else
            games[game.id] = .memory(MemoryController(runtime: runtime))
          #endif
        case .chess:
          let historicalFixtureID: String
          switch game.id.rawValue {
          case "sample-game-chess-white": historicalFixtureID = "queen-corner-white"
          case "sample-game-chess-black": historicalFixtureID = "queen-corner-black"
          default: throw GameCompositionError.missingChessFixture(game.id.rawValue)
          }
          #if DEBUG
            let fixtureID: String
            let arguments = CommandLine.arguments
            if let index = arguments.firstIndex(of: "-sidequest-chess-catalog") {
              guard arguments.indices.contains(index + 1) else {
                throw GameCompositionError.missingChessFixture("catalog selection")
              }
              fixtureID = arguments[index + 1]
            } else {
              fixtureID = historicalFixtureID
            }
          #else
            let fixtureID = historicalFixtureID
          #endif
          guard
            let puzzle = chessPuzzles.first(where: { $0.id == fixtureID }),
            puzzle.sideToMove == (game.id.rawValue == "sample-game-chess-white" ? .white : .black)
          else {
            throw GameCompositionError.missingChessFixture(fixtureID)
          }
          games[game.id] = .chess(ChessController(puzzle: puzzle, runtime: runtime))
        case .bubbleShooter:
          let controller: BubbleShooterController
          #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sidequest-bubble-slow-shot") {
              controller = BubbleShooterController(
                runtime: runtime,
                pause: {
                  try await Task.sleep(for: .milliseconds(250))
                })
            } else {
              controller = BubbleShooterController(runtime: runtime)
            }
          #else
            controller = BubbleShooterController(runtime: runtime)
          #endif
          games[game.id] = .bubbleShooter(controller)
        }
      }
    }
    self.chessPuzzles = chessPuzzles
    session = .loaded(cards)
    controller = FeedController(cards: cards, runtimes: games.mapValues(\.runtime))
    self.games = games
    for game in games.values { bindCompletion(to: game.runtime) }
  }
  #if DEBUG
    convenience init(chessPuzzles: [ChessPuzzle]) {
      let useDemoGames: Bool
      #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        useDemoGames =
          arguments.contains("-sidequest-feed-test")
          || arguments.contains("-sidequest-feed-games-only")
          || arguments.contains("-sidequest-feed-replacement-test")
      #else
        useDemoGames = false
      #endif
      let source = SampleSession.make(includeChessVariants: !useDemoGames)
      let session: SampleSession
      #if DEBUG
        if case .loaded(let cards) = source {
          let arguments = ProcessInfo.processInfo.arguments
          if arguments.contains("-sidequest-bubble-fixtures") {
            let bubble = cards.filter { card in
              if case .game(let game) = card { return game.kind == .bubbleShooter }
              return false
            }
            let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
              if case .news = card { return true }
              return false
            }.prefix(1)
            session = .loaded(bubble + news)
          } else if arguments.contains("-sidequest-chess-white-fixture")
            || arguments.contains("-sidequest-chess-black-fixture")
          {
            let side = arguments.contains("-sidequest-chess-black-fixture") ? "black" : "white"
            let chess = cards.filter { $0.id.rawValue == "sample-game-chess-\(side)" }
            let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
              if case .news = card { return true }
              return false
            }.prefix(1)
            session = .loaded(chess + news)
          } else if arguments.contains("-sidequest-sudoku-test")
            || arguments.contains("-sidequest-standard-sudoku-test")
          {
            let sudoku = cards.filter { card in
              if case .game(let game) = card { return game.kind == .sudoku }
              return false
            }
            let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
              if case .news = card { return true }
              return false
            }.prefix(1)
            session = .loaded(sudoku + news)
          } else if arguments.contains("-sidequest-memory-fixtures") {
            let memory = cards.filter { card in
              if case .game(let game) = card { return game.kind == .memory }
              return false
            }
            let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
              if case .news = card { return true }
              return false
            }.prefix(1)
            session = .loaded(memory + news)
          } else if arguments.contains("-sidequest-feed-empty") {
            session = .loaded([])
          } else if arguments.contains("-sidequest-feed-games-only") {
            session = .loaded(
              cards.filter {
                if case .game = $0 { return true }
                return false
              })
          } else if arguments.contains("-sidequest-feed-test")
            || arguments.contains("-sidequest-feed-replacement-test")
          {
            session = .loaded(cards.sorted { $0.id.rawValue < $1.id.rawValue })
          } else {
            session = source
          }
        } else {
          session = source
        }
      #else
        session = source
      #endif
      do {
        guard case .loaded(let cards) = session else {
          self.init(failure: "Could not prepare the test session.", chessPuzzles: chessPuzzles)
          return
        }
        try self.init(cards: cards, chessPuzzles: chessPuzzles, useDemoGames: useDemoGames)
      } catch {
        self.init(
          failure: "Could not prepare games: \(error.localizedDescription)",
          chessPuzzles: chessPuzzles)
      }
    }

    private init(failure: String, chessPuzzles: [ChessPuzzle]) {
      self.chessPuzzles = chessPuzzles
      session = .failed(failure)
      controller = nil
      games = [:]
    }
  #endif

  func gameContent(_ card: GameCard, runtime: GameRuntime) -> AnyView {
    guard let game = games[card.id] else {
      preconditionFailure("Every composed game card has a retained controller.")
    }
    return game.content()
  }

  func newsContent(_ news: NewsSnapshot) -> AnyView {
    AnyView(NewsCardContent(snapshot: news))
  }
}

enum GameCompositionError: Error, LocalizedError {
  case reservedNewsID
  case missingSudokuFixture
  case missingChessFixture(String)

  var errorDescription: String? {
    switch self {
    case .reservedNewsID: "A news ID is reserved for a game. Choose a different snapshot ID."
    case .missingSudokuFixture: "The Sudoku fixture set is empty."
    case .missingChessFixture(let id): "The chess fixture for \(id) is missing."
    }
  }
}

/// The concrete adapter boundary supports controlled fallible preparation without a second owner.
typealias GameReconstruction =
  @MainActor (GeneratedGameDescriptor, CompletedGameState?) throws -> ComposedGame
