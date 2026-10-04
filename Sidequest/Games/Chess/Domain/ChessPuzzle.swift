enum ChessFixtureError: Error, Equatable {
  case invalidPosition
  case unsupportedObjective
  case invalidMoves
  case duplicateID
  case missingResource
}

struct ChessPuzzle: Sendable {
  let id: String
  let fen: String
  let sideToMove: ChessSide
  let objective: String
  let board: [ChessSquare: ChessPiece]
  let legalMoves: Set<ChessMove>
  let acceptedMoves: Set<ChessMove>

  init(
    id: String, fen: String, sideToMove: ChessSide, objective: String,
    legalMoves: [String], acceptedMoves: [String]
  ) throws {
    guard !id.isEmpty, !id.allSatisfy({ $0.isWhitespace }) else {
      throw ChessFixtureError.invalidPosition
    }
    guard objective == "checkmate-in-one" else { throw ChessFixtureError.unsupportedObjective }
    let fields = fen.split(separator: " ", omittingEmptySubsequences: false)
    guard fields.count == 6, fields[1] == (sideToMove == .white ? "w" : "b"),
      fields[2] == "-", fields[3] == "-",
      let halfMoves = Int(fields[4]), halfMoves >= 0,
      let fullMoves = Int(fields[5]), fullMoves >= 1
    else { throw ChessFixtureError.invalidPosition }
    let rows = fields[0].split(separator: "/", omittingEmptySubsequences: false)
    guard rows.count == 8 else { throw ChessFixtureError.invalidPosition }
    var board: [ChessSquare: ChessPiece] = [:]
    for (row, symbols) in rows.enumerated() {
      var file = 0
      for symbol in symbols {
        if let digit = symbol.asciiValue, (49...56).contains(digit) {
          file += Int(digit) - 48
        } else {
          guard let square = ChessSquare(file: file, rank: 7 - row),
            ["K", "Q", "k", "q"].contains(symbol)
          else { throw ChessFixtureError.invalidPosition }
          board[square] = ChessPiece(
            side: symbol.isUppercase ? .white : .black,
            kind: symbol.lowercased() == "k" ? .king : .queen)
          file += 1
        }
        guard file <= 8 else { throw ChessFixtureError.invalidPosition }
      }
      guard file == 8 else { throw ChessFixtureError.invalidPosition }
    }
    let kings = board.filter { $0.value.kind == .king }
    guard board.count == 3, kings.count == 2,
      kings.values.filter({ $0.side == .white }).count == 1,
      kings.values.filter({ $0.side == .black }).count == 1,
      board.values.filter({ $0.kind == .queen && $0.side == sideToMove }).count == 1
    else { throw ChessFixtureError.invalidPosition }
    let kingSquares = Array(kings.keys)
    guard
      max(
        abs(kingSquares[0].file - kingSquares[1].file),
        abs(kingSquares[0].rank - kingSquares[1].rank)) > 1
    else { throw ChessFixtureError.invalidPosition }
    let legal = legalMoves.compactMap(ChessMove.init)
    let accepted = acceptedMoves.compactMap(ChessMove.init)
    guard !legal.isEmpty, !accepted.isEmpty,
      legal.count == legalMoves.count, accepted.count == acceptedMoves.count,
      Set(legal).count == legal.count, Set(accepted).count == accepted.count,
      Set(accepted).isSubset(of: Set(legal)),
      legal.allSatisfy({ move in
        board[move.origin]?.side == sideToMove && board[move.destination]?.side != sideToMove
          && board[move.destination]?.kind != .king
      })
    else { throw ChessFixtureError.invalidMoves }
    self.id = id
    self.fen = fen
    self.sideToMove = sideToMove
    self.objective = objective
    self.board = board
    self.legalMoves = Set(legal)
    self.acceptedMoves = Set(accepted)
  }
}
