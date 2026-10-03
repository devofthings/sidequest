import Foundation

struct NewsSnapshotDocument: Codable, Sendable {
  let schemaVersion: Int
  let snapshots: [NewsSnapshot]
}

enum NewsImportError: Error, LocalizedError, Equatable {
  case unsupportedSchema(Int)
  case invalid(String)
  case oversized
  case unavailableStorage

  var errorDescription: String? {
    switch self {
    case .unsupportedSchema(let version): "Unsupported schemaVersion \(version). Use version 1."
    case .invalid(let reason): "Invalid news file: \(reason)"
    case .oversized: "News files must be no larger than 1 MiB. Choose a smaller snapshot set."
    case .unavailableStorage: "Local news storage is unavailable. Check the app's file access."
    }
  }
}

enum NewsSnapshotImporter {
  static let maximumBytes = 1_048_576

  static func decode(_ data: Data) throws -> [NewsSnapshot] {
    guard data.count <= maximumBytes else { throw NewsImportError.oversized }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let raw = try container.decode(String.self)
      let formatter = ISO8601DateFormatter()
      if let date = formatter.date(from: raw) { return date }
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = formatter.date(from: raw) { return date }
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Expected an ISO 8601 timestamp with a time zone.")
    }
    let document: NewsSnapshotDocument
    do {
      document = try decoder.decode(NewsSnapshotDocument.self, from: data)
    } catch let error as CardValidationError {
      throw NewsImportError.invalid(error.localizedDescription)
    } catch let error as DecodingError {
      throw NewsImportError.invalid(decodingMessage(error))
    } catch {
      throw NewsImportError.invalid("Check JSON syntax and the documented field types.")
    }
    guard document.schemaVersion == 1 else {
      throw NewsImportError.unsupportedSchema(document.schemaVersion)
    }
    var seen = Set<CardID>()
    for (index, snapshot) in document.snapshots.enumerated() {
      guard seen.insert(snapshot.id).inserted else {
        throw NewsImportError.invalid("snapshots[\(index)].id repeats an earlier card ID.")
      }
    }
    return document.snapshots
  }

  static func encode(_ snapshots: [NewsSnapshot]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(NewsSnapshotDocument(schemaVersion: 1, snapshots: snapshots))
    _ = try decode(data)
    return data
  }

  private static func decodingMessage(_ error: DecodingError) -> String {
    let context: DecodingError.Context
    let detail: String
    switch error {
    case .keyNotFound(let key, let value):
      context = value
      detail = "Missing required field \(key.stringValue)."
    case .typeMismatch(_, let value):
      context = value
      detail = "A field has the wrong type. Check the schema."
    case .valueNotFound(_, let value):
      context = value
      detail = "A required value is null."
    case .dataCorrupted(let value):
      context = value
      detail = "Check JSON syntax, URLs, and ISO 8601 timestamps."
    @unknown default:
      return "Check the documented JSON schema."
    }
    let path = context.codingPath.map(\.stringValue).joined(separator: ".")
    return path.isEmpty ? detail : "\(path): \(detail)"
  }
}
