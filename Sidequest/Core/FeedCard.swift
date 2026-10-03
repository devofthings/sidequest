enum GameKind: String, CaseIterable, Codable, Sendable {
  case sudoku
  case memory
  case chess
  case bubbleShooter
}

struct GameCard: Equatable, Codable, Sendable {
  let id: CardID
  let kind: GameKind
}

enum FeedCard: Equatable, Codable, Identifiable, Sendable {
  case news(NewsSnapshot)
  case game(GameCard)

  var id: CardID {
    switch self {
    case .news(let news): news.id
    case .game(let game): game.id
    }
  }
}
