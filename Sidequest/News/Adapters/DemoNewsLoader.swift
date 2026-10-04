import Foundation

/// Original bundled content, separate from the legacy two-story sample fixture.
enum DemoNewsLoader {
  @concurrent static func bundled() async throws -> [NewsSnapshot] {
    guard let url = Bundle.main.url(forResource: "demo-news", withExtension: "json") else {
      throw NewsImportError.invalid("Bundled demo stories are missing. Rebuild the app.")
    }
    let snapshots = try await LocalNewsStore.samples(in: url)
    guard snapshots.count == 30,
      snapshots.allSatisfy({
        $0.isSample && $0.sourceURL.host == "example.com" && $0.publishedAt == nil
      })
    else { throw NewsImportError.invalid("Bundled demo stories have invalid provenance.") }
    return snapshots
  }
}
