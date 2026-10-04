import SwiftUI

/// App-owned concrete adapters keep the feed independent of each game's rules.
@MainActor
enum ComposedGame {
  #if DEBUG
    case placeholder(PlaceholderGameController)
  #endif
  case sudoku(SudokuController)
  case memory(MemoryController)
  case chess(ChessController)
  case bubbleShooter(BubbleShooterController)

  var runtime: GameRuntime {
    switch self {
    #if DEBUG
      case .placeholder(let game): game.runtime
    #endif
    case .sudoku(let game): game.runtime
    case .memory(let game): game.runtime
    case .chess(let game): game.runtime
    case .bubbleShooter(let game): game.runtime
    }
  }

  func content() -> AnyView {
    switch self {
    #if DEBUG
      case .placeholder(let game): AnyView(PlaceholderGameView(controller: game))
    #endif
    case .sudoku(let game): AnyView(SudokuGameView(controller: game))
    case .memory(let game): AnyView(MemoryGameView(controller: game))
    case .chess(let game): AnyView(ChessPuzzleView(controller: game))
    case .bubbleShooter(let game): AnyView(BubbleShooterView(controller: game))
    }
  }
}
