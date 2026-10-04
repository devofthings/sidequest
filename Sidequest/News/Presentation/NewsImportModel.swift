import Foundation
import Observation

@Observable
@MainActor
final class NewsImportModel {
  private(set) var snapshots: [NewsSnapshot] = []
  private(set) var isBusy = false
  private(set) var message: String?
  private var hasLoaded = false
  private let store: (any NewsSnapshotStorage)?
  private let prepareReplacement: @MainActor ([NewsSnapshot]) throws -> (@MainActor () -> Void)
  private let readImport: @Sendable (URL) async throws -> ValidatedNewsImport

  init(
    store: (any NewsSnapshotStorage)? = NewsImportModel.defaultStore(),
    prepareReplacement: @escaping @MainActor ([NewsSnapshot]) throws -> (@MainActor () -> Void) = {
      _ in {}
    },
    readImport: @escaping @Sendable (URL) async throws -> ValidatedNewsImport =
      LocalNewsStore.readImport
  ) {
    self.store = store
    self.prepareReplacement = prepareReplacement
    self.readImport = readImport
  }

  private static func defaultStore() -> LocalNewsStore? {
    #if DEBUG
      if CommandLine.arguments.contains("-sidequest-news-fixtures") {
        return LocalNewsStore(
          directory: FileManager.default.temporaryDirectory.appendingPathComponent(
            "NewsUITests-\(UUID().uuidString)", isDirectory: true))
      }
    #endif
    return try? LocalNewsStore.applicationStore()
  }

  /// Startup owns generation checks; this read never adopts state or claims an operation.
  func loadSavedSnapshots() async throws -> [NewsSnapshot]? {
    guard let store else { throw NewsImportError.unavailableStorage }
    return try await store.load()
  }

  func adoptRestored(_ snapshots: [NewsSnapshot], message: String? = nil) {
    self.snapshots = snapshots
    self.message = message
    hasLoaded = message == nil
  }

  func restore() async {
    guard !hasLoaded, !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      let saved = try await loadSavedSnapshots()
      var restored = saved ?? []
      #if DEBUG
        if saved == nil && CommandLine.arguments.contains("-sidequest-news-fixtures") {
          guard let url = Bundle.main.url(forResource: "sample-news", withExtension: "json") else {
            throw NewsImportError.invalid("Bundled samples are missing. Rebuild the app.")
          }
          restored = try await LocalNewsStore.samples(in: url)
        }
      #endif
      try Task.checkCancellation()
      let commit = try prepareReplacement(restored)
      try Task.checkCancellation()
      adoptRestored(restored)
      commit()
    } catch is CancellationError {
      hasLoaded = false
    } catch {
      hasLoaded = false
      message = "Could not load local news. \(display(error))"
    }
  }

  func importFile(at url: URL) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      guard let store else { throw NewsImportError.unavailableStorage }
      let imported = try await readImport(url)
      try Task.checkCancellation()
      let commit = try prepareReplacement(imported.snapshots)
      try Task.checkCancellation()
      try await store.save(imported.data)
      // Durable success and adoption are one main-actor turn; no cancellation check or await here.
      snapshots = imported.snapshots
      hasLoaded = true
      message = "Imported \(imported.snapshots.count) news snapshots."
      commit()
    } catch is CancellationError {
      message = "Import canceled. Your previous news is unchanged."
    } catch {
      message = "Import failed. Your previous news is unchanged. \(display(error))"
    }
  }

  func showPickerError() {
    message = "Could not select that file. Choose an accessible JSON file in Files."
  }

  private func display(_ error: any Error) -> String {
    if let known = error as? NewsImportError { return known.localizedDescription }
    return "Check file access and try again."
  }
}
