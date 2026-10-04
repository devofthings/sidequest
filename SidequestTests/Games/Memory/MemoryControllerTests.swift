import XCTest

@testable import Sidequest

@MainActor
final class MemoryControllerTests: XCTestCase {
  func testFrozenVisiblePreviewRejectsInputAndStartDoesNotFlipCards() async throws {
    let runtime = GameRuntime()
    let board = try fixedBoard()
    let differentBoard = try MemoryRules(symbols: Array(board.symbols.reversed()))
    var creations = 0
    var delays = 0
    let controller = MemoryController(
      runtime: runtime,
      makeBoard: {
        creations += 1
        return creations == 1 ? board : differentBoard
      },
      delay: { delays += 1 })
    controller.flip(0)
    runtime.start()
    XCTAssertNil(controller.rules)
    XCTAssertEqual(controller.displayedRules, board)
    XCTAssertEqual(creations, 1)
    await Task.yield()
    XCTAssertEqual(delays, 0)
    runtime.setVisible(true)
    controller.flip(0)
    XCTAssertNil(controller.rules)
    XCTAssertEqual(controller.displayedRules, board)
    runtime.start()
    XCTAssertEqual(controller.rules, board)
    XCTAssertFalse(
      try XCTUnwrap(controller.rules).symbols.indices.contains {
        controller.rules?.isRevealed($0) == true
      })
    controller.flip(0)
    runtime.setVisible(false)
    XCTAssertEqual(runtime.phase, .preview)
    XCTAssertNil(controller.rules)
    XCTAssertEqual(controller.displayedRules, board)
    controller.flip(1)
    runtime.setVisible(true)
    runtime.start()
    XCTAssertEqual(controller.rules, board)
    XCTAssertEqual(controller.displayedRules, board)
    XCTAssertEqual(creations, 1)
  }

  func testMismatchLocksInputThenRevealsOnlyMatchedPairs() async throws {
    let gate = MemoryDelayGate()
    let runtime = GameRuntime()
    let board = try fixedBoard()
    let controller = MemoryController(
      runtime: runtime, makeBoard: { board },
      delay: {
        await gate.pause()
      })
    runtime.setVisible(true)
    runtime.start()
    controller.flip(0)
    controller.flip(1)
    controller.flip(2)
    controller.flip(4)
    await gate.waitUntilStarted(1)
    let pending = controller.rules
    controller.flip(3)
    XCTAssertEqual(controller.rules, pending)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertFalse(try XCTUnwrap(controller.rules).isResolvingMismatch)
    XCTAssertEqual(controller.rules?.matchedPairCount, 1)
    XCTAssertTrue(controller.rules?.isRevealed(0) == true)
    XCTAssertFalse(controller.rules?.isRevealed(2) == true)
  }

  func testCanceledOldDelayCannotConcealNewAttemptsMismatch() async throws {
    let gate = MemoryDelayGate()
    let runtime = GameRuntime()
    let board = try fixedBoard()
    let controller = MemoryController(
      runtime: runtime, makeBoard: { board },
      delay: {
        // Deliberately ignores cancellation until the test resumes it.
        await gate.pause()
      })
    runtime.setVisible(true)
    runtime.start()
    let oldPhase = runtime.phase
    controller.flip(0)
    controller.flip(2)
    await gate.waitUntilStarted(1)
    runtime.setVisible(false)
    XCTAssertNil(controller.rules)
    runtime.setVisible(true)
    runtime.start()
    XCTAssertNotEqual(runtime.phase, oldPhase)
    controller.flip(4)
    controller.flip(6)
    await gate.waitUntilStarted(2)
    let newMismatch = controller.rules
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertEqual(controller.rules, newMismatch)
    XCTAssertEqual(controller.rules?.turn, .mismatch(first: 4, second: 6))
    gate.resume(2)
    await gate.waitUntilReturned(2)
    XCTAssertEqual(controller.rules?.turn, .choosing(first: nil))
  }

  func testUnexpectedDelayFailureDoesNotPermanentlyLockInput() async throws {
    enum DelayFailure: Error { case unavailable }
    let gate = MemoryDelayGate()
    let runtime = GameRuntime()
    let board = try fixedBoard()
    let controller = MemoryController(
      runtime: runtime, makeBoard: { board },
      delay: {
        await gate.pause()
        throw DelayFailure.unavailable
      })
    runtime.setVisible(true)
    runtime.start()
    controller.flip(0)
    controller.flip(2)
    await gate.waitUntilStarted(1)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertEqual(controller.rules?.turn, .choosing(first: nil))
    controller.flip(0)
    controller.flip(1)
    XCTAssertEqual(controller.rules?.matchedPairCount, 1)
  }

  func testCompletionStaysInPlaceAndSurvivesRevisiting() throws {
    let runtime = GameRuntime()
    let board = try fixedBoard()
    let controller = MemoryController(runtime: runtime, makeBoard: { board })
    runtime.setVisible(true)
    runtime.start()
    for index in stride(from: 0, to: 12, by: 2) {
      controller.flip(index)
      controller.flip(index + 1)
    }
    guard case .completed = runtime.phase else { return XCTFail("Expected completion.") }
    let completed = controller.rules
    runtime.setVisible(false)
    XCTAssertEqual(controller.rules, completed)
    runtime.setVisible(true)
    runtime.start()
    controller.flip(0)
    XCTAssertEqual(controller.rules, completed)
    XCTAssertEqual(controller.rules?.matchedPairCount, 6)
  }

  private func fixedBoard() throws -> MemoryRules {
    try MemoryRules(symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
  }
}

/// Test-owned, noncooperative suspension; every continuation is explicitly resumed.
/// All continuations run on MainActor, so returning from a delay precedes the
/// waiting test's next actor turn and the controller can apply its guarded result.
@MainActor
private final class MemoryDelayGate {
  private var count = 0
  private var pauses: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returned = Set<Int>()
  private var startWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returnWaiters: [Int: CheckedContinuation<Void, Never>] = [:]

  func pause() async {
    count += 1
    let number = count
    await withCheckedContinuation { continuation in
      pauses[number] = continuation
      startWaiters.removeValue(forKey: number)?.resume()
    }
    returned.insert(number)
    returnWaiters.removeValue(forKey: number)?.resume()
  }

  func waitUntilStarted(_ number: Int) async {
    if pauses[number] != nil { return }
    await withCheckedContinuation { startWaiters[number] = $0 }
  }

  func waitUntilReturned(_ number: Int) async {
    if returned.contains(number) { return }
    await withCheckedContinuation { returnWaiters[number] = $0 }
  }

  func resume(_ number: Int) {
    pauses.removeValue(forKey: number)?.resume()
  }
}
