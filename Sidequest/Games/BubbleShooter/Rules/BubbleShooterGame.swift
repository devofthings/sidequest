import Foundation

enum BubbleColor: CaseIterable, Equatable, Sendable {
  case red, blue, green
}

enum BubbleLoss: Equatable, Sendable {
  case shotLimit, dangerRow, blockedAttachment
}

enum BubbleOutcome: Equatable, Sendable {
  case playing, won
  case lost(BubbleLoss)
}

enum BubbleShotError: Error, Equatable {
  case invalidAngle, invalidTrajectory, invalidBoard, invalidConfiguration, noActiveChallenge,
    staleShot
}

struct BubbleShot: Equatable, Sendable {
  let color: BubbleColor
  let trajectory: BubbleTrajectory
  let attachment: BubbleSlot?
  fileprivate let revision: Int
}

struct BubbleShotResult: Equatable, Sendable {
  let matched: Set<BubbleSlot>
  let detached: Set<BubbleSlot>
  let outcome: BubbleOutcome
}

struct BubbleShooterGame: Equatable, Sendable {
  private(set) var board: [BubbleSlot: BubbleColor]
  private(set) var shotsFired = 0
  private(set) var outcome: BubbleOutcome = .playing
  private var revision = 0
  private let colors: [BubbleColor]
  private let initialBoard: [BubbleSlot: BubbleColor]
  static let shotLimit = 8
  let maximumShots: Int
  let difficulty: GameDifficulty?

  static func maximumShots(for difficulty: GameDifficulty) -> Int {
    switch difficulty {
    case .easy: return 8
    case .medium: return 5
    case .hard: return 3
    }
  }

  var nextColor: BubbleColor { colors[shotsFired % colors.count] }

  init() {
    maximumShots = Self.shotLimit
    difficulty = nil
    board = Self.challenge
    initialBoard = Self.challenge
    colors = [.red, .blue, .green]
  }

  /// Deterministic injected boards support rules verification without UI or random state.
  init(
    board: [BubbleSlot: BubbleColor], shotColors: [BubbleColor],
    maximumShots: Int = Self.shotLimit, difficulty: GameDifficulty? = nil
  ) throws {
    guard (1...Self.shotLimit).contains(maximumShots),
      difficulty.map({ Self.maximumShots(for: $0) == maximumShots }) ?? true
    else { throw BubbleShotError.invalidConfiguration }
    self.maximumShots = maximumShots
    self.difficulty = difficulty
    guard !shotColors.isEmpty, board.keys.allSatisfy(BubbleGeometry.slots.contains) else {
      throw BubbleShotError.invalidBoard
    }
    self.board = board
    initialBoard = board
    colors = shotColors
    if board.isEmpty { outcome = .won }
  }

  /// Configuration starts from the same frozen initial board and complete legacy queue.
  func configured(for difficulty: GameDifficulty) throws -> Self {
    try Self(
      board: initialBoard, shotColors: colors,
      maximumShots: Self.maximumShots(for: difficulty), difficulty: difficulty)
  }

  /// Completion archives must describe the same frozen board, queue, and attempt budget.
  func hasSameChallenge(as other: Self) -> Bool {
    initialBoard == other.initialBoard && colors == other.colors
      && maximumShots == other.maximumShots && difficulty == other.difficulty
  }

  static let challenge: [BubbleSlot: BubbleColor] = [
    BubbleSlot(row: 0, column: 0): .red, BubbleSlot(row: 0, column: 1): .red,
    BubbleSlot(row: 0, column: 2): .blue, BubbleSlot(row: 0, column: 3): .blue,
    BubbleSlot(row: 0, column: 4): .green,
    BubbleSlot(row: 1, column: 0): .red, BubbleSlot(row: 1, column: 1): .red,
    BubbleSlot(row: 1, column: 2): .blue, BubbleSlot(row: 1, column: 3): .green,
  ]

  func traceShot(angleRadians: Double) throws -> BubbleShot {
    guard outcome == .playing else { throw BubbleShotError.noActiveChallenge }
    let trajectory = try BubbleGeometry.trace(angleRadians: angleRadians, occupied: board)
    return BubbleShot(
      color: nextColor, trajectory: trajectory,
      attachment: BubbleGeometry.attachment(for: trajectory, occupied: board), revision: revision)
  }

  mutating func commitShot(_ shot: BubbleShot) throws -> BubbleShotResult {
    guard outcome == .playing else { throw BubbleShotError.noActiveChallenge }
    guard shot.revision == revision, shot.color == nextColor else {
      throw BubbleShotError.staleShot
    }
    if let slot = shot.attachment {
      guard BubbleGeometry.slots.contains(slot), board[slot] == nil else {
        throw BubbleShotError.staleShot
      }
    }
    revision += 1
    shotsFired += 1
    guard let slot = shot.attachment else {
      outcome = .lost(.blockedAttachment)
      return BubbleShotResult(matched: [], detached: [], outcome: outcome)
    }
    board[slot] = shot.color
    var matched = connectedColor(from: slot)
    var detached: Set<BubbleSlot> = []
    if matched.count >= 3 {
      for slot in matched { board.removeValue(forKey: slot) }
      detached = Set(board.keys).subtracting(ceilingConnected())
      for slot in detached { board.removeValue(forKey: slot) }
    } else {
      matched = []
    }
    if board.isEmpty {
      outcome = .won
    } else if board.keys.contains(where: { $0.row == BubbleGeometry.rows - 1 }) {
      outcome = .lost(.dangerRow)
    } else if shotsFired >= maximumShots {
      outcome = .lost(.shotLimit)
    }
    return BubbleShotResult(matched: matched, detached: detached, outcome: outcome)
  }

  mutating func fire(angleRadians: Double) throws -> BubbleShotResult {
    try commitShot(traceShot(angleRadians: angleRadians))
  }

  mutating func reset() {
    board = initialBoard
    shotsFired = 0
    outcome = board.isEmpty ? .won : .playing
    revision += 1
  }

  func connectedColor(from start: BubbleSlot) -> Set<BubbleSlot> {
    guard let color = board[start] else { return [] }
    return connected(starting: [start]) { board[$0] == color }
  }

  private func ceilingConnected() -> Set<BubbleSlot> {
    connected(starting: board.keys.filter { $0.row == 0 }) { board[$0] != nil }
  }

  private func connected(
    starting: [BubbleSlot], includes: (BubbleSlot) -> Bool
  ) -> Set<BubbleSlot> {
    var visited = Set(starting)
    var pending = starting
    while let slot = pending.popLast() {
      for neighbor in BubbleGeometry.neighbors(of: slot)
      where !visited.contains(neighbor) && includes(neighbor) {
        visited.insert(neighbor)
        pending.append(neighbor)
      }
    }
    return visited
  }
}
