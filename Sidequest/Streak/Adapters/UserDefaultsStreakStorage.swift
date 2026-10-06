import Foundation

/// A tiny local preference, independent of private news imports and account services.
struct UserDefaultsStreakStorage: DailyStreakStorage {
  let defaults: UserDefaults
  let key: String

  init(defaults: UserDefaults = .standard, key: String = "sidequest.dailyStreak.v1") {
    self.defaults = defaults
    self.key = key
  }

  func load() throws -> DailyStreakRecord? {
    guard let value = defaults.object(forKey: key) else { return nil }
    guard let data = value as? Data, data.count <= 1024 else { throw Failure.invalidRecord }
    let record = try JSONDecoder().decode(DailyStreakRecord.self, from: data)
    guard record.isValid else { throw Failure.invalidRecord }
    return record
  }

  func save(_ record: DailyStreakRecord) throws {
    guard record.isValid else { throw Failure.invalidRecord }
    defaults.set(try JSONEncoder().encode(record), forKey: key)
  }

  enum Failure: Error { case invalidRecord }
}
