/// A technique certificate, not a measurement of human solving time.
struct SudokuClassification: Equatable, Sendable {
  let difficulty: GameDifficulty
  let version: Int
  let placements: Int
  let hiddenSingles: Int
  let candidateRemovals: Int
}

enum SudokuDifficultyClassifier {
  static let version = 1

  /// Every replay makes at most 81 placements and 729 effective removals.
  /// Uniqueness uses the existing exhaustive search and its authoritative node budget.
  static func classify(_ givens: [Int], nodeLimit: Int = 100_000) -> SudokuClassification? {
    guard givens.count == 81, givens.allSatisfy({ (0...9).contains($0) }),
      SudokuGrid.conflicts(in: givens, configuration: .standard).isEmpty
    else { return nil }
    let search = SudokuGrid.search(for: givens, configuration: .standard, nodeLimit: nodeLimit)
    guard search.isExhaustive, search.solutions.count == 1,
      let solution = search.solutions.first
    else { return nil }
    for (level, hidden, advanced) in [
      (GameDifficulty.easy, false, false), (.medium, true, false), (.hard, true, true),
    ] {
      if let replay = Replay(givens).solve(hidden: hidden, advanced: advanced),
        replay.cells == solution
      {
        return SudokuClassification(
          difficulty: level, version: version, placements: replay.placements,
          hiddenSingles: replay.hiddenSingles, candidateRemovals: replay.removals)
      }
    }
    return nil
  }

  // Rows, columns, then boxes; indices and digits are always considered ascending.
  private static let units: [[Int]] =
    (0..<9).map { row in (0..<9).map { row * 9 + $0 } }
    + (0..<9).map { column in (0..<9).map { $0 * 9 + column } }
    + (0..<9).map { box in
      (0..<9).map { (box / 3 * 3 + $0 / 3) * 9 + box % 3 * 3 + $0 % 3 }
    }

  private struct Replay {
    var cells: [Int]
    var candidates: [Set<Int>]
    var placements = 0
    var hiddenSingles = 0
    var removals = 0

    init(_ cells: [Int]) {
      self.cells = cells
      candidates = cells.indices.map { index in
        guard cells[index] == 0 else { return [] }
        let used = cells.indices.filter {
          SudokuGrid.arePeers(index, $0, configuration: .standard)
        }.map { cells[$0] }
        return Set(1...9).subtracting(used)
      }
    }

    func solve(hidden: Bool, advanced: Bool) -> Self? {
      var state = self
      while state.cells.contains(0) {
        guard state.placements < 81, state.removals <= 729,
          !state.cells.indices.contains(where: {
            state.cells[$0] == 0 && state.candidates[$0].isEmpty
          })
        else { return nil }
        if let index = state.cells.indices.first(where: {
          state.cells[$0] == 0 && state.candidates[$0].count == 1
        }), let digit = state.candidates[index].first {
          state.place(digit, at: index)
          continue
        }
        if hidden, let single = state.hiddenSingle() {
          state.hiddenSingles += 1
          state.place(single.digit, at: single.index)
          continue
        }
        guard advanced, state.eliminatePair() || state.eliminatePointing() else { return nil }
      }
      return state
    }

    mutating func place(_ digit: Int, at index: Int) {
      cells[index] = digit
      candidates[index] = []
      placements += 1
      for peer in cells.indices
      where cells[peer] == 0
        && SudokuGrid.arePeers(index, peer, configuration: .standard)
      {
        candidates[peer].remove(digit)
      }
    }

    func hiddenSingle() -> (index: Int, digit: Int)? {
      for unit in SudokuDifficultyClassifier.units {
        for digit in 1...9 {
          let possible = unit.filter { cells[$0] == 0 && candidates[$0].contains(digit) }
          if possible.count == 1 { return (possible[0], digit) }
        }
      }
      return nil
    }

    mutating func remove(_ digits: Set<Int>, from indices: [Int]) -> Bool {
      var changed = false
      for index in indices where cells[index] == 0 {
        let removed = candidates[index].intersection(digits).count
        candidates[index].subtract(digits)
        removals += removed
        changed = changed || removed > 0
      }
      return changed
    }

    mutating func eliminatePair() -> Bool {
      for unit in SudokuDifficultyClassifier.units {
        for first in unit where cells[first] == 0 && candidates[first].count == 2 {
          let matches = unit.filter { cells[$0] == 0 && candidates[$0] == candidates[first] }
          guard matches.count == 2 else { continue }
          let digits = candidates[first]
          if remove(digits, from: unit.filter { !matches.contains($0) }) { return true }
        }
      }
      return false
    }

    mutating func eliminatePointing() -> Bool {
      for box in SudokuDifficultyClassifier.units.suffix(9) {
        for digit in 1...9 {
          let positions = box.filter { cells[$0] == 0 && candidates[$0].contains(digit) }
          guard positions.count >= 2 else { continue }
          if positions.allSatisfy({ $0 / 9 == positions[0] / 9 }),
            remove(
              [digit],
              from: SudokuDifficultyClassifier.units[positions[0] / 9].filter {
                !box.contains($0)
              })
          {
            return true
          }
          if positions.allSatisfy({ $0 % 9 == positions[0] % 9 }),
            remove(
              [digit],
              from: SudokuDifficultyClassifier.units[9 + positions[0] % 9].filter {
                !box.contains($0)
              })
          {
            return true
          }
        }
      }
      return false
    }
  }
}
