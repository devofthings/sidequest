struct SudokuBoard: Equatable, Sendable {
  let puzzle: SudokuPuzzle
  private(set) var cells: [Int]

  init(puzzle: SudokuPuzzle) {
    self.puzzle = puzzle
    cells = puzzle.givens
  }

  var conflicts: Set<Int> { SudokuGrid.conflicts(in: cells, configuration: puzzle.configuration) }
  var isComplete: Bool { !cells.contains(0) && conflicts.isEmpty }

  @discardableResult
  mutating func setValue(_ value: Int, at index: Int) -> Bool {
    guard cells.indices.contains(index), (0...puzzle.configuration.size).contains(value),
      puzzle.givens[index] == 0
    else {
      return false
    }
    cells[index] = value
    return true
  }

  mutating func reset() { cells = puzzle.givens }
}
