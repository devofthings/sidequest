struct ChessFocusArea: Codable, Equatable, Sendable {
  let fileStart: Int
  let rankStart: Int
  let size: Int

  var isValid: Bool {
    (3...5).contains(size) && (0...(8 - size)).contains(fileStart)
      && (0...(8 - size)).contains(rankStart)
  }

  func contains(_ square: ChessSquare) -> Bool {
    isValid && (fileStart..<(fileStart + size)).contains(square.file)
      && (rankStart..<(rankStart + size)).contains(square.rank)
  }
}

/// Search-choice proxies over externally certified full-board move tables, not human ratings.
struct ChessChallengeMetadata: Codable, Equatable, Sendable {
  let difficulty: GameDifficulty
  let checkingNonmates: [String]
  let focus: ChessFocusArea

  func validate(
    board: [ChessSquare: ChessPiece], sideToMove: ChessSide,
    legalMoves: Set<ChessMove>, acceptedMoves: Set<ChessMove>
  ) throws {
    let expected: GameDifficulty =
      acceptedMoves.count >= 3 ? .easy : (acceptedMoves.count == 2 ? .medium : .hard)
    let checks = checkingNonmates.compactMap(ChessMove.init)
    guard focus.isValid, difficulty == expected,
      checks.count == checkingNonmates.count, Set(checks).count == checks.count,
      Set(checks).isSubset(of: legalMoves.subtracting(acceptedMoves)),
      board.keys.allSatisfy(focus.contains),
      acceptedMoves.allSatisfy({ focus.contains($0.origin) && focus.contains($0.destination) }),
      let defender = board.first(where: { $0.value.side != sideToMove && $0.value.kind == .king })?
        .key,
      ChessSquare.displayOrder.filter({
        max(abs($0.file - defender.file), abs($0.rank - defender.rank)) <= 1
      }).allSatisfy(focus.contains)
    else { throw ChessFixtureError.invalidChallenge }
  }
}
