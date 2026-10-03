import SwiftUI

@MainActor
struct FeedView: View {
  let controller: FeedController
  let gameContent: (GameCard, GameRuntime) -> AnyView
  let newsContent: (NewsSnapshot) -> AnyView
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(spacing: 16) {
      Text("Sidequest")
        .font(.largeTitle.bold())
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("foundation.title")
      if let card = controller.selectedCard {
        HStack(spacing: 12) {
          cardContent(card)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(card.id)
          navigationRail
        }
        Group {
          if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
              previousButton
              nextButton
            }
          } else {
            HStack {
              previousButton
              Spacer(minLength: 8)
              nextButton
            }
          }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        Text(
          controller.canGoForward
            ? "Card \(controller.position ?? 0) of \(controller.count)"
            : "End of feed • Card \(controller.position ?? 0) of \(controller.count)"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("feed.position")
      } else {
        ContentUnavailableView(
          "No cards yet", systemImage: "rectangle.stack",
          description: Text("News and games will appear here when a session is available.")
        )
        .accessibilityIdentifier("feed.empty")
      }
    }
    .padding()
    .onChange(of: scenePhase, initial: true) { _, phase in
      controller.setSceneActive(phase == .active)
    }
    .onDisappear { controller.setSceneActive(false) }
  }

  @ViewBuilder
  private func cardContent(_ card: FeedCard) -> some View {
    switch card {
    case .news(let news): newsContent(news)
    case .game(let game):
      if let runtime = controller.runtimes[game.id] {
        ScrollView {
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
          .padding(.vertical)
        }
      }
    }
  }

  private var navigationRail: some View {
    VStack(spacing: 12) {
      Image(systemName: "chevron.up").font(.system(size: 20))
      if !dynamicTypeSize.isAccessibilitySize { Text("Swipe").font(.caption) }
      Image(systemName: "chevron.down").font(.system(size: 20))
    }
    .frame(width: 56)
    .frame(maxHeight: .infinity)
    .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 24).onEnded { value in
        guard abs(value.translation.height) > 50,
          abs(value.translation.height) > abs(value.translation.width) * 1.3
        else { return }
        if value.translation.height < 0 { controller.next() } else { controller.previous() }
      }
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Swipe feed navigation")
    .accessibilityHint(
      "Swipe up for the next card, or down for the previous card. You can also use the navigation buttons."
    )
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: controller.next()
      case .decrement: controller.previous()
      @unknown default: break
      }
    }
    .accessibilityIdentifier("feed.navigationRail")
  }

  private var previousButton: some View {
    Button("Previous", action: controller.previous)
      .disabled(!controller.canGoBack)
      .accessibilityIdentifier("feed.previous")
  }

  private var nextButton: some View {
    Button("Next", action: controller.next)
      .disabled(!controller.canGoForward)
      .accessibilityIdentifier("feed.next")
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
