import SwiftUI

@MainActor
final class FeedComposition {
  let session: SampleSession
  let controller: FeedController?
  private let games: [CardID: PlaceholderGameController]

  init() {
    let source = SampleSession.make()
    let session: SampleSession
    #if DEBUG
      if case .loaded(let cards) = source {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sidequest-feed-empty") {
          session = .loaded([])
        } else if arguments.contains("-sidequest-feed-games-only") {
          session = .loaded(
            cards.filter {
              if case .game = $0 { return true }
              return false
            })
        } else if arguments.contains("-sidequest-feed-test") {
          session = .loaded(cards.sorted { $0.id.rawValue < $1.id.rawValue })
        } else {
          session = source
        }
      } else {
        session = source
      }
    #else
      session = source
    #endif
    self.session = session
    var games: [CardID: PlaceholderGameController] = [:]
    if case .loaded(let cards) = session {
      for card in cards {
        if case .game(let game) = card {
          games[game.id] = PlaceholderGameController(runtime: GameRuntime())
        }
      }
      controller = FeedController(cards: cards, runtimes: games.mapValues(\.runtime))
    } else {
      controller = nil
    }
    self.games = games
  }

  func gameContent(_ card: GameCard, runtime: GameRuntime) -> AnyView {
    guard let game = games[card.id] else {
      preconditionFailure("Every composed game card has a retained controller.")
    }
    return AnyView(PlaceholderGameView(controller: game))
  }

  func newsContent(_ news: NewsSnapshot) -> AnyView {
    AnyView(
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(news.headline).font(.title.bold()).accessibilityAddTraits(.isHeader)
          Text(news.publisher).font(.caption).foregroundStyle(.secondary)
          Text(news.excerpt)
          Text("Fictional sample • News imports follow their own task.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      })
  }
}
