import Foundation

/// RFC 3339 is the zoned ISO 8601 form used by the JSON schema. Foundation's
/// formatter normalizes invalid dates and accepts suffixes, so validate fully.
enum NewsTimestamp {
  static func parse(_ raw: String) throws -> Date? {
    let expression = try NSRegularExpression(
      pattern:
        #"\A([0-9]{4})-([0-9]{2})-([0-9]{2})[Tt]([0-9]{2}):([0-9]{2}):([0-9]{2})(?:\.([0-9]+))?([Zz]|([+-])([0-9]{2}):([0-9]{2}))\z"#
    )
    let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
    guard let match = expression.firstMatch(in: raw, range: range) else { return nil }
    func component(_ index: Int) -> String? {
      guard let range = Range(match.range(at: index), in: raw) else { return nil }
      return String(raw[range])
    }
    let numbers = (1...6).compactMap { component($0).flatMap(Int.init) }
    guard numbers.count == 6 else { return nil }
    let year = numbers[0]
    let month = numbers[1]
    let day = numbers[2]
    let hour = numbers[3]
    let minute = numbers[4]
    let second = numbers[5]
    guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day),
      (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second)
    else { return nil }
    var offsetSeconds = 0
    if let sign = component(9), let hours = component(10).flatMap(Int.init),
      let minutes = component(11).flatMap(Int.init)
    {
      guard hours <= 23, minutes <= 59 else { return nil }
      offsetSeconds = (hours * 3600 + minutes * 60) * (sign == "+" ? 1 : -1)
    }
    // Count Gregorian days directly: Foundation calendars use a historical
    // Julian/Gregorian cutover, whereas RFC 3339 applies Gregorian leap rules.
    let leapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    let monthLengths = [31, leapYear ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    guard day <= monthLengths[month - 1] else { return nil }
    let previousYear = year - 1
    let daysBeforeYear =
      previousYear * 365 + previousYear / 4 - previousYear / 100 + previousYear / 400
    let daysBeforeMonth = monthLengths.prefix(month - 1).reduce(0, +)
    // 719162 is the number of Gregorian days preceding 1970-01-01.
    let daysSinceEpoch = daysBeforeYear + daysBeforeMonth + day - 1 - 719_162
    let secondsSinceEpoch = daysSinceEpoch * 86_400 + hour * 3600 + minute * 60 + second
    let fraction = component(7).flatMap { Double("0." + $0) } ?? 0
    return Date(timeIntervalSince1970: Double(secondsSinceEpoch - offsetSeconds) + fraction)
  }
}
