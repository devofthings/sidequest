import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class LiveNewsRefreshTests: XCTestCase {
  func testPreparationDoesNotWaitForLiveNewsOrLoadFictionalFallback() async throws {
    let transport = SuspendedLiveNews()
    let fixture = try await makeSession(transport)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await fixture.session.prepare(newsModel: fixture.model)
    let composition = try current(fixture.session)
    XCTAssertEqual(composition.controller?.count, 5)
    XCTAssertTrue(fixture.model.snapshots.isEmpty)
    let beforeRefresh = await transport.requestCount
    XCTAssertEqual(beforeRefresh, 0)
    let storageLoads = await fixture.store.loadCount
    XCTAssertEqual(storageLoads, 0, "Live startup must not resolve saved or demo stories")
    fixture.session.refreshLiveNews(newsModel: fixture.model)
    await transport.waitForRequest(1)
    XCTAssertTrue(try current(fixture.session) === composition)
    await transport.finish(1, .failure(LiveNewsFailure.offline))
    try await waitUntil { fixture.model.message != nil }
    XCTAssertTrue(fixture.model.snapshots.isEmpty)
    XCTAssertEqual(composition.controller?.count, 5)
    XCTAssertTrue(try current(fixture.session) === composition)
  }

  func testRepeatedActiveCallbacksDoNotDuplicateRequestAndSuccessPreservesPlayingGame()
    async throws
  {
    let transport = SuspendedLiveNews()
    let fixture = try await preparedSession(transport)
    let composition = try current(fixture.session)
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    let selected = try XCTUnwrap(feed.selectedCard)
    let runtime = try XCTUnwrap(feed.runtimes[selected.id])
    runtime.start()
    let playing = runtime.phase
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(1)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    fixture.session.refreshLiveNews(newsModel: fixture.model)
    let count = await transport.requestCount
    XCTAssertEqual(count, 1)
    let story = try snapshot("live-first")
    await transport.finish(1, .success([story]))
    try await waitUntil { fixture.model.snapshots == [story] }
    XCTAssertTrue(try current(fixture.session) === composition)
    XCTAssertEqual(feed.selectedCard?.id, selected.id)
    XCTAssertTrue(feed.runtimes[selected.id] === runtime)
    XCTAssertEqual(runtime.phase, playing)
    XCTAssertTrue(runtime.isVisible)
    XCTAssertNil(fixture.model.message)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    let afterAdoption = await transport.requestCount
    XCTAssertEqual(afterAdoption, 1, "A duplicate active callback is not a reopen")
  }

  func testBackgroundRejectsNoncooperativeLateResultAndReopenRetries() async throws {
    let transport = SuspendedLiveNews()
    let fixture = try await preparedSession(transport)
    let composition = try current(fixture.session)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(1)
    let staleTask = try XCTUnwrap(fixture.session.refreshLiveNews(newsModel: fixture.model))
    fixture.session.setNewsSceneActive(false, newsModel: fixture.model)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(2)
    let fresh = try snapshot("fresh-on-reopen")
    await transport.finish(2, .success([fresh]))
    try await waitUntil { fixture.model.snapshots == [fresh] }
    await transport.finish(1, .success([try snapshot("stale-background-response")]))
    await staleTask.value
    XCTAssertEqual(fixture.model.snapshots, [fresh])
    XCTAssertNil(fixture.model.message)
    XCTAssertTrue(try current(fixture.session) === composition)
  }

  func testReopenFailureRetainsLatestValidNewsAndCurrentGame() async throws {
    let transport = SuspendedLiveNews()
    let fixture = try await preparedSession(transport)
    let composition = try current(fixture.session)
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    let selected = try XCTUnwrap(feed.selectedCard)
    let runtime = try XCTUnwrap(feed.runtimes[selected.id])
    runtime.start()
    let playing = runtime.phase
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(1)
    let retained = try snapshot("retained-live")
    await transport.finish(1, .success([retained]))
    try await waitUntil { fixture.model.snapshots == [retained] }
    fixture.session.setNewsSceneActive(false, newsModel: fixture.model)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(2)
    await transport.finish(2, .failure(LiveNewsFailure.offline))
    try await waitUntil { fixture.model.message != nil }
    XCTAssertEqual(fixture.model.snapshots, [retained])
    XCTAssertTrue(fixture.model.message?.contains("latest articles") ?? false)
    XCTAssertTrue(try current(fixture.session) === composition)
    XCTAssertEqual(feed.selectedCard?.id, selected.id)
    XCTAssertTrue(feed.runtimes[selected.id] === runtime)
    XCTAssertEqual(runtime.phase, playing)
  }

  func testSuccessfulManualImportCancelsLateLiveRequestAndDisablesFutureRefresh() async throws {
    let transport = SuspendedLiveNews()
    let manual = try snapshot("manual-owner-import")
    let fixture = try await makeSession(transport, imported: [manual])
    await fixture.session.prepare(newsModel: fixture.model)
    let original = try current(fixture.session)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(1)
    let staleTask = try XCTUnwrap(fixture.session.refreshLiveNews(newsModel: fixture.model))
    await fixture.model.importFile(at: URL(fileURLWithPath: "/fictional-test-import.json"))
    let replacement = try current(fixture.session)
    XCTAssertFalse(replacement === original)
    XCTAssertFalse(fixture.session.usesLiveNews)
    XCTAssertEqual(fixture.model.snapshots, [manual])
    let persisted = await fixture.store.savedBytes
    XCTAssertEqual(persisted, try NewsSnapshotImporter.encode([manual]))
    await transport.finish(1, .success([try snapshot("late-live-after-import")]))
    await staleTask.value
    fixture.session.setNewsSceneActive(false, newsModel: fixture.model)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    XCTAssertNil(fixture.session.refreshLiveNews(newsModel: fixture.model))
    let count = await transport.requestCount
    XCTAssertEqual(count, 1)
    XCTAssertEqual(fixture.model.snapshots, [manual])
    XCTAssertTrue(try current(fixture.session) === replacement)
  }

  func testLiveResponseDuringFailedImportReleasesRequestAndAllowsRetry() async throws {
    let transport = SuspendedLiveNews()
    let manual = try snapshot("failed-manual-import")
    let fixture = try await makeSession(transport, imported: [manual], suspendSaves: true)
    await fixture.session.prepare(newsModel: fixture.model)
    let original = try current(fixture.session)
    fixture.session.setNewsSceneActive(true, newsModel: fixture.model)
    await transport.waitForRequest(1)
    let leasedResponse = try XCTUnwrap(fixture.session.refreshLiveNews(newsModel: fixture.model))
    let importing = Task {
      await fixture.model.importFile(at: URL(fileURLWithPath: "/fictional-failing-import.json"))
    }
    await fixture.store.waitForSave()
    await transport.finish(1, .success([try snapshot("response-during-save-lease")]))
    await leasedResponse.value
    XCTAssertTrue(fixture.model.snapshots.isEmpty, "The import lease excludes live adoption")
    await fixture.store.finishSave(.failure(LiveNewsFailure.offline))
    await importing.value
    XCTAssertTrue(fixture.session.usesLiveNews)
    XCTAssertTrue(try current(fixture.session) === original)
    XCTAssertTrue(fixture.model.message?.hasPrefix("Import failed.") ?? false)
    let persisted = await fixture.store.savedBytes
    XCTAssertNil(persisted)
    let retry = try XCTUnwrap(fixture.session.refreshLiveNews(newsModel: fixture.model))
    await transport.waitForRequest(2)
    let recovered = try snapshot("live-after-failed-import")
    await transport.finish(2, .success([recovered]))
    await retry.value
    XCTAssertEqual(fixture.model.snapshots, [recovered])
    XCTAssertNil(fixture.model.message)
    XCTAssertTrue(try current(fixture.session) === original)
  }

  private struct Fixture {
    let session: FeedSessionState
    let model: NewsImportModel
    let store: LiveRefreshStorage
  }

  private func preparedSession(_ transport: SuspendedLiveNews) async throws -> Fixture {
    let fixture = try await makeSession(transport)
    await fixture.session.prepare(newsModel: fixture.model)
    return fixture
  }

  private func makeSession(
    _ transport: SuspendedLiveNews, imported: [NewsSnapshot] = [], suspendSaves: Bool = false
  ) async throws -> Fixture {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let store = LiveRefreshStorage(suspendSaves: suspendSaves)
    let session = FeedSessionState(
      useEndless: false, loadLiveNews: { try await transport.load() }, loadChess: { puzzles })
    let payload = ValidatedNewsImport(
      data: try NewsSnapshotImporter.encode(imported), snapshots: imported)
    let model = NewsImportModel(
      store: store, usesDemoWhenMissing: true,
      loadDemo: { throw LiveNewsFailure.fictionalFallbackReached },
      beginReplacement: session.beginReplacement, readImport: { _ in payload })
    return Fixture(session: session, model: model, store: store)
  }

  private func current(_ session: FeedSessionState) throws -> FeedComposition {
    guard case .ready(let composition) = session.state else {
      throw NewsImportError.unavailableStorage
    }
    return composition
  }

  private func snapshot(_ id: String) throws -> NewsSnapshot {
    try NewsSnapshot(
      id: CardID(id), headline: "Fictional offline story", excerpt: "Deterministic test input.",
      publisher: "Sidequest test fixture",
      sourceURL: XCTUnwrap(URL(string: "https://example.com/\(id)")),
      capturedAt: Date(timeIntervalSince1970: 1_700_000_000), isSample: false)
  }

  private func waitUntil(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(5)
    while !condition() {
      guard ContinuousClock.now < deadline else {
        XCTFail("Controlled live-news response was not adopted")
        throw CancellationError()
      }
      await Task.yield()
    }
  }

}

