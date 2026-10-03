import SwiftUI

@MainActor
struct FoundationView: View {
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
      }
      .padding(24)
      .frame(maxWidth: .infinity)
    }
  }
}
