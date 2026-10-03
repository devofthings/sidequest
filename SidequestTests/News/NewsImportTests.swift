import Foundation
import XCTest

@testable import Sidequest

final class NewsImportTests: XCTestCase {
  func testBundledSamplesRoundTripAndRetainProvenance() throws {
    let snapshots = try samples()
    XCTAssertEqual(snapshots.count, 2)
    XCTAssertTrue(snapshots.allSatisfy(\.isSample))
    XCTAssertNotNil(snapshots.first?.publishedAt)
    XCTAssertEqual(
      try NewsSnapshotImporter.decode(NewsSnapshotImporter.encode(snapshots)), snapshots)
    XCTAssertEqual(
      try NewsSnapshotImporter.decode(Data("{\"schemaVersion\":1,\"snapshots\":[]}".utf8)), [])
  }

  func testInvalidDocumentsGiveActionableErrors() throws {
    var document = try sampleObject()
    document["schemaVersion"] = 9
    XCTAssertThrowsError(try decode(document)) {
      XCTAssertEqual($0 as? NewsImportError, .unsupportedSchema(9))
    }
    document = try sampleObject()
    var snapshots = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
    let first = snapshots[0]
    snapshots.append(first)
    document["snapshots"] = snapshots
    XCTAssertThrowsError(try decode(document)) {
      XCTAssertTrue($0.localizedDescription.contains("repeats"))
    }
    for field in ["id", "headline", "excerpt", "publisher", "sourceURL", "capturedAt", "isSample"] {
      document = try sampleObject()
      snapshots = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
      snapshots[0].removeValue(forKey: field)
      document["snapshots"] = snapshots
      XCTAssertThrowsError(try decode(document)) {
        XCTAssertTrue($0.localizedDescription.contains(field))
      }
    }
    for (field, value) in [
      ("headline", " "), ("sourceURL", "file:///tmp/article"), ("capturedAt", "yesterday"),
    ] {
      document = try sampleObject()
      snapshots = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
      snapshots[0][field] = value
      document["snapshots"] = snapshots
      XCTAssertThrowsError(try decode(document))
    }
    XCTAssertThrowsError(try NewsSnapshotImporter.decode(Data("not JSON".utf8)))
    XCTAssertThrowsError(
      try NewsSnapshotImporter.decode(
        Data(repeating: 0, count: NewsSnapshotImporter.maximumBytes + 1))
    ) {
      XCTAssertEqual($0 as? NewsImportError, .oversized)
    }
  }

  func testFractionalTimestampAndTimeZoneAreAccepted() throws {
    var document = try sampleObject()
    var snapshots = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
    snapshots[0]["capturedAt"] = "2024-01-01T02:00:00.125+02:00"
    document["snapshots"] = snapshots
    let imported = try decode(document)
    XCTAssertEqual(
      try XCTUnwrap(imported.first).capturedAt.timeIntervalSince1970, 1_704_067_200.125,
      accuracy: 0.001)
  }

  func testInvalidCalendarDatesSuffixesAndOffsetsAreRejectedForBothDates() throws {
    for field in ["capturedAt", "publishedAt"] {
      for raw in [
        "2024-02-30T00:00:00Z", "2023-02-29T00:00:00Z", "2024-01-01T00:00:00Zgarbage",
        "2024-01-01T00:00:00+99:00", "2024-01-01T00:00:00+00:99", "2024-01-01T24:00:00Z",
        "2024-01-01T00:00:00", "2024-01-01T00:00:00Z\n",
      ] {
        var document = try sampleObject()
        var entries = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
        entries[0][field] = raw
        document["snapshots"] = entries
        XCTAssertThrowsError(try decode(document), "\(field) accepted \(raw)")
      }
    }
    var document = try sampleObject()
    var entries = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
    entries[0]["capturedAt"] = "2024-02-29T12:34:56-05:30"
    document["snapshots"] = entries
    XCTAssertNoThrow(try decode(document))
  }

  @MainActor
  func testAbsentFolderSaveReloadAndRejectedImportPreservesSavedSet() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    let absent = try await store.load()
    XCTAssertNil(absent)
    let originals = try samples()
    try await store.save(NewsSnapshotImporter.encode(originals))
    let restored = try await store.load()
    XCTAssertEqual(restored, originals)
    let invalid = directory.appendingPathComponent("invalid.json")
    try Data("invalid".utf8).write(to: invalid)
    let model = NewsImportModel(store: store)
    await model.restore()
    await model.importFile(at: invalid)
    XCTAssertEqual(model.snapshots, originals)
    XCTAssertTrue(try XCTUnwrap(model.message).contains("previous news is unchanged"))
    let savedAfterFailure = try await store.load()
    XCTAssertEqual(savedAfterFailure, originals)
    let replacement = directory.appendingPathComponent("replacement.json")
    try NewsSnapshotImporter.encode([]).write(to: replacement)
    await model.importFile(at: replacement)
    XCTAssertEqual(model.snapshots, [])
    let savedEmpty = try await store.load()
    XCTAssertEqual(savedEmpty, [])
  }

  @MainActor
  func testCanceledReadDoesNotPersistNewInput() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    try await store.save(NewsSnapshotImporter.encode(samples()))
    let task = Task {
      try Task.checkCancellation()
      return try await LocalNewsStore.readImport(at: store.fileURL)
    }
    task.cancel()
    do {
      _ = try await task.value
      XCTFail("Canceled input must not succeed.")
    } catch is CancellationError {}
    let retained = try await store.load()
    XCTAssertEqual(retained, try samples())
  }

  @MainActor
  func testPersistedImportRetainsOriginalBytesAndTimestampPrecision() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    var document = try sampleObject()
    var entries = try XCTUnwrap(document["snapshots"] as? [[String: Any]])
    entries[0]["capturedAt"] = "2024-01-01T02:00:00.125+02:00"
    document["snapshots"] = entries
    let bytes = try JSONSerialization.data(withJSONObject: document)
    let source = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: source) }
    try bytes.write(to: source)
    let model = NewsImportModel(store: store)
    await model.importFile(at: source)
    XCTAssertEqual(try Data(contentsOf: store.fileURL), bytes)
    let restored = try await store.load()
    XCTAssertEqual(
      try XCTUnwrap(restored?.first).capturedAt.timeIntervalSince1970, 1_704_067_200.125,
      accuracy: 0.001)
    XCTAssertThrowsError(try NewsSnapshotImporter.decode(Data("invalid".utf8)))
  }

  private func sampleObject() throws -> [String: Any] {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "sample-news", withExtension: "json"))
    return try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
  }

  private func samples() throws -> [NewsSnapshot] { try decode(sampleObject()) }
  private func decode(_ object: [String: Any]) throws -> [NewsSnapshot] {
    try NewsSnapshotImporter.decode(JSONSerialization.data(withJSONObject: object))
  }
}
