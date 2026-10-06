import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class FeedAutoContinueTests: XCTestCase {
  func testSuccessDuringCanceledPagingNeverStartsOrRestartsCountdown() async throws {
    let composition = try FeedComposition(
      news: [], chessPuzzles: await ChessPuzzleLoader.bundled(),
      shuffle: { cards in cards.sorted { $0.id.rawValue < $1.id.rawValue } })
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    while feed.selectedCard?.id.rawValue != "sample-game-chess-white" { feed.next() }
    let card = try XCTUnwrap(feed.selectedCard)
    guard case .chess(let chess) = composition.games[card.id] else {
      return XCTFail("Expected Chess")
    }
    feed.setPagingBusy(true)
    let origin = try XCTUnwrap(ChessSquare("g6"))
    let destination = try XCTUnwrap(ChessSquare("g7"))
    chess.tap(origin)
    chess.tap(destination)
    guard case .completed = chess.runtime.phase else { return XCTFail("Expected a real mate") }
    XCTAssertNil(feed.autoContinue.remaining)
    feed.setPagingBusy(false)
    XCTAssertNil(feed.autoContinue.remaining)
    feed.next()
    feed.previous()
    XCTAssertNil(feed.autoContinue.remaining)
    feed.retire()
  }

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
