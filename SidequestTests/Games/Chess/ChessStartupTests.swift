import XCTest

@testable import Sidequest

@MainActor
final class ChessStartupTests: XCTestCase {
  func testLoadsOnceBeforeCompositionAndReplacementReusesImmutableFixtures() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let gate = FixtureGate()
    let startup = FeedStartup(loadChess: { try await gate.load() })
    let loading = Task { await startup.prepare() }
    await gate.waitForRequest(1)
    guard case .loading = startup.state else { return XCTFail("Composition must await fixtures") }
    await startup.prepare()
    XCTAssertEqual(gate.count, 1)
    gate.finish(1, with: puzzles)
    await loading.value
    guard case .ready(let original) = startup.state else { return XCTFail("Expected ready feed") }
    XCTAssertNotNil(original.controller)
    XCTAssertEqual(original.chessPuzzles.map(\.id), puzzles.map(\.id))
    let originalCards = original.controller?.cards.map(\.id)
    await startup.prepare()
    startup.cancelPreparation()
    guard case .ready(let retained) = startup.state else { return XCTFail("Keep loaded feed") }
    XCTAssertTrue(retained === original)
    XCTAssertEqual(retained.controller?.cards.map(\.id), originalCards)
    startup.replaceFixtureSession()
    guard case .ready(let replacement) = startup.state else {
      return XCTFail("Expected replacement")
    }
    XCTAssertFalse(replacement === original)
    XCTAssertEqual(replacement.chessPuzzles.map(\.id), puzzles.map(\.id))
    XCTAssertEqual(gate.count, 1)
  }

  func testLateCanceledLoadCannotOverwriteAReplacementStartup() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let gate = FixtureGate()
    let startup = FeedStartup(loadChess: { try await gate.load() })
    let old = Task { await startup.prepare() }
    await gate.waitForRequest(1)
    startup.cancelPreparation()
    // A dependency can finish despite appearance invalidation; identity must stand alone.
    let current = Task { await startup.prepare() }
    await gate.waitForRequest(2)
    gate.finish(2, with: puzzles)
    await current.value
    guard case .ready(let original) = startup.state else { return XCTFail("Expected new feed") }
    startup.replaceFixtureSession()
    guard case .ready(let replacement) = startup.state else {
      return XCTFail("Expected replacement")
    }
    XCTAssertFalse(original === replacement)
    gate.finish(1, with: puzzles)
    await old.value
    guard case .ready(let final) = startup.state else { return XCTFail("Late load changed state") }
    XCTAssertTrue(final === replacement)
    XCTAssertEqual(gate.count, 2)
  }

  func testCooperativeTaskCancellationReturnsToNotStartedAndCanRetry() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let gate = FixtureGate()
    let startup = FeedStartup(loadChess: { try await gate.load() })
    let canceled = Task { await startup.prepare() }
    await gate.waitForRequest(1)
    canceled.cancel()
    gate.finish(1, with: puzzles)
    await canceled.value
    guard case .notStarted = startup.state else {
      return XCTFail("Cancellation must allow a new appearance")
    }
    let retry = Task { await startup.prepare() }
    await gate.waitForRequest(2)
    gate.finish(2, with: puzzles)
    await retry.value
    guard case .ready = startup.state else { return XCTFail("Expected usable retry") }
    XCTAssertEqual(gate.count, 2)
  }

  func testLoaderFailureRemainsVisibleWithoutPublishingAFeed() async {
    let startup = FeedStartup(loadChess: { throw ChessFixtureError.missingResource })
    await startup.prepare()
    guard case .failed(let message) = startup.state else {
      return XCTFail("Expected visible failure")
    }
    XCTAssertTrue(message.contains("Could not prepare games:"))
    await startup.prepare()
    guard case .failed = startup.state else {
      return XCTFail("Do not silently retry or fabricate a feed")
    }
  }

  func testMissingCachedPuzzleFailsCompositionWithoutAnotherRead() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let composition = FeedComposition(chessPuzzles: Array(puzzles.prefix(1)))
    XCTAssertNil(composition.controller)
    guard case .failed(let message) = composition.session else {
      return XCTFail("Missing required fixture must fail composition")
    }
    XCTAssertTrue(message.contains("chess fixture"))
  }
}

@MainActor
private final class FixtureGate {
  private(set) var count = 0
  private var continuations: [Int: CheckedContinuation<[ChessPuzzle], Error>] = [:]
  private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]

  func load() async throws -> [ChessPuzzle] {
    count += 1
    let request = count
    return try await withCheckedThrowingContinuation { continuation in
      continuations[request] = continuation
      waiters.removeValue(forKey: request)?.resume()
    }
  }

  func waitForRequest(_ request: Int) async {
    if count >= request { return }
    await withCheckedContinuation { waiters[request] = $0 }
  }

  func finish(_ request: Int, with puzzles: [ChessPuzzle]) {
    continuations.removeValue(forKey: request)?.resume(returning: puzzles)
  }
}
