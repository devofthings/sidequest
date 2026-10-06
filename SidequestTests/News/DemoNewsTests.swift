import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class DemoNewsTests: XCTestCase {
  func testActualBundledDemoIsVariedFictionalReadableAndSeparateFromLegacySamples() async throws {
    let stories = try await DemoNewsLoader.bundled()
    XCTAssertEqual(stories.count, 30)
    XCTAssertEqual(Set(stories.map(\.id)).count, 30)
    XCTAssertEqual(Set(stories.map(\.headline)).count, 30)
    XCTAssertEqual(Set(stories.map(\.sourceURL)).count, 30)
    for (index, story) in stories.enumerated() {
      XCTAssertEqual(story.id.rawValue, String(format: "demo-news-%02d", index + 1))
      XCTAssertEqual(story.publisher, "Sidequest Demo")
      XCTAssertTrue(story.isSample)
      XCTAssertNil(story.publishedAt)
      XCTAssertEqual(story.sourceURL.host, "example.com")
      XCTAssertEqual(story.capturedAt, try NewsTimestamp.parse("2026-10-04T00:00:00Z"))
      let words = story.excerpt.split(whereSeparator: { $0.isWhitespace }).count
      XCTAssertGreaterThanOrEqual(words, 80)
      XCTAssertLessThanOrEqual(words, 140)
    }
    let oldURL = try XCTUnwrap(Bundle.main.url(forResource: "sample-news", withExtension: "json"))
    let legacy = try await LocalNewsStore.samples(in: oldURL)
    XCTAssertEqual(legacy.count, 2)
  }

  func testExplicitBundledDemoImportReplacesSavedPoolThroughTheOrdinaryTransaction() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    let demo = try await DemoNewsLoader.bundled()
    try await store.save(NewsSnapshotImporter.encode(Array(demo.suffix(1))))
    let session = FeedSessionState(bidirectional: false)
    let model = NewsImportModel(
      store: store, usesDemoWhenMissing: true, beginReplacement: session.beginReplacement)
    await session.prepare(newsModel: model)
    XCTAssertEqual(model.snapshots, Array(demo.suffix(1)))
    let url = try XCTUnwrap(Bundle.main.url(forResource: "demo-news", withExtension: "json"))
    let bytes = try Data(contentsOf: url)
    await model.importFile(at: url)
    XCTAssertEqual(model.snapshots, demo)
    XCTAssertEqual(try Data(contentsOf: store.fileURL), bytes)
    guard case .ready(let replacement) = session.state,
      let controller = replacement.controller,
      case .news(let appearance) = controller.cards[5]
    else { return XCTFail("Expected cadence-bearing replacement") }
    XCTAssertEqual(appearance.snapshot, demo[0])
    XCTAssertNotEqual(appearance.id, demo[0].id)
    controller.retire()
  }

  func testNilOnlyDemoResolutionDoesNotSaveAndIntentionalEmptyOrPrivateNewsWins() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    let model = NewsImportModel(store: store, usesDemoWhenMissing: true)
    await model.restore()
    XCTAssertEqual(model.snapshots.count, 30)
    let savedDocument = try await store.load()
    XCTAssertNil(savedDocument)
    XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    try await store.save(NewsSnapshotImporter.encode([]))
    let empty = NewsImportModel(store: store, usesDemoWhenMissing: true)
    await empty.restore()
    XCTAssertEqual(empty.snapshots, [])
    XCTAssertNil(empty.message)
    let source = try XCTUnwrap(model.snapshots.first)
    let privateStory = try NewsSnapshot(
      id: CardID("personal-story"), headline: source.headline, excerpt: source.excerpt,
      publisher: "Original test source", sourceURL: source.sourceURL,
      capturedAt: source.capturedAt, isSample: false)
    let bytes = try NewsSnapshotImporter.encode([privateStory])
    try await store.save(bytes)
    let saved = NewsImportModel(store: store, usesDemoWhenMissing: true)
    await saved.restore()
    XCTAssertEqual(saved.snapshots, [privateStory])
    XCTAssertEqual(try Data(contentsOf: store.fileURL), bytes)
  }

  func testCorruptionDoesNotActivateDemosAndRetryUsesSameNilOnlyPolicy() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LocalNewsStore(directory: directory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let broken = Data("corrupt private bytes".utf8)
    try broken.write(to: store.fileURL)
    let session = FeedSessionState(bidirectional: false)
    let model = NewsImportModel(
      store: store, usesDemoWhenMissing: true, beginReplacement: session.beginReplacement)
    await session.prepare(newsModel: model)
    guard case .ready(let old) = session.state else {
      return XCTFail("Games should remain available")
    }
    XCTAssertEqual(old.controller?.count, 8)
    XCTAssertEqual(model.snapshots, [])
    XCTAssertTrue(model.canRetryRestore)
    XCTAssertEqual(try Data(contentsOf: store.fileURL), broken)
    try FileManager.default.removeItem(at: store.fileURL)
    await model.restore()
    XCTAssertEqual(model.snapshots.count, 30)
    guard case .ready(let replacement) = session.state else {
      return XCTFail("Expected replacement")
    }
    XCTAssertEqual(replacement.controller?.count, 9)
    XCTAssertFalse(old === replacement)
    let savedDocument = try await store.load()
    XCTAssertNil(savedDocument)
    old.controller?.retire()
    replacement.controller?.retire()
  }

  func testUnavailableStoreAndFailingDemoRemainRecoverableWithoutFabricatingContent() async throws {
    let unavailable = NewsImportModel(store: nil, usesDemoWhenMissing: true)
    await unavailable.restore()
    XCTAssertEqual(unavailable.snapshots, [])
    XCTAssertTrue(unavailable.canRetryRestore)
    let probe = DemoReadProbe()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = LocalNewsStore(directory: directory)
    let session = FeedSessionState(bidirectional: false)
    let model = NewsImportModel(
      store: store, usesDemoWhenMissing: true,
      loadDemo: { try await probe.load() }, beginReplacement: session.beginReplacement)
    await session.prepare(newsModel: model)
    guard case .ready(let old) = session.state else { return XCTFail("Expected recoverable games") }
    XCTAssertEqual(old.controller?.count, 8)
    XCTAssertEqual(model.snapshots, [])
    XCTAssertTrue(model.canRetryRestore)
    await model.restore()
    XCTAssertEqual(model.snapshots.count, 30)
    XCTAssertFalse(model.canRetryRestore)
    let savedDocument = try await store.load()
    XCTAssertNil(savedDocument)
    if case .ready(let current) = session.state { current.controller?.retire() }
    old.controller?.retire()
  }

  func testActualStoreDistinguishesMissingFromInvalidPathsDanglingLinksAndOversizedData()
    async throws
  {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let missing = LocalNewsStore(directory: root.appendingPathComponent("absent"))
    let absent = try await missing.load()
    XCTAssertNil(absent)
    let invalidDirectory = root.appendingPathComponent("regular-file")
    try Data("not a directory".utf8).write(to: invalidDirectory)
    await assertFails(LocalNewsStore(directory: invalidDirectory))
    let store = LocalNewsStore(directory: root)
    try FileManager.default.createDirectory(at: store.fileURL, withIntermediateDirectories: true)
    await assertFails(store)
    try FileManager.default.removeItem(at: store.fileURL)
    try FileManager.default.createSymbolicLink(
      at: store.fileURL, withDestinationURL: root.appendingPathComponent("missing-target"))
    await assertFails(store)
    try FileManager.default.removeItem(at: store.fileURL)
    let danglingParent = root.appendingPathComponent("dangling-parent")
    try FileManager.default.createSymbolicLink(
      at: danglingParent, withDestinationURL: root.appendingPathComponent("missing-directory"))
    await assertFails(LocalNewsStore(directory: danglingParent))
    try Data(repeating: 0, count: NewsSnapshotImporter.maximumBytes + 1).write(to: store.fileURL)
    await assertFails(store)
    try Data("unreadable".utf8).write(to: store.fileURL)
    try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: store.fileURL.path)
    await assertFails(store)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o600], ofItemAtPath: store.fileURL.path)
  }

  private func assertFails(_ store: LocalNewsStore) async {
    do {
      _ = try await store.load()
      XCTFail("An existing invalid or inaccessible path cannot be ordinary absence")
    } catch {}
  }
}

private actor DemoReadProbe {
  private var attempts = 0
  func load() async throws -> [NewsSnapshot] {
    attempts += 1
    if attempts == 1 { throw NewsImportError.invalid("Demo resource unavailable.") }
    return try await DemoNewsLoader.bundled()
  }
}
