enum SudokuGenerator {
  /// Mini remains the existing production default and consumes the same random draws.
  static func generate<R: RandomNumberGenerator>(
    configuration: SudokuConfiguration, using random: inout R
  ) throws -> SudokuPuzzle {
    switch configuration {
    case .mini: return try generate(using: &random)
    case .standard: return try generateStandard(using: &random)
    }
  }

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
  /// Original standard grids use only rule-preserving permutations; each accepted removal
  /// has an exhaustive uniqueness proof. The clue floor is a work bound, not a difficulty tier.
  private static func generateStandard<R: RandomNumberGenerator>(
    using random: inout R
  ) throws -> SudokuPuzzle {
    try Task.checkCancellation()
    let digits = Array(1...9).shuffled(using: &random)
    let bands = Array(0..<3).shuffled(using: &random)
    let stacks = Array(0..<3).shuffled(using: &random)
    let rows = bands.flatMap { band in
      Array(0..<3).shuffled(using: &random).map { band * 3 + $0 }
    }
    let columns = stacks.flatMap { stack in
      Array(0..<3).shuffled(using: &random).map { stack * 3 + $0 }
    }
    var givens = rows.flatMap { row in
      columns.map { column in digits[(row * 3 + row / 3 + column) % 9] }
    }
    var clues = givens.count
    for index in Array(givens.indices).shuffled(using: &random) {
      try Task.checkCancellation()
      guard clues > 40 else { break }
      let previous = givens[index]
      givens[index] = 0
      let search = SudokuGrid.search(for: givens, configuration: .standard, nodeLimit: 10_000)
      if search.isExhaustive && search.solutions.count == 1 {
        clues -= 1
      } else {
        givens[index] = previous
      }
    }
    return try SudokuPuzzle(givens: givens, configuration: .standard)
  }
}
