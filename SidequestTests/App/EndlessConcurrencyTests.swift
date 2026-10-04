import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class EndlessConcurrencyTests: XCTestCase {
  func testCanceledReplenishmentCannotAppendOrPublishLateErrorAndResumesOnce() async throws {
    let gate = GameBatchGate()
    let puzzles = try await ChessPuzzleLoader.bundled()
    let composition = try await FeedComposition.endless(
      news: [], chessPuzzles: puzzles, seed: 104,
      ordered: true,
      prepareBatch: { id, sequence, seed, puzzles, ordered in
        if sequence > 0 { try await gate.pause() }
        return try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed,
          chessPuzzles: puzzles, ordered: ordered)
      })
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    feed.next()
    feed.next()
    feed.next()
    await gate.waitForRequest(1)
    feed.setSceneActive(false)
    feed.setSceneActive(true)
    await gate.waitForRequest(2)
    await gate.finish(1, error: BubbleGenerationError.noAttainableChallenge)
    await Task.yield()
    XCTAssertEqual(feed.count, 8)
    XCTAssertNil(feed.replenishmentMessage)
    await gate.finish(2)
    try await wait { feed.count == 16 }
    XCTAssertEqual(Set(feed.cards.map(\.id)).count, 16)
    let count = await gate.count
    XCTAssertEqual(count, 2)
    feed.retire()
  }

  func testGenerationFailureKeepsHistoryAndRetrySuppliesCurrentBatch() async throws {
    let gate = GameBatchGate()
    let puzzles = try await ChessPuzzleLoader.bundled()
    let composition = try await FeedComposition.endless(
      news: [], chessPuzzles: puzzles, ordered: true,
      prepareBatch: { id, sequence, seed, puzzles, ordered in
        if sequence > 0 { try await gate.pause() }
        return try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed,
          chessPuzzles: puzzles, ordered: ordered)
      })
    let feed = try XCTUnwrap(composition.controller)
    let initial = feed.cards
    feed.setSceneActive(true)
    feed.next()
    feed.next()
    feed.next()
    await gate.waitForRequest(1)
    await gate.finish(1, error: BubbleGenerationError.noAttainableChallenge)
    try await wait { feed.replenishmentMessage != nil }
    XCTAssertEqual(feed.cards, initial)
    feed.retryReplenishment?()
    await gate.waitForRequest(2)
    await gate.finish(2)
    try await wait { feed.count == 16 }
    XCTAssertEqual(Array(feed.cards.prefix(8)), initial)
    XCTAssertNil(feed.replenishmentMessage)
    feed.retire()
  }

  func testImportCapturesOriginBeforeNoncooperativeReadAndCannotSaveIntoNewSession() async throws {
    let session = FeedSessionState()
    let store = EndlessStorage()
    let read = EndlessReadGate()
    let model = NewsImportModel(
      store: store, beginReplacement: session.beginReplacement,
      readImport: { _ in await read.read() })
    await session.prepare(newsModel: model)
    let old = try current(session)
    let task = Task { await model.importFile(at: URL(fileURLWithPath: "/fictional.json")) }
    await read.waitUntilStarted()
    let request = try session.beginReplacement()
    let replacement = try await request.prepare([])
    try replacement.acquire()
    replacement.commit()
    replacement.release()
    let newer = try current(session)
    XCTAssertFalse(old === newer)
    await read.finish(try imported([]))
    await task.value
    let saves = await store.saves
    XCTAssertEqual(saves, 0)
    XCTAssertTrue(try current(session) === newer)
    XCTAssertEqual(model.snapshots, [])
  }

  func testStaleSuspendedReplacementPreparationNeverSaves() async throws {
    let gate = GameBatchGate()
    let store = EndlessStorage()
    let session = FeedSessionState(prepareBatch: { id, sequence, seed, puzzles, ordered in
      try await gate.pauseAfterFirst()
      return try await GeneratedGameBatch.prepare(
        sessionID: id, sequence: sequence, seed: seed,
        chessPuzzles: puzzles, ordered: ordered)
    })
    let data = try imported([])
    let model = NewsImportModel(
      store: store, beginReplacement: session.beginReplacement,
      readImport: { _ in data })
    await session.prepare(newsModel: model)
    let task = Task { await model.importFile(at: URL(fileURLWithPath: "/fictional.json")) }
    await gate.waitForRequest(2)
    let replacementTask = Task { () throws -> Void in
      let request = try session.beginReplacement()
      let prepared = try await request.prepare([])
      try prepared.acquire()
      prepared.commit()
      prepared.release()
    }
    await gate.waitForRequest(3)
    await gate.finish(3)
    try await replacementTask.value
    let current = try current(session)
    await gate.finish(2)
    await task.value
    let saves = await store.saves
    XCTAssertEqual(saves, 0)
    XCTAssertTrue(try self.current(session) === current)
  }

  func testSaveLeaseSerializesReplacementAndCanceledDurableSuccessStillAdopts() async throws {
    let store = EndlessStorage(pauseSave: true)
    let session = FeedSessionState()
    let data = try imported([])
    let model = NewsImportModel(
      store: store, beginReplacement: session.beginReplacement,
      readImport: { _ in data })
    await session.prepare(newsModel: model)
    let old = try current(session)
    let importing = Task { await model.importFile(at: URL(fileURLWithPath: "/fictional.json")) }
    await store.waitForSave()
    XCTAssertThrowsError(try session.beginReplacement())
    importing.cancel()
    await store.finishSave()
    await importing.value
    let replacement = try current(session)
    XCTAssertFalse(replacement === old)
    XCTAssertEqual(replacement.controller?.count, 8)
    XCTAssertEqual(model.message, "Imported 0 news snapshots.")
    XCTAssertNoThrow(try session.beginReplacement())
    old.controller?.setSceneActive(true)
    XCTAssertFalse(old.controller?.canNavigate ?? true)
    let bytes = await store.bytes
    XCTAssertEqual(bytes, data.data)
  }

  func testFailedSaveReleasesLeaseAndKeepsTheCurrentSession() async throws {
    let store = EndlessStorage(rejectSave: true)
    let session = FeedSessionState()
    let data = try imported([])
    let model = NewsImportModel(
      store: store, beginReplacement: session.beginReplacement,
      readImport: { _ in data })
    await session.prepare(newsModel: model)
    let old = try current(session)
    await model.importFile(at: URL(fileURLWithPath: "/fictional.json"))
    XCTAssertTrue(try current(session) === old)
    XCTAssertNoThrow(try session.beginReplacement())
    XCTAssertTrue(model.message?.hasPrefix("Import failed.") ?? false)
  }

  private func current(_ session: FeedSessionState) throws -> FeedComposition {
    guard case .ready(let composition) = session.state else {
      throw NewsImportError.unavailableStorage
    }
    return composition
  }
  private func imported(_ news: [NewsSnapshot]) throws -> ValidatedNewsImport {
    ValidatedNewsImport(data: try NewsSnapshotImporter.encode(news), snapshots: news)
  }
  private func wait(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(5)
    while !condition() {
      guard ContinuousClock.now < deadline else {
        XCTFail("Owned work timed out")
        throw CancellationError()
      }
      try await Task.sleep(for: .milliseconds(5))
    }
  }
}

