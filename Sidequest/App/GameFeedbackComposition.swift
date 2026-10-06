import Foundation

@MainActor
enum GameFeedbackComposition {
  static var initialCelebrationStyle: SuccessCelebrationStyle {
    #if DEBUG
      let arguments = CommandLine.arguments
      if arguments.contains("-sidequest-success-feedback-test"),
        arguments.contains("-sidequest-chess-white-fixture"),
        let flag = arguments.firstIndex(of: "-sidequest-celebration-style"),
        arguments.indices.contains(flag + 1),
        let index = Int(arguments[flag + 1]),
        let style = SuccessCelebrationStyle(rawValue: index)
      {
        return style
      }
    #endif
    return SuccessCelebrationStyle.allCases.randomElement() ?? .pop
  }

  static func makeRuntime(completed: GameAttemptID? = nil) -> GameRuntime {
    #if DEBUG
      let arguments = CommandLine.arguments
      let realFixtureFlags = [
        "-sidequest-sudoku-test", "-sidequest-memory-fixtures", "-sidequest-chess-white-fixture",
        "-sidequest-chess-black-fixture", "-sidequest-bubble-fixtures",
      ]
      if arguments.contains("-sidequest-success-feedback-test"),
        realFixtureFlags.contains(where: arguments.contains)
      {
        // Only presentation lifetime changes, so XCTest can observe real game outcomes reliably.
        return GameRuntime(
          completed: completed, activationPolicy: .firstInteraction,
          celebrationDelay: {
            try await Task.sleep(for: .seconds(10))
          })
      }
    #endif
    return GameRuntime(completed: completed, activationPolicy: .firstInteraction)
  }
}
