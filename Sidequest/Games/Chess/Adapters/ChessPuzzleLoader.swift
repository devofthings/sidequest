import Foundation

enum ChessPuzzleLoader {
  private struct Fixture: Decodable {
    let id: String
    let fen: String
    let sideToMove: ChessSide
    let objective: String
    let legalMoves: [String]
    let acceptedMoves: [String]
    let challenge: ChessChallengeMetadata?
  }

  static func decode(_ data: Data, requiresChallenge: Bool = false) throws -> [ChessPuzzle] {
    let fixtures = try JSONDecoder().decode([Fixture].self, from: data)
    guard !fixtures.isEmpty else { throw ChessFixtureError.invalidPosition }
    let puzzles = try fixtures.map {
      try ChessPuzzle(
        id: $0.id, fen: $0.fen, sideToMove: $0.sideToMove, objective: $0.objective,
        legalMoves: $0.legalMoves, acceptedMoves: $0.acceptedMoves, challenge: $0.challenge)
    }
    guard !requiresChallenge || puzzles.allSatisfy({ $0.challenge != nil }) else {
      throw ChessFixtureError.invalidChallenge
    }
    guard Set(puzzles.map(\.id)).count == puzzles.count else { throw ChessFixtureError.duplicateID }
    return puzzles
  }

  @concurrent static func bundled(in bundle: Bundle = .main) async throws -> [ChessPuzzle] {
    try load(resource: "chess-puzzles", in: bundle)
  }

  @concurrent static func bundledCatalog(in bundle: Bundle = .main) async throws -> [ChessPuzzle] {
    try load(resource: "chess-challenges", in: bundle, requiresChallenge: true)
  }

  private static func load(resource: String, in bundle: Bundle, requiresChallenge: Bool = false)
    throws -> [ChessPuzzle]
  {
    try Task.checkCancellation()
    guard let url = bundle.url(forResource: resource, withExtension: "json") else {
      throw ChessFixtureError.missingResource
    }
    let data = try Data(contentsOf: url)
    try Task.checkCancellation()
    return try decode(data, requiresChallenge: requiresChallenge)
  }
}
