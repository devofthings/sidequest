import XCTest

@testable import Sidequest

final class SudokuRulesTests: XCTestCase {
  func testOriginalFixturesHaveVerifiedSolutionAndPreserveGivens() throws {
    let expected = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]
    let puzzles = try SudokuPuzzle.fixtures()
    XCTAssertEqual(puzzles.count, 2)
    for puzzle in puzzles {
      XCTAssertEqual(puzzle.solution, expected)
      var board = SudokuBoard(puzzle: puzzle)
      XCTAssertFalse(board.isComplete)
      for index in 0..<16 {
        if puzzle.givens[index] != 0 {
          XCTAssertEqual(puzzle.solution[index], puzzle.givens[index])
          XCTAssertFalse(board.setValue(0, at: index))
        } else {
          XCTAssertTrue(board.setValue(expected[index], at: index))
        }
      }
      XCTAssertTrue(board.isComplete)
      XCTAssertEqual(board.cells, expected)
      XCTAssertTrue(board.conflicts.isEmpty)
      board.reset()
      XCTAssertEqual(board.cells, puzzle.givens)
      XCTAssertFalse(board.isComplete)
    }
  }

  func testInvalidAndAmbiguousPuzzlesAreRejected() {
    XCTAssertThrowsError(try SudokuPuzzle(givens: []))
    XCTAssertThrowsError(try SudokuPuzzle(givens: [5] + Array(repeating: 0, count: 15)))
    XCTAssertThrowsError(try SudokuPuzzle(givens: [1, 1] + Array(repeating: 0, count: 14))) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .conflictingGivens)
    }
    XCTAssertThrowsError(try SudokuPuzzle(givens: Array(repeating: 0, count: 16))) {
      XCTAssertEqual($0 as? SudokuPuzzleError, .nonUniqueSolution)
    }
  }

  func testEditableCellsCanBeCorrectedAndCleared() throws {
    let puzzle = try XCTUnwrap(SudokuPuzzle.fixtures().first)
    var board = SudokuBoard(puzzle: puzzle)
    XCTAssertFalse(board.setValue(9, at: 2))
    XCTAssertFalse(board.setValue(1, at: -1))
    XCTAssertFalse(board.setValue(1, at: 16))
    XCTAssertTrue(board.setValue(1, at: 2))
    XCTAssertTrue(board.conflicts.contains(0))
    XCTAssertTrue(board.conflicts.contains(2))
    XCTAssertFalse(board.isComplete)
    XCTAssertTrue(board.setValue(3, at: 2))
    XCTAssertTrue(board.conflicts.isEmpty)
    XCTAssertTrue(board.setValue(0, at: 2))
    XCTAssertEqual(board.cells[2], 0)
  }

  func testConflictsIncludeColumnAndRegionPeers() throws {
    var board = SudokuBoard(puzzle: try XCTUnwrap(SudokuPuzzle.fixtures().first))
    board.setValue(1, at: 4)
    XCTAssertTrue(board.conflicts.isSuperset(of: [0, 4]))
    board.setValue(0, at: 4)
    board.setValue(3, at: 11)
    board.setValue(3, at: 14)
    XCTAssertTrue(board.conflicts.contains(11))
    XCTAssertTrue(board.conflicts.contains(14))
  }
}
