/// Ephemeral presentation values; completed game archives never retain celebrations.
enum SuccessCelebrationStyle: Int, CaseIterable, Sendable {
  case pop, confetti, orbit, rays

  var message: String {
    switch self {
    case .pop: "Nice!"
    case .confetti: "Brilliant!"
    case .orbit: "Nailed it!"
    case .rays: "Well played!"
    }
  }
}

/// Composition owns one cycle per feed session, independent of game kind or adapter eviction.
struct SuccessCelebrationSequence {
  private var nextStyle: SuccessCelebrationStyle

  init(startingWith style: SuccessCelebrationStyle) { nextStyle = style }

  mutating func next() -> SuccessCelebrationStyle {
    let selected = nextStyle
    let following = (selected.rawValue + 1) % SuccessCelebrationStyle.allCases.count
    nextStyle = SuccessCelebrationStyle(rawValue: following) ?? .pop
    return selected
  }
}
