import Observation

@Observable
@MainActor
final class SudokuController {
  let runtime: GameRuntime
  let puzzle: SudokuPuzzle
  private let initialBoard: SudokuBoard
  private(set) var board: SudokuBoard?
  private(set) var selectedCell: Int?
  private(set) var coordinateRow = 0
  private(set) var coordinateColumn = 0

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
    if let selectedCell {
      coordinateRow = selectedCell / puzzle.configuration.size
      coordinateColumn = selectedCell % puzzle.configuration.size
    }
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  func selectCell(_ index: Int) {
    guard let board, board.cells.indices.contains(index), puzzle.givens[index] == 0,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt)
    else { return }
    selectedCell = index
    coordinateRow = index / puzzle.configuration.size
    coordinateColumn = index % puzzle.configuration.size
  }

  func selectRow(_ row: Int) {
    selectCoordinate(row: row, column: coordinateColumn)
  }

  func selectColumn(_ column: Int) {
    selectCoordinate(row: coordinateRow, column: column)
  }

  private func selectCoordinate(row: Int, column: Int) {
    let size = puzzle.configuration.size
    guard (0..<size).contains(row), (0..<size).contains(column), board != nil,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt)
    else { return }
    coordinateRow = row
    coordinateColumn = column
    let index = row * size + column
    selectedCell = puzzle.givens[index] == 0 ? index : nil
  }

  func enter(_ value: Int) {
    guard let selectedCell, var board,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt),
      board.cells[selectedCell] != value,
      board.setValue(value, at: selectedCell)
    else { return }
    self.board = board
    if board.isComplete {
      runtime.complete(attempt: attempt, successful: true)
    } else {
      runtime.feedbackForInteraction(attempt: attempt)
    }
  }

  private func apply(_ effect: GameLifecycleEffect) {
    switch effect {
    case .start:
      board = initialBoard
      selectedCell = nil
      coordinateRow = 0
      coordinateColumn = 0
    case .reset:
      board = nil
      selectedCell = nil
      coordinateRow = 0
      coordinateColumn = 0
    case .stop:
      break
    }
  }
}
