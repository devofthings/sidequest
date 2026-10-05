enum GameKind: String, CaseIterable, Codable, Sendable {
  case sudoku
  case memory
  case chess
  case bubbleShooter
}

struct GameCard: Equatable, Codable, Sendable {
  let id: CardID
  let kind: GameKind
  let difficulty: GameDifficulty?

  init(id: CardID, kind: GameKind, difficulty: GameDifficulty? = nil) {
    self.id = id
    self.kind = kind
    self.difficulty = difficulty
  }
}

/// An appearance can repeat a source story without changing its imported identity.
struct FeedNewsCard: Equatable, Codable, Sendable {
  let id: CardID
  let snapshot: NewsSnapshot

  init(snapshot: NewsSnapshot, id: CardID? = nil) {
    self.id = id ?? snapshot.id
    self.snapshot = snapshot
  }
}

enum FeedCard: Equatable, Codable, Identifiable, Sendable {
  case news(FeedNewsCard)
  case game(GameCard)

  /// Finite legacy routes use the source ID as their single appearance ID.
  static func news(_ snapshot: NewsSnapshot) -> Self {
    .news(FeedNewsCard(snapshot: snapshot))
  }

  var id: CardID {
    switch self {
    case .news(let news): news.id
    case .game(let game): game.id
    }
  }
}
