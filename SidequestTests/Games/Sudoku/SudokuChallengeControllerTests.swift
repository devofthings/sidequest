import XCTest

@testable import Sidequest

@MainActor
final class SudokuChallengeControllerTests: XCTestCase {
  func testFirstInputResetCompletionAndQuietRestorationRetainCertificate() throws {
    for challenge in try SudokuChallenge.catalog() {
      let runtime = GameRuntime(activationPolicy: .firstInteraction)
      let controller = SudokuController(challenge: challenge, runtime: runtime)
      let first = try XCTUnwrap(challenge.puzzle.givens.firstIndex(of: 0))
      controller.selectCell(first)
      XCTAssertNil(controller.board)
      runtime.setVisible(true)
      controller.selectCell(first)
      XCTAssertEqual(controller.selectedCell, first)
      controller.enter(challenge.puzzle.solution[first])
      runtime.setVisible(false)
      XCTAssertEqual(controller.displayedBoard.cells, challenge.puzzle.givens)
      XCTAssertEqual(controller.challenge, challenge)
      runtime.setVisible(true)
      for index in challenge.puzzle.givens.indices where challenge.puzzle.givens[index] == 0 {
        controller.selectCell(index)
        controller.enter(challenge.puzzle.solution[index])
      }
      XCTAssertTrue(controller.displayedBoard.isComplete)
      guard case .completed(let attempt) = runtime.phase else {
        return XCTFail("Certified board must complete through real accepted input")
      }
      let restored = SudokuController(
        challenge: challenge,
        runtime: GameRuntime(completed: attempt, activationPolicy: .firstInteraction),
        completedBoard: controller.displayedBoard,
        selectedCell: controller.selectedCell)
      restored.runtime.setVisible(true)
      restored.selectCell(first)
      restored.enter(0)
      XCTAssertEqual(restored.challenge, challenge)
      XCTAssertEqual(restored.displayedBoard.cells, challenge.puzzle.solution)
      XCTAssertNil(restored.runtime.celebrationAttempt)
    }
  }
}
