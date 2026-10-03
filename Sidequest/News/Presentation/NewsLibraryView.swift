import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct NewsLibraryView: View {
  @State private var model = NewsImportModel()
  @State private var showsImporter = false
  @State private var importTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 12) {
      Button("Import news JSON") { showsImporter = true }
        .buttonStyle(.borderedProminent)
        .disabled(model.isBusy)
        .accessibilityIdentifier("news.import")
      if model.isBusy { ProgressView("Loading news") }
      if let message = model.message {
        Text(message)
          .font(.footnote)
          .accessibilityIdentifier("news.message")
          .padding(.horizontal)
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
    .task { await model.restore() }
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
