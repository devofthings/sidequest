import XCTest

@testable import Sidequest

final class SudokuDifficultyTests: XCTestCase {
  func testOriginalCatalogUsesCanonicalUniqueSolutionsAndEffectiveTechniques() throws {
    let catalog = try SudokuChallenge.catalog()
    XCTAssertEqual(catalog.map(\.difficulty), [.easy, .medium, .hard])
    XCTAssertEqual(catalog.map { $0.puzzle.givens.filter { $0 == 0 }.count }, [12, 13, 20])
    for challenge in catalog {
      XCTAssertEqual(
        SudokuGrid.search(
          for: challenge.puzzle.givens,
          configuration: .standard
        ).solutions, [challenge.puzzle.solution])
      XCTAssertEqual(
        SudokuDifficultyClassifier.classify(challenge.puzzle.givens),
        challenge.classification)
      XCTAssertEqual(challenge.classification.version, 1)
      XCTAssertLessThanOrEqual(challenge.classification.placements, 81)
      XCTAssertLessThanOrEqual(challenge.classification.candidateRemovals, 729)
    }
    XCTAssertEqual(catalog[0].classification.hiddenSingles, 0)
    XCTAssertEqual(catalog[0].classification.candidateRemovals, 0)
    XCTAssertGreaterThan(catalog[1].classification.hiddenSingles, 0)
    XCTAssertEqual(catalog[1].classification.candidateRemovals, 0)
    XCTAssertGreaterThan(catalog[2].classification.candidateRemovals, 0)
    // This original cannot start with either kind of single. Its effective
    // pointing elimination must survive the next placement to finish the replay.
    XCTAssertEqual(catalog[2].classification.placements, 20)
  }

  func testInvalidAmbiguousAndExhaustedBoardsRemainUnclassified() throws {
    let easy = try XCTUnwrap(SudokuChallenge.catalog().first)
    XCTAssertNil(SudokuDifficultyClassifier.classify(Array(repeating: 0, count: 81)))
    XCTAssertNil(SudokuDifficultyClassifier.classify([0]))
    var invalid = easy.puzzle.givens
    invalid[0] = 10
    XCTAssertNil(SudokuDifficultyClassifier.classify(invalid))
    invalid = easy.puzzle.solution
    invalid[0] = invalid[1]
    XCTAssertNil(SudokuDifficultyClassifier.classify(invalid))
    XCTAssertNil(SudokuDifficultyClassifier.classify(easy.puzzle.givens, nodeLimit: 0))
    XCTAssertNil(SudokuDifficultyClassifier.classify(easy.puzzle.givens, nodeLimit: 1))
    XCTAssertThrowsError(
      try SudokuChallenge(
        givens: easy.puzzle.givens,
        solution: Array(repeating: 1, count: 81), difficulty: .easy)
    ) {
      XCTAssertEqual($0 as? SudokuChallengeError, .incorrectSolution)
    }
    XCTAssertThrowsError(
      try SudokuChallenge(
        givens: easy.puzzle.givens,
        solution: easy.puzzle.solution, difficulty: .hard)
    ) {
      XCTAssertEqual($0 as? SudokuChallengeError, .wrongDifficulty)
    }
  }

  func testSeededVariantsRecertifyActualGivensAndPreserveNeighborRandomStream() throws {
    var legacy = ChallengeRandom(seed: 187)
    var expectedLegacy = ChallengeRandom(seed: 187)
    var independent = ChallengeRandom(seed: 118)
    _ = try SudokuChallenge.generate(difficulty: .hard, using: &independent)
    XCTAssertEqual(
      try SudokuGenerator.generate(using: &legacy),
      try SudokuGenerator.generate(using: &expectedLegacy))
    XCTAssertEqual(legacy.next(), expectedLegacy.next())
    for difficulty in [GameDifficulty.easy, .medium, .hard] {
      var boards = Set<[Int]>()
      for seed in UInt64(0)..<8 {
        var first = ChallengeRandom(seed: seed)
        var second = ChallengeRandom(seed: seed)
        let challenge = try SudokuChallenge.generate(difficulty: difficulty, using: &first)
        XCTAssertEqual(
          challenge,
          try SudokuChallenge.generate(difficulty: difficulty, using: &second))
        XCTAssertEqual(first.next(), second.next())
        XCTAssertEqual(challenge.difficulty, difficulty)
        XCTAssertEqual(
          SudokuDifficultyClassifier.classify(challenge.puzzle.givens),
          challenge.classification)
        boards.insert(challenge.puzzle.givens)
      }
      XCTAssertGreaterThan(boards.count, 1)
    }
  }
}
