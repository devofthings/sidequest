import XCTest

@testable import Sidequest

@MainActor
final class MemoryWorkloadControllerTests: XCTestCase {
  func testFrozenChallengeResetCompletionAndRestorationForEveryWorkload() throws {
    for difficulty in [GameDifficulty.easy, .medium, .hard] {
      let challenge = MemoryChallenge(difficulty: difficulty, seed: 178)
      let runtime = GameRuntime()
      let controller = try MemoryController(runtime: runtime, challenge: challenge)
      XCTAssertEqual(controller.displayedRules, challenge.rules)
      controller.flip(0)
      XCTAssertNil(controller.rules)
      runtime.setVisible(true)
      runtime.start()
      controller.flip(0)
      runtime.setVisible(false)
      XCTAssertNil(controller.rules)
      XCTAssertEqual(controller.challenge, challenge)
      runtime.setVisible(true)
      runtime.start()
      XCTAssertEqual(controller.rules, challenge.rules)
      for symbol in Set(challenge.rules.symbols) {
        let indices = challenge.rules.symbols.indices.filter {
          challenge.rules.symbols[$0] == symbol
        }
        controller.flip(indices[0])
        controller.flip(indices[1])
      }
      let completed = try XCTUnwrap(controller.rules)
      XCTAssertTrue(completed.isCompleted)
      runtime.setVisible(false)
      runtime.setVisible(true)
      XCTAssertEqual(controller.rules, completed)
      XCTAssertEqual(controller.challenge, challenge)
      let restored = try MemoryController(
        runtime: GameRuntime(), challenge: challenge, completedRules: completed)
      XCTAssertEqual(restored.rules, completed)
      XCTAssertEqual(restored.challenge, challenge)
    }
  }

  func testChallengeRestorationRejectsIncompleteAndUnrelatedResults() throws {
    let challenge = MemoryChallenge(difficulty: .easy, seed: 1)
    XCTAssertThrowsError(
      try MemoryController(
        runtime: GameRuntime(), challenge: challenge, completedRules: challenge.rules))
    var unrelated = MemoryChallenge(difficulty: .hard, seed: 1).rules
    for symbol in MemorySymbol.allCases {
      let indices = unrelated.symbols.indices.filter { unrelated.symbols[$0] == symbol }
      _ = unrelated.flip(indices[0])
      _ = unrelated.flip(indices[1])
    }
    XCTAssertThrowsError(
      try MemoryController(runtime: GameRuntime(), challenge: challenge, completedRules: unrelated))
  }
}
