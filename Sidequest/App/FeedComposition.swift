import SwiftUI

@MainActor
final class FeedComposition {
  let session: SampleSession
  let controller: FeedController?
  private let games: [CardID: ComposedGame]

  init() {
    let source = SampleSession.make()
    let session: SampleSession
    #if DEBUG
      if case .loaded(let cards) = source {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sidequest-sudoku-test") {
          let sudoku = cards.filter { card in
            if case .game(let game) = card { return game.kind == .sudoku }
            return false
          }
          let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
            if case .news = card { return true }
            return false
          }.prefix(1)
          session = .loaded(sudoku + news)
        } else if arguments.contains("-sidequest-memory-fixtures") {
          let memory = cards.filter { card in
            if case .game(let game) = card { return game.kind == .memory }
            return false
          }
          let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
            if case .news = card { return true }
            return false
          }.prefix(1)
          session = .loaded(memory + news)
        } else if arguments.contains("-sidequest-feed-empty") {
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
    let useDemoGames: Bool
    #if DEBUG
      useDemoGames = ProcessInfo.processInfo.arguments.contains("-sidequest-feed-test")
    #else
      useDemoGames = false
    #endif
    var games: [CardID: ComposedGame] = [:]
    var composedSession = session
    var feed: FeedController?
    do {
      if case .loaded(let cards) = session {
        for card in cards {
          if case .game(let game) = card {
            let runtime = GameRuntime()
            switch game.kind {
            case .sudoku where !useDemoGames:
              let puzzles = try SudokuPuzzle.fixtures()
              guard !puzzles.isEmpty else {
                throw GameCompositionError.missingSudokuFixture
              }
              let index: Int
              #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-sidequest-sudoku-test") {
                  index = 0
                } else {
                  index = Int.random(in: puzzles.indices)
                }
              #else
                index = Int.random(in: puzzles.indices)
              #endif
              let puzzle = puzzles[index]
              games[game.id] = .sudoku(SudokuController(puzzle: puzzle, runtime: runtime))
            case .memory where !useDemoGames:
              #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-sidequest-memory-fixtures") {
                  let board = try MemoryRules(
                    symbols: MemorySymbol.allCases.flatMap { [$0, $0] })
                  games[game.id] = .memory(
                    MemoryController(
                      runtime: runtime, makeBoard: { board },
                      delay: { try await Task.sleep(for: .seconds(2)) }))
                } else {
                  games[game.id] = .memory(MemoryController(runtime: runtime))
                }
              #else
                games[game.id] = .memory(MemoryController(runtime: runtime))
              #endif
            default:
              games[game.id] = .placeholder(PlaceholderGameController(runtime: runtime))
            }
          }
        }
        feed = FeedController(cards: cards, runtimes: games.mapValues(\.runtime))
      }
    } catch {
      composedSession = .failed("Could not prepare games: \(error.localizedDescription)")
      games = [:]
    }
    self.session = composedSession
    self.controller = feed
    self.games = games
  }

  func gameContent(_ card: GameCard, runtime: GameRuntime) -> AnyView {
    guard let game = games[card.id] else {
      preconditionFailure("Every composed game card has a retained controller.")
    }
    return game.content()
  }

  func newsContent(_ news: NewsSnapshot) -> AnyView {
    AnyView(NewsCardContent(snapshot: news))
  }
}

private enum GameCompositionError: Error, LocalizedError {
  case missingSudokuFixture

  var errorDescription: String? { "The Sudoku fixture set is empty." }
}
