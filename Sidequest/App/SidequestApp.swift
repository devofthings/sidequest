import SwiftUI

@main
@MainActor
struct SidequestApp: App {
  @State private var composition = FeedComposition()

  var body: some Scene {
    WindowGroup {
      #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-sidequest-news-preview") {
          FoundationView(session: composition.session)
        } else if ProcessInfo.processInfo.arguments.contains("-sidequest-feed-replacement-test") {
          VStack(spacing: 0) {
            feed
            Button("Replace fixture session") {
              composition.controller?.retire()
              composition = FeedComposition()
            }
            .frame(minHeight: 44)
            .accessibilityIdentifier("feed.replaceFixture")
          }
        } else if ProcessInfo.processInfo.arguments.contains("-sidequest-large-text") {
          feed.dynamicTypeSize(.accessibility5)
        } else {
          feed
        }
      #else
        feed
      #endif
    }
  }

  @ViewBuilder
  private var feed: some View {
    if let controller = composition.controller {
      FeedView(
        controller: controller, gameContent: composition.gameContent,
        newsContent: composition.newsContent)
    } else {
      FoundationView(session: composition.session)
    }
  }
}
