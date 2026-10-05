import XCTest

@testable import Sidequest

final class MemoryChallengeTests: XCTestCase {
  func testEveryWorkloadIsReproducibleValidAndCompletableAcrossSeeds() throws {
    for difficulty in [GameDifficulty.easy, .medium, .hard] {
      let expectedPairs = difficulty == .easy ? 3 : difficulty == .medium ? 4 : 6
      for seed in UInt64(0)..<64 {
        let challenge = MemoryChallenge(difficulty: difficulty, seed: seed)
        XCTAssertEqual(challenge, MemoryChallenge(difficulty: difficulty, seed: seed))
        XCTAssertEqual(challenge.seed, seed)
        XCTAssertEqual(challenge.difficulty, difficulty)
        XCTAssertEqual(challenge.rules.difficulty, difficulty)
        XCTAssertEqual(challenge.pairCount, expectedPairs)
        XCTAssertEqual(try MemoryRules(symbols: challenge.rules.symbols), challenge.rules)
        var rules = challenge.rules
        let symbols = Set(rules.symbols)
        for (pairIndex, symbol) in symbols.enumerated() {
          let indices = rules.symbols.indices.filter { rules.symbols[$0] == symbol }
          XCTAssertEqual(indices.count, 2)
          XCTAssertEqual(rules.flip(indices[0]), .revealed)
          XCTAssertEqual(
            rules.flip(indices[1]), pairIndex == expectedPairs - 1 ? .completed : .matched)
        }
        XCTAssertTrue(rules.isCompleted)
        XCTAssertEqual(rules.matchedPairCount, expectedPairs)
        let completed = rules
        XCTAssertEqual(rules.flip(0), .ignored)
        XCTAssertEqual(rules, completed)
      }
    }
  }

  func testDefaultSixPairShufflePreservesLegacyRandomConsumption() {
    for seed in UInt64(0)..<64 {
      var legacyRandom = ChallengeRandom(seed: seed)
      let expected = (MemorySymbol.allCases + MemorySymbol.allCases).shuffled(using: &legacyRandom)
      var currentRandom = ChallengeRandom(seed: seed)
      let current = MemoryRules(using: &currentRandom)
      XCTAssertEqual(current.symbols, expected)
      XCTAssertEqual(current.difficulty, .hard)
      XCTAssertEqual(currentRandom.next(), legacyRandom.next())
    }
  }

  func testInvalidCountsAndUnequalMultiplicityAreRejected() {
    for count in [0, 1, 2, 5] {
      let symbols = Array(MemorySymbol.allCases.prefix(count)).flatMap { [$0, $0] }
      XCTAssertThrowsError(try MemoryRules(symbols: symbols))
    }
    XCTAssertThrowsError(try MemoryRules(symbols: [.star, .star, .star, .heart, .heart, .moon]))
    XCTAssertThrowsError(try MemoryRules(symbols: [.star, .star, .heart, .heart, .moon]))
    XCTAssertThrowsError(try MemoryRules(symbols: Array(repeating: .star, count: 12)))
  }
}

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
