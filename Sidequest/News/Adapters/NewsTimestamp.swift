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
    var calendar = Calendar(identifier: .gregorian)
    guard let utc = TimeZone(secondsFromGMT: 0) else { return nil }
    calendar.timeZone = utc
    let components = DateComponents(
      year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    guard let local = calendar.date(from: components) else { return nil }
    let recovered = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: local)
    guard recovered.year == year, recovered.month == month, recovered.day == day,
      recovered.hour == hour, recovered.minute == minute, recovered.second == second
    else { return nil }
    let fraction = component(7).flatMap { Double("0." + $0) } ?? 0
    return local.addingTimeInterval(fraction - Double(offsetSeconds))
  }
}
