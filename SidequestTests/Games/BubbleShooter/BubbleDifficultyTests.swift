import XCTest

@testable import Sidequest

final class BubbleDifficultyTests: XCTestCase {
  func testEveryTierAndFallbackHasTheSameOriginalWitnessAndRNGConsumption() throws {
    for seed in 0..<64 {
      for fallback in [false, true] {
        for (tier, cap) in [(GameDifficulty.easy, 8), (.medium, 5), (.hard, 3)] {
          var legacyRandom = ChallengeRandom(seed: UInt64(seed))
          var tierRandom = ChallengeRandom(seed: UInt64(seed))
          let legacy =
            try fallback
            ? BubbleChallengeGenerator.fallback(using: &legacyRandom)
            : BubbleChallengeGenerator.generate(using: &legacyRandom)
          let challenge =
            try fallback
            ? BubbleChallengeGenerator.fallback(difficulty: tier, using: &tierRandom)
            : BubbleChallengeGenerator.generate(difficulty: tier, using: &tierRandom)
          XCTAssertEqual(legacyRandom.next(), tierRandom.next())
          XCTAssertEqual(challenge.game.board, legacy.game.board)
          XCTAssertEqual(challenge.winningAngles, legacy.winningAngles)
          XCTAssertEqual(challenge.game.maximumShots, cap)
          XCTAssertEqual(challenge.game.difficulty, tier)
          var game = challenge.game
          var original = legacy.game
          for (index, angle) in challenge.winningAngles.enumerated() {
            XCTAssertEqual(game.nextColor, original.nextColor)
            let radians = angle * .pi / 180
            XCTAssertEqual(
              try game.fire(angleRadians: radians), try original.fire(angleRadians: radians))
            XCTAssertEqual(game.outcome, index == 2 ? .won : .playing)
          }
          XCTAssertEqual(game.shotsFired, 3)
          XCTAssertEqual(
            game.outcome, .won, "Hard's last permitted shot must win before exhaustion")
          game.reset()
          XCTAssertEqual(game.maximumShots, cap)
          XCTAssertEqual(game.difficulty, tier)
          XCTAssertEqual(game.board, challenge.game.board)
          XCTAssertEqual(game.nextColor, challenge.game.nextColor)
          XCTAssertEqual(game.shotsFired, 0)
        }
      }
    }
  }

  func testConfiguredShotExhaustionIsAnActualNonwinningRuleTransition() throws {
    for (tier, cap) in [(GameDifficulty.easy, 8), (.medium, 5), (.hard, 3)] {
      var game = try BubbleShooterGame(
        board: [BubbleSlot(row: 0, column: 0): .red], shotColors: [.blue],
        maximumShots: cap, difficulty: tier)
      for shot in 1...cap {
        _ = try game.fire(angleRadians: 0)
        XCTAssertEqual(game.shotsFired, shot)
        XCTAssertEqual(game.outcome, shot == cap ? .lost(.shotLimit) : .playing)
      }
      XCTAssertEqual(game.board[BubbleSlot(row: 0, column: 0)], .red)
      XCTAssertThrowsError(try game.fire(angleRadians: 0))
      game.reset()
      XCTAssertEqual(game.maximumShots, cap)
      XCTAssertEqual(game.difficulty, tier)
      XCTAssertEqual(game.outcome, .playing)
    }
  }

  func testInvalidConfigurationCannotCarryFalseTierMetadata() throws {
    for cap in [-1, 0, 9, Int.max] {
      XCTAssertThrowsError(
        try BubbleShooterGame(
          board: BubbleShooterGame.challenge, shotColors: [.red], maximumShots: cap)
      ) {
        XCTAssertEqual($0 as? BubbleShotError, .invalidConfiguration)
      }
    }
    for tier in [GameDifficulty.easy, .medium, .hard] {
      for cap in 1...8 where cap != BubbleShooterGame.maximumShots(for: tier) {
        XCTAssertThrowsError(
          try BubbleShooterGame(
            board: BubbleShooterGame.challenge, shotColors: [.red], maximumShots: cap,
            difficulty: tier)
        ) {
          XCTAssertEqual($0 as? BubbleShotError, .invalidConfiguration)
        }
      }
    }
    XCTAssertEqual(BubbleShooterGame().maximumShots, 8)
    XCTAssertNil(BubbleShooterGame().difficulty)
  }

  func testDangerLossCanPrecedeTheAvailableAttemptBudget() throws {
    var game = try BubbleShooterGame().configured(for: .easy)
    while game.outcome == .playing { _ = try game.fire(angleRadians: 0) }
    XCTAssertEqual(game.outcome, .lost(.dangerRow))
    XCTAssertLessThan(game.shotsFired, game.maximumShots)
  }
}
