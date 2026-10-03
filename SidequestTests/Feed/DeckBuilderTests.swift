import XCTest

@testable import Sidequest

final class DeckBuilderTests: XCTestCase {
  func testEmptyAndSingleDecks() throws {
    var random = SeededRandom(seed: 9)
    XCTAssertEqual(try DeckBuilder.shuffled([], using: &random), [])
    let single = try cards(count: 1)
    XCTAssertEqual(try DeckBuilder.shuffled(single, using: &random), single)
  }

  func testSeededShufflePreservesEveryStableIdentityAndIsReproducible() throws {
    let originals = try cards(count: 24)
    var first = SeededRandom(seed: 42)
    var second = SeededRandom(seed: 42)
    let session = try DeckBuilder.shuffled(originals, using: &first)
    XCTAssertEqual(session, try DeckBuilder.shuffled(originals, using: &second))
    XCTAssertEqual(session.count, originals.count)
    XCTAssertEqual(Set(session.map(\.id)), Set(originals.map(\.id)))
    XCTAssertEqual(session.filter { originals.contains($0) }.count, originals.count)
  }

  func testDuplicateIDsAreRejectedButRepeatedGameKindsAreValid() throws {
    let card = FeedCard.game(GameCard(id: try CardID("same"), kind: .memory))
    var random = SeededRandom(seed: 1)
    XCTAssertThrowsError(try DeckBuilder.shuffled([card, card], using: &random)) {
      XCTAssertEqual($0 as? DeckConstructionError, .duplicateCardID(card.id))
    }
    XCTAssertEqual(try DeckBuilder.shuffled(cards(count: 2), using: &random).count, 2)
  }

  private func cards(count: Int) throws -> [FeedCard] {
    try (0..<count).map { .game(GameCard(id: try CardID("memory-\($0)"), kind: .memory)) }
  }
}

private struct SeededRandom: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    seed &+= 0x9e37_79b9_7f4a_7c15
    var value = seed
    value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
    value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
    return value ^ (value >> 31)
  }
}
