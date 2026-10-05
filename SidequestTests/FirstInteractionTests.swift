import XCTest

@testable import Sidequest

@MainActor
final class FirstInteractionTests: XCTestCase {
  func testEditableSudokuSelectionStartsAndSelectsInOneAction() throws {
    let puzzle = try XCTUnwrap(SudokuPuzzle.fixtures().first)
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let controller = SudokuController(puzzle: puzzle, runtime: runtime)
    runtime.setVisible(true)
    let given = try XCTUnwrap(puzzle.givens.firstIndex { $0 != 0 })
    let empty = try XCTUnwrap(puzzle.givens.firstIndex(of: 0))
    controller.selectCell(given)
    controller.selectCell(-1)
    XCTAssertEqual(runtime.phase, .preview)
    controller.selectCell(empty)
    XCTAssertEqual(controller.selectedCell, empty)
    XCTAssertEqual(controller.board?.cells[empty], 0)
    controller.enter(puzzle.solution[empty])
    XCTAssertEqual(controller.board?.cells[empty], puzzle.solution[empty])
  }

  func testCoordinateSelectionSurvivesStartResetAndGivensDoNotStart() throws {
    let puzzle = try SudokuPuzzle.standardFixture()
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let controller = SudokuController(puzzle: puzzle, runtime: runtime)
    runtime.setVisible(true)
    controller.selectRow(8)
    XCTAssertEqual(runtime.phase, .preview)
    XCTAssertEqual(controller.coordinateRow, 8)
    controller.selectColumn(8)
    XCTAssertEqual(runtime.phase, .preview)
    let target = 8
    controller.selectRow(0)
    XCTAssertEqual(controller.selectedCell, target)
    XCTAssertEqual(controller.coordinateRow, 0)
    XCTAssertEqual(controller.coordinateColumn, target % 9)
  }

  func testMemoryFirstTileRevealsAndSkipRestartsFrozenBoard() throws {
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let board = try MemoryRules(symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
    let controller = MemoryController(runtime: runtime, makeBoard: { board })
    runtime.setVisible(true)
    controller.flip(-1)
    XCTAssertEqual(runtime.phase, .preview)
    controller.flip(0)
    XCTAssertTrue(controller.rules?.isRevealed(0) == true)
    runtime.setVisible(false)
    XCTAssertNil(controller.rules)
    runtime.setVisible(true)
    controller.flip(1)
    XCTAssertEqual(controller.rules?.symbols, board.symbols)
    XCTAssertTrue(controller.rules?.isRevealed(1) == true)
    XCTAssertFalse(controller.rules?.isRevealed(0) == true)
  }

  func testBothChessSidesSelectFirstOwnPieceAndCompletedRevisitIsQuiet() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled() {
      let runtime = GameRuntime(activationPolicy: .firstInteraction)
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      runtime.setVisible(true)
      let opponent = try XCTUnwrap(puzzle.board.first { $0.value.side != puzzle.sideToMove }?.key)
      controller.tap(opponent)
      XCTAssertEqual(runtime.phase, .preview)
      let move = try XCTUnwrap(puzzle.acceptedMoves.first)
      controller.tap(move.origin)
      XCTAssertEqual(controller.attempt?.selectedSquare, move.origin)
      controller.tap(move.destination)
      XCTAssertTrue(controller.attempt?.isSolved == true)
      let phase = runtime.phase
      runtime.setVisible(false)
      runtime.setVisible(true)
      controller.tap(move.origin)
      XCTAssertEqual(runtime.phase, phase)
      XCTAssertTrue(controller.attempt?.isSolved == true)
      XCTAssertNil(runtime.celebrationAttempt)
    }
  }

  func testBubbleFiniteAimStartsWithoutFiringAndStaleLeaseCannotRestart() {
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let controller = BubbleShooterController(runtime: runtime)
    runtime.setVisible(true)
    controller.aim(degrees: .nan)
    XCTAssertEqual(runtime.phase, .preview)
    controller.aim(degrees: 30)
    XCTAssertEqual(controller.aimDegrees, 30)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 0)
    let lease = controller.beginAimDrag()
    runtime.setVisible(false)
    runtime.setVisible(true)
    if let lease { XCTAssertFalse(controller.updateAimDrag(lease, degrees: -30)) }
    XCTAssertEqual(runtime.phase, .preview)
    XCTAssertEqual(controller.aimDegrees, 0)
  }

  func testBubbleFirstFireCreatesFlightAndHideCancelsIt() {
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let controller = BubbleShooterController(runtime: runtime)
    runtime.setVisible(true)
    XCTAssertTrue(controller.fire())
    XCTAssertNotNil(controller.flight)
    XCTAssertFalse(controller.fire())
    runtime.setVisible(false)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 0)
  }

  func testHiddenReturnedHeldActionAndRetirementCannotInitiate() throws {
    let runtime = GameRuntime(activationPolicy: .firstInteraction)
    let board = try MemoryRules(symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
    let controller = MemoryController(runtime: runtime, makeBoard: { board })
    controller.flip(0)
    XCTAssertEqual(runtime.phase, .preview)
    runtime.setVisible(true)
    let heldVisibility = runtime.visibilityIdentity
    runtime.setVisible(false)
    runtime.setVisible(true)
    controller.flip(0, visibility: heldVisibility)
    XCTAssertEqual(runtime.phase, .preview)
    runtime.retire()
    runtime.setVisible(true)
    controller.flip(0)
    XCTAssertEqual(runtime.phase, .preview)
  }

  func testRenderingEligibilityAndAppCompositionNeverStartAnAttempt() {
    let runtime = GameFeedbackComposition.makeRuntime()
    runtime.installEffectHandler { _ in XCTFail("Reading eligibility must not start") }
    runtime.setVisible(true)
    XCTAssertTrue(runtime.canBeginInteraction)
    XCTAssertTrue(runtime.canInteract)
    XCTAssertEqual(runtime.activationPolicy, .firstInteraction)
    XCTAssertEqual(runtime.phase, .preview)
  }
}
