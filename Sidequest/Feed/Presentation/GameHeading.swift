import SwiftUI

/// Maximum text footprints are measured independently of the current challenge and attempt.
@MainActor
struct GameHeading: View {
  let kind: GameKind?
  let difficulty: GameDifficulty?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ZStack(alignment: .topLeading) {
        ForEach(["Sidequest"] + GameKind.allCases.map(\.title), id: \.self) { value in
          title(value).hidden().accessibilityHidden(true)
        }
        title(kind?.title ?? "Sidequest")
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("foundation.title")
      }
      ZStack(alignment: .topLeading) {
        ForEach([GameDifficulty.easy, .medium, .hard], id: \.self) { tier in
          subtitle(tier).hidden().accessibilityHidden(true)
        }
        if let difficulty {
          subtitle(difficulty)
            .accessibilityIdentifier("game.difficulty")
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func title(_ text: String) -> some View {
    Text(text).font(.system(.title2, design: .rounded, weight: .heavy))
      .fixedSize(horizontal: false, vertical: true)
  }

  private func subtitle(_ tier: GameDifficulty) -> some View {
    Text("Difficulty: \(tier.displayName)")
      .font(.system(.subheadline, design: .rounded, weight: .semibold))
      .fixedSize(horizontal: false, vertical: true)
  }
}

extension GameDifficulty {
  var displayName: String {
    switch self {
    case .easy: "Easy"
    case .medium: "Medium"
    case .hard: "Hard"
    }
  }
}
