import XCTest

@testable import Sidequest

final class MemoryRulesTests: XCTestCase {
  func testControlledShuffleHasExactlyTwoOfEachSymbol() {
    var firstRandom = MemoryRandom(seed: 42)
    var secondRandom = MemoryRandom(seed: 42)
    let first = MemoryRules(using: &firstRandom)
    let second = MemoryRules(using: &secondRandom)
    XCTAssertEqual(first, second)
    XCTAssertEqual(first.symbols.count, 12)
    for symbol in MemorySymbol.allCases {
      XCTAssertEqual(first.symbols.filter { $0 == symbol }.count, 2)
    }
    XCTAssertFalse(first.symbols.indices.contains { first.isRevealed($0) })
  }

  func testDoubleTapMatchedTapAndOutOfBoundsAreIgnored() throws {
    var rules = try fixedBoard()
    XCTAssertEqual(rules.flip(-1), .ignored)
    XCTAssertEqual(rules.flip(12), .ignored)
    XCTAssertEqual(rules.flip(0), .revealed)
    XCTAssertEqual(rules.flip(0), .ignored)
    XCTAssertEqual(rules.turn, .choosing(first: 0))
    XCTAssertEqual(rules.flip(1), .matched)
    XCTAssertEqual(rules.flip(0), .ignored)
    XCTAssertEqual(rules.matchedPairCount, 1)
    XCTAssertTrue(rules.isRevealed(0))
    XCTAssertTrue(rules.isRevealed(1))
  }

  func testMismatchLocksAllAdditionalInputThenConcealsOnlyUnmatchedCards() throws {
    var rules = try fixedBoard()
    XCTAssertEqual(rules.flip(0), .revealed)
    XCTAssertEqual(rules.flip(1), .matched)
    XCTAssertEqual(rules.flip(2), .revealed)
    XCTAssertEqual(rules.flip(4), .mismatch)
    let pending = rules
    for index in rules.symbols.indices { XCTAssertEqual(rules.flip(index), .ignored) }
    XCTAssertEqual(rules, pending)
    XCTAssertTrue(rules.isRevealed(2))
    XCTAssertTrue(rules.isRevealed(4))
    rules.concealMismatch()
    XCTAssertFalse(rules.isRevealed(2))
    XCTAssertFalse(rules.isRevealed(4))
    XCTAssertTrue(rules.isRevealed(0))
    XCTAssertEqual(rules.flip(2), .revealed)
  }

  func testEveryPairCompletesAndFurtherActionsPreserveResult() throws {
    var rules = try fixedBoard()
    for index in stride(from: 0, to: 12, by: 2) {
      XCTAssertEqual(rules.flip(index), .revealed)
      XCTAssertEqual(rules.flip(index + 1), index == 10 ? .completed : .matched)
    }
    XCTAssertTrue(rules.isCompleted)
    XCTAssertEqual(rules.matchedPairCount, 6)
    let completed = rules
    rules.concealMismatch()
    XCTAssertEqual(rules.flip(0), .ignored)
    XCTAssertEqual(rules, completed)
  }

  func testMalformedPairBoardsAreRejected() {
    XCTAssertThrowsError(try MemoryRules(symbols: []))
    XCTAssertThrowsError(try MemoryRules(symbols: Array(repeating: .star, count: 12)))
  }

  private func fixedBoard() throws -> MemoryRules {
    try MemoryRules(symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
  }
}

private struct MemoryRandom: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    seed = seed &* 6_364_136_223_846_793_005 &+ 1
    return seed
  }
}
