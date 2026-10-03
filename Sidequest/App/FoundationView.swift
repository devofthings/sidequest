import SwiftUI

@MainActor
struct FoundationView: View {
  @State private var showsNews = false
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
        Button("Read news") { showsNews = true }
          .buttonStyle(.bordered)
          .accessibilityIdentifier("foundation.news")

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
    .sheet(isPresented: $showsNews) {
      NavigationStack {
        NewsLibraryView()
          .navigationTitle("News snapshots")
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button("Done") { showsNews = false }
            }
          }
      }
    }
  }
}
