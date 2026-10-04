import SwiftUI

@main
@MainActor
struct SidequestApp: App {
  @State private var startup = FeedStartup()

  var body: some Scene {
    WindowGroup {
      Group {
        switch startup.state {
        case .notStarted, .loading:
          VStack(spacing: 16) {
            Text("Sidequest")
              .font(.largeTitle.bold())
              .accessibilityAddTraits(.isHeader)
              .accessibilityIdentifier("foundation.title")
            ProgressView("Preparing games")
              .accessibilityIdentifier("feed.loading")
          }
          .padding(24)
        case .failed(let message):
          FoundationView(session: .failed(message))
        case .ready(let composition):
          content(composition)
        }
      }
      .task { await startup.prepare() }
      .onDisappear { startup.cancelPreparation() }
    }
  }

  @ViewBuilder
  private func content(_ composition: FeedComposition) -> some View {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-sidequest-news-preview") {
        FoundationView(session: composition.session)
      } else if ProcessInfo.processInfo.arguments.contains("-sidequest-feed-replacement-test") {
        VStack(spacing: 0) {
          feed(composition)
          Button("Replace fixture session") { startup.replaceFixtureSession() }
            .frame(minHeight: 44)
            .accessibilityIdentifier("feed.replaceFixture")
        }
      } else if ProcessInfo.processInfo.arguments.contains("-sidequest-large-text") {
        feed(composition).dynamicTypeSize(.accessibility5)
      } else {
        feed(composition)
      }
    #else
      feed(composition)
    #endif
  }

  @ViewBuilder
  private func feed(_ composition: FeedComposition) -> some View {
    if let controller = composition.controller {
      FeedView(
        controller: controller, gameContent: composition.gameContent,
        newsContent: composition.newsContent)
    } else {
      FoundationView(session: composition.session)
    }
  }
}
