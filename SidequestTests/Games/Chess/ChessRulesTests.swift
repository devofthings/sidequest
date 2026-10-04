import Foundation
import XCTest

@testable import Sidequest

final class ChessRulesTests: XCTestCase {
  func testEveryVerifiedMateSolvesAndFreezesTheCorrectBoard() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled(in: Bundle.main)
    XCTAssertEqual(puzzles.count, 2)
    XCTAssertEqual(Set(puzzles.map(\.sideToMove)), [.white, .black])
    for puzzle in puzzles {
      XCTAssertEqual(puzzle.legalMoves.count, 26)
      XCTAssertEqual(puzzle.acceptedMoves.count, 4)
      for move in puzzle.acceptedMoves {
        var attempt = ChessAttempt(puzzle: puzzle)
        XCTAssertNil(attempt.selectedSquare)
        XCTAssertNil(attempt.feedback)
        attempt.tap(move.origin)
        XCTAssertEqual(attempt.selectedSquare, move.origin)
        XCTAssertFalse(attempt.isSolved)
        attempt.tap(move.destination)
        XCTAssertTrue(attempt.isSolved)
        XCTAssertEqual(attempt.solution, move)
        XCTAssertEqual(attempt.feedback, .checkmate)
        XCTAssertNil(attempt.selectedSquare)
        XCTAssertNil(attempt.board[move.origin])
        XCTAssertEqual(attempt.board[move.destination], puzzle.board[move.origin])
        let completedBoard = attempt.board
        attempt.tap(move.origin)
        XCTAssertEqual(attempt.board, completedBoard)
        XCTAssertEqual(attempt.solution, move)
        XCTAssertEqual(attempt.feedback, .checkmate)
      }
    }
  }

  func testWrongLegalMovesAndIllegalMovesPreserveThePosition() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      for move in puzzle.legalMoves.subtracting(puzzle.acceptedMoves) {
        var attempt = ChessAttempt(puzzle: puzzle)
        attempt.tap(move.origin)
        attempt.tap(move.destination)
        XCTAssertEqual(attempt.feedback, .notCheckmate)
        XCTAssertFalse(attempt.isSolved)
        XCTAssertNil(attempt.selectedSquare)
        XCTAssertEqual(attempt.board, puzzle.board)
      }
      let queen = try XCTUnwrap(puzzle.board.first { $0.value.kind == .queen }?.key)
      let otherKing = try XCTUnwrap(
        puzzle.board.first { $0.value.side != puzzle.sideToMove }?.key)
      var attempt = ChessAttempt(puzzle: puzzle)
      attempt.tap(otherKing)
      XCTAssertNil(attempt.selectedSquare)
      XCTAssertEqual(attempt.feedback, .chooseMovingPiece)
      attempt.tap(queen)
      attempt.tap(otherKing)
      XCTAssertEqual(attempt.feedback, .illegalMove)
      XCTAssertFalse(attempt.isSolved)
      XCTAssertEqual(attempt.board, puzzle.board)
    }
  }

  func testCoordinatesSideSelectionAndFreshAttempt() async throws {
    XCTAssertEqual(ChessSquare.displayOrder.count, 64)
    XCTAssertEqual(Set(ChessSquare.displayOrder).count, 64)
    XCTAssertEqual(ChessSquare.displayOrder.first?.coordinate, "a8")
    XCTAssertEqual(ChessSquare.displayOrder.last?.coordinate, "h1")
    for coordinate in ["a1", "b3", "g6", "h8"] {
      XCTAssertEqual(ChessSquare(coordinate)?.coordinate, coordinate)
    }
    for invalid in ["a0", "i1", "A1", "a11", "", "é1"] {
      XCTAssertNil(ChessSquare(invalid))
    }
    XCTAssertNil(ChessMove("a1a1"))
    XCTAssertNil(ChessMove("a7a8q"))
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let own = puzzle.board.filter { $0.value.side == puzzle.sideToMove }.map(\.key)
      XCTAssertEqual(own.count, 2)
      var attempt = ChessAttempt(puzzle: puzzle)
      attempt.tap(own[0])
      attempt.tap(own[1])
      XCTAssertEqual(attempt.selectedSquare, own[1])
      attempt.tap(own[1])
      XCTAssertNil(attempt.selectedSquare)
      attempt.tap(own[0])
      let fresh = ChessAttempt(puzzle: puzzle)
      XCTAssertNil(fresh.selectedSquare)
      XCTAssertNil(fresh.feedback)
      XCTAssertFalse(fresh.isSolved)
      XCTAssertEqual(fresh.board, puzzle.board)
    }
  }

  func testFixtureBoundaryRejectsMalformedOrUnsupportedData() throws {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "chess-puzzles", withExtension: "json"))
    let valid = try Data(contentsOf: url)
    let fixtures = try XCTUnwrap(JSONSerialization.jsonObject(with: valid) as? [[String: Any]])
    for field in ["id", "fen", "sideToMove", "objective", "legalMoves", "acceptedMoves"] {
      var missing = fixtures
      missing[0].removeValue(forKey: field)
      XCTAssertThrowsError(
        try ChessPuzzleLoader.decode(JSONSerialization.data(withJSONObject: missing)))
    }
    let mutations: [(String, Any)] = [
      ("id", " "), ("fen", "7k/5K2/6Q1/8/8/8/8/7 w - - 0 1"),
      ("fen", "7k/5K2/6Q1/8/8/8/8/8 w K - 0 1"),
      ("fen", "7k/5K2/6Q1/8/8/8/8/8 w - a6 0 1"),
      ("fen", "7k/5K2/6P1/8/8/8/8/8 w - - 0 1"),
      ("fen", "7k/7K/6Q1/8/8/8/8/8 w - - 0 1"),
      ("sideToMove", "black"), ("objective", "play-a-match"),
      ("legalMoves", ["h8h7"]), ("acceptedMoves", ["g6g7q"]),
      ("acceptedMoves", ["g6g7", "g6g7"]), ("acceptedMoves", []),
    ]
    for (field, value) in mutations {
      var malformed = fixtures
      malformed[0][field] = value
      XCTAssertThrowsError(
        try ChessPuzzleLoader.decode(JSONSerialization.data(withJSONObject: malformed)), field)
    }
    var duplicate = fixtures
    duplicate[1]["id"] = fixtures[0]["id"]
    XCTAssertThrowsError(
      try ChessPuzzleLoader.decode(JSONSerialization.data(withJSONObject: duplicate)))
    XCTAssertThrowsError(try ChessPuzzleLoader.decode(Data("[]".utf8)))
  }
}
