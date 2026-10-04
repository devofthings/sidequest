import Observation

@Observable
@MainActor
final class SudokuController {
  let runtime: GameRuntime
  let puzzle: SudokuPuzzle
  private let initialBoard: SudokuBoard
  private(set) var board: SudokuBoard?
  private(set) var selectedCell: Int?

  var displayedBoard: SudokuBoard { board ?? initialBoard }

  init(
    puzzle: SudokuPuzzle, runtime: GameRuntime, completedBoard: SudokuBoard? = nil,
    selectedCell: Int? = nil
  ) {
    self.puzzle = puzzle
    self.runtime = runtime
    initialBoard = SudokuBoard(puzzle: puzzle)
    board = completedBoard
    self.selectedCell = selectedCell
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  func selectCell(_ index: Int) {
    guard let board, board.cells.indices.contains(index), puzzle.givens[index] == 0,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt)
    else { return }
    selectedCell = index
  }

  func enter(_ value: Int) {
    guard let selectedCell, var board,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt),
      board.setValue(value, at: selectedCell)
    else { return }
    self.board = board
    if board.isComplete { runtime.complete(attempt: attempt) }
  }

  private func apply(_ effect: GameLifecycleEffect) {
    switch effect {
    case .start:
      board = initialBoard
      selectedCell = nil
    case .reset:
      board = nil
      selectedCell = nil
    case .stop:
      break
    }
  }
}
