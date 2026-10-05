import Foundation
import XCTest

@testable import Sidequest

final class ChessChallengeTests: XCTestCase {
  func testCatalogSpansBothSidesBandsAndIndependentFocusSizes() async throws {
    let puzzles = try await ChessPuzzleLoader.bundledCatalog(in: Bundle.main)
    XCTAssertEqual(puzzles.count, 10)
    XCTAssertEqual(Set(puzzles.compactMap { $0.challenge?.difficulty }), [.easy, .medium, .hard])
    XCTAssertEqual(Set(puzzles.compactMap { $0.challenge?.focus.size }), [3, 4, 5])
    for difficulty in [GameDifficulty.easy, .medium, .hard] {
      XCTAssertEqual(
        Set(puzzles.filter { $0.challenge?.difficulty == difficulty }.map(\.sideToMove)),
        [.white, .black])
    }
    XCTAssertEqual(
      Set(
        puzzles.filter { $0.challenge?.difficulty == .hard }.compactMap { $0.challenge?.focus.size }
      ), [3, 4, 5])
    for puzzle in puzzles {
      let metadata = try XCTUnwrap(puzzle.challenge)
      let window = ChessBoardWindow(puzzle: puzzle)
      XCTAssertEqual(window.displayOrder.count, metadata.focus.size * metadata.focus.size)
      XCTAssertTrue(puzzle.board.keys.allSatisfy(window.contains))
      for move in puzzle.acceptedMoves {
        var attempt = ChessAttempt(puzzle: puzzle)
        attempt.tap(move.origin)
        attempt.submit(to: move.destination)
        XCTAssertTrue(attempt.isSolved, puzzle.id)
        XCTAssertTrue(attempt.board.keys.allSatisfy(window.contains))
        XCTAssertEqual(ChessBoardWindow(puzzle: puzzle), window)
      }
      let outside = puzzle.legalMoves.filter { !window.contains($0.destination) }
      XCTAssertFalse(outside.isEmpty)
      for move in outside {
        var attempt = ChessAttempt(puzzle: puzzle)
        attempt.tap(move.origin)
        attempt.submit(to: move.destination)
        XCTAssertEqual(attempt.feedback, .notCheckmate)
        XCTAssertEqual(attempt.board, puzzle.board)
      }
    }
  }

  func testCatalogBoundaryRejectsIncorrectBandsAndMalformedOrClippingFocus() throws {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "chess-challenges", withExtension: "json"))
    let fixtures = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
    let mutations: [[String: Any]] = [
      [
        "difficulty": "easy", "checkingNonmates": [],
        "focus": ["fileStart": 0, "rankStart": 0, "size": 3],
      ],
      [
        "difficulty": "hard", "checkingNonmates": ["c2b2"],
        "focus": ["fileStart": 0, "rankStart": 0, "size": 3],
      ],
      [
        "difficulty": "hard", "checkingNonmates": [],
        "focus": ["fileStart": 0, "rankStart": 0, "size": 2],
      ],
      [
        "difficulty": "hard", "checkingNonmates": [],
        "focus": ["fileStart": -1, "rankStart": 0, "size": 3],
      ],
      [
        "difficulty": "hard", "checkingNonmates": [],
        "focus": ["fileStart": 6, "rankStart": 0, "size": 3],
      ],
      [
        "difficulty": "hard", "checkingNonmates": [],
        "focus": ["fileStart": 1, "rankStart": 0, "size": 3],
      ],
      [
        "difficulty": "hard", "checkingNonmates": ["c2a2", "c2a2"],
        "focus": ["fileStart": 0, "rankStart": 0, "size": 3],
      ],
    ]
    for metadata in mutations {
      var bad = fixtures
      bad[0]["challenge"] = metadata
      XCTAssertThrowsError(
        try ChessPuzzleLoader.decode(
          JSONSerialization.data(withJSONObject: bad), requiresChallenge: true))
    }
    var missing = fixtures
    missing[0].removeValue(forKey: "challenge")
    XCTAssertThrowsError(
      try ChessPuzzleLoader.decode(
        JSONSerialization.data(withJSONObject: missing), requiresChallenge: true))
    for size in [Int.min, -1, 2, 6, Int.max] {
      XCTAssertFalse(ChessFocusArea(fileStart: 0, rankStart: 0, size: size).isValid)
    }
  }

  @MainActor
  func testCatalogConfigurationRemainsFrozenThroughResetAndCompletedRevisit() async throws {
    for puzzle in try await ChessPuzzleLoader.bundledCatalog(in: Bundle.main) {
      let metadata = puzzle.challenge
      let window = ChessBoardWindow(puzzle: puzzle)
      let runtime = GameRuntime(activationPolicy: .firstInteraction)
      let controller = ChessController(puzzle: puzzle, runtime: runtime)
      let move = try XCTUnwrap(puzzle.acceptedMoves.sorted { $0.notation < $1.notation }.first)
      controller.tap(move.origin)
      XCTAssertNil(controller.attempt)
      runtime.setVisible(true)
      controller.tap(move.origin)
      XCTAssertEqual(controller.attempt?.selectedSquare, move.origin)
      runtime.setVisible(false)
      XCTAssertNil(controller.attempt)
      XCTAssertEqual(controller.puzzle.challenge, metadata)
      XCTAssertEqual(ChessBoardWindow(puzzle: controller.puzzle), window)
      runtime.setVisible(true)
      controller.tap(move.origin)
      XCTAssertEqual(controller.attempt?.selectedSquare, move.origin)
      controller.selectFile(move.destination.file)
      controller.selectRank(move.destination.rank)
      controller.submitCoordinates()
      XCTAssertTrue(controller.attempt?.isSolved ?? false)
      let completed = controller.attempt?.board
      runtime.setVisible(false)
      runtime.setVisible(true)
      controller.tap(move.origin)
      XCTAssertEqual(controller.attempt?.board, completed)
      XCTAssertEqual(controller.puzzle.challenge, metadata)
      XCTAssertEqual(ChessBoardWindow(puzzle: controller.puzzle), window)
      XCTAssertFalse(controller.canAcceptInput)
    }
  }
}
