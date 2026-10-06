import Foundation

@MainActor
enum StreakComposition {
  static func makeModel() -> DailyStreakModel {
    #if DEBUG
      if CommandLine.arguments.contains("-sidequest-streak-fixtures"),
        let defaults = UserDefaults(suiteName: "SidequestDailyStreakFixtures")
      {
        let storage = UserDefaultsStreakStorage(defaults: defaults)
        if CommandLine.arguments.contains("-sidequest-streak-reset") {
          defaults.removeObject(forKey: storage.key)
        }
        return DailyStreakModel(storage: storage)
      }
    #endif
    return DailyStreakModel(storage: UserDefaultsStreakStorage())
  }
}
