import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class NewsTransactionTests: XCTestCase {
  func testImmutableLoadsCannotAdoptOrOverwriteANewerRestoration() async throws {
    let original = try samples()
    let store = NewsStorageProbe(pauseLoads: true)
    let model = NewsImportModel(store: store)
    model.adoptRestored(original, message: "Retry available")
    let old = Task { try await model.loadSavedSnapshots() }
    await store.waitForLoad(1)
    let current = Task { try await model.loadSavedSnapshots() }
    await store.waitForLoad(2)
    XCTAssertFalse(model.isBusy)
    XCTAssertEqual(model.snapshots, original)
    await store.finishLoad(2, result: .success([]))
    let newer = try await current.value
    model.adoptRestored(newer ?? [])
    await store.finishLoad(1, result: .success(original))
    let earlier = try await old.value
    XCTAssertEqual(earlier, original)
    XCTAssertEqual(model.snapshots, [])
    XCTAssertNil(model.message)
    let failed = Task { try await model.loadSavedSnapshots() }
    await store.waitForLoad(3)
    await store.finishLoad(3, result: .failure(NewsImportError.unavailableStorage))
    do {
      _ = try await failed.value
      XCTFail("Expected read failure")
    } catch {}
    XCTAssertEqual(model.snapshots, [])
    XCTAssertNil(model.message)
    XCTAssertFalse(model.isBusy)
  }

  func testAbsentNewsIsEmptyAndRestoreLoadsOnlyOnce() async {
    let store = NewsStorageProbe()
    var commits = 0
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { news in
        XCTAssertEqual(news, [])
        return { commits += 1 }
      })
    await model.restore()
    await model.restore()
    XCTAssertEqual(model.snapshots, [])
    XCTAssertNil(model.message)
    XCTAssertEqual(commits, 1)
    let loads = await store.loadCount
    XCTAssertEqual(loads, 1)
  }

  func testFailedRestoreIsRetryableAndPreservesPriorStateAndBytes() async throws {
    let original = try samples()
    let corrupt = Data("invalid".utf8)
    let store = NewsStorageProbe(bytes: corrupt)
    var commits = 0
    let model = NewsImportModel(store: store, prepareReplacement: { _ in { commits += 1 } })
    model.adoptRestored(original, message: "Retry available")
    await model.restore()
    XCTAssertEqual(model.snapshots, original)
    XCTAssertTrue(model.message?.contains("Could not load local news") ?? false)
    XCTAssertEqual(commits, 0)
    let preserved = await store.bytes
    XCTAssertEqual(preserved, corrupt)
    await store.replaceBytes(try NewsSnapshotImporter.encode([]))
    await model.restore()
    XCTAssertEqual(model.snapshots, [])
    XCTAssertNil(model.message)
    XCTAssertEqual(commits, 1)
    let loads = await store.loadCount
    XCTAssertEqual(loads, 2)
  }

  func testCanceledRestoreSerializesAndCanRetryWithoutAdoptingLateData() async throws {
    let original = try samples()
    let store = NewsStorageProbe(pauseLoads: true)
    var commits = 0
    let model = NewsImportModel(store: store, prepareReplacement: { _ in { commits += 1 } })
    model.adoptRestored(original, message: "Retry available")
    let canceled = Task { await model.restore() }
    await store.waitForLoad(1)
    await model.restore()
    let loads = await store.loadCount
    XCTAssertEqual(loads, 1)
    XCTAssertTrue(model.isBusy)
    canceled.cancel()
    await store.finishLoad(1, result: .success([]))
    await canceled.value
    XCTAssertEqual(model.snapshots, original)
    XCTAssertEqual(model.message, "Retry available")
    XCTAssertFalse(model.isBusy)
    XCTAssertEqual(commits, 0)
    let retry = Task { await model.restore() }
    await store.waitForLoad(2)
    await store.finishLoad(2, result: .success([]))
    await retry.value
    XCTAssertEqual(model.snapshots, [])
    XCTAssertEqual(commits, 1)
  }

  func testFailedPreparationDoesNotSaveOrCommitAndImportCanRetry() async throws {
    let original = try samples()
    let bytes = try NewsSnapshotImporter.encode(original)
    let replacement = try validated([])
    let store = NewsStorageProbe(bytes: bytes)
    let rejection = NewsPreparationRejection()
    var commits = 0
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { _ in
        if rejection.reject { throw NewsImportError.invalid("The replacement cannot be composed.") }
        return { commits += 1 }
      }, readImport: { _ in replacement })
    model.adoptRestored(original)
    await model.importFile(at: importURL)
    XCTAssertEqual(model.snapshots, original)
    XCTAssertTrue(model.message?.contains("previous news is unchanged") ?? false)
    let saved = await store.bytes
    let writes = await store.saveCount
    XCTAssertEqual(saved, bytes)
    XCTAssertEqual(writes, 0)
    XCTAssertEqual(commits, 0)
    rejection.reject = false
    await model.importFile(at: importURL)
    XCTAssertEqual(model.snapshots, [])
    XCTAssertEqual(commits, 1)
  }

  func testSaveFailurePreservesDataAndNeverCommitsPreparedCandidate() async throws {
    let original = try samples()
    let bytes = try NewsSnapshotImporter.encode(original)
    let replacement = try validated([])
    let store = NewsStorageProbe(bytes: bytes, rejectSave: true)
    var prepares = 0
    var commits = 0
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { _ in
        prepares += 1
        return { commits += 1 }
      }, readImport: { _ in replacement })
    model.adoptRestored(original)
    await model.importFile(at: importURL)
    XCTAssertEqual(prepares, 1)
    XCTAssertEqual(commits, 0)
    XCTAssertEqual(model.snapshots, original)
    let saved = await store.bytes
    XCTAssertEqual(saved, bytes)
    XCTAssertTrue(model.message?.contains("previous news is unchanged") ?? false)
  }

  func testCancellationDuringNoncooperativeReadCannotPrepareOrSave() async throws {
    let original = try samples()
    let bytes = try NewsSnapshotImporter.encode(original)
    let replacement = try validated([])
    let store = NewsStorageProbe(bytes: bytes)
    let read = NewsReadGate()
    var prepares = 0
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { _ in
        prepares += 1
        return {}
      }, readImport: { _ in await read.read() })
    model.adoptRestored(original)
    let importing = Task { await model.importFile(at: importURL) }
    await read.waitUntilStarted()
    importing.cancel()
    await read.finish(replacement)
    await importing.value
    XCTAssertEqual(prepares, 0)
    XCTAssertEqual(model.snapshots, original)
    let saved = await store.bytes
    let writes = await store.saveCount
    XCTAssertEqual(saved, bytes)
    XCTAssertEqual(writes, 0)
  }

  func testCancellationAfterPreparationIsCheckedBeforeSave() async throws {
    let original = try samples()
    let bytes = try NewsSnapshotImporter.encode(original)
    let replacement = try validated([])
    let store = NewsStorageProbe(bytes: bytes)
    var commits = 0
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { _ in
        withUnsafeCurrentTask { $0?.cancel() }
        return { commits += 1 }
      }, readImport: { _ in replacement })
    model.adoptRestored(original)
    let importing = Task { await model.importFile(at: importURL) }
    await importing.value
    XCTAssertEqual(commits, 0)
    XCTAssertEqual(model.snapshots, original)
    let saved = await store.bytes
    let writes = await store.saveCount
    XCTAssertEqual(saved, bytes)
    XCTAssertEqual(writes, 0)
  }

  func testCancellationAfterDurableSaveStillAdoptsAndCommitsExactlyOnce() async throws {
    let original = try samples()
    let oldBytes = try NewsSnapshotImporter.encode(original)
    let replacement = try validated([])
    let store = NewsStorageProbe(bytes: oldBytes, pauseAfterSave: true)
    var commits = 0
    weak var adoptedModel: NewsImportModel?
    let model = NewsImportModel(
      store: store,
      prepareReplacement: { _ in
        {
          XCTAssertEqual(adoptedModel?.snapshots, [])
          XCTAssertEqual(adoptedModel?.message, "Imported 0 news snapshots.")
          XCTAssertEqual(adoptedModel?.isBusy, true)
          commits += 1
        }
      },
      readImport: { _ in replacement })
    adoptedModel = model
    model.adoptRestored(original)
    let importing = Task { await model.importFile(at: importURL) }
    await store.waitForDurableSave()
    let written = await store.bytes
    XCTAssertEqual(written, replacement.data)
    XCTAssertEqual(model.snapshots, original)
    importing.cancel()
    await store.finishSave()
    await importing.value
    XCTAssertEqual(model.snapshots, [])
    XCTAssertEqual(model.message, "Imported 0 news snapshots.")
    XCTAssertEqual(commits, 1)
    XCTAssertFalse(model.isBusy)
    await model.restore()
    let loads = await store.loadCount
    XCTAssertEqual(loads, 0)
    XCTAssertEqual(commits, 1)
  }

  private var importURL: URL { URL(fileURLWithPath: "/unused-controlled-import.json") }

  private func validated(_ snapshots: [NewsSnapshot]) throws -> ValidatedNewsImport {
    let data = try NewsSnapshotImporter.encode(snapshots)
    return ValidatedNewsImport(data: data, snapshots: try NewsSnapshotImporter.decode(data))
  }

  private func samples() throws -> [NewsSnapshot] {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "sample-news", withExtension: "json"))
    return try NewsSnapshotImporter.decode(Data(contentsOf: url))
  }
}

