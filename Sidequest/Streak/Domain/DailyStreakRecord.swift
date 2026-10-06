import Foundation

/// Local Gregorian day identifiers avoid treating daylight-saving changes as 24-hour days.
struct StreakDay: Codable, Equatable, Comparable, Sendable {
  let year: Int
  let month: Int
  let day: Int

  init(date: Date, calendar: Calendar) {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    year = parts.year ?? 0
    month = parts.month ?? 0
    day = parts.day ?? 0
  }

  private var ordinal: Int? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    let parts = DateComponents(year: year, month: month, day: day)
    guard let date = calendar.date(from: parts),
      calendar.component(.year, from: date) == year,
      calendar.component(.month, from: date) == month,
      calendar.component(.day, from: date) == day
    else { return nil }
    return Int((date.timeIntervalSince1970 / 86400).rounded(.down))
  }

  var isValid: Bool { (1...9999).contains(year) && ordinal != nil }

  func distance(to other: StreakDay) -> Int? {
    guard let start = ordinal, let end = other.ordinal else { return nil }
    return end - start
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
  }
}

struct DailyStreakRecord: Codable, Equatable, Sendable {
  private(set) var count: Int = 0
  private(set) var lastQualifiedDay: StreakDay?

  var isValid: Bool {
    if count == 0 { return lastQualifiedDay == nil }
    return (1...3_652_425).contains(count) && lastQualifiedDay?.isValid == true
  }

  func displayedCount(on day: StreakDay) -> Int {
    guard let lastQualifiedDay, let elapsed = lastQualifiedDay.distance(to: day) else { return 0 }
    // Moving the clock backward never credits another day or destroys the high-water record.
    return elapsed <= 1 ? count : 0
  }

  @discardableResult
  mutating func qualify(on day: StreakDay) -> Bool {
    guard day.isValid else { return false }
    if let lastQualifiedDay {
      guard let elapsed = lastQualifiedDay.distance(to: day), elapsed > 0 else { return false }
      count = elapsed == 1 ? min(count + 1, 3_652_425) : 1
    } else {
      count = 1
    }
    lastQualifiedDay = day
    return true
  }
}

protocol DailyStreakStorage {
  func load() throws -> DailyStreakRecord?
  func save(_ record: DailyStreakRecord) throws
}
