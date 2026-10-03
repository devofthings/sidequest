import SwiftUI

@MainActor
struct FoundationView: View {
  let session: SampleSession

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text("Sidequest")
          .font(.largeTitle.bold())
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("foundation.title")

        Text("A little news. A little play.")
          .font(.title3)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        switch session {
        case .loaded(let cards):
          Text("Fictional sample session: \(cards.count) cards")
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .failed(let message):
          Text("Sample session unavailable: \(message)")
            .accessibilityIdentifier("foundation.error")
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity)
    }
  }
}
