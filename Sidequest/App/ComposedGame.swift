import SwiftUI

/// App-owned concrete adapters keep the feed independent of each game's rules.
@MainActor
enum ComposedGame {
  case placeholder(PlaceholderGameController)
  case sudoku(SudokuController)
  case memory(MemoryController)

  var runtime: GameRuntime {
    switch self {
    case .placeholder(let game): game.runtime
    case .sudoku(let game): game.runtime
    case .memory(let game): game.runtime
    }
  }

  func content() -> AnyView {
    switch self {
    case .placeholder(let game): AnyView(PlaceholderGameView(controller: game))
    case .sudoku(let game): AnyView(SudokuGameView(controller: game))
    case .memory(let game): AnyView(MemoryGameView(controller: game))
    }
  }
}
