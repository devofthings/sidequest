import Foundation

enum ChessPuzzleLoader {
  private struct Fixture: Decodable {
    let id: String
    let fen: String
    let sideToMove: ChessSide
    let objective: String
    let legalMoves: [String]
    let acceptedMoves: [String]
  }

  static func decode(_ data: Data) throws -> [ChessPuzzle] {
    let fixtures = try JSONDecoder().decode([Fixture].self, from: data)
    guard !fixtures.isEmpty else { throw ChessFixtureError.invalidPosition }
    let puzzles = try fixtures.map {
      try ChessPuzzle(
        id: $0.id, fen: $0.fen, sideToMove: $0.sideToMove, objective: $0.objective,
        legalMoves: $0.legalMoves, acceptedMoves: $0.acceptedMoves)
    }
    guard Set(puzzles.map(\.id)).count == puzzles.count else { throw ChessFixtureError.duplicateID }
    return puzzles
  }

  static func bundled(in bundle: Bundle = .main) throws -> [ChessPuzzle] {
    guard let url = bundle.url(forResource: "chess-puzzles", withExtension: "json") else {
      throw ChessFixtureError.missingResource
    }
    return try decode(Data(contentsOf: url))
  }
}
