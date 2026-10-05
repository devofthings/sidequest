/// Value validation precedes any lifecycle ownership or window mutation.
enum PreparedGameReconstruction {
  enum Failure: Error, Equatable {
    case invalidDescriptor
    case incompatibleCompletion
  }

  static func validate(_ descriptor: GeneratedGameDescriptor, completed: CompletedGameState?) throws
  {
    let kind: GameKind
    let tier: GameDifficulty?
    switch descriptor.challenge {
    case .sudoku:
      kind = .sudoku
      tier = nil
    case .certifiedSudoku(let challenge):
      kind = .sudoku
      tier = challenge.difficulty
    case .memory:
      kind = .memory
      tier = nil
    case .certifiedMemory(let challenge):
      kind = .memory
      tier = challenge.difficulty
    case .chess(let puzzle):
      kind = .chess
      tier = descriptor.card.difficulty == nil ? nil : puzzle.challenge?.difficulty
    case .bubble(let challenge):
      kind = .bubbleShooter
      tier = challenge.game.difficulty
    }
    guard descriptor.card.kind == kind, descriptor.card.difficulty == tier else {
      throw Failure.invalidDescriptor
    }
    if case .bubble(let challenge) = descriptor.challenge {
      var witnessed = challenge.game
      for angle in challenge.winningAngles {
        _ = try witnessed.fire(angleRadians: angle * .pi / 180)
      }
      guard witnessed.outcome == .won else { throw Failure.invalidDescriptor }
    }
    guard let completed else { return }
    let valid: Bool
    switch (descriptor.challenge, completed.result) {
    case (.sudoku(let puzzle), .sudoku(let board, let selected)):
      valid = validSudoku(puzzle, board: board, selected: selected)
    case (.certifiedSudoku(let challenge), .sudoku(let board, let selected)):
      valid = validSudoku(challenge.puzzle, board: board, selected: selected)
    case (.memory(let rules), .memory(let restored)):
      valid = restored.isCompleted && restored.symbols == rules.symbols
    case (.certifiedMemory(let challenge), .memory(let restored)):
      valid = restored.isCompleted && restored.symbols == challenge.rules.symbols
    case (.chess(let puzzle), .chess(let restored)):
      valid =
        restored.isSolved && restored.puzzle.id == puzzle.id
        && restored.puzzle.fen == puzzle.fen && restored.puzzle.challenge == puzzle.challenge
        && restored.puzzle.legalMoves == puzzle.legalMoves
        && restored.puzzle.acceptedMoves == puzzle.acceptedMoves
    case (.bubble(let challenge), .bubble(let game, let aim, _)):
      valid =
        game.outcome != .playing && aim.isFinite
        && abs(aim) <= BubbleGeometry.maximumAngle * 180 / .pi
        && game.hasSameChallenge(as: challenge.game)
    default: valid = false
    }
    guard valid else { throw Failure.incompatibleCompletion }
  }

  private static func validSudoku(_ puzzle: SudokuPuzzle, board: SudokuBoard, selected: Int?)
    -> Bool
  {
    board.isComplete && board.puzzle == puzzle
      && (selected.map { puzzle.givens.indices.contains($0) && puzzle.givens[$0] == 0 } ?? true)
  }
}
