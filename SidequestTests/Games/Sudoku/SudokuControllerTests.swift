import XCTest

@testable import Sidequest

@MainActor
final class SudokuControllerTests: XCTestCase {
  func testVisibleInitialBoardHasNoAttemptAndStartDoesNotSelectOrMove() throws {
    let controller = try makeController()
    controller.selectCell(2)
    controller.enter(3)
    XCTAssertNil(controller.board)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.givens)
    controller.runtime.setVisible(true)
    XCTAssertNil(controller.board)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.givens)
    controller.runtime.start()
    XCTAssertEqual(controller.board?.cells, controller.puzzle.givens)
    XCTAssertNil(controller.selectedCell)
    controller.selectCell(2)
    controller.enter(3)
    controller.runtime.start()
    XCTAssertEqual(controller.board?.cells[2], 3)
    XCTAssertEqual(controller.selectedCell, 2)
  }

  func testSkipClearsEntriesAndSelectionAndBlocksOffscreenInput() throws {
    let controller = try makeController()
    controller.runtime.setVisible(true)
    controller.runtime.start()
    controller.selectCell(2)
    controller.enter(3)
    controller.runtime.setVisible(false)
    XCTAssertNil(controller.board)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.givens)
    XCTAssertNil(controller.selectedCell)
    controller.selectCell(4)
    controller.enter(3)
    controller.runtime.setVisible(true)
    XCTAssertNil(controller.board)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.givens)
    controller.runtime.start()
    XCTAssertEqual(controller.board?.cells, controller.puzzle.givens)
    XCTAssertNil(controller.selectedCell)
  }

  func testCompletionIsRetainedOnRevisitAndGivensCannotChange() throws {
    let controller = try makeController()
    controller.runtime.setVisible(true)
    controller.runtime.start()
    controller.selectCell(0)
    controller.enter(4)
    XCTAssertNil(controller.selectedCell)
    XCTAssertEqual(controller.board?.cells[0], 1)
    for index in 0..<16 where controller.puzzle.givens[index] == 0 {
      controller.selectCell(index)
      controller.enter(controller.puzzle.solution[index])
    }
    XCTAssertTrue(try XCTUnwrap(controller.board).isComplete)
    let phase = controller.runtime.phase
    guard case .completed(let attempt) = phase else {
      return XCTFail("Solved board must complete the runtime.")
    }
    XCTAssertEqual(controller.runtime.celebrationAttempt, attempt)
    controller.runtime.setVisible(false)
    controller.runtime.setVisible(true)
    controller.runtime.start()
    XCTAssertEqual(controller.runtime.phase, phase)
    XCTAssertNil(controller.runtime.celebrationAttempt)
    XCTAssertEqual(controller.board?.cells, controller.puzzle.solution)
    controller.enter(0)
    XCTAssertEqual(controller.board?.cells, controller.puzzle.solution)
  }

  private func makeController() throws -> SudokuController {
    SudokuController(puzzle: try XCTUnwrap(SudokuPuzzle.fixtures().first), runtime: GameRuntime())
  }
}
