/// Selection changes never rebuild or shuffle the session's immutable deck.
struct FeedSelection {
  private(set) var cards: [FeedCard]
  private(set) var index: Int?

  init(cards: [FeedCard]) {
    self.cards = cards
    index = cards.isEmpty ? nil : 0
  }

  var card: FeedCard? { index.map { cards[$0] } }
  var canGoBack: Bool { index.map { $0 > 0 } ?? false }
  var canGoForward: Bool { index.map { $0 + 1 < cards.count } ?? false }

  mutating func append(_ additions: [FeedCard]) {
    cards.append(contentsOf: additions)
    if index == nil, !cards.isEmpty { index = 0 }
  }

  /// Refresh story values without moving cards or changing appearance identity.
  mutating func refreshNews(_ snapshots: [NewsSnapshot]) {
    guard !snapshots.isEmpty else { return }
    var cursor = 0
    cards = cards.map { card in
      guard case .news(let appearance) = card else { return card }
      let snapshot = snapshots[cursor % snapshots.count]
      cursor += 1
      return .news(FeedNewsCard(snapshot: snapshot, id: appearance.id))
    }
  }

  @discardableResult
  mutating func move(by offset: Int) -> Bool {
    guard let index, cards.indices.contains(index + offset), offset != 0 else { return false }
    self.index = index + offset
    return true
  }
}
