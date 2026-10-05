import Foundation

/// Composition selects the historical Debug format; the value generator receives it explicitly.
enum GameGenerationComposition {
  @concurrent static func prepare(
    sessionID: UUID, sequence: Int, seed: UInt64, chessPuzzles: [ChessPuzzle], ordered: Bool,
    mixedDifficulties: Bool = false
  ) async throws -> GeneratedGameBatch {
    let configuration: SudokuConfiguration
    #if DEBUG
      configuration =
        ProcessInfo.processInfo.arguments.contains("-sidequest-endless-fixtures")
        ? .mini : .standard
    #else
      configuration = .standard
    #endif
    return try await GeneratedGameBatch.prepare(
      sessionID: sessionID, sequence: sequence, seed: seed, chessPuzzles: chessPuzzles,
      ordered: ordered, sudokuConfiguration: configuration, mixedDifficulties: mixedDifficulties)
  }
}
