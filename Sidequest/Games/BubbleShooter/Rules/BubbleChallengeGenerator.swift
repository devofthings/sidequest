import Foundation

struct BubbleChallenge: Equatable, Sendable {
  let game: BubbleShooterGame
  let winningAngles: [Double]
}

enum BubbleGenerationError: Error { case noAttainableChallenge }

enum BubbleChallengeGenerator {
  static let attemptLimit = 4
  static let witnessShotsPerAttempt = 3

  /// Three differently colored ceiling anchors require three clearing actions even when lower
  /// bubbles detach. Every constructive witness is replayed through the actual rules before use.
  static func generate<R: RandomNumberGenerator>(using random: inout R) throws -> BubbleChallenge {
    for _ in 0..<attemptLimit {
      if let challenge = try candidate(
        pattern: Int.random(in: 0..<8, using: &random), using: &random)
      {
        return challenge
      }
    }
    return try fallback(using: &random)
  }

  /// The fallback has the same three required color groups, never a trivial single-shot clear.
  static func fallback<R: RandomNumberGenerator>(using random: inout R) throws -> BubbleChallenge {
    guard let challenge = try candidate(pattern: 7, using: &random) else {
      throw BubbleGenerationError.noAttainableChallenge
    }
    return challenge
  }

  private static func candidate<R: RandomNumberGenerator>(pattern: Int, using random: inout R)
    throws -> BubbleChallenge?
  {
    let colors = BubbleColor.allCases.shuffled(using: &random)
    let reflected = Bool.random(using: &random)
    var board: [BubbleSlot: BubbleColor] = [:]
    for column in 0..<5 {
      board[BubbleSlot(row: 0, column: reflected ? 4 - column : column)] =
        colors[min(column / 2, 2)]
    }
    board[BubbleSlot(row: 1, column: reflected ? 0 : 3)] = colors[2]
    for column in 0..<3 where pattern & (1 << column) != 0 {
      board[BubbleSlot(row: 1, column: reflected ? 3 - column : column)] =
        colors[column < 2 ? 0 : 1]
    }
    let shotColors =
      colors
      + (0..<5).map { _ in
        BubbleColor.allCases.randomElement(using: &random) ?? colors[0]
      }
    let game = try BubbleShooterGame(board: board, shotColors: shotColors)
    // Original pattern witnesses were independently replayed; reflection also reflects each angle.
    let witnesses: [[Double]] = [
      [-45, -51, -60], [-45, -51, -60], [-51, -51, -60], [-51, -51, -60],
      [-45, -60, -60], [-45, -60, -60], [-55, -60, -60], [-55, -60, -60],
    ]
    let angles = witnesses[pattern].map { reflected ? -$0 : $0 }
    var replay = game
    for (index, angle) in angles.enumerated() {
      guard replay.outcome == .playing,
        let result = try? replay.fire(angleRadians: angle * .pi / 180), result.matched.count >= 3,
        !replay.board.values.contains(colors[index])
      else { return nil }
    }
    guard replay.outcome == .won, replay.shotsFired == witnessShotsPerAttempt else { return nil }
    return BubbleChallenge(game: game, winningAngles: angles)
  }
}
