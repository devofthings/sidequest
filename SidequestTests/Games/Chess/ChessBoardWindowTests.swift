import Foundation
import XCTest

@testable import Sidequest

final class ChessBoardWindowTests: XCTestCase {
  func testOriginalWindowsRetainCoordinatesPiecesAndEveryMate() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let window = ChessBoardWindow(puzzle: puzzle)
      XCTAssertEqual(window.displayOrder.count, 16)
      XCTAssertEqual(Set(window.displayOrder).count, 16)
      XCTAssertEqual(window.files.count, 4)
      XCTAssertEqual(window.ranks.count, 4)
      XCTAssertEqual(window.coordinateRange, puzzle.sideToMove == .white ? "e5–h8" : "a1–d4")
      XCTAssertEqual(
        window.displayOrder.first?.coordinate, puzzle.sideToMove == .white ? "e8" : "a4")
      XCTAssertEqual(
        window.displayOrder.last?.coordinate, puzzle.sideToMove == .white ? "h5" : "d1")
      XCTAssertTrue(puzzle.board.keys.allSatisfy(window.contains))
      let defender = try XCTUnwrap(puzzle.board.first { $0.value.side != puzzle.sideToMove }?.key)
      for neighbor in ChessSquare.displayOrder
      where
        max(abs(neighbor.file - defender.file), abs(neighbor.rank - defender.rank)) <= 1
      {
        XCTAssertTrue(window.contains(neighbor))
      }
      for move in puzzle.acceptedMoves {
        XCTAssertTrue(window.contains(move.origin))
        XCTAssertTrue(window.contains(move.destination))
        var attempt = ChessAttempt(puzzle: puzzle)
        attempt.tap(move.origin)
        attempt.tap(move.destination)
        XCTAssertTrue(attempt.isSolved)
        XCTAssertTrue(attempt.board.keys.allSatisfy(window.contains))
        XCTAssertEqual(ChessBoardWindow(puzzle: puzzle), window)
      }
    }
  }

  func testOutsideWindowLegalDestinationsKeepStandardNonmateBehavior() async throws {
    for puzzle in try await ChessPuzzleLoader.bundled(in: Bundle.main) {
      let window = ChessBoardWindow(puzzle: puzzle)
      let outside = puzzle.legalMoves.filter { !window.contains($0.destination) }
      XCTAssertFalse(outside.isEmpty)
      for move in outside {
        XCTAssertFalse(puzzle.acceptedMoves.contains(move))
        var attempt = ChessAttempt(puzzle: puzzle)
        attempt.tap(move.origin)
        attempt.submit(to: move.destination)
        XCTAssertEqual(attempt.feedback, .notCheckmate)
        XCTAssertEqual(attempt.board, puzzle.board)
        XCTAssertFalse(attempt.isSolved)
        XCTAssertEqual(ChessBoardWindow(puzzle: puzzle), window)
      }
    }
  }

  func testUnknownOrChangedFixtureFallsBackInsteadOfClippingInformation() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled(in: Bundle.main)
    let puzzle = try XCTUnwrap(puzzles.first)
    let outside = try XCTUnwrap(puzzle.legalMoves.first { $0.notation == "g6a6" })
    for changed in [
      try ChessPuzzle(
        id: "future-position", fen: puzzle.fen, sideToMove: puzzle.sideToMove,
        objective: puzzle.objective, legalMoves: puzzle.legalMoves.map(\.notation),
        acceptedMoves: puzzle.acceptedMoves.map(\.notation)),
      // Structurally accepted input is not legality certification; altered answer data must not be clipped.
      try ChessPuzzle(
        id: puzzle.id, fen: puzzle.fen, sideToMove: puzzle.sideToMove,
        objective: puzzle.objective, legalMoves: puzzle.legalMoves.map(\.notation),
        acceptedMoves: [outside.notation]),
      try ChessPuzzle(
        id: puzzle.id, fen: "7k/5K2/6Q1/8/8/8/8/8 w - - 1 1", sideToMove: puzzle.sideToMove,
        objective: puzzle.objective, legalMoves: puzzle.legalMoves.map(\.notation),
        acceptedMoves: puzzle.acceptedMoves.map(\.notation)),
    ] {
      XCTAssertEqual(ChessBoardWindow(puzzle: changed), .fullBoard)
      XCTAssertEqual(ChessBoardWindow(puzzle: changed).displayOrder, ChessSquare.displayOrder)
      XCTAssertEqual(ChessBoardWindow(puzzle: changed).coordinateRange, "a1–h8")
    }
  }
}
