import Foundation

protocol NewsFeedSource: Sendable {
  func load() async throws -> [NewsSnapshot]
}

struct NewsImage: Equatable, Codable, Sendable {
  let url: URL
  let description: String
  let credit: String

  init(url: URL, description: String, credit: String) throws {
    guard url.scheme?.lowercased() == "https", url.host?.lowercased() == "images.tagesschau.de",
      url.user == nil, url.password == nil, url.port == nil,
      !credit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      description.utf8.count <= 4096, credit.utf8.count <= 4096
    else {
      throw NewsFeedError.invalidImage
    }
    self.url = url
    self.description = description
    self.credit = credit
  }

  private enum CodingKeys: String, CodingKey { case url, description, credit }
  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      url: values.decode(URL.self, forKey: .url),
      description: values.decode(String.self, forKey: .description),
      credit: values.decode(String.self, forKey: .credit))
  }
}

enum NewsFeedError: Error, LocalizedError {
  case invalidFeed, oversized, invalidImage, invalidResponse
  var errorDescription: String? {
    switch self {
    case .invalidFeed: "The news feed could not be read."
    case .oversized: "The news response is too large."
    case .invalidImage: "The article image is unavailable."
    case .invalidResponse: "The news service is unavailable."
    }
  }
}
