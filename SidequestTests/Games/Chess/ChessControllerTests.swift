import Foundation
import XCTest

@testable import Sidequest

final class ChessControllerTests: XCTestCase {
  @MainActor
  func testPreviewStartAndRepeatedStartDoNotMakeAMove() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let runtime = GameRuntime()
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      let queen = try queenSquare(in: puzzle)
      controller.tap(queen)
      controller.selectFile(0)
      controller.selectRank(0)
      controller.submitCoordinates()
      runtime.start()
      XCTAssertNil(controller.attempt)
      XCTAssertFalse(controller.canAcceptInput)
      runtime.setVisible(true)
      XCTAssertNil(controller.attempt)
      runtime.start()
      XCTAssertTrue(controller.canAcceptInput)
      XCTAssertNil(controller.attempt?.selectedSquare)
      XCTAssertNil(controller.attempt?.feedback)
      XCTAssertEqual(controller.attempt?.board, puzzle.board)
      controller.tap(queen)
      runtime.start()
      XCTAssertEqual(controller.attempt?.selectedSquare, queen)
      XCTAssertFalse(controller.attempt?.isSolved ?? true)
    }
  }

  @MainActor
  func testCoordinateControlsRequireExplicitSubmitAndReportWrongMoves() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let runtime = GameRuntime()
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      runtime.setVisible(true)
      runtime.start()
      controller.selectFile(0)
      controller.selectRank(0)
      XCTAssertNil(controller.destinationFile)
      XCTAssertNil(controller.destinationRank)
      let wrong = try XCTUnwrap(puzzle.legalMoves.subtracting(puzzle.acceptedMoves).first)
      controller.tap(wrong.origin)
      controller.selectFile(-1)
      controller.selectRank(8)
      XCTAssertFalse(controller.canSubmitCoordinates)
      controller.selectFile(wrong.destination.file)
      controller.selectRank(wrong.destination.rank)
      XCTAssertTrue(controller.canSubmitCoordinates)
      XCTAssertNil(controller.attempt?.feedback)
      XCTAssertEqual(controller.attempt?.board, puzzle.board)
      controller.submitCoordinates()
      XCTAssertEqual(controller.attempt?.feedback, .notCheckmate)
      XCTAssertEqual(controller.attempt?.board, puzzle.board)
      XCTAssertNil(controller.destinationFile)
      XCTAssertNil(controller.destinationRank)
      let queen = try queenSquare(in: puzzle)
      controller.tap(queen)
      controller.selectFile(queen.file)
      controller.selectRank(queen.rank)
      controller.submitCoordinates()
      XCTAssertEqual(controller.attempt?.feedback, .illegalMove)
      XCTAssertNil(controller.attempt?.selectedSquare)
      XCTAssertEqual(controller.attempt?.board, puzzle.board)
      let opponent = try XCTUnwrap(puzzle.board.first { $0.value.side != puzzle.sideToMove }?.key)
      controller.tap(opponent)
      XCTAssertEqual(controller.attempt?.feedback, .chooseMovingPiece)
      XCTAssertNil(controller.attempt?.selectedSquare)
    }
  }

  @MainActor
  func testIneligibleResetClearsSelectionCoordinatesFeedbackAndRejectsOldAttempt() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let runtime = GameRuntime()
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      runtime.setVisible(true)
      runtime.start()
      guard case .playing(let firstID) = runtime.phase else { return XCTFail("Expected playing") }
      let queen = try queenSquare(in: puzzle)
      controller.tap(queen)
      controller.selectFile(0)
      controller.selectRank(0)
      runtime.setVisible(false)
      XCTAssertNil(controller.attempt)
      XCTAssertNil(controller.destinationFile)
      XCTAssertNil(controller.destinationRank)
      XCTAssertFalse(controller.canAcceptInput)
      XCTAssertFalse(runtime.acceptsInput(from: firstID))
      controller.tap(queen)
      controller.submitCoordinates()
      runtime.setVisible(true)
      XCTAssertNil(controller.attempt)
      XCTAssertFalse(controller.canAcceptInput)
      runtime.start()
      XCTAssertNil(controller.attempt?.selectedSquare)
      XCTAssertNil(controller.attempt?.feedback)
      XCTAssertEqual(controller.attempt?.board, puzzle.board)
      XCTAssertFalse(runtime.acceptsInput(from: firstID))
      runtime.complete(attempt: firstID)
      XCTAssertFalse(controller.attempt?.isSolved ?? true)
      XCTAssertTrue(controller.canAcceptInput)
    }
  }

  @MainActor
  func testAllSolutionsKeepCompletedBoardAcrossRevisitsAndIgnoreLaterInput() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      for move in puzzle.acceptedMoves {
        let runtime = GameRuntime()
        let controller = ChessController(puzzle: puzzle, runtime: runtime)
        runtime.setVisible(true)
        runtime.start()
        controller.tap(move.origin)
        controller.selectFile(move.destination.file)
        controller.selectRank(move.destination.rank)
        controller.submitCoordinates()
        XCTAssertTrue(controller.attempt?.isSolved ?? false)
        guard case .completed(let attemptID) = runtime.phase else {
          return XCTFail("Expected solved completion")
        }
        XCTAssertEqual(runtime.celebrationAttempt, attemptID)
        XCTAssertNil(controller.attempt?.board[move.origin])
        XCTAssertEqual(controller.attempt?.board[move.destination], puzzle.board[move.origin])
        XCTAssertFalse(controller.canAcceptInput)
        let board = controller.attempt?.board
        runtime.setVisible(false)
        runtime.setVisible(true)
        runtime.start()
        controller.tap(move.destination)
        controller.selectFile(0)
        controller.selectRank(0)
        controller.submitCoordinates()
        XCTAssertEqual(controller.attempt?.board, board)
        XCTAssertEqual(controller.attempt?.solution, move)
        XCTAssertEqual(controller.attempt?.feedback, .checkmate)
        XCTAssertNil(controller.destinationFile)
        XCTAssertNil(controller.destinationRank)
        XCTAssertFalse(controller.canSubmitCoordinates)
      }
    }
  }

  private func queenSquare(in puzzle: ChessPuzzle) throws -> ChessSquare {
    try XCTUnwrap(puzzle.board.first { $0.value.kind == .queen }?.key)
  }
}
