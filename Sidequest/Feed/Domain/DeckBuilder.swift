enum DeckConstructionError: Error, Equatable {
  case duplicateCardID(CardID)
}

enum DeckBuilder {
  /// Construct once at session creation. Rendering uses the stored result.
  static func shuffled<R: RandomNumberGenerator>(
    _ cards: [FeedCard], using random: inout R
  ) throws -> [FeedCard] {
    var seen = Set<CardID>()
    for card in cards {
      guard seen.insert(card.id).inserted else {
        throw DeckConstructionError.duplicateCardID(card.id)
      }
    }
    return cards.shuffled(using: &random)
  }
}
