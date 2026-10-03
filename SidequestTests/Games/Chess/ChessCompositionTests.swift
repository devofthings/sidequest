import XCTest

@testable import Sidequest

final class ChessCompositionTests: XCTestCase {
  func testNormalSampleSessionKeepsBothStableChessCardsInTheMixedDeck() {
    for _ in 0..<3 {
      guard case .loaded(let cards) = SampleSession.make() else {
        return XCTFail("Original sample cards must compose successfully.")
      }
      XCTAssertEqual(cards.count, 7)
      XCTAssertEqual(Set(cards.map(\.id)).count, 7)
      let chess = cards.compactMap { card -> GameCard? in
        guard case .game(let game) = card, game.kind == .chess else { return nil }
        return game
      }
      XCTAssertEqual(
        Set(chess.map { $0.id.rawValue }), ["sample-game-chess-white", "sample-game-chess-black"])
      XCTAssertEqual(
        cards.filter {
          if case .news = $0 { return true }
          return false
        }.count, 2)
    }
  }

  func testGenericHarnessKeepsOriginalSixCardMembership() {
    guard case .loaded(let cards) = SampleSession.make(includeChessVariants: false) else {
      return XCTFail("Generic harness must compose successfully.")
    }
    XCTAssertEqual(cards.count, 6)
    let games = cards.compactMap { card -> GameCard? in
      guard case .game(let game) = card else { return nil }
      return game
    }
    XCTAssertEqual(games.count, 4)
    XCTAssertEqual(Set(games.map(\.kind)), Set(GameKind.allCases))
    XCTAssertEqual(games.first { $0.kind == .chess }?.id.rawValue, "sample-game-chess")
  }
}
