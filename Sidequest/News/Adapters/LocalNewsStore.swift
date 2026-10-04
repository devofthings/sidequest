import Foundation

struct ValidatedNewsImport: Sendable {
  let data: Data
  let snapshots: [NewsSnapshot]
}

struct LocalNewsStore: NewsSnapshotStorage {
  let directory: URL
  var fileURL: URL { directory.appendingPathComponent("snapshots.json") }

  static func applicationStore() throws -> Self {
    guard
      let directory = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      ).first
    else { throw NewsImportError.unavailableStorage }
    return Self(directory: directory.appendingPathComponent("SidequestNews", isDirectory: true))
  }

  /// Explicitly leaves the caller's actor for bounded file I/O and decoding.
  @concurrent static func readImport(at url: URL) async throws -> ValidatedNewsImport {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    try Task.checkCancellation()
    if let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
      bytes > NewsSnapshotImporter.maximumBytes
    {
      throw NewsImportError.oversized
    }
    let data = try Data(contentsOf: url)
    try Task.checkCancellation()
    return ValidatedNewsImport(data: data, snapshots: try NewsSnapshotImporter.decode(data))
  }

  @concurrent func load() async throws -> [NewsSnapshot]? {
    try Task.checkCancellation()
    // Inspect each component: fileExists conflates absence, invalid paths and access errors.
    // A dangling symlink exists and must fail loading rather than activate demo fallback.
    var componentURL = URL(fileURLWithPath: "/")
    for component in fileURL.pathComponents.dropFirst() {
      componentURL.appendPathComponent(component)
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath: componentURL.path)
        let type = attributes[.type] as? FileAttributeType
        if type == .typeSymbolicLink {
          // A Boolean failure here is an error, never proof of ordinary absence.
          guard FileManager.default.fileExists(atPath: componentURL.path) else {
            throw NewsImportError.unavailableStorage
          }
        } else if componentURL != fileURL, type != .typeDirectory {
          throw NewsImportError.unavailableStorage
        }
      } catch let error as NSError {
        if error.domain == NSCocoaErrorDomain,
          [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(error.code)
        {
          // A missing ordinary component is confirmed absence. Existing symlinks are errors.
          if (try? FileManager.default.destinationOfSymbolicLink(atPath: componentURL.path)) != nil
          {
            throw error
          }
          return nil
        }
        throw error
      }
    }
    let imported = try await Self.readImport(at: fileURL)
    return imported.snapshots
  }

  @concurrent func save(_ data: Data) async throws {
    _ = try NewsSnapshotImporter.decode(data)
    try Task.checkCancellation()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    // The caller must synchronously publish after success, even if cancellation arrives now.
    try data.write(to: fileURL, options: .atomic)
  }

  @concurrent static func samples(in bundleURL: URL) async throws -> [NewsSnapshot] {
    let imported = try await readImport(at: bundleURL)
    return imported.snapshots
  }
}
