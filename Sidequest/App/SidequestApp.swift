import SwiftUI

@main
@MainActor
struct SidequestApp: App {
  @State private var session: FeedSessionState
  @State private var startupRetry = 0
  @State private var introduction = StartupIntroduction()
  #if DEBUG
    @State private var fixturesPrepared = false
  #endif
  @State private var newsModel: NewsImportModel

  init() {
    let session = FeedSessionState(
      prepareBatch: { id, sequence, seed, puzzles, ordered in
        let mixed: Bool
        #if DEBUG
          mixed = !FeedSessionState.usesHistoricalGeneration
        #else
          mixed = true
        #endif
        return try await GameGenerationComposition.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles,
          ordered: ordered, mixedDifficulties: mixed)
      },
      loadChess: {
        #if DEBUG
          if CommandLine.arguments.contains("-sidequest-chess-catalog") {
            return try await ChessPuzzleLoader.bundledCatalog()
          }
          if FeedSessionState.usesHistoricalGeneration {
            return try await ChessPuzzleLoader.bundled()
          }
        #endif
        let historical = try await ChessPuzzleLoader.bundled()
        let catalog = try await ChessPuzzleLoader.bundledCatalog()
        return historical + catalog
      })
    _session = State(initialValue: session)
    #if DEBUG
      let store = IntegrationFixtures.newsStore()
    #else
      let store = try? LocalNewsStore.applicationStore()
    #endif
    _newsModel = State(
      initialValue: NewsImportModel(
        store: store, usesDemoWhenMissing: Self.usesDemoNews,
        beginReplacement: session.beginReplacement))
  }

  private static var usesDemoNews: Bool {
    #if DEBUG
      if FeedSessionState.usesLegacyHarness { return false }
      if CommandLine.arguments.contains("-sidequest-integration-fixtures"),
        !CommandLine.arguments.contains("-sidequest-endless-fixtures")
      {
        return false
      }
    #endif
    return true
  }

  var body: some Scene {
    WindowGroup {
      StartupIntroductionView(introduction: introduction, content: startupContent)
        .task(id: startupRetry) {
          #if DEBUG
            if !fixturesPrepared {
              do {
                try await IntegrationFixtures.prepare()
                try Task.checkCancellation()
                fixturesPrepared = true
              } catch is CancellationError {
                return
              } catch {
                guard !Task.isCancelled else { return }
                session.fixturePreparationFailed()
                return
              }
            }
          #endif
          await session.prepare(newsModel: newsModel)
        }
        .onDisappear { session.cancelPreparation() }
        .sheet(
          isPresented: Binding(
            get: { session.libraryIsPresented },
            set: { session.setLibraryPresented($0) })
        ) {
          NavigationStack {
            NewsLibraryView(model: newsModel, automaticallyRestores: false)
              .navigationTitle("News snapshots")
              .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                  Button("Done") { session.setLibraryPresented(false) }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("news.done")
                }
              }
          }
        }
    }
  }

  private var startupContent: some View {
    Group {
      switch session.state {
      case .notStarted, .loading:
        VStack(spacing: 16) {
          Text("Sidequest")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("foundation.title")
          ProgressView("Preparing news and games")
            .accessibilityIdentifier("feed.loading")
        }
        .padding(24)
      case .failed(let message):
        VStack(spacing: 16) {
          Text("Sidequest").font(.system(.largeTitle, design: .rounded, weight: .bold))
            .accessibilityIdentifier("foundation.title")
          Text(message).accessibilityIdentifier("foundation.error")
          Button("Retry") {
            session.retryPreparation()
            startupRetry += 1
          }
          .buttonStyle(SidequestButtonStyle(prominent: true))
        }.padding(24)
      case .ready(let composition):
        content(composition)
      }
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
          Button("Replace fixture session") { session.replaceFixtureSession() }
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
      VStack(spacing: 4) {
        FeedView(
          controller: controller, gameContent: composition.gameContent,
          newsContent: composition.newsContent, openNews: { session.setLibraryPresented(true) })
        if let message = newsModel.message {
          Text(message).font(.footnote)
            .accessibilityIdentifier("news.status")
            .padding(.horizontal, 16)
        }
      }
    } else {
      #if DEBUG
        FoundationView(session: composition.session)
      #else
        Text("Could not prepare the feed.")
      #endif
    }
  }
}
