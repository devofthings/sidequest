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
