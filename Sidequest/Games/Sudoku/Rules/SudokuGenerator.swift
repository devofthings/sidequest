enum SudokuGenerator {
  /// Transform a solved grid, then remove each clue at most once while proving uniqueness.
  static func generate<R: RandomNumberGenerator>(using random: inout R) throws -> SudokuPuzzle {
    let digits = [1, 2, 3, 4].shuffled(using: &random)
    let bands = [0, 1].shuffled(using: &random)
    let stacks = [0, 1].shuffled(using: &random)
    let rows = bands.flatMap { band in [0, 1].shuffled(using: &random).map { band * 2 + $0 } }
    let columns = stacks.flatMap { stack in [0, 1].shuffled(using: &random).map { stack * 2 + $0 } }
    var givens = rows.flatMap { row in
      columns.map { column in digits[(row * 2 + row / 2 + column) % 4] }
    }
    for index in Array(0..<16).shuffled(using: &random) {
      let previous = givens[index]
      givens[index] = 0
      if SudokuGrid.solutions(for: givens).count != 1 { givens[index] = previous }
    }
    return try SudokuPuzzle(givens: givens)
  }
}
