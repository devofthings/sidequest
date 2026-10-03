import Foundation

/// Fictional, redistributable development input. Real imports belong to #4.
enum SampleSession {
  case loaded([FeedCard])
  case failed(String)

  static func make() -> Self {
    do {
      guard let gardenURL = URL(string: "https://example.com/garden"),
        let libraryURL = URL(string: "https://example.com/library")
      else { throw CardValidationError.invalidSourceURL }
      let timestamp = Date(timeIntervalSince1970: 1_704_067_200)
      var cards = try [
        FeedCard.news(
          NewsSnapshot(
            id: CardID("sample-news-garden"), headline: "Sample: A neighborhood garden opens",
            excerpt:
              "This fictional sample introduces a community garden. It is not a real news report.",
            publisher: "Sidequest sample", sourceURL: gardenURL,
            capturedAt: timestamp, isSample: true)),
        FeedCard.news(
          NewsSnapshot(
            id: CardID("sample-news-library"),
            headline: "Sample: A library hosts a puzzle afternoon",
            excerpt:
              "This fictional sample describes a library event. It is not a real news report.",
            publisher: "Sidequest sample", sourceURL: libraryURL,
            capturedAt: timestamp, isSample: true)),
      ]
      cards += try GameKind.allCases.map {
        .game(GameCard(id: try CardID("sample-game-\($0.rawValue)"), kind: $0))
      }
      var random = SystemRandomNumberGenerator()
      return .loaded(try DeckBuilder.shuffled(cards, using: &random))
    } catch {
      return .failed(error.localizedDescription)
    }
  }
}
