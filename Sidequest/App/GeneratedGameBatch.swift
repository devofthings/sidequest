import Foundation

enum GeneratedChallenge: Sendable {
  case sudoku(SudokuPuzzle)
  case memory(MemoryRules)
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
    ordered: Bool = false
  ) async throws -> GeneratedGameBatch {
    #if DEBUG
      if sequence > 0,
        ProcessInfo.processInfo.arguments.contains("-sidequest-endless-slow-generation")
      {
        try await Task.sleep(for: .seconds(4))
      }
    #endif
    guard chessPuzzles.count >= 2 else {
      throw GameCompositionError.missingChessFixture("both sides")
    }
    var random = ChallengeRandom(seed: seed &+ UInt64(sequence))
    var descriptors: [GeneratedGameDescriptor] = []
    for offset in 0..<8 {
      try Task.checkCancellation()
      let index = sequence + offset
      let challenge: GeneratedChallenge
      let kind: GameKind
      switch offset % 4 {
      case 0:
        kind = .sudoku
        challenge = .sudoku(try SudokuGenerator.generate(using: &random))
      case 1:
        kind = .memory
        challenge = .memory(MemoryRules(using: &random))
      case 2:
        kind = .chess
        challenge = .chess(chessPuzzles[(index / 4) % chessPuzzles.count])
      default:
        kind = .bubbleShooter
        challenge = .bubble(try BubbleChallengeGenerator.generate(using: &random))
      }
      let id = try CardID("game-\(sessionID.uuidString.lowercased())-\(index)")
      descriptors.append(
        GeneratedGameDescriptor(card: GameCard(id: id, kind: kind), challenge: challenge))
    }
    if !ordered { descriptors.shuffle(using: &random) }
    try Task.checkCancellation()
    return GeneratedGameBatch(descriptors: descriptors, nextSequence: sequence + 8)
  }
}
