import Foundation

/// Session history keeps only completed rule values, never a controller, task, or view.
struct CompletedGameState {
  enum Result {
    case sudoku(SudokuBoard, selectedCell: Int?)
    case memory(MemoryRules)
    case chess(ChessAttempt)
    case bubble(BubbleShooterGame, aim: Double, feedback: String)
  }
  let attempt: GameAttemptID
  let result: Result
}

extension ComposedGame {
  var completedState: CompletedGameState? {
    guard case .completed(let attempt) = runtime.phase else { return nil }
    let result: CompletedGameState.Result
    switch self {
    #if DEBUG
      case .placeholder: return nil
    #endif
    case .sudoku(let game):
      guard let board = game.board else { return nil }
      result = .sudoku(board, selectedCell: game.selectedCell)
    case .memory(let game):
      guard let rules = game.rules else { return nil }
      result = .memory(rules)
    case .chess(let game):
      guard let value = game.attempt else { return nil }
      result = .chess(value)
    case .bubbleShooter(let game):
      result = .bubble(game.game, aim: game.aimDegrees, feedback: game.feedback)
    }
    return CompletedGameState(attempt: attempt, result: result)
  }

  static func generated(_ descriptor: GeneratedGameDescriptor, completed: CompletedGameState?)
    throws -> ComposedGame
  {
    try PreparedGameReconstruction.validate(descriptor, completed: completed)
    let runtime = GameFeedbackComposition.makeRuntime(completed: completed?.attempt)
    switch descriptor.challenge {
    case .sudoku(let puzzle):
      if case .sudoku(let board, let selected)? = completed?.result {
        return .sudoku(
          SudokuController(
            puzzle: puzzle, runtime: runtime, completedBoard: board, selectedCell: selected))
      }
      return .sudoku(SudokuController(puzzle: puzzle, runtime: runtime))
    case .certifiedSudoku(let challenge):
      let restored: SudokuBoard?
      let selected: Int?
      if case .sudoku(let board, let cell)? = completed?.result {
        restored = board
        selected = cell
      } else {
        restored = nil
        selected = nil
      }
      return .sudoku(
        SudokuController(
          challenge: challenge, runtime: runtime, completedBoard: restored, selectedCell: selected))
    case .certifiedMemory(let challenge):
      let restored: MemoryRules?
      if case .memory(let value)? = completed?.result { restored = value } else { restored = nil }
      return .memory(
        try MemoryController(runtime: runtime, challenge: challenge, completedRules: restored))
    case .memory(let rules):
      let restored: MemoryRules?
      if case .memory(let value)? = completed?.result { restored = value } else { restored = nil }
      return .memory(
        MemoryController(runtime: runtime, completedRules: restored, makeBoard: { rules }))
    case .chess(let puzzle):
      let restored: ChessAttempt?
      if case .chess(let value)? = completed?.result { restored = value } else { restored = nil }
      return .chess(ChessController(puzzle: puzzle, runtime: runtime, completedAttempt: restored))
    case .bubble(let challenge):
      if case .bubble(let game, let aim, let feedback)? = completed?.result {
        return .bubbleShooter(
          bubbleController(
            runtime: runtime, game: game, completedAim: aim, completedFeedback: feedback))
      }
      return .bubbleShooter(bubbleController(runtime: runtime, game: challenge.game))
    }
  }
  private static func bubbleController(
    runtime: GameRuntime, game: BubbleShooterGame,
    completedAim: Double = 0, completedFeedback: String? = nil
  ) -> BubbleShooterController {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-sidequest-bubble-slow-shot") {
        return BubbleShooterController(
          runtime: runtime, game: game, completedAim: completedAim,
          completedFeedback: completedFeedback,
          pause: { try await Task.sleep(for: .milliseconds(250)) })
      }
    #endif
    return BubbleShooterController(
      runtime: runtime, game: game, completedAim: completedAim,
      completedFeedback: completedFeedback)
  }

}
