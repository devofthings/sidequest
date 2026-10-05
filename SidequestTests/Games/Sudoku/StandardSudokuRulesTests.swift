import XCTest

@testable import Sidequest

final class StandardSudokuRulesTests: XCTestCase {
  private var solved: [Int] {
    (0..<9).flatMap { row in (0..<9).map { column in (row * 3 + row / 3 + column) % 9 + 1 } }
  }

  func testFormatsRequireExplicitCellAndDigitContracts() throws {
    XCTAssertThrowsError(try SudokuPuzzle(givens: solved)) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .invalidCellCount)
    }
    XCTAssertThrowsError(
      try SudokuPuzzle(givens: Array(repeating: 0, count: 16), configuration: .standard)
    ) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .invalidCellCount)
    }
    var invalid = solved
    invalid[0] = 10
    XCTAssertThrowsError(try SudokuPuzzle(givens: invalid, configuration: .standard)) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .invalidValue)
    }
    let puzzle = try SudokuPuzzle(givens: solved, configuration: .standard)
    XCTAssertEqual(puzzle.configuration, .standard)
    XCTAssertEqual(puzzle.solution, solved)
  }

  func testStandardRegionsDetectPeersBeyondRowsAndColumns() {
    XCTAssertTrue(SudokuGrid.arePeers(0, 10, configuration: .standard))
    XCTAssertFalse(SudokuGrid.arePeers(0, 30, configuration: .standard))
    var cells = Array(repeating: 0, count: 81)
    cells[0] = 9
    cells[10] = 9
    XCTAssertEqual(SudokuGrid.conflicts(in: cells, configuration: .standard), [0, 10])
    XCTAssertThrowsError(try SudokuPuzzle(givens: cells, configuration: .standard)) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .conflictingGivens)
    }
  }

  func testAmbiguityAndIncompleteSearchCannotProveUniqueness() {
    let empty = Array(repeating: 0, count: 81)
    let ambiguous = SudokuGrid.search(for: empty, configuration: .standard)
    XCTAssertTrue(ambiguous.isExhaustive)
    XCTAssertEqual(ambiguous.solutions.count, 2)
    XCTAssertThrowsError(try SudokuPuzzle(givens: empty, configuration: .standard)) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .nonUniqueSolution)
    }
    var almostSolved = solved
    almostSolved[0] = 0
    let incomplete = SudokuGrid.search(for: almostSolved, configuration: .standard, nodeLimit: 1)
    XCTAssertFalse(incomplete.isExhaustive)
    XCTAssertTrue(incomplete.solutions.isEmpty)
    let complete = SudokuGrid.search(for: almostSolved, configuration: .standard, nodeLimit: 2)
    XCTAssertTrue(complete.isExhaustive)
    XCTAssertEqual(complete.solutions, [solved])
    let partialWithSolution = SudokuGrid.search(
      for: Array(repeating: 0, count: 16), configuration: .mini, nodeLimit: 17)
    XCTAssertEqual(partialWithSolution.solutions.count, 1)
    XCTAssertFalse(partialWithSolution.isExhaustive)
  }

  func testConflictFreeUnsolvableStandardGivensAreRejected() {
    var givens = solved
    givens[0] = 0
    givens[9] = 1
    givens[15] = 0
    XCTAssertTrue(SudokuGrid.conflicts(in: givens, configuration: .standard).isEmpty)
    let result = SudokuGrid.search(for: givens, configuration: .standard)
    XCTAssertTrue(result.isExhaustive)
    XCTAssertTrue(result.solutions.isEmpty)
    XCTAssertThrowsError(try SudokuPuzzle(givens: givens, configuration: .standard)) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .nonUniqueSolution)
    }
  }

  func testStandardEntryAllowsNineAndKeepsGivensImmutable() throws {
    var givens = solved
    givens[8] = 0
    let puzzle = try SudokuPuzzle(givens: givens, configuration: .standard)
    var board = SudokuBoard(puzzle: puzzle)
    XCTAssertFalse(board.setValue(10, at: 8))
    XCTAssertFalse(board.setValue(0, at: 0))
    XCTAssertTrue(board.setValue(1, at: 8))
    XCTAssertTrue(board.conflicts.contains(8))
    XCTAssertFalse(board.isComplete)
    XCTAssertTrue(board.setValue(9, at: 8))
    XCTAssertTrue(board.isComplete)
    XCTAssertTrue(board.conflicts.isEmpty)
    board.reset()
    XCTAssertEqual(board.cells, givens)
  }

  func testGeneratedStandardPuzzlesAreDeterministicUniqueAndDistinct() throws {
    var distinct = Set<[Int]>()
    for seed in 0..<24 {
      var random = ChallengeRandom(seed: UInt64(seed))
      let puzzle = try SudokuGenerator.generate(configuration: .standard, using: &random)
      var repeated = ChallengeRandom(seed: UInt64(seed))
      XCTAssertEqual(
        try SudokuGenerator.generate(configuration: .standard, using: &repeated), puzzle)
      XCTAssertEqual(puzzle.configuration, .standard)
      XCTAssertEqual(puzzle.givens.count, 81)
      XCTAssertGreaterThanOrEqual(puzzle.givens.filter { $0 != 0 }.count, 40)
      XCTAssertGreaterThan(puzzle.givens.filter { $0 == 0 }.count, 20)
      XCTAssertEqual(
        SudokuGrid.solutions(for: puzzle.givens, configuration: .standard), [puzzle.solution])
      for row in 0..<9 {
        XCTAssertEqual(Set(puzzle.solution[(row * 9)..<(row * 9 + 9)]), Set(1...9))
        XCTAssertEqual(Set((0..<9).map { puzzle.solution[$0 * 9 + row] }), Set(1...9))
      }
      for region in 0..<9 {
        let values = (0..<9).map { offset in
          puzzle.solution[(region / 3 * 3 + offset / 3) * 9 + region % 3 * 3 + offset % 3]
        }
        XCTAssertEqual(Set(values), Set(1...9))
      }
      distinct.insert(puzzle.givens)
    }
    XCTAssertGreaterThan(distinct.count, 20)
  }

  func testExplicitMiniGenerationPreservesRandomStreamAndFrozenBoard() throws {
    for seed in 0..<24 {
      var legacy = ChallengeRandom(seed: UInt64(seed))
      var explicit = ChallengeRandom(seed: UInt64(seed))
      let puzzle = try SudokuGenerator.generate(using: &legacy)
      XCTAssertEqual(try SudokuGenerator.generate(configuration: .mini, using: &explicit), puzzle)
      XCTAssertEqual(legacy.next(), explicit.next())
      XCTAssertEqual(puzzle.configuration, .mini)
      XCTAssertEqual(puzzle.givens.count, 16)
    }
  }
}
