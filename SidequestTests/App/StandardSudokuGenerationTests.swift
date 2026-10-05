import XCTest

@testable import Sidequest

@MainActor
final class StandardSudokuGenerationTests: XCTestCase {
  func testStandardExposurePreservesHistoricalNeighborRandomDraws() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let sessionID = UUID()
    for sequence in [0, 8, 16] {
      let batch = try await GeneratedGameBatch.prepare(
        sessionID: sessionID, sequence: sequence,
        seed: 104, chessPuzzles: puzzles, ordered: true)
      var legacy = ChallengeRandom(seed: 104 &+ UInt64(sequence))
      for offset in stride(from: 0, to: 8, by: 4) {
        _ = try SudokuGenerator.generate(using: &legacy)
        let memory = MemoryRules(using: &legacy)
        let bubble = try BubbleChallengeGenerator.generate(using: &legacy)
        guard case .sudoku(let sudoku) = batch.descriptors[offset].challenge,
          case .memory(let actualMemory) = batch.descriptors[offset + 1].challenge,
          case .bubble(let actualBubble) = batch.descriptors[offset + 3].challenge
        else { return XCTFail("Batch kinds must stay compatible") }
        XCTAssertEqual(sudoku.configuration, .standard)
        XCTAssertEqual(sudoku.givens.filter { $0 == 0 }.count, 12)
        XCTAssertEqual(actualMemory, memory)
        XCTAssertEqual(actualBubble, bubble)
      }
      let expectedOrder = Array(0..<8).shuffled(using: &legacy)
      let shuffled = try await GeneratedGameBatch.prepare(
        sessionID: sessionID, sequence: sequence, seed: 104,
        chessPuzzles: puzzles, ordered: false)
      XCTAssertEqual(
        shuffled.descriptors.map(\.card.id), expectedOrder.map { batch.descriptors[$0].card.id })
      let repeated = try await GeneratedGameBatch.prepare(
        sessionID: sessionID, sequence: sequence,
        seed: 104, chessPuzzles: puzzles, ordered: true)
      for index in [0, 4] {
        guard case .sudoku(let original) = batch.descriptors[index].challenge,
          case .sudoku(let replayed) = repeated.descriptors[index].challenge
        else { return XCTFail("Expected standard puzzle") }
        XCTAssertEqual(original, replayed)
      }
    }
  }
}
