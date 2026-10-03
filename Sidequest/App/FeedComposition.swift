import SwiftUI

@MainActor
final class FeedComposition {
  let chessPuzzles: [ChessPuzzle]
  let session: SampleSession
  let controller: FeedController?
  private let games: [CardID: ComposedGame]

  init(chessPuzzles: [ChessPuzzle]) {
    self.chessPuzzles = chessPuzzles
    let useDemoGames: Bool
    #if DEBUG
      let arguments = ProcessInfo.processInfo.arguments
      useDemoGames =
        arguments.contains("-sidequest-feed-test")
        || arguments.contains("-sidequest-feed-games-only")
        || arguments.contains("-sidequest-feed-replacement-test")
    #else
      useDemoGames = false
    #endif
    let source = SampleSession.make(includeChessVariants: !useDemoGames)
    let session: SampleSession
    #if DEBUG
      if case .loaded(let cards) = source {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sidequest-bubble-fixtures") {
          let bubble = cards.filter { card in
            if case .game(let game) = card { return game.kind == .bubbleShooter }
            return false
          }
          let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
            if case .news = card { return true }
            return false
          }.prefix(1)
          session = .loaded(bubble + news)
        } else if arguments.contains("-sidequest-chess-white-fixture")
          || arguments.contains("-sidequest-chess-black-fixture")
        {
          let side = arguments.contains("-sidequest-chess-black-fixture") ? "black" : "white"
          let chess = cards.filter { $0.id.rawValue == "sample-game-chess-\(side)" }
          let news = cards.sorted { $0.id.rawValue < $1.id.rawValue }.filter { card in
            if case .news = card { return true }
            return false
          }.prefix(1)
          session = .loaded(chess + news)
        } else if arguments.contains("-sidequest-sudoku-test") {
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
        } else if arguments.contains("-sidequest-feed-test")
          || arguments.contains("-sidequest-feed-replacement-test")
        {
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
            case .chess where !useDemoGames:
              let fixtureID: String
              switch game.id.rawValue {
              case "sample-game-chess-white": fixtureID = "queen-corner-white"
              case "sample-game-chess-black": fixtureID = "queen-corner-black"
              case .bubbleShooter where !useDemoGames:
              let controller: BubbleShooterController
              #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-sidequest-bubble-slow-shot") {
                  controller = BubbleShooterController(
                    runtime: runtime,
                    pause: {
                      try await Task.sleep(for: .milliseconds(100))
                    })
                } else {
                  controller = BubbleShooterController(runtime: runtime)
                }
              #else
                controller = BubbleShooterController(runtime: runtime)
              #endif
              games[game.id] = .bubbleShooter(controller)
            default: throw GameCompositionError.missingChessFixture(game.id.rawValue)
              }
              guard
                let puzzle = chessPuzzles.first(where: { $0.id == fixtureID })
              else {
                throw GameCompositionError.missingChessFixture(fixtureID)
              }
              games[game.id] = .chess(ChessController(puzzle: puzzle, runtime: runtime))
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
  case missingChessFixture(String)

  var errorDescription: String? {
    switch self {
    case .missingSudokuFixture: "The Sudoku fixture set is empty."
    case .missingChessFixture(let id): "The chess fixture for \(id) is missing."
    }
  }
}
