/// Frozen generation inputs and original layout travel together for one card.
struct MemoryChallenge: Equatable, Sendable {
  let seed: UInt64
  let difficulty: GameDifficulty
  let rules: MemoryRules

  var pairCount: Int { rules.pairCount }

  init(difficulty: GameDifficulty, seed: UInt64) {
    self.seed = seed
    self.difficulty = difficulty
    var random = ChallengeRandom(seed: seed)
    rules = MemoryRules(using: &random, difficulty: difficulty)
  }
}
