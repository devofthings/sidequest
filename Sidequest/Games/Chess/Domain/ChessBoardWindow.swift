/// A fixed presentation crop; the puzzle's full standard board still owns every move rule.
struct ChessBoardWindow: Equatable, Sendable {
  let files: Range<Int>
  let ranks: Range<Int>

  static let fullBoard = ChessBoardWindow(files: 0..<8, ranks: 0..<8)

  init(puzzle: ChessPuzzle) {
    let candidate: ChessBoardWindow
    switch (puzzle.id, puzzle.fen) {
    case ("queen-corner-white", "7k/5K2/6Q1/8/8/8/8/8 w - - 0 1"):
      candidate = ChessBoardWindow(files: 4..<8, ranks: 4..<8)
    case ("queen-corner-black", "8/8/8/8/8/1q6/2k5/K7 b - - 0 1"):
      candidate = ChessBoardWindow(files: 0..<4, ranks: 0..<4)
    default:
      self = Self.fullBoard
      return
    }
    // Changed answer data must never place a supplied solution outside the visible board.
    self =
      puzzle.board.keys.allSatisfy(candidate.contains)
        && puzzle.acceptedMoves.allSatisfy {
          candidate.contains($0.origin) && candidate.contains($0.destination)
        } ? candidate : Self.fullBoard
  }

  private init(files: Range<Int>, ranks: Range<Int>) {
    self.files = files
    self.ranks = ranks
  }

  var displayOrder: [ChessSquare] {
    ChessSquare.displayOrder.filter(contains)
  }

  var coordinateRange: String {
    let first =
      String("abcdefgh".dropFirst(files.lowerBound).prefix(1)) + String(ranks.lowerBound + 1)
    let last =
      String("abcdefgh".dropFirst(files.upperBound - 1).prefix(1)) + String(ranks.upperBound)
    return "\(first)–\(last)"
  }

  func contains(_ square: ChessSquare) -> Bool {
    files.contains(square.file) && ranks.contains(square.rank)
  }
}
