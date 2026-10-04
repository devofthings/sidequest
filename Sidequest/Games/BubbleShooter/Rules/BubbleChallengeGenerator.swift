import Foundation

struct BubbleChallenge: Equatable, Sendable {
  let game: BubbleShooterGame
  let winningAngles: [Double]
}

enum BubbleGenerationError: Error { case noAttainableChallenge }

enum BubbleChallengeGenerator {
  static let attemptLimit = 16
  static let anglesPerAttempt = 121

  /// Small ceiling-connected shapes stay quick. Accept only a replayed winning shot.
  /// Different geometry, colors, and frozen shot sequences produce fresh configurations.
  static func generate<R: RandomNumberGenerator>(using random: inout R) throws -> BubbleChallenge {
    for _ in 0..<attemptLimit {
      let color = BubbleColor.allCases.randomElement(using: &random) ?? .red
      let count = Int.random(in: 2...4, using: &random)
      let start = Int.random(in: 0...(5 - count), using: &random)
      var board: [BubbleSlot: BubbleColor] = [:]
      for column in start..<(start + count) { board[BubbleSlot(row: 0, column: column)] = color }
      // Optional connected second-row bubbles either match or detach when the ceiling clears.
      for column in max(0, start - 1)...min(3, start + count - 1) {
        if Bool.random(using: &random) {
          board[BubbleSlot(row: 1, column: column)] =
            BubbleColor.allCases.randomElement(using: &random) ?? color
        }
      }
      let colors =
        [color]
        + (0..<7).map { _ in
          BubbleColor.allCases.randomElement(using: &random) ?? color
        }
      let game = try BubbleShooterGame(board: board, shotColors: colors)
      if let angle = winningAngle(for: game) {
        return BubbleChallenge(game: game, winningAngles: [angle])
      }
    }
    return try fallback(using: &random)
  }

  /// Also bounded and validated; callers may choose the small fallback directly.
  static func fallback<R: RandomNumberGenerator>(using random: inout R) throws -> BubbleChallenge {
    // The small fallback varies by color and shot sequence.
    let color = BubbleColor.allCases.randomElement(using: &random) ?? .red
    let game = try BubbleShooterGame(
      board: [BubbleSlot(row: 0, column: 2): color, BubbleSlot(row: 0, column: 3): color],
      shotColors: [color] + BubbleColor.allCases.shuffled(using: &random))
    guard let angle = winningAngle(for: game) else {
      throw BubbleGenerationError.noAttainableChallenge
    }
    return BubbleChallenge(game: game, winningAngles: [angle])
  }

  private static func winningAngle(for game: BubbleShooterGame) -> Double? {
    for degrees in -60...60 {
      var candidate = game
      if let result = try? candidate.fire(angleRadians: Double(degrees) * .pi / 180),
        result.outcome == .won, candidate.shotsFired <= BubbleShooterGame.shotLimit
      {
        return Double(degrees)
      }
    }
    return nil
  }
}
