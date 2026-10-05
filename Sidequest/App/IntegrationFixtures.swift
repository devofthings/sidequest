#if DEBUG
  import Foundation

  /// Original fictional files exercise the native picker; Release has no fixture/reset path.
  enum IntegrationFixtures {
    static func newsStore() -> LocalNewsStore? {
      guard
        CommandLine.arguments.contains("-sidequest-integration-fixtures")
          || CommandLine.arguments.contains("-sidequest-mixed-difficulties-test")
      else {
        return try? LocalNewsStore.applicationStore()
      }
      guard
        let support = FileManager.default.urls(
          for: .applicationSupportDirectory, in: .userDomainMask
        ).first
      else { return nil }
      let folder: String
      if CommandLine.arguments.contains("-sidequest-mixed-difficulties-test") {
        folder = "MixedDifficultyNewsTests"
      } else {
        folder =
          CommandLine.arguments.contains("-sidequest-endless-fixtures")
          ? "EndlessNewsTests" : "IntegrationNewsTests"
      }
      return LocalNewsStore(directory: support.appendingPathComponent(folder))
    }

    @concurrent static func prepare() async throws {
      if CommandLine.arguments.contains("-sidequest-mixed-difficulties-test") {
        guard let store = newsStore() else { throw NewsImportError.unavailableStorage }
        try Task.checkCancellation()
        if FileManager.default.fileExists(atPath: store.directory.path) {
          try FileManager.default.removeItem(at: store.directory)
        }
        return
      }
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
      let folder = documents.appendingPathComponent("Sidequest Fixtures v2", isDirectory: true)
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
      var selectedFiles = files
      if CommandLine.arguments.contains("-sidequest-endless-fixtures") {
        selectedFiles["Collision News.json"] = valid.replacingOccurrences(
          of: "imported-news-one",
          with: "game-00000000-0000-0000-0000-000000000104-0")
      }
      for (name, content) in selectedFiles {
        try Task.checkCancellation()
        let data = Data(content.utf8)
        let file = folder.appendingPathComponent(name)
        // Preserve File Provider item identity across test launches and app installations.
        if (try? Data(contentsOf: file)) == data { continue }
        try data.write(to: file, options: .atomic)
      }
    }
  }
#endif
