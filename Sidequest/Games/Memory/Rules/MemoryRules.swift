enum MemorySymbol: String, CaseIterable, Sendable {
  case star, heart, moon, sun, leaf, bolt
}

enum MemoryBoardError: Error, Equatable {
  case invalidPairs, invalidRestoration
}

enum MemoryTurn: Equatable, Sendable {
  case choosing(first: Int?)
  case mismatch(first: Int, second: Int)
  case completed
}

enum MemoryFlip: Equatable, Sendable {
  case ignored, revealed, matched, mismatch, completed
}

/// Matching rules know neither lifecycle, time, nor presentation.
struct MemoryRules: Equatable, Sendable {
  let symbols: [MemorySymbol]
  private(set) var matchedIndices = Set<Int>()
  private(set) var turn: MemoryTurn = .choosing(first: nil)

  init<R: RandomNumberGenerator>(using random: inout R, difficulty: GameDifficulty = .hard) {
    let selected: [MemorySymbol]
    switch difficulty {
    case .easy: selected = Array(MemorySymbol.allCases.shuffled(using: &random).prefix(3))
    case .medium: selected = Array(MemorySymbol.allCases.shuffled(using: &random).prefix(4))
    case .hard: selected = MemorySymbol.allCases
    }
    symbols = (selected + selected).shuffled(using: &random)
  }

  init(symbols: [MemorySymbol]) throws {
    let distinct = Set(symbols)
    guard [3, 4, 6].contains(distinct.count), symbols.count == distinct.count * 2,
      distinct.allSatisfy({ symbol in symbols.filter { $0 == symbol }.count == 2 })
    else { throw MemoryBoardError.invalidPairs }
    self.symbols = symbols
  }

  var pairCount: Int { symbols.count / 2 }

  /// Workload classification follows the validated pair count, not a human difficulty rating.
  var difficulty: GameDifficulty {
    switch pairCount {
    case 3: return .easy
    case 4: return .medium
    default: return .hard  // Both constructors guarantee only three, four, or six pairs.
    }
  }

  var matchedPairCount: Int { matchedIndices.count / 2 }
  var isCompleted: Bool { turn == .completed }
  var isResolvingMismatch: Bool {
    if case .mismatch = turn { return true }
    return false
  }

  func isRevealed(_ index: Int) -> Bool {
    guard symbols.indices.contains(index) else { return false }
    if matchedIndices.contains(index) { return true }
    switch turn {
    case .choosing(let first): return first == index
    case .mismatch(let first, let second): return first == index || second == index
    case .completed: return true
    }
  }

  mutating func flip(_ index: Int) -> MemoryFlip {
    guard symbols.indices.contains(index), !matchedIndices.contains(index),
      case .choosing(let first) = turn, first != index
    else { return .ignored }
    guard let first else {
      turn = .choosing(first: index)
      return .revealed
    }
    if symbols[first] != symbols[index] {
      turn = .mismatch(first: first, second: index)
      return .mismatch
    }
    matchedIndices.formUnion([first, index])
    if matchedIndices.count == symbols.count {
      turn = .completed
      return .completed
    }
    turn = .choosing(first: nil)
    return .matched
  }

  mutating func concealMismatch() {
    guard case .mismatch = turn else { return }
    turn = .choosing(first: nil)
  }
}
