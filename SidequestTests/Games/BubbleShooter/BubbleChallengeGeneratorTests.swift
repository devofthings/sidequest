import XCTest

@testable import Sidequest

final class BubbleChallengeGeneratorTests: XCTestCase {
  func testGeneratedAndFallbackChallengesRequireThreeAnchoredColorClears() throws {
    for seed in 0..<128 {
      for useFallback in [false, true] {
        var random = ChallengeRandom(seed: UInt64(seed))
        let challenge =
          try useFallback
          ? BubbleChallengeGenerator.fallback(using: &random)
          : BubbleChallengeGenerator.generate(using: &random)
        var game = challenge.game
        let pending = try game.traceShot(angleRadians: challenge.winningAngles[0] * .pi / 180)
        XCTAssertTrue(game.board.keys.allSatisfy { $0.row < 2 })
        XCTAssertTrue((6...9).contains(game.board.count))
        XCTAssertEqual(Set(game.board.filter { $0.key.row == 0 }.values).count, 3)
        XCTAssertEqual(challenge.winningAngles.count, 3)
        for (index, angle) in challenge.winningAngles.enumerated() {
          let color = game.nextColor
          let result = try game.fire(angleRadians: angle * .pi / 180)
          XCTAssertGreaterThanOrEqual(result.matched.count, 3)
          XCTAssertFalse(game.board.values.contains(color))
          XCTAssertEqual(Set(game.board.filter { $0.key.row == 0 }.values).count, 2 - index)
          XCTAssertEqual(game.outcome, index == 2 ? .won : .playing)
        }
        XCTAssertEqual(game.shotsFired, 3)
        game.reset()
        XCTAssertEqual(game.board, challenge.game.board)
        XCTAssertEqual(game.nextColor, challenge.game.nextColor)
        XCTAssertEqual(game.shotsFired, 0)
        XCTAssertEqual(game.outcome, .playing)
        XCTAssertThrowsError(try game.commitShot(pending)) { error in
          XCTAssertEqual(error as? BubbleShotError, .staleShot)
        }
        var fresh = challenge.game
        for angle in challenge.winningAngles {
          XCTAssertEqual(
            try game.fire(angleRadians: angle * .pi / 180),
            try fresh.fire(angleRadians: angle * .pi / 180))
          XCTAssertEqual(game.board, fresh.board)
          XCTAssertEqual(game.nextColor, fresh.nextColor)
          XCTAssertEqual(game.shotsFired, fresh.shotsFired)
          XCTAssertEqual(game.outcome, fresh.outcome)
        }
        XCTAssertEqual(game.outcome, .won)
      }
    }
  }

  func testNoFirstShotCanClearTheOtherCeilingColors() throws {
    for seed in 0..<12 {
      var random = ChallengeRandom(seed: UInt64(seed))
      let challenge = try BubbleChallengeGenerator.generate(using: &random)
      for degrees in -60...60 {
        var game = challenge.game
        _ = try game.fire(angleRadians: Double(degrees) * .pi / 180)
        XCTAssertNotEqual(game.outcome, .won)
        XCTAssertGreaterThanOrEqual(Set(game.board.filter { $0.key.row == 0 }.values).count, 2)
      }
    }
  }
}
