/// Internal operations accept validated cell counts and values. Zero means empty.
enum SudokuGrid {
  struct SearchResult {
    let solutions: [[Int]]
    /// True when search finished or proved ambiguity by finding two solutions.
    let isExhaustive: Bool
  }

  static func conflicts(
    in cells: [Int], configuration: SudokuConfiguration = .mini
  ) -> Set<Int> {
    var result = Set<Int>()
    for first in cells.indices where cells[first] != 0 {
      for second in cells.indices where second > first && cells[first] == cells[second] {
        if arePeers(first, second, configuration: configuration) {
          result.formUnion([first, second])
        }
      }
    }
    return result
  }

  static func solutions(
    for givens: [Int], configuration: SudokuConfiguration = .mini
  ) -> [[Int]] {
    let result = search(for: givens, configuration: configuration)
    return result.isExhaustive ? result.solutions : []
  }

  /// Minimum-remaining-values search stops after two solutions or its node budget.
  /// A partial search can never certify uniqueness, even if it found one solution.
  static func search(
    for givens: [Int], configuration: SudokuConfiguration, nodeLimit: Int = 100_000
  ) -> SearchResult {
    guard givens.count == configuration.cellCount,
      givens.allSatisfy({ (0...configuration.size).contains($0) }),
      conflicts(in: givens, configuration: configuration).isEmpty
    else { return SearchResult(solutions: [], isExhaustive: true) }
    var solutions: [[Int]] = []
    var cells = givens
    var rowMasks = Array(repeating: 0, count: configuration.size)
    var columnMasks = rowMasks
    var regionMasks = rowMasks
    func region(_ index: Int) -> Int {
      (index / configuration.size / configuration.regionSize) * configuration.regionSize
        + index % configuration.size / configuration.regionSize
    }
    for index in cells.indices where cells[index] != 0 {
      let bit = 1 << cells[index]
      rowMasks[index / configuration.size] |= bit
      columnMasks[index % configuration.size] |= bit
      regionMasks[region(index)] |= bit
    }
    var visited = 0
    var exhausted = true
    func visit() {
      guard solutions.count < 2, exhausted else { return }
      guard visited < nodeLimit else {
        exhausted = false
        return
      }
      visited += 1
      var selected: Int?
      var candidates: [Int] = []
      for index in cells.indices where cells[index] == 0 {
        let used =
          rowMasks[index / configuration.size] | columnMasks[index % configuration.size]
          | regionMasks[region(index)]
        let values = (1...configuration.size).filter { used & (1 << $0) == 0 }
        if values.isEmpty { return }
        if selected == nil || values.count < candidates.count {
          selected = index
          candidates = values
          if values.count == 1 { break }
        }
      }
      guard let selected else {
        solutions.append(cells)
        return
      }
      for value in candidates {
        let bit = 1 << value
        cells[selected] = value
        rowMasks[selected / configuration.size] |= bit
        columnMasks[selected % configuration.size] |= bit
        regionMasks[region(selected)] |= bit
        visit()
        rowMasks[selected / configuration.size] &= ~bit
        columnMasks[selected % configuration.size] &= ~bit
        regionMasks[region(selected)] &= ~bit
        cells[selected] = 0
        if solutions.count == 2 || !exhausted { break }
      }
    }
    visit()
    return SearchResult(solutions: solutions, isExhaustive: exhausted || solutions.count == 2)
  }

  static func arePeers(
    _ first: Int, _ second: Int, configuration: SudokuConfiguration = .mini
  ) -> Bool {
    guard first != second else { return false }
    let firstRow = first / configuration.size
    let secondRow = second / configuration.size
    let firstColumn = first % configuration.size
    let secondColumn = second % configuration.size
    return firstRow == secondRow || firstColumn == secondColumn
      || (firstRow / configuration.regionSize == secondRow / configuration.regionSize
        && firstColumn / configuration.regionSize == secondColumn / configuration.regionSize)
  }
}
