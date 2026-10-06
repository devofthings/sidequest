import Foundation
import XCTest

@testable import Sidequest

final class DailyStreakTests: XCTestCase {
  private func date(_ value: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: value))
  }

  private func calendar(_ zone: String = "Europe/Berlin") throws -> Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = try XCTUnwrap(TimeZone(identifier: zone))
    return value
  }

  func testConsecutiveLocalDaysRepeatedActivityGapAndBackwardClock() throws {
    let calendar = try calendar()
    func day(_ value: String) throws -> StreakDay {
      StreakDay(date: try date(value), calendar: calendar)
    }
    var record = DailyStreakRecord()
    XCTAssertEqual(record.displayedCount(on: try day("2026-10-06T10:00:00Z")), 0)
    XCTAssertTrue(record.qualify(on: try day("2026-10-06T10:00:00Z")))
    XCTAssertFalse(record.qualify(on: try day("2026-10-06T22:00:00+02:00")))
    XCTAssertEqual(record.count, 1)
    XCTAssertEqual(record.displayedCount(on: try day("2026-10-07T10:00:00Z")), 1)
    XCTAssertTrue(record.qualify(on: try day("2026-10-07T10:00:00Z")))
    XCTAssertEqual(record.count, 2)
    XCTAssertFalse(record.qualify(on: try day("2026-10-06T10:00:00Z")))
    XCTAssertEqual(record.count, 2)
    XCTAssertEqual(record.displayedCount(on: try day("2026-10-09T10:00:00Z")), 0)
    XCTAssertTrue(record.qualify(on: try day("2026-10-09T10:00:00Z")))
    XCTAssertEqual(record.count, 1)
  }

  func testDayArithmeticAcrossDSTLeapDayAndYearBoundary() throws {
    let calendar = try calendar()
    for pair in [
      ("2026-03-28T23:30:00+01:00", "2026-03-29T23:30:00+02:00"),
      ("2026-10-24T23:30:00+02:00", "2026-10-25T23:30:00+01:00"),
      ("2028-02-28T12:00:00Z", "2028-02-29T12:00:00Z"),
      ("2026-12-31T12:00:00Z", "2027-01-01T12:00:00Z"),
    ] {
      var record = DailyStreakRecord()
      record.qualify(on: StreakDay(date: try date(pair.0), calendar: calendar))
      record.qualify(on: StreakDay(date: try date(pair.1), calendar: calendar))
      XCTAssertEqual(record.count, 2)
    }
  }

  @MainActor
  func testReopeningDoesNotQualifyAndPersistenceRestoresAfterMidnight() throws {
    let storage = MemoryStreakStorage()
    var now = try date("2026-10-06T10:00:00Z")
    let calendar = try calendar()
    let first = DailyStreakModel(storage: storage, now: { now }, calendar: { calendar })
    XCTAssertEqual(first.count, 0)
    first.refresh()
    XCTAssertNil(storage.record)
    first.qualify()
    XCTAssertEqual(first.count, 1)
    now = try date("2026-10-07T10:00:00Z")
    let reopened = DailyStreakModel(storage: storage, now: { now }, calendar: { calendar })
    XCTAssertEqual(reopened.count, 1)
    reopened.qualify()
    XCTAssertEqual(reopened.count, 2)
    now = try date("2026-10-09T10:00:00Z")
    reopened.refresh()
    XCTAssertEqual(reopened.count, 0)
    reopened.qualify()
    XCTAssertEqual(reopened.count, 1)
  }

  @MainActor
  func testUnreadableRecordIsPreservedAndSaveFailureIsTemporaryAndRetryable() throws {
    let calendar = try calendar()
    let now = try date("2026-10-06T10:00:00Z")
    let storage = MemoryStreakStorage()
    storage.failLoad = true
    let unreadable = DailyStreakModel(storage: storage, now: { now }, calendar: { calendar })
    unreadable.qualify()
    XCTAssertEqual(unreadable.count, 1)
    XCTAssertNotNil(unreadable.status)
    XCTAssertEqual(storage.saves, 0)
    storage.failLoad = false
    storage.failSave = true
    let failedSave = DailyStreakModel(storage: storage, now: { now }, calendar: { calendar })
    failedSave.qualify()
    XCTAssertEqual(failedSave.count, 1)
    XCTAssertNotNil(failedSave.status)
    storage.failSave = false
    failedSave.qualify()
    XCTAssertNil(failedSave.status)
    XCTAssertEqual(storage.record?.count, 1)
  }

  func testUserDefaultsRoundTripAndInvalidBytesStayIntact() throws {
    let name = "SidequestStreakTests.\(UUID())"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let store = UserDefaultsStreakStorage(defaults: defaults)
    XCTAssertNil(try store.load())
    var record = DailyStreakRecord()
    record.qualify(on: StreakDay(date: try date("2026-10-06T10:00:00Z"), calendar: try calendar()))
    try store.save(record)
    XCTAssertEqual(try store.load(), record)
    let invalid = Data(
      "{\"count\":2,\"lastQualifiedDay\":{\"year\":2026,\"month\":2,\"day\":30}}".utf8)
    defaults.set(invalid, forKey: store.key)
    XCTAssertThrowsError(try store.load())
    XCTAssertEqual(defaults.data(forKey: store.key), invalid)
  }

  @MainActor
  func testOnlyAcceptedPhysicalNavigationEmitsQualification() throws {
    let ids = try [CardID("first"), CardID("second")]
    let runtimes = ids.map { _ in GameRuntime() }
    for runtime in runtimes { runtime.installEffectHandler { _ in } }
    let feed = FeedController(
      cards: ids.map { .game(GameCard(id: $0, kind: .memory)) },
      runtimes: Dictionary(uniqueKeysWithValues: zip(ids, runtimes)))
    var events = 0
    feed.physicalSwipeDidCommit = { events += 1 }
    feed.commitPage(at: 1, origin: .physicalSwipe)
    XCTAssertEqual(events, 0)
    feed.setSceneActive(true)
    feed.commitPage(at: 0, origin: .physicalSwipe)
    feed.next()
    feed.previous()
    XCTAssertEqual(events, 0)
    feed.windowDidChange = { _ in .failure(.preparationFailed) }
    feed.commitPage(at: 1, origin: .physicalSwipe)
    XCTAssertEqual(events, 0)
    feed.windowDidChange = nil
    feed.commitPage(at: 1, origin: .physicalSwipe)
    feed.commitPage(at: 0, origin: .physicalSwipe)
    XCTAssertEqual(events, 2)
    feed.retire()
    feed.commitPage(at: 1, origin: .physicalSwipe)
    XCTAssertEqual(events, 2)
  }

  @MainActor
  func testSuccessObserverRejectsLossDuplicateHiddenAndRestoredCompletion() {
    var events = 0
    let runtime = GameRuntime(successHaptic: {})
    runtime.installEffectHandler { _ in }
    runtime.installSuccessfulCompletionHandler { events += 1 }
    runtime.setVisible(true)
    runtime.start()
    guard case .playing(let loss) = runtime.phase else { return XCTFail("Missing attempt") }
    runtime.complete(attempt: loss)
    XCTAssertEqual(events, 0)
    XCTAssertTrue(runtime.replay())
    guard case .playing(let win) = runtime.phase else { return XCTFail("Missing replay attempt") }
    runtime.complete(attempt: win, successful: true)
    runtime.complete(attempt: win, successful: true)
    XCTAssertEqual(events, 1)
    runtime.setVisible(false)
    runtime.setVisible(true)
    XCTAssertEqual(events, 1)
    let restored = GameRuntime(completed: win, successHaptic: {})
    restored.installEffectHandler { _ in }
    restored.installSuccessfulCompletionHandler { events += 1 }
    restored.setVisible(true)
    restored.complete(attempt: win, successful: true)
    XCTAssertEqual(events, 1)
    runtime.replay()
    guard case .playing(let stale) = runtime.phase else { return XCTFail("Missing attempt") }
    runtime.setVisible(false)
    runtime.complete(attempt: stale, successful: true)
    XCTAssertEqual(events, 1)
  }
}

private final class MemoryStreakStorage: DailyStreakStorage {
  var record: DailyStreakRecord?
  var failLoad = false
  var failSave = false
  var saves = 0
  func load() throws -> DailyStreakRecord? {
    if failLoad { throw Failure.unavailable }
    return record
  }
  func save(_ record: DailyStreakRecord) throws {
    if failSave { throw Failure.unavailable }
    saves += 1
    self.record = record
  }
  private enum Failure: Error { case unavailable }
}
