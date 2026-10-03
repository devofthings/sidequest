import SwiftUI

@MainActor
struct FeedView: View {
  let controller: FeedController
  let gameContent: (GameCard, GameRuntime) -> AnyView
  let newsContent: (NewsSnapshot) -> AnyView
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.self) private var environment
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var pageRequest: FeedPageRequest?

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("Sidequest")
          .font(.title2.bold())
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("foundation.title")
        Spacer(minLength: 8)
        Menu {
          Button("Previous card") { requestPage(-1) }
            .disabled(!controller.canGoBack || !controller.canNavigate)
            .accessibilityIdentifier("feed.previous")
          Button("Next card") { requestPage(1) }
            .disabled(!controller.canGoForward || !controller.canNavigate)
            .accessibilityIdentifier("feed.next")
        } label: {
          Label("Feed navigation", systemImage: "ellipsis.circle")
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Feed navigation")
        .accessibilityIdentifier("feed.navigation")
      }
      .padding(.horizontal, 16)
      if controller.selectedCard != nil {
        VerticalFeedPager(
          controller: controller, request: pageRequest, reduceMotion: reduceMotion,
          content: { card in
            AnyView(
              cardContent(card)
                .environment(\.dynamicTypeSize, environment.dynamicTypeSize)
                .environment(\.colorScheme, environment.colorScheme)
                .environment(\.locale, environment.locale)
                .environment(\.layoutDirection, environment.layoutDirection))
          }
        )
        .id(ObjectIdentifier(controller))
        Text(
          controller.canGoForward
            ? "Card \(controller.position ?? 0) of \(controller.count)"
            : "End of feed • Card \(controller.position ?? 0) of \(controller.count)"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("feed.position")
        .padding(.horizontal, 16)
      } else {
        ContentUnavailableView(
          "No cards yet", systemImage: "rectangle.stack",
          description: Text("News and games will appear here when a session is available.")
        )
        .accessibilityIdentifier("feed.empty")
      }
    }
    .padding(.vertical, 8)
    .onChange(of: scenePhase, initial: true) { _, phase in
      controller.setSceneActive(phase == .active)
    }
    .onDisappear { controller.setSceneActive(false) }
  }

  private func requestPage(_ step: Int) {
    guard controller.canNavigate,
      step > 0 ? controller.canGoForward : controller.canGoBack
    else { return }
    pageRequest = FeedPageRequest(step: step)
  }

  @ViewBuilder
  private func cardContent(_ card: FeedCard) -> some View {
    switch card {
    case .news(let news): newsContent(news)
    case .game(let game):
      if let runtime = controller.runtimes[game.id] {
        VStack(spacing: 20) {
          Text(game.kind.title)
            .font(.title.bold())
            .accessibilityAddTraits(.isHeader)
          switch runtime.phase {
          case .preview:
            Button("Tap to play", action: runtime.start)
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .accessibilityHint("Starts this game without making a move.")
              .accessibilityIdentifier("game.start")
              .disabled(!runtime.isVisible)
            Text("A quick game, whenever you’re ready.")
              .foregroundStyle(.secondary)
          case .playing, .completed:
            gameContent(game, runtime)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
      }
    }
  }
}

extension GameKind {
  var title: String {
    switch self {
    case .sudoku: "Sudoku"
    case .memory: "Memory"
    case .chess: "Chess puzzle"
    case .bubbleShooter: "Bubble shooter"
    }
  }
}
