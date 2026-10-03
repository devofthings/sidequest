import Foundation

struct NewsSnapshot: Equatable, Codable, Sendable {
  let id: CardID
  let headline: String
  let excerpt: String
  let publisher: String
  let sourceURL: URL
  let capturedAt: Date
  let publishedAt: Date?
  let isSample: Bool

  init(
    id: CardID, headline: String, excerpt: String, publisher: String,
    sourceURL: URL, capturedAt: Date, publishedAt: Date? = nil, isSample: Bool
  ) throws {
    for (field, value) in [("headline", headline), ("excerpt", excerpt), ("publisher", publisher)] {
      guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw CardValidationError.emptyField(field)
      }
    }
    guard let scheme = sourceURL.scheme?.lowercased(), ["http", "https"].contains(scheme),
      let host = sourceURL.host, !host.isEmpty,
      host.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    else { throw CardValidationError.invalidSourceURL }
    guard capturedAt.timeIntervalSinceReferenceDate.isFinite else {
      throw CardValidationError.invalidTimestamp("capturedAt")
    }
    if let publishedAt, !publishedAt.timeIntervalSinceReferenceDate.isFinite {
      throw CardValidationError.invalidTimestamp("publishedAt")
    }
    self.id = id
    self.headline = headline
    self.excerpt = excerpt
    self.publisher = publisher
    self.sourceURL = sourceURL
    self.capturedAt = capturedAt
    self.publishedAt = publishedAt
    self.isSample = isSample
  }

  private enum CodingKeys: String, CodingKey {
    case id, headline, excerpt, publisher, sourceURL, capturedAt, publishedAt, isSample
  }

  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      id: values.decode(CardID.self, forKey: .id),
      headline: values.decode(String.self, forKey: .headline),
      excerpt: values.decode(String.self, forKey: .excerpt),
      publisher: values.decode(String.self, forKey: .publisher),
      sourceURL: values.decode(URL.self, forKey: .sourceURL),
      capturedAt: values.decode(Date.self, forKey: .capturedAt),
      publishedAt: values.decodeIfPresent(Date.self, forKey: .publishedAt),
      isSample: values.decode(Bool.self, forKey: .isSample)
    )
  }
}
