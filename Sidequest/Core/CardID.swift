import Foundation

struct CardID: Hashable, Codable, Sendable {
  let rawValue: String

  init(_ rawValue: String) throws {
    guard !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw CardValidationError.emptyField("id")
    }
    self.rawValue = rawValue
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(container.decode(String.self))
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

enum CardValidationError: Error, Equatable, LocalizedError {
  case emptyField(String)
  case invalidSourceURL
  case invalidTimestamp(String)

  var errorDescription: String? {
    switch self {
    case .emptyField(let field): "\(field) must contain text."
    case .invalidSourceURL: "sourceURL must be an absolute HTTP or HTTPS URL with a host."
    case .invalidTimestamp(let field): "\(field) must be a valid timestamp."
    }
  }
}
