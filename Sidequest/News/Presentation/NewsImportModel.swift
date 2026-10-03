import Foundation
import Observation

@Observable
@MainActor
final class NewsImportModel {
  private(set) var snapshots: [NewsSnapshot] = []
  private(set) var isBusy = false
  private(set) var message: String?
  private var hasLoaded = false
  private let store: LocalNewsStore?

  init(store: LocalNewsStore? = NewsImportModel.defaultStore()) {
    self.store = store
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

  func restore() async {
    guard !hasLoaded, !isBusy else { return }
    hasLoaded = true
    isBusy = true
    defer { isBusy = false }
    do {
      guard let store else { throw NewsImportError.unavailableStorage }
      if let saved = try await store.load() {
        snapshots = saved
      } else {
        guard let url = Bundle.main.url(forResource: "sample-news", withExtension: "json") else {
          throw NewsImportError.invalid("Bundled samples are missing. Rebuild the app.")
        }
        snapshots = try await LocalNewsStore.samples(in: url)
      }
      message = nil
    } catch is CancellationError {
      hasLoaded = false
    } catch {
      message = "Could not load local news. \(display(error))"
    }
  }

  func importFile(at url: URL) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      guard let store else { throw NewsImportError.unavailableStorage }
      let imported = try await LocalNewsStore.readImport(at: url)
      try Task.checkCancellation()
      try await store.save(imported.data)
      snapshots = imported.snapshots
      hasLoaded = true
      message = "Imported \(imported.snapshots.count) news snapshots."
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