private actor NewsStorageProbe: NewsSnapshotStorage {
  private(set) var bytes: Data?
  private(set) var loadCount = 0
  private(set) var saveCount = 0
  private let pauseLoads: Bool
  private let pauseAfterSave: Bool
  private let rejectSave: Bool
  private var loads: [Int: CheckedContinuation<[NewsSnapshot]?, any Error>] = [:]
  private var loadWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
  private var save: CheckedContinuation<Void, Never>?
  private var saveWaiter: CheckedContinuation<Void, Never>?

  init(
    bytes: Data? = nil, pauseLoads: Bool = false, pauseAfterSave: Bool = false,
    rejectSave: Bool = false
  ) {
    self.bytes = bytes
    self.pauseLoads = pauseLoads
    self.pauseAfterSave = pauseAfterSave
    self.rejectSave = rejectSave
  }

  func load() async throws -> [NewsSnapshot]? {
    loadCount += 1
    if pauseLoads {
      let request = loadCount
      return try await withCheckedThrowingContinuation {
        loads[request] = $0
        loadWaiters.removeValue(forKey: request)?.resume()
      }
    }
    return try bytes.map(NewsSnapshotImporter.decode)
  }

  func save(_ data: Data) async throws {
    saveCount += 1
    if rejectSave { throw NewsImportError.unavailableStorage }
    try Task.checkCancellation()
    bytes = data
    if pauseAfterSave {
      await withCheckedContinuation {
        save = $0
        saveWaiter?.resume()
        saveWaiter = nil
      }
    }
  }

  func waitForLoad(_ request: Int) async {
    if loadCount >= request { return }
    await withCheckedContinuation { loadWaiters[request] = $0 }
  }

  func finishLoad(_ request: Int, result: Result<[NewsSnapshot]?, any Error>) {
    loads.removeValue(forKey: request)?.resume(with: result)
  }

  func replaceBytes(_ data: Data) { bytes = data }

  func waitForDurableSave() async {
    if save != nil { return }
    await withCheckedContinuation { saveWaiter = $0 }
  }

  func finishSave() {
    save?.resume()
    save = nil
  }
}

private actor NewsReadGate {
  private var continuation: CheckedContinuation<ValidatedNewsImport, Never>?
  private var waiter: CheckedContinuation<Void, Never>?

  func read() async -> ValidatedNewsImport {
    await withCheckedContinuation {
      continuation = $0
      waiter?.resume()
      waiter = nil
    }
  }

  func waitUntilStarted() async {
    if continuation != nil { return }
    await withCheckedContinuation { waiter = $0 }
  }

  func finish(_ imported: ValidatedNewsImport) {
    continuation?.resume(returning: imported)
    continuation = nil
  }
}

@MainActor
private final class NewsPreparationRejection { var reject = true }
