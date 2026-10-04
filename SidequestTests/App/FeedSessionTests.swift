import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class FeedSessionTests: XCTestCase {
  func testProductionIncludesAllRealGamesAndOnlyLoadedNewsWithOneShuffle() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    var shuffles = 0
    let story = try snapshot("private-one")
    let composition = try FeedComposition(news: [story], chessPuzzles: puzzles) { cards in
      shuffles += 1
      return cards
    }
    let controller = try XCTUnwrap(composition.controller)
    XCTAssertEqual(shuffles, 1)
    XCTAssertEqual(controller.count, 6)
    XCTAssertEqual(Set(controller.runtimes.keys.map(\.rawValue)), FeedComposition.gameIDs)
    XCTAssertEqual(controller.cards.first, .news(story))
    XCTAssertTrue(controller.runtimes.values.allSatisfy { !$0.isVisible && $0.phase == .preview })
    controller.setSceneActive(true)
    controller.next()
    let runtime = try XCTUnwrap(controller.runtimes[try XCTUnwrap(controller.selectedCard).id])
    XCTAssertEqual(runtime.phase, .preview)
    runtime.start()
    let playing = runtime.phase
    runtime.start()
    XCTAssertEqual(runtime.phase, playing)
    controller.next()
    XCTAssertEqual(runtime.phase, .preview)
    controller.previous()
    XCTAssertEqual(runtime.phase, .preview)
    XCTAssertEqual(shuffles, 1)
  }

  func testAllFiveReservedIDsRejectNewsWhileSimilarIDsRemainValid() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    for id in FeedComposition.gameIDs {
      XCTAssertThrowsError(try FeedComposition(news: [snapshot(id)], chessPuzzles: puzzles))
    }
    XCTAssertNoThrow(
      try FeedComposition(news: [snapshot("sample-game-chess")], chessPuzzles: puzzles))
    XCTAssertThrowsError(try FeedComposition(news: [], chessPuzzles: Array(puzzles.prefix(1))))
  }

  func testStaleStartupSuccessCannotAdoptNewsOrReplaceCurrentSession() async throws {
    try await staleStartup(error: nil)
  }

  func testStaleStartupErrorCannotEraseNewerNewsOrPublishFallback() async throws {
    try await staleStartup(error: NewsImportError.unavailableStorage)
  }

  func testCanceledNewsReadReturnsToNotStartedWithoutFallback() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let store = PausedNewsStore()
    let model = NewsImportModel(store: store)
    let session = FeedSessionState(loadChess: { puzzles })
    let task = Task { await session.prepare(newsModel: model) }
    await store.waitForRequest(1)
    task.cancel()
    await store.finish(1, result: .failure(NewsImportError.unavailableStorage))
    await task.value
    guard case .notStarted = session.state else {
      return XCTFail("Cancellation must not become fallback")
    }
    XCTAssertTrue(model.snapshots.isEmpty)
    XCTAssertNil(model.message)
  }

  func testMissingAndCorruptNewsKeepRealGamesAndRetryIsPossible() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let store = PausedNewsStore()
    let model = NewsImportModel(store: store)
    let session = FeedSessionState(loadChess: { puzzles })
    let task = Task { await session.prepare(newsModel: model) }
    await store.waitForRequest(1)
    await store.finish(1, result: .failure(NewsImportError.unavailableStorage))
    await task.value
    guard case .ready(let old) = session.state else {
      return XCTFail("Games should remain available")
    }
    XCTAssertEqual(old.controller?.count, 5)
    XCTAssertNotNil(model.message)
    // The retry uses the production replacement seam, and no startup wrapper owns another deck.
    let retryModel = NewsImportModel(store: store, prepareReplacement: session.prepareReplacement)
    retryModel.adoptRestored([], message: model.message)
    let retry = Task { await retryModel.restore() }
    await store.waitForRequest(2)
    await store.finish(2, result: .success([try snapshot("recovered")]))
    await retry.value
    guard case .ready(let recovered) = session.state else {
      return XCTFail("Expected recovered deck")
    }
    XCTAssertFalse(recovered === old)
    XCTAssertEqual(recovered.controller?.count, 6)
    XCTAssertEqual(retryModel.snapshots.count, 1)
    XCTAssertNil(retryModel.message)
  }

  func testModalAndSceneChangesKeepOldSessionRetiredAndCandidateInactiveUntilDismissed()
    async throws
  {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let session = FeedSessionState(loadChess: { puzzles })
    let model = NewsImportModel(store: EmptyNewsStore())
    await session.prepare(newsModel: model)
    guard case .ready(let old) = session.state, let oldFeed = old.controller else {
      return XCTFail("Expected initial real games")
    }
    oldFeed.setSceneActive(true)
    let runtime = try XCTUnwrap(oldFeed.runtimes[try XCTUnwrap(oldFeed.selectedCard).id])
    runtime.start()
    session.setLibraryPresented(true)
    XCTAssertEqual(runtime.phase, .preview)
    oldFeed.setSceneActive(false)
    oldFeed.setSceneActive(true)
    XCTAssertFalse(oldFeed.canNavigate)
    XCTAssertFalse(runtime.isVisible)
    let commit = try session.prepareReplacement([snapshot("new")])
    guard case .ready(let retained) = session.state else { return XCTFail("Preparation is inert") }
    XCTAssertTrue(retained === old)
    commit()
    guard case .ready(let replacement) = session.state, let newFeed = replacement.controller else {
      return XCTFail("Expected replacement")
    }
    newFeed.setSceneActive(true)
    XCTAssertFalse(newFeed.canNavigate)
    session.setLibraryPresented(false)
    XCTAssertTrue(newFeed.canNavigate)
    oldFeed.setHostAvailable(true)
    oldFeed.setSceneActive(true)
    runtime.start()
    XCTAssertFalse(oldFeed.canNavigate)
    XCTAssertEqual(runtime.phase, .preview)
  }

  private func staleStartup(error: (any Error)?) async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let store = PausedNewsStore()
    let model = NewsImportModel(store: store)
    let session = FeedSessionState(loadChess: { puzzles })
    let old = Task { await session.prepare(newsModel: model) }
    await store.waitForRequest(1)
    session.cancelPreparation()
    let current = Task { await session.prepare(newsModel: model) }
    await store.waitForRequest(2)
    let fresh = try snapshot("current")
    await store.finish(2, result: .success([fresh]))
    await current.value
    guard case .ready(let ready) = session.state else { return XCTFail("Expected current deck") }
    if let error {
      await store.finish(1, result: .failure(error))
    } else {
      await store.finish(1, result: .success([try snapshot("old")]))
    }
    await old.value
    guard case .ready(let final) = session.state else {
      return XCTFail("Old read changed ready state")
    }
    XCTAssertTrue(final === ready)
    XCTAssertEqual(model.snapshots, [fresh])
    XCTAssertNil(model.message)
  }

  private func snapshot(_ id: String) throws -> NewsSnapshot {
    try NewsSnapshot(
      id: CardID(id), headline: "Fixture", excerpt: "Offline fictional input.",
      publisher: "Sidequest fixture",
      sourceURL: XCTUnwrap(URL(string: "https://example.com/story")),
      capturedAt: Date(timeIntervalSince1970: 1_700_000_000), isSample: true)
  }
}

private struct EmptyNewsStore: NewsSnapshotStorage {
  func load() async throws -> [NewsSnapshot]? { nil }
  func save(_ data: Data) async throws {}
}

private actor PausedNewsStore: NewsSnapshotStorage {
  private var count = 0
  private var reads: [Int: CheckedContinuation<[NewsSnapshot]?, Error>] = [:]
  private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]

  func load() async throws -> [NewsSnapshot]? {
    count += 1
    let id = count
    return try await withCheckedThrowingContinuation { continuation in
      reads[id] = continuation
      waiters.removeValue(forKey: id)?.resume()
    }
  }

  func save(_ data: Data) async throws {}

  func waitForRequest(_ id: Int) async {
    if count >= id { return }
    await withCheckedContinuation { waiters[id] = $0 }
  }

  func finish(_ id: Int, result: Result<[NewsSnapshot]?, Error>) {
    reads.removeValue(forKey: id)?.resume(with: result)
  }
}
