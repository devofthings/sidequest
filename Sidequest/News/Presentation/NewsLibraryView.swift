import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct NewsLibraryView: View {
  @State private var model: NewsImportModel
  let automaticallyRestores: Bool

  init(model: NewsImportModel = NewsImportModel(), automaticallyRestores: Bool = true) {
    _model = State(initialValue: model)
    self.automaticallyRestores = automaticallyRestores
  }
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var contrast

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrast)
  }

  @State private var showsImporter = false
  @State private var importTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 12) {
      Button("Import news JSON") { showsImporter = true }
        .buttonStyle(SidequestButtonStyle(neutral: true))
        .frame(minHeight: 44)
        .disabled(model.isBusy)
        .accessibilityIdentifier("news.import")
      if model.isBusy { ProgressView("Loading news") }
      if let message = model.message {
        Text(message)
          .font(.footnote)
          .accessibilityIdentifier("news.message")
          .padding(.horizontal)
        if model.canRetryRestore {
          Button("Retry loading saved news") {
            importTask?.cancel()
            importTask = Task { await model.restore() }
          }
          .frame(minHeight: 44)
          .accessibilityIdentifier("news.retry")
        }
      }
      if !model.isBusy && model.snapshots.isEmpty {
        ContentUnavailableView(
          "No news snapshots", systemImage: "newspaper",
          description: Text("Import a JSON file to add news."))
      } else {
        TabView {
          ForEach(model.snapshots, id: \.id) { snapshot in
            NewsCardView(snapshot: snapshot)
          }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
      }
    }
    .padding(.top, 12)
    .foregroundStyle(theme.ink)
    .tint(theme.ink)
    .background(theme.utilityCanvas)
    .task { if automaticallyRestores { await model.restore() } }
    .fileImporter(isPresented: $showsImporter, allowedContentTypes: [.json]) { result in
      switch result {
      case .success(let url):
        importTask?.cancel()
        importTask = Task { await model.importFile(at: url) }
      case .failure:
        model.showPickerError()
      }
    }
    .onDisappear { importTask?.cancel() }
  }
}
