enum SudokuPuzzleError: Error, Equatable {
  case invalidCellCount
  case invalidValue
  case conflictingGivens
  case nonUniqueSolution
  case searchLimitReached
}

struct SudokuPuzzle: Equatable, Sendable {
  let configuration: SudokuConfiguration
  let givens: [Int]
  let solution: [Int]

  init(givens: [Int], configuration: SudokuConfiguration = .mini) throws {
    guard givens.count == configuration.cellCount else { throw SudokuPuzzleError.invalidCellCount }
    guard givens.allSatisfy({ (0...configuration.size).contains($0) }) else {
      throw SudokuPuzzleError.invalidValue
    }
    guard SudokuGrid.conflicts(in: givens, configuration: configuration).isEmpty else {
      throw SudokuPuzzleError.conflictingGivens
    }
    let search = SudokuGrid.search(for: givens, configuration: configuration)
    guard search.isExhaustive else { throw SudokuPuzzleError.searchLimitReached }
    let solutions = search.solutions
    guard solutions.count == 1, let solution = solutions.first else {
      throw SudokuPuzzleError.nonUniqueSolution
    }
    self.configuration = configuration
    self.givens = givens
    self.solution = solution
  }

  #if DEBUG
    static func standardFixture() throws -> Self {
      var givens = (0..<9).flatMap { row in
        (0..<9).map { column in (row * 3 + row / 3 + column) % 9 + 1 }
      }
      for index in Array(0..<9) + [9, 18, 27] { givens[index] = 0 }
      return try Self(givens: givens, configuration: .standard)
    }
  #endif

  static func fixtures() throws -> [Self] {
    try [
      [1, 2, 0, 4, 0, 4, 1, 0, 0, 1, 4, 0, 4, 0, 0, 1],
      [1, 2, 3, 0, 3, 0, 0, 2, 2, 0, 0, 3, 0, 3, 2, 0],
    ].map { try Self(givens: $0) }
  }
}