private actor GameBatchGate {
  private(set) var count = 0
  private var requests: [Int: CheckedContinuation<Void, any Error>] = [:]
  private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]
  func pauseAfterFirst() async throws {
    if count == 0 {
      count = 1
      return
    }
    try await pause()
  }
  func pause() async throws {
    count += 1
    let request = count
    try await withCheckedThrowingContinuation {
      requests[request] = $0
      waiters.removeValue(forKey: request)?.resume()
    }
  }
  func waitForRequest(_ number: Int) async {
    if requests[number] != nil { return }
    await withCheckedContinuation { waiters[number] = $0 }
  }
  func finish(_ number: Int, error: (any Error)? = nil) {
    if let error {
      requests.removeValue(forKey: number)?.resume(throwing: error)
    } else {
      requests.removeValue(forKey: number)?.resume()
    }
  }
}

private actor EndlessReadGate {
  private var readContinuation: CheckedContinuation<ValidatedNewsImport, Never>?
  private var waiter: CheckedContinuation<Void, Never>?
  func read() async -> ValidatedNewsImport {
    await withCheckedContinuation {
      readContinuation = $0
      waiter?.resume()
      waiter = nil
    }
  }
  func waitUntilStarted() async {
    if readContinuation != nil { return }
    await withCheckedContinuation { waiter = $0 }
  }
  func finish(_ value: ValidatedNewsImport) {
    readContinuation?.resume(returning: value)
    readContinuation = nil
  }
}

private actor EndlessStorage: NewsSnapshotStorage {
  private(set) var bytes: Data?
  private(set) var saves = 0
  private let pauseSave: Bool
  private let rejectSave: Bool
  private var continuation: CheckedContinuation<Void, Never>?
  private var waiter: CheckedContinuation<Void, Never>?
  init(pauseSave: Bool = false, rejectSave: Bool = false) {
    self.pauseSave = pauseSave
    self.rejectSave = rejectSave
  }
  func load() async throws -> [NewsSnapshot]? { nil }
  func save(_ data: Data) async throws {
    if rejectSave { throw NewsImportError.unavailableStorage }
    try Task.checkCancellation()
    bytes = data
    saves += 1
    if pauseSave {
      await withCheckedContinuation {
        continuation = $0
        waiter?.resume()
        waiter = nil
      }
    }
  }
  func waitForSave() async {
    if continuation != nil { return }
    await withCheckedContinuation { waiter = $0 }
  }
  func finishSave() {
    continuation?.resume()
    continuation = nil
  }
}
