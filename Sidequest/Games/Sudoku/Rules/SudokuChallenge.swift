enum SudokuChallengeError: Error, Equatable {
  case unclassified
  case wrongDifficulty
  case incorrectSolution
  case pocketBudgetExceeded
}

/// Certified against the actual givens; callers must recertify transformed puzzles.
struct SudokuChallenge: Equatable, Sendable {
  let puzzle: SudokuPuzzle
  let classification: SudokuClassification
  var difficulty: GameDifficulty { classification.difficulty }

  init(givens: [Int], solution: [Int], difficulty: GameDifficulty) throws {
    let puzzle = try SudokuPuzzle(givens: givens, configuration: .standard)
    guard puzzle.solution == solution else { throw SudokuChallengeError.incorrectSolution }
    guard let classification = SudokuDifficultyClassifier.classify(givens) else {
      throw SudokuChallengeError.unclassified
    }
    guard classification.difficulty == difficulty else {
      throw SudokuChallengeError.wrongDifficulty
    }
    let budget: Int
    switch difficulty {
    case .easy: budget = 12
    case .medium: budget = 13
    case .hard: budget = 20
    }
    guard givens.filter({ $0 == 0 }).count <= budget else {
      throw SudokuChallengeError.pocketBudgetExceeded
    }
    self.puzzle = puzzle
    self.classification = classification
  }

  static func generate<R: RandomNumberGenerator>(
    difficulty: GameDifficulty, using generator: inout R
  ) throws -> Self {
    let originals = try catalog()
    guard let original = originals.first(where: { $0.difficulty == difficulty }) else {
      throw SudokuChallengeError.unclassified
    }
    var digits = Array(1...9)
    digits.shuffle(using: &generator)
    func renamed(_ cells: [Int]) -> [Int] {
      cells.map { $0 == 0 ? 0 : digits[$0 - 1] }
    }
    // Reclassification, rather than inherited metadata, decides acceptance.
    if let transformed = try? Self(
      givens: renamed(original.puzzle.givens), solution: renamed(original.puzzle.solution),
      difficulty: difficulty)
    {
      return transformed
    }
    return original
  }

  /// Three original fixtures; no random draws or live corpus search.
  static func catalog() throws -> [Self] {
    let easySolution = (0..<9).flatMap { row in
      (0..<9).map { column in (row * 3 + row / 3 + column) % 9 + 1 }
    }
    var easy = easySolution
    for index in [0, 4, 10, 14, 20, 24, 30, 34, 40, 50, 60, 70] { easy[index] = 0 }
    return try [
      Self(givens: easy, solution: easySolution, difficulty: .easy),
      Self(
        givens: [
          3, 7, 8, 1, 4, 5, 0, 9, 0, 5, 6, 1, 0, 0, 9, 7, 3, 4, 9, 2, 4, 0, 3, 7, 0, 1, 5, 2, 4, 7,
          9, 1, 8, 5, 6, 3, 8, 9, 6, 3, 5, 2, 1, 4, 7, 1, 5, 3, 4, 7, 6, 9, 0, 0, 7, 1, 9, 5, 0, 4,
          3, 0, 0, 6, 8, 2, 7, 9, 3, 4, 5, 1, 4, 3, 5, 0, 6, 1, 0, 7, 9,
        ],
        solution: [
          3, 7, 8, 1, 4, 5, 6, 9, 2, 5, 6, 1, 2, 8, 9, 7, 3, 4, 9, 2, 4, 6, 3, 7, 8, 1, 5, 2, 4, 7,
          9, 1, 8, 5, 6, 3, 8, 9, 6, 3, 5, 2, 1, 4, 7, 1, 5, 3, 4, 7, 6, 9, 2, 8, 7, 1, 9, 5, 2, 4,
          3, 8, 6, 6, 8, 2, 7, 9, 3, 4, 5, 1, 4, 3, 5, 8, 6, 1, 2, 7, 9,
        ], difficulty: .medium),
      Self(
        givens: [
          8, 6, 3, 9, 5, 7, 1, 2, 4, 4, 2, 9, 6, 0, 0, 0, 7, 5, 7, 5, 1, 0, 2, 4, 9, 6, 0, 2, 4, 7,
          5, 0, 9, 6, 0, 0, 0, 9, 6, 2, 4, 0, 0, 5, 7, 5, 0, 8, 0, 7, 6, 2, 4, 9, 6, 0, 4, 0, 9, 5,
          7, 0, 2, 0, 8, 5, 7, 6, 2, 4, 9, 0, 9, 7, 2, 4, 3, 0, 5, 0, 6,
        ],
        solution: [
          8, 6, 3, 9, 5, 7, 1, 2, 4, 4, 2, 9, 6, 1, 8, 3, 7, 5, 7, 5, 1, 3, 2, 4, 9, 6, 8, 2, 4, 7,
          5, 8, 9, 6, 1, 3, 1, 9, 6, 2, 4, 3, 8, 5, 7, 5, 3, 8, 1, 7, 6, 2, 4, 9, 6, 1, 4, 8, 9, 5,
          7, 3, 2, 3, 8, 5, 7, 6, 2, 4, 9, 1, 9, 7, 2, 4, 3, 1, 5, 8, 6,
        ], difficulty: .hard),
    ]
  }
}
