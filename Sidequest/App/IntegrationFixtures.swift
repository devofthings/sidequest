#if DEBUG
  import Foundation

  /// Original fictional files exercise the native picker; Release has no fixture/reset path.
  enum IntegrationFixtures {
    static func newsStore() -> LocalNewsStore? {
      guard CommandLine.arguments.contains("-sidequest-integration-fixtures") else {
        return try? LocalNewsStore.applicationStore()
      }
      guard
        let support = FileManager.default.urls(
          for: .applicationSupportDirectory, in: .userDomainMask
        ).first
      else { return nil }
      return LocalNewsStore(directory: support.appendingPathComponent("IntegrationNewsTests"))
    }

    @concurrent static func prepare() async throws {
      guard CommandLine.arguments.contains("-sidequest-integration-fixtures"),
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          .first,
        let store = newsStore()
      else { return }
      try Task.checkCancellation()
      if CommandLine.arguments.contains("-sidequest-integration-reset"),
        FileManager.default.fileExists(atPath: store.directory.path)
      {
        try FileManager.default.removeItem(at: store.directory)
      }
      let folder = documents.appendingPathComponent("Sidequest Fixtures", isDirectory: true)
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      let valid = """
        {"schemaVersion":1,"snapshots":[{"id":"imported-news-one","headline":"Imported fixture story","excerpt":"A fictional story for offline import and overflow checks. ","publisher":"Sidequest fixture","sourceURL":"https://example.com/news","capturedAt":"2026-10-04T00:00:00.123456Z","isSample":true}]}
        """
      // Overflow is intentional and original, so the real card owns scroll arbitration.
      let overflowing = valid.replacingOccurrences(
        of: "A fictional story for offline import and overflow checks. ",
        with: String(
          repeating: "A fictional story for offline import and overflow checks. ", count: 12))
      let files = [
        "Valid News.json": overflowing,
        "Empty News.json": "{\"schemaVersion\":1,\"snapshots\":[]}",
        "Malformed News.json": "{\"schemaVersion\":1,\"snapshots\":[{\"id\":\"broken\"}]}",
        "Reserved News.json": valid.replacingOccurrences(
          of: "imported-news-one", with: "sample-game-memory"),
      ]
      for (name, content) in files {
        try Task.checkCancellation()
        try Data(content.utf8).write(to: folder.appendingPathComponent(name), options: .atomic)
      }
    }
  }
#endif