private enum LiveNewsFailure: Error {
  case offline
  case fictionalFallbackReached
}

private actor LiveRefreshStorage: NewsSnapshotStorage {
  private(set) var loadCount = 0
  private(set) var savedBytes: Data?
  private let suspendSaves: Bool
  private var saveArrived = false
  private var saveArrival: CheckedContinuation<Void, Never>?
  private var pendingSave: CheckedContinuation<Void, Error>?

  init(suspendSaves: Bool = false) { self.suspendSaves = suspendSaves }

  func load() async throws -> [NewsSnapshot]? {
    loadCount += 1
    return nil
  }
  func save(_ data: Data) async throws {
    if suspendSaves {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        pendingSave = continuation
        saveArrived = true
        saveArrival?.resume()
        saveArrival = nil
      }
    }
    savedBytes = data
  }

  func waitForSave() async {
    if saveArrived { return }
    await withCheckedContinuation { saveArrival = $0 }
  }

  func finishSave(_ result: Result<Void, Error>) {
    pendingSave?.resume(with: result)
    pendingSave = nil
  }
}

/// Deliberately ignores cancellation so tests exercise the session's stale-response boundary.
private actor SuspendedLiveNews {
  private(set) var requestCount = 0
  private var requests: [Int: CheckedContinuation<[NewsSnapshot], Error>] = [:]
  private var arrivals: [Int: CheckedContinuation<Void, Never>] = [:]

  func load() async throws -> [NewsSnapshot] {
    requestCount += 1
    let id = requestCount
    return try await withCheckedThrowingContinuation { continuation in
      requests[id] = continuation
      arrivals.removeValue(forKey: id)?.resume()
    }
  }

  func waitForRequest(_ id: Int) async {
    if requestCount >= id { return }
    await withCheckedContinuation { arrivals[id] = $0 }
  }

  func finish(_ id: Int, _ result: Result<[NewsSnapshot], Error>) {
    requests.removeValue(forKey: id)?.resume(with: result)
  }
}
