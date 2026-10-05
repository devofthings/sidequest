import Foundation

enum GeneratedChallenge: Sendable {
  case sudoku(SudokuPuzzle)
  case certifiedSudoku(SudokuChallenge)
  case memory(MemoryRules)
  case certifiedMemory(MemoryChallenge)
  case chess(ChessPuzzle)
  case bubble(BubbleChallenge)
}

struct GeneratedGameDescriptor: Sendable {
  let card: GameCard
  let challenge: GeneratedChallenge
}

typealias GameBatchPreparation =
  @Sendable (UUID, Int, UInt64, [ChessPuzzle], Bool) async throws -> GeneratedGameBatch

struct GeneratedGameBatch: Sendable {
  let descriptors: [GeneratedGameDescriptor]
  let nextSequence: Int

  /// Value generation explicitly runs off the UI actor and has bounded work per card.
  @concurrent static func prepare(
    sessionID: UUID, sequence: Int, seed: UInt64, chessPuzzles: [ChessPuzzle],
    ordered: Bool = false, sudokuConfiguration: SudokuConfiguration = .standard,
    mixedDifficulties: Bool = false
  ) async throws -> GeneratedGameBatch {
    #if DEBUG
      if sequence > 0,
        ProcessInfo.processInfo.arguments.contains("-sidequest-endless-slow-generation")
      {
        try await Task.sleep(for: .seconds(4))
      }
    #endif
    guard sequence >= 0, sequence <= Int.max - 8, sequence.isMultiple(of: 8) else {
      throw PreparedGameReconstruction.Failure.invalidDescriptor
    }
    guard chessPuzzles.count >= 2 else {
      throw GameCompositionError.missingChessFixture("both sides")
    }
    var random = ChallengeRandom(seed: seed &+ UInt64(sequence))
    var descriptors: [GeneratedGameDescriptor] = []
    for offset in 0..<8 {
      try Task.checkCancellation()
      let index = sequence + offset
      let occurrence = index / 4
      let kindOffset = UInt64(offset % 4)
      let tiers: [GameDifficulty] = [.easy, .medium, .hard]
      let tier = tiers[(occurrence + Int((seed &+ kindOffset) % 3)) % 3]
      var tierRandom = ChallengeRandom(
        seed: seed &+ UInt64(index) &* 0xD1B5_4A32_D192_ED03 &+ 0x5449_4552)
      let challenge: GeneratedChallenge
      let kind: GameKind
      switch offset % 4 {
      case 0:
        kind = .sudoku
        // Preserve neighboring challenges and shuffle draws from the historical batch stream.
        let mini = try SudokuGenerator.generate(using: &random)
        var sudokuRandom = ChallengeRandom(
          seed: seed &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15 &+ 0x5355_444F_4B55)
        if mixedDifficulties {
          challenge = .certifiedSudoku(
            try SudokuChallenge.generate(difficulty: tier, using: &tierRandom))
        } else if sudokuConfiguration == .mini {
          challenge = .sudoku(mini)
        } else {
          challenge = .sudoku(
            try SudokuGenerator.generate(
              configuration: .standard, maximumEmptyCells: 12, using: &sudokuRandom))
        }
      case 1:
        kind = .memory
        let legacy = MemoryRules(using: &random)
        challenge =
          mixedDifficulties
          ? .certifiedMemory(MemoryChallenge(difficulty: tier, seed: tierRandom.next()))
          : .memory(legacy)
      case 2:
        kind = .chess
        if mixedDifficulties {
          let candidates = chessPuzzles.filter { $0.challenge?.difficulty == tier }
          guard !candidates.isEmpty else { throw ChessFixtureError.invalidChallenge }
          challenge = .chess(candidates[occurrence % candidates.count])
        } else {
          challenge = .chess(chessPuzzles[(index / 4) % chessPuzzles.count])
        }
      default:
        kind = .bubbleShooter
        let legacy = try BubbleChallengeGenerator.generate(using: &random)
        if mixedDifficulties {
          let configured = try legacy.game.configured(for: tier)
          challenge = .bubble(
            BubbleChallenge(game: configured, winningAngles: legacy.winningAngles))
        } else {
          challenge = .bubble(legacy)
        }
      }
      let id = try CardID("game-\(sessionID.uuidString.lowercased())-\(index)")
      descriptors.append(
        GeneratedGameDescriptor(
          card: GameCard(id: id, kind: kind, difficulty: mixedDifficulties ? tier : nil),
          challenge: challenge))
    }
    for descriptor in descriptors {
      try Task.checkCancellation()
      try PreparedGameReconstruction.validate(descriptor, completed: nil)
    }
    if !ordered { descriptors.shuffle(using: &random) }
    try Task.checkCancellation()
    return GeneratedGameBatch(descriptors: descriptors, nextSequence: sequence + 8)
  }
}
