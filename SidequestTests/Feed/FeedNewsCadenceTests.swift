import Foundation
import XCTest

@testable import Sidequest

final class FeedNewsCadenceTests: XCTestCase {
  func testFiveGamesThenNewsAcrossVaryingBoundariesCyclesAllStoriesWithoutRewritingThem()
    async throws
  {
    let stories = try await DemoNewsLoader.bundled()
    let original = try NewsSnapshotImporter.encode(stories)
    let id = UUID()
    var cadence = FeedNewsCadence(pool: stories, sessionID: id)
    var history: [FeedCard] = []
    var sequence = 0
    for size in [8, 1, 3, 8, 7, 2, 11, 8, 320] {
      let games = try (sequence..<(sequence + size)).map {
        GameCard(id: try CardID("game-\($0)"), kind: .memory)
      }
      let unchanged = cadence
      let prepared = try cadence.preparing(games)
      XCTAssertEqual(cadence, unchanged)
      XCTAssertEqual(try cadence.preparing(games).cards, prepared.cards)
      history += prepared.cards
      cadence = prepared.next
      sequence += size
    }
    XCTAssertEqual(Set(history.map(\.id)).count, history.count)
    var newsCount = 0
    var gamesSinceNews = 0
    for card in history {
      switch card {
      case .game: gamesSinceNews += 1
      case .news(let news):
        XCTAssertEqual(gamesSinceNews, 5)
        XCTAssertEqual(news.snapshot, stories[newsCount % stories.count])
        XCTAssertEqual(news.id.rawValue, "news-\(id.uuidString.lowercased())-\(newsCount)")
        newsCount += 1
        gamesSinceNews = 0
      }
    }
    XCTAssertGreaterThan(newsCount, 60)
    XCTAssertEqual(cadence.gameCount, sequence % 5)
    XCTAssertEqual(cadence.appearanceOrdinal, sequence / 5)
    XCTAssertEqual(try NewsSnapshotImporter.encode(stories), original)
  }

  func testEmptyPoolKeepsEveryGameAndFiniteAppearanceDefaultsToSourceID() async throws {
    let games = try (0..<17).map { GameCard(id: try CardID("empty-\($0)"), kind: .sudoku) }
    let cadence = FeedNewsCadence(pool: [], sessionID: UUID())
    let prepared = try cadence.preparing(games)
    XCTAssertEqual(prepared.cards, games.map(FeedCard.game))
    XCTAssertEqual(prepared.next.gameCount, 2)
    XCTAssertEqual(prepared.next.appearanceOrdinal, 0)
    let stories = try await DemoNewsLoader.bundled()
    let story = try XCTUnwrap(stories.first)
    XCTAssertEqual(FeedNewsCard(snapshot: story).id, story.id)
    XCTAssertEqual(FeedCard.news(story).id, story.id)
  }
}
