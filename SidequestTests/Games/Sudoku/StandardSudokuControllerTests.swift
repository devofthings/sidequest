import XCTest

@testable import Sidequest

@MainActor
final class StandardSudokuControllerTests: XCTestCase {
  func testCoordinateSelectionReadsGivensWithoutAllowingEntryAndResetsOnSkip() throws {
    let controller = try make()
    controller.selectRow(8)
    XCTAssertEqual(controller.coordinateRow, 0)
    controller.runtime.setVisible(true)
    controller.runtime.start()
    XCTAssertNil(controller.selectedCell)
    controller.selectRow(8)
    XCTAssertEqual(controller.coordinateRow, 8)
    XCTAssertNil(controller.selectedCell)
    let givens = controller.displayedBoard.cells
    controller.enter(9)
    XCTAssertEqual(controller.displayedBoard.cells, givens)
    controller.selectRow(0)
    controller.selectColumn(8)
    XCTAssertEqual(controller.selectedCell, 8)
    controller.enter(9)
    XCTAssertEqual(controller.displayedBoard.cells[8], 9)
    controller.runtime.setVisible(false)
    XCTAssertEqual(controller.displayedBoard.cells, givens)
    XCTAssertEqual(controller.coordinateRow, 0)
    XCTAssertEqual(controller.coordinateColumn, 0)
    XCTAssertNil(controller.selectedCell)
    controller.selectColumn(8)
    XCTAssertEqual(controller.coordinateColumn, 0)
  }

  func testCoordinateBoundsAndConflictCorrectionThroughNineThenClear() throws {
    let controller = try make()
    controller.runtime.setVisible(true)
    controller.runtime.start()
    controller.selectRow(-1)
    controller.selectColumn(9)
    XCTAssertNil(controller.selectedCell)
    controller.selectColumn(8)
    controller.enter(1)
    XCTAssertFalse(controller.displayedBoard.conflicts.isEmpty)
    controller.enter(9)
    XCTAssertTrue(controller.displayedBoard.conflicts.isEmpty)
    controller.enter(0)
    XCTAssertEqual(controller.displayedBoard.cells[8], 0)
    controller.selectCell(9)
    XCTAssertEqual(controller.coordinateRow, 1)
    XCTAssertEqual(controller.coordinateColumn, 0)
  }

  func testFullStandardCompletionRestoresWithoutAnotherAttempt() throws {
    let controller = try make()
    controller.runtime.setVisible(true)
    controller.runtime.start()
    for index in controller.puzzle.givens.indices where controller.puzzle.givens[index] == 0 {
      controller.selectRow(index / 9)
      controller.selectColumn(index % 9)
      controller.enter(controller.puzzle.solution[index])
    }
    XCTAssertTrue(controller.displayedBoard.isComplete)
    guard case .completed(let attempt) = controller.runtime.phase else {
      return XCTFail("All twelve real entries must complete the standard board")
    }
    controller.runtime.setVisible(false)
    controller.runtime.setVisible(true)
    controller.selectRow(0)
    controller.enter(0)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.solution)
    let restored = SudokuController(
      puzzle: controller.puzzle,
      runtime: GameRuntime(completed: attempt), completedBoard: controller.displayedBoard,
      selectedCell: controller.selectedCell)
    XCTAssertEqual(restored.displayedBoard.cells, controller.puzzle.solution)
    XCTAssertEqual(restored.coordinateRow, controller.coordinateRow)
    XCTAssertEqual(restored.coordinateColumn, controller.coordinateColumn)
    XCTAssertNil(restored.runtime.celebrationAttempt)
  }

  func testPocketGenerationCapsEditableCellsWithoutClaimingDifficulty() throws {
    for seed in UInt64(0)..<24 {
      var random = ChallengeRandom(seed: seed)
      let puzzle = try SudokuGenerator.generate(
        configuration: .standard, maximumEmptyCells: 12, using: &random)
      XCTAssertEqual(puzzle.configuration, .standard)
      XCTAssertEqual(puzzle.givens.filter { $0 == 0 }.count, 12)
      XCTAssertEqual(
        SudokuGrid.solutions(for: puzzle.givens, configuration: .standard), [puzzle.solution])
    }
    var random = ChallengeRandom(seed: 104)
    let solved = try SudokuGenerator.generate(
      configuration: .standard, maximumEmptyCells: 0, using: &random)
    XCTAssertEqual(solved.givens, solved.solution)
  }

  private func make() throws -> SudokuController {
    SudokuController(puzzle: try SudokuPuzzle.standardFixture(), runtime: GameRuntime())
  }
}
