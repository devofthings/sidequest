import Foundation

/// Pure prepared cadence state; the composition commits it only with accepted additions.
struct FeedNewsCadence: Equatable, Sendable {
  private(set) var pool: [NewsSnapshot]
  let sessionID: UUID
  private(set) var gameCount = 0
  private(set) var newsCursor = 0
  private(set) var appearanceOrdinal = 0

  /// New stories restart the pool cursor, while accepted game/appearance counts stay intact.
  mutating func refreshNews(_ snapshots: [NewsSnapshot]) {
    guard !snapshots.isEmpty else { return }
    pool = snapshots
    newsCursor = 0
  }

  /// Walking outward above the initial card crosses a news boundary before each five games.
  func preparingBackward(_ games: [GameCard]) throws -> (cards: [FeedCard], next: Self) {
    var next = self
    var outward: [FeedCard] = []
    for game in games {
      if next.gameCount == 0, !next.pool.isEmpty {
        let id = try CardID("news-\(sessionID.uuidString.lowercased())-\(next.appearanceOrdinal)")
        outward.append(.news(FeedNewsCard(snapshot: next.pool[next.newsCursor], id: id)))
        next.newsCursor = (next.newsCursor + 1) % next.pool.count
        next.appearanceOrdinal += 1
      }
      outward.append(.game(game))
      next.gameCount = (next.gameCount + 1) % 5
    }
    return (Array(outward.reversed()), next)
  }

  func preparing(_ games: [GameCard]) throws -> (cards: [FeedCard], next: Self) {
    var next = self
    var cards: [FeedCard] = []
    for game in games {
      cards.append(.game(game))
      next.gameCount += 1
      if next.gameCount == 5 {
        next.gameCount = 0
        if !pool.isEmpty {
          let appearanceID = try CardID(
            "news-\(sessionID.uuidString.lowercased())-\(next.appearanceOrdinal)")
          cards.append(.news(FeedNewsCard(snapshot: pool[next.newsCursor], id: appearanceID)))
          next.newsCursor = (next.newsCursor + 1) % pool.count
          next.appearanceOrdinal += 1
        }
      }
    }
    return (cards, next)
  }
}
