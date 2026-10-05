import XCTest

@testable import Sidequest

@MainActor
final class GameInteractionFeedbackTests: XCTestCase {
  func testOnlyCurrentVisibleAttemptCanEmitAndRapidEventsAreSuppressed() throws {
    var haptics = 0
    var now = 10.0
    let runtime = GameRuntime(interactionHaptic: { haptics += 1 }, interactionTime: { now })
    runtime.installEffectHandler { _ in }
    runtime.feedbackForInteraction(attempt: GameAttemptID())
    let old = try start(runtime)
    runtime.feedbackForInteraction(attempt: old)
    now += 0.05
    runtime.feedbackForInteraction(attempt: old)
    XCTAssertEqual(haptics, 1)
    now += 0.2
    runtime.feedbackForInteraction(attempt: old)
    XCTAssertEqual(haptics, 2)
    runtime.setVisible(false)
    runtime.feedbackForInteraction(attempt: old)
    let fresh = try start(runtime)
    runtime.feedbackForInteraction(attempt: old)
    runtime.feedbackForInteraction(attempt: fresh)
    XCTAssertEqual(haptics, 3, "A reset attempt does not inherit the old cooldown.")
    runtime.complete(attempt: fresh)
    runtime.feedbackForInteraction(attempt: fresh)
    runtime.setVisible(false)
    runtime.setVisible(true)
    runtime.feedbackForInteraction(attempt: fresh)
    XCTAssertEqual(haptics, 3)
  }

  func testRetiredAndRestoredCompletedOwnersRemainQuiet() throws {
    var haptics = 0
    let runtime = GameRuntime(interactionHaptic: { haptics += 1 })
    runtime.installEffectHandler { _ in }
    let attempt = try start(runtime)
    runtime.retire()
    runtime.setVisible(true)
    runtime.feedbackForInteraction(attempt: attempt)
    let restored = GameRuntime(completed: attempt, interactionHaptic: { haptics += 1 })
    restored.installEffectHandler { _ in }
    restored.setVisible(true)
    restored.feedbackForInteraction(attempt: attempt)
    XCTAssertEqual(haptics, 0)
  }

  func testSudokuOnlyChangedEntriesAndCorrectionsEmitUntilFinalSuccess() throws {
    var haptics = 0
    var successes = 0
    var now = 0.0
    let runtime = GameRuntime(
      interactionHaptic: { haptics += 1 }, interactionTime: { now },
      successHaptic: { successes += 1 })
    let puzzle = try XCTUnwrap(SudokuPuzzle.fixtures().first)
    let controller = SudokuController(puzzle: puzzle, runtime: runtime)
    controller.selectCell(2)
    controller.enter(3)
    _ = try start(runtime)
    controller.selectCell(0)
    controller.enter(4)
    controller.selectCell(2)
    XCTAssertEqual(haptics, 0)
    controller.enter(3)
    XCTAssertEqual(haptics, 1)
    now += 1
    controller.enter(3)
    controller.enter(9)
    XCTAssertEqual(haptics, 1)
    controller.enter(1)
    XCTAssertFalse(try XCTUnwrap(controller.board).conflicts.isEmpty)
    XCTAssertEqual(haptics, 2)
    now += 1
    controller.enter(0)
    XCTAssertEqual(haptics, 3)
    let editable = puzzle.givens.indices.filter { puzzle.givens[$0] == 0 }
    for index in editable {
      now += 1
      controller.selectCell(index)
      controller.enter(puzzle.solution[index])
    }
    XCTAssertEqual(haptics, 3 + editable.count - 1)
    XCTAssertEqual(
      successes, 1, "The final entry receives success, without an interaction duplicate.")
    controller.enter(0)
    XCTAssertEqual(successes, 1)
  }

  func testMemoryMatchingIsTactileButRevealsAndFinalPairDoNotDuplicate() throws {
    var haptics = 0
    var successes = 0
    var now = 0.0
    let runtime = GameRuntime(
      interactionHaptic: { haptics += 1 }, interactionTime: { now },
      successHaptic: { successes += 1 })
    let board = try MemoryRules(symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
    let controller = MemoryController(runtime: runtime, makeBoard: { board })
    controller.flip(0)
    _ = try start(runtime)
    for index in stride(from: 0, to: 12, by: 2) {
      now += 1
      controller.flip(index)
      XCTAssertEqual(haptics, index / 2)
      controller.flip(index + 1)
    }
    XCTAssertEqual(haptics, 5)
    XCTAssertEqual(successes, 1)
    controller.flip(0)
    runtime.setVisible(false)
    runtime.setVisible(true)
    controller.flip(1)
    XCTAssertEqual(haptics, 5)
    XCTAssertEqual(successes, 1)
  }

  func testChessAcceptedMoveUsesOnlyExistingSuccessFeedback() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      var haptics = 0
      var successes = 0
      let runtime = GameRuntime(
        interactionHaptic: { haptics += 1 }, successHaptic: { successes += 1 })
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      _ = try start(runtime)
      let wrong = try XCTUnwrap(puzzle.legalMoves.subtracting(puzzle.acceptedMoves).first)
      controller.tap(wrong.origin)
      controller.tap(wrong.destination)
      XCTAssertEqual(haptics, 0)
      XCTAssertEqual(successes, 0)
      let accepted = try XCTUnwrap(puzzle.acceptedMoves.first)
      controller.tap(accepted.origin)
      controller.tap(accepted.destination)
      XCTAssertEqual(haptics, 0)
      XCTAssertEqual(successes, 1)
      XCTAssertTrue(try XCTUnwrap(controller.attempt).isSolved)
    }
  }

  private func start(_ runtime: GameRuntime) throws -> GameAttemptID {
    runtime.setVisible(true)
    runtime.start()
    guard case .playing(let attempt) = runtime.phase else {
      throw Failure.notPlaying
    }
    return attempt
  }

  private enum Failure: Error { case notPlaying }
}
