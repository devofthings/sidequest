import XCTest

@testable import Sidequest

@MainActor
final class PreviewStartRequestTests: XCTestCase {
  func testPreviewRequestStartsOnceWithoutSelectingOrEnteringSudoku() throws {
    let runtime = GameRuntime(successHaptic: {})
    let controller = SudokuController(
      puzzle: try XCTUnwrap(SudokuPuzzle.fixtures().first), runtime: runtime)
    XCTAssertNil(PreviewStartRequest(runtime: runtime))
    runtime.setVisible(true)
    let request = try XCTUnwrap(PreviewStartRequest(runtime: runtime))
    request.activate()
    guard case .playing(let attempt) = runtime.phase else { return XCTFail("Expected start") }
    XCTAssertNil(controller.selectedCell)
    XCTAssertEqual(controller.displayedBoard.cells, controller.puzzle.givens)
    request.activate()
    XCTAssertEqual(runtime.phase, .playing(attempt))
    XCTAssertNil(PreviewStartRequest(runtime: runtime))
  }

  func testHeldRequestCannotStartAfterSkipAndReturnToPreview() throws {
    let runtime = GameRuntime(successHaptic: {})
    runtime.installEffectHandler { _ in }
    runtime.setVisible(true)
    let request = try XCTUnwrap(PreviewStartRequest(runtime: runtime))
    runtime.setVisible(false)
    runtime.setVisible(true)
    request.activate()
    XCTAssertEqual(runtime.phase, .preview)
    let fresh = try XCTUnwrap(PreviewStartRequest(runtime: runtime))
    runtime.setVisible(true)  // An idempotent host update must not discard a deliberate tap.
    fresh.activate()
    guard case .playing = runtime.phase else { return XCTFail("Expected fresh start") }
  }

  func testRetiredAndCompletedRequestsNeverStartAnotherAttempt() throws {
    let retired = GameRuntime(successHaptic: {})
    retired.installEffectHandler { _ in }
    retired.setVisible(true)
    let stale = try XCTUnwrap(PreviewStartRequest(runtime: retired))
    retired.retire()
    stale.activate()
    XCTAssertEqual(retired.phase, .preview)
    XCTAssertNil(PreviewStartRequest(runtime: retired))

    let completed = GameRuntime(successHaptic: {})
    completed.installEffectHandler { _ in }
    completed.setVisible(true)
    let request = try XCTUnwrap(PreviewStartRequest(runtime: completed))
    completed.start()
    guard case .playing(let attempt) = completed.phase else { return XCTFail("Expected start") }
    completed.complete(attempt: attempt)
    request.activate()
    XCTAssertEqual(completed.phase, .completed(attempt))
    XCTAssertNil(PreviewStartRequest(runtime: completed))
  }
}
