import SwiftUI

/// App-owned concrete adapters keep the feed independent of each game's rules.
@MainActor
enum ComposedGame {
  case placeholder(PlaceholderGameController)
  case sudoku(SudokuController)
  case memory(MemoryController)
  case chess(ChessController)
  case bubbleShooter(BubbleShooterController)
