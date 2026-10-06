import Foundation
import Observation

@MainActor
@Observable
final class DailyStreakModel {
  private(set) var count = 0
  private(set) var status: String?
  private var record = DailyStreakRecord()
  @ObservationIgnored private let storage: any DailyStreakStorage
  @ObservationIgnored private let now: () -> Date
  @ObservationIgnored private let calendar: () -> Calendar
  @ObservationIgnored private var storageIsReadable = true
  @ObservationIgnored private var isActive = false
  @ObservationIgnored private var rolloverTask: Task<Void, Never>?

  init(
    storage: any DailyStreakStorage,
    now: @escaping () -> Date = Date.init,
    calendar: @escaping () -> Calendar = {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = .current
      return calendar
    }
  ) {
    self.storage = storage
    self.now = now
    self.calendar = calendar
    do {
      if let saved = try storage.load() {
        guard saved.isValid else { throw Failure.invalidRecord }
        record = saved
      }
    } catch {
      storageIsReadable = false
      status = "Daily streak is temporary because its saved record could not be read."
    }
    refresh()
  }

  deinit { rolloverTask?.cancel() }

  func qualify() {
    let day = StreakDay(date: now(), calendar: calendar())
    _ = record.qualify(on: day)
    if storageIsReadable {
      do {
        try storage.save(record)
        status = nil
      } catch {
        status = "Daily streak is temporary because it could not be saved."
      }
    }
    refresh()
  }

  func refresh() {
    count = record.displayedCount(on: StreakDay(date: now(), calendar: calendar()))
  }

  func setSceneActive(_ active: Bool) {
    isActive = active
    rolloverTask?.cancel()
    rolloverTask = nil
    refresh()
    guard active else { return }
    scheduleRolloverCheck()
  }

  private func scheduleRolloverCheck() {
    let date = now()
    let calendar = calendar()
    guard let next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
    else { return }
    // Recheck periodically for time-zone/clock changes, without retaining the owner while asleep.
    let seconds = min(60, max(1, next.timeIntervalSince(date)))
    rolloverTask = Task { @MainActor [weak self] in
      do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
      guard !Task.isCancelled, let self, self.isActive else { return }
      self.refresh()
      self.scheduleRolloverCheck()
    }
  }

  private enum Failure: Error { case invalidRecord }
}
