import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class FeedAutoContinueTests: XCTestCase {
  func testThreeTicksRequestOneAdvanceAndCompletedRevisitsStayQuiet() async throws {
    let gate = CountdownGate()
    let timer = FeedAutoContinue(pause: { try await gate.pause() })
    let card = try CardID("successful")
    let attempt = GameAttemptID()
    timer.start(cardID: card, attempt: attempt)
    XCTAssertEqual(timer.remaining, 3)
    for tick in [2, 1, 0] {
      await gate.waitForRequest()
      await gate.finish()
      for _ in 0..<20 { await Task.yield() }
      XCTAssertEqual(timer.remaining, tick)
    }
    XCTAssertNotNil(timer.advanceRequested)
    timer.cancel()
    timer.start(cardID: card, attempt: attempt)
    XCTAssertNil(timer.remaining)
    XCTAssertNil(timer.advanceRequested)
  }

  func testDisableAndCanceledNoncooperativeTickCannotAdvanceAnotherAttempt() async throws {
    let gate = CountdownGate()
    let timer = FeedAutoContinue(pause: { try await gate.pause() })
    let card = try CardID("successful")
    timer.start(cardID: card, attempt: GameAttemptID())
    await gate.waitForRequest()
    timer.setEnabled(false)
    await gate.finish()
    for _ in 0..<20 { await Task.yield() }
    XCTAssertFalse(timer.enabled)
    XCTAssertNil(timer.remaining)
    XCTAssertNil(timer.advanceRequested)
    timer.setEnabled(true)
    XCTAssertNil(timer.remaining)
    timer.start(cardID: card, attempt: GameAttemptID())
    await gate.waitForRequest()
    timer.cancel()
    await gate.finish()
    for _ in 0..<20 { await Task.yield() }
    XCTAssertNil(timer.advanceRequested)
  }
}

private actor CountdownGate {
  private var continuation: CheckedContinuation<Void, Never>?
  private var waiter: CheckedContinuation<Void, Never>?
  func pause() async throws {
    await withCheckedContinuation {
      continuation = $0
      waiter?.resume()
      waiter = nil
    }
  }
  func waitForRequest() async {
    if continuation != nil { return }
    await withCheckedContinuation { waiter = $0 }
  }
  func finish() {
    continuation?.resume()
    continuation = nil
  }
}
