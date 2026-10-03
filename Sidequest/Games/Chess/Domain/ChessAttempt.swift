enum ChessFeedback: Equatable, Sendable {
  case chooseMovingPiece
  case illegalMove
  case notCheckmate
  case checkmate
}

struct ChessAttempt: Sendable {
  let puzzle: ChessPuzzle
  private(set) var selectedSquare: ChessSquare?
  private(set) var feedback: ChessFeedback?
  private(set) var solution: ChessMove?

  init(puzzle: ChessPuzzle) {
    self.puzzle = puzzle
  }

  var isSolved: Bool { solution != nil }

  var board: [ChessSquare: ChessPiece] {
    var result = puzzle.board
    if let solution {
      result[solution.destination] = result.removeValue(forKey: solution.origin)
    }
    return result
  }

  mutating func tap(_ square: ChessSquare) {
    guard !isSolved else { return }
    if puzzle.board[square]?.side == puzzle.sideToMove {
      selectedSquare = selectedSquare == square ? nil : square
      feedback = nil
      return
    }
    guard let origin = selectedSquare else {
      feedback = .chooseMovingPiece
      return
    }
    let move = ChessMove(origin: origin, destination: square)
    selectedSquare = nil
    guard puzzle.legalMoves.contains(move) else {
      feedback = .illegalMove
      return
    }
    guard puzzle.acceptedMoves.contains(move) else {
      feedback = .notCheckmate
      return
    }
    solution = move
    feedback = .checkmate
  }
}
