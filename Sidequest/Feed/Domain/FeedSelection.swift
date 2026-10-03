/// Selection changes never rebuild or shuffle the session's immutable deck.
struct FeedSelection {
  let cards: [FeedCard]
  private(set) var index: Int?

  init(cards: [FeedCard]) {
    self.cards = cards
    index = cards.isEmpty ? nil : 0
  }

  var card: FeedCard? { index.map { cards[$0] } }
  var canGoBack: Bool { index.map { $0 > 0 } ?? false }
  var canGoForward: Bool { index.map { $0 + 1 < cards.count } ?? false }

  @discardableResult
  mutating func move(by offset: Int) -> Bool {
    guard let index, cards.indices.contains(index + offset), offset != 0 else { return false }
    self.index = index + offset
    return true
  }
}
