enum SudokuPuzzleError: Error, Equatable {
  case invalidCellCount
  case invalidValue
  case conflictingGivens
  case nonUniqueSolution
}

struct SudokuPuzzle: Equatable, Sendable {
  let givens: [Int]
  let solution: [Int]

  init(givens: [Int]) throws {
    guard givens.count == 16 else { throw SudokuPuzzleError.invalidCellCount }
    guard givens.allSatisfy({ (0...4).contains($0) }) else { throw SudokuPuzzleError.invalidValue }
    guard SudokuGrid.conflicts(in: givens).isEmpty else {
      throw SudokuPuzzleError.conflictingGivens
    }
    let solutions = SudokuGrid.solutions(for: givens)
    guard solutions.count == 1, let solution = solutions.first else {
      throw SudokuPuzzleError.nonUniqueSolution
    }
    self.givens = givens
    self.solution = solution
  }

  static func fixtures() throws -> [Self] {
    try [
      [1, 2, 0, 4, 0, 4, 1, 0, 0, 1, 4, 0, 4, 0, 0, 1],
      [1, 2, 3, 0, 3, 0, 0, 2, 2, 0, 0, 3, 0, 3, 2, 0],
    ].map { try Self(givens: $0) }
  }
}

/// Internal grid operations receive exactly 16 validated cells (0 means empty).
enum SudokuGrid {
  static func conflicts(in cells: [Int]) -> Set<Int> {
    var result = Set<Int>()
    for first in cells.indices where cells[first] != 0 {
      for second in cells.indices where second > first && cells[first] == cells[second] {
        if arePeers(first, second) { result.formUnion([first, second]) }
      }
    }
    return result
  }

  static func solutions(for givens: [Int]) -> [[Int]] {
    var solutions: [[Int]] = []
    var cells = givens
    func visit() {
      guard solutions.count < 2 else { return }
      guard let index = cells.firstIndex(of: 0) else {
        solutions.append(cells)
        return
      }
      for value in 1...4 {
        guard !cells.indices.contains(where: { arePeers(index, $0) && cells[$0] == value }) else {
          continue
        }
        cells[index] = value
        visit()
      }
      cells[index] = 0
    }
    visit()
    return solutions
  }

  static func arePeers(_ first: Int, _ second: Int) -> Bool {
    guard first != second else { return false }
    let firstRow = first / 4
    let secondRow = second / 4
    let firstColumn = first % 4
    let secondColumn = second % 4
    return firstRow == secondRow || firstColumn == secondColumn
      || (firstRow / 2 == secondRow / 2 && firstColumn / 2 == secondColumn / 2)
  }
}
