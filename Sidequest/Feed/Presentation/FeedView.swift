import SwiftUI

@MainActor
struct FeedView: View {
  let controller: FeedController
  let gameContent: (GameCard, GameRuntime) -> AnyView
  let newsContent: (NewsSnapshot) -> AnyView
  var openNews: (() -> Void)? = nil
  var streak: DailyStreakModel? = nil
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.self) private var environment
  @Environment(\.colorSchemeContrast) private var contrast
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var pageRequest: FeedPageRequest?

  private var theme: SidequestTheme {
    SidequestTheme(scheme: environment.colorScheme, contrast: contrast)
  }

  private var selectedGame: GameCard? {
    guard case .game(let game) = controller.selectedCard else { return nil }
    return game
  }

  private var selectedRuntime: GameRuntime? {
    guard let selectedGame else { return nil }
    return controller.runtimes[selectedGame.id]
  }

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        GameHeading(kind: selectedGame?.kind, difficulty: selectedGame?.difficulty)
        Spacer(minLength: 8)
        if let streak { DailyStreakIndicator(model: streak) }
        autoContinueControl
        Menu {
          if let status = streak?.status { Text(status) }
          Toggle(
            "Auto-continue",
            isOn: Binding(
              get: { controller.autoContinue.enabled },
              set: { controller.autoContinue.setEnabled($0) })
          )
          .accessibilityIdentifier("feed.autoContinueToggle")
          if let openNews {
            Button(action: openNews) {
              Label("News snapshots", systemImage: "newspaper")
            }
            .accessibilityIdentifier("feed.news")
          }
        } label: {
          Label("More options", systemImage: "ellipsis")
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SidequestButtonStyle(compact: true, neutral: true))
        .tint(theme.ink)
        .accessibilityLabel("More options")
        .accessibilityIdentifier("feed.navigation")
      }
      .padding(.horizontal, 16)
      if controller.selectedCard != nil {
        VerticalFeedPager(
          controller: controller, request: pageRequest, reduceMotion: reduceMotion,
          content: { card in
            AnyView(
              cardContent(card)
                .foregroundStyle(theme.ink)
                .background(theme.utilityCanvas)
                .environment(\.dynamicTypeSize, environment.dynamicTypeSize)
                .environment(\.colorScheme, environment.colorScheme)
                .environment(\.sidequestContrast, contrast)
                .environment(\.sidequestReduceMotion, reduceMotion)
                .environment(\.locale, environment.locale)
                .environment(\.layoutDirection, environment.layoutDirection))
          }
        )
        .id(ObjectIdentifier(controller))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card feed")
        .accessibilityAction(named: Text("Previous card")) { requestPage(-1) }
        .accessibilityAction(named: Text("Next card")) { requestPage(1) }
        .overlay {
          SuccessCelebrationView(
            runtime: selectedRuntime, gameTitle: selectedGame?.kind.title ?? "Game"
          )
          .padding(16)
        }
        if let message = controller.replenishmentMessage {
          VStack {
            Text(message)
            Button("Retry games") { controller.retryReplenishment?() }
              .frame(minHeight: 44)
              .accessibilityIdentifier("feed.retryGames")
          }
        }
      } else {
        ContentUnavailableView(
          "No cards yet", systemImage: "rectangle.stack",
          description: Text("News and games will appear here when a session is available.")
        )
        .accessibilityIdentifier("feed.empty")
      }
    }
    .padding(.vertical, 8)
    .foregroundStyle(theme.ink)
    .background(theme.utilityCanvas)
    .onChange(of: ObjectIdentifier(controller), initial: true) { _, _ in
      pageRequest = nil
      #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-sidequest-disable-auto-continue") {
          controller.autoContinue.setEnabled(false)
        }
      #endif
      controller.setSceneActive(scenePhase == .active)
    }
    .onChange(of: controller.autoContinue.advanceRequested) { _, request in
      guard request != nil else { return }
      let origin = controller.autoContinue.origin
      let valid =
        controller.canNavigate && !controller.pagingIsBusy
        && controller.selectedCard?.id == origin?.cardID
        && selectedRuntime?.phase == origin.map { .completed($0.attempt) }
      controller.autoContinue.cancel()
      if valid { requestPage(1) }
    }
    .onChange(of: scenePhase) { _, phase in
      controller.setSceneActive(phase == .active)
    }
    .onDisappear { controller.setSceneActive(false) }
  }

  private var autoContinueControl: some View {
    Group {
      if let remaining = controller.autoContinue.remaining {
        Button {
          controller.autoContinue.setEnabled(false)
        } label: {
          ZStack {
            Circle().stroke(theme.ink.opacity(0.15), lineWidth: 3)
            AutoContinueRing(remaining: remaining, reduceMotion: reduceMotion, ink: theme.ink)
              .id(controller.autoContinue.origin?.attempt.rawValue)
            Text("\(remaining)").font(.system(size: 16, weight: .semibold, design: .rounded))
          }.frame(width: 30, height: 30)
            .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Disable auto-continue")
        .accessibilityValue("\(remaining) seconds remaining")
        .accessibilityIdentifier("feed.autoContinue")
      } else {
        Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
      }
    }
  }

  private func requestPage(_ step: Int) {
    guard controller.canNavigate,
      step > 0 ? controller.canGoForward : controller.canGoBack
    else { return }
    pageRequest = FeedPageRequest(controller: controller, step: step)
  }

  @ViewBuilder
  private func cardContent(_ card: FeedCard) -> some View {
    switch card {
    case .news(let news): newsContent(news.snapshot)
    case .game(let game):
      if let runtime = controller.runtimes[game.id] {
        GameCardLayout(
          showsStart: runtime.activationPolicy == .explicitStart,
          start: StableGameRegion {
            Color.clear.frame(height: 44)
          } content: {
            if runtime.activationPolicy == .explicitStart && runtime.phase == .preview {
              Button("Tap to play", action: runtime.start)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityLabel("Start game")
                .accessibilityIdentifier("game.start")
                .disabled(!runtime.isVisible)
            }
          },
          content: gameContent(game, runtime)
            .disabled(
              !runtime.isVisible
                || (runtime.activationPolicy == .explicitStart && runtime.phase == .preview)
            )
            .overlay {
              if runtime.activationPolicy == .explicitStart && runtime.phase == .preview {
                GamePreviewSurface(runtime: runtime)
              }
            }
        )
      }
    }
  }

}

extension GameKind {
  var title: String {
    switch self {
    case .sudoku: "Sudoku"
    case .memory: "Memory"
    case .chess: "Chess"
    case .bubbleShooter: "Bubble shooter"
    }
  }
}

/// Decorative depletion runs once across the entire countdown, independently of numeric ticks.
private struct AutoContinueRing: View {
  let remaining: Int
  let reduceMotion: Bool
  let ink: Color
  @State private var fraction: CGFloat = 1

  var body: some View {
    Circle().trim(from: 0, to: reduceMotion ? CGFloat(remaining) / 3 : fraction)
      .stroke(ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
      .rotationEffect(.degrees(-90))
      .onAppear {
        withAnimation(reduceMotion ? nil : .linear(duration: 3)) { fraction = 0 }
      }
      .accessibilityHidden(true)
  }
}
