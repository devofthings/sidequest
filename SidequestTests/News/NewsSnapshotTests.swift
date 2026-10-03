import Foundation
import XCTest

@testable import Sidequest

final class NewsSnapshotTests: XCTestCase {
  func testIdentityAndMixedCardsRoundTripThroughCodable() throws {
    let news = try snapshot()
    let cards: [FeedCard] = [
      .news(news), .game(GameCard(id: try CardID("sudoku-a"), kind: .sudoku)),
      .game(GameCard(id: try CardID("sudoku-b"), kind: .sudoku)),
    ]
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    XCTAssertEqual(try decoder.decode([FeedCard].self, from: encoder.encode(cards)), cards)
    XCTAssertNil(news.publishedAt)
    XCTAssertTrue(news.isSample)
    XCTAssertEqual(try decoder.decode(CardID.self, from: Data("\"source-a\"".utf8)), news.id)
    for raw in ["", "  ", "\n"] {
      XCTAssertThrowsError(try CardID(raw))
    }
    XCTAssertThrowsError(try decoder.decode(CardID.self, from: Data("\" \"".utf8)))
  }

  func testRequiredMetadataAndSourceURLValidation() throws {
    for field in ["headline", "excerpt", "publisher"] {
      XCTAssertThrowsError(try snapshot(blankField: field)) {
        XCTAssertEqual($0 as? CardValidationError, .emptyField(field))
      }
    }
    for raw in ["/relative", "https:article", "file:///tmp/story", "ftp://example.com/story"] {
      let url = try XCTUnwrap(URL(string: raw))
      XCTAssertThrowsError(try snapshot(sourceURL: url)) {
        XCTAssertEqual($0 as? CardValidationError, .invalidSourceURL)
      }
    }
    let published = Date(timeIntervalSince1970: 1)
    XCTAssertEqual(try snapshot(publishedAt: published).publishedAt, published)
    for value in [Double.infinity, -Double.infinity, Double.nan] {
      XCTAssertThrowsError(try snapshot(capturedAt: Date(timeIntervalSince1970: value)))
      XCTAssertThrowsError(try snapshot(publishedAt: Date(timeIntervalSince1970: value)))
    }
  }

  func testDecodingUsesValidationAndRequiresSampleProvenance() throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = try encoder.encode(snapshot())
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    for field in ["id", "headline", "excerpt", "publisher", "sourceURL", "capturedAt", "isSample"] {
      var missing = object
      missing.removeValue(forKey: field)
      XCTAssertThrowsError(
        try decoder.decode(NewsSnapshot.self, from: JSONSerialization.data(withJSONObject: missing))
      )
    }
    var blank = object
    blank["headline"] = "  "
    XCTAssertThrowsError(
      try decoder.decode(NewsSnapshot.self, from: JSONSerialization.data(withJSONObject: blank)))
    var invalidURL = object
    invalidURL["sourceURL"] = "file:///tmp/story"
    XCTAssertThrowsError(
      try decoder.decode(
        NewsSnapshot.self, from: JSONSerialization.data(withJSONObject: invalidURL)))
  }

  private func snapshot(
    blankField: String? = nil, sourceURL: URL? = nil,
    capturedAt: Date = Date(timeIntervalSince1970: 1_704_067_200), publishedAt: Date? = nil
  ) throws -> NewsSnapshot {
    let url = try XCTUnwrap(sourceURL ?? URL(string: "https://example.com/article"))
    return try NewsSnapshot(
      id: CardID("source-a"), headline: blankField == "headline" ? " " : "Fictional headline",
      excerpt: blankField == "excerpt" ? "\n" : "Fictional excerpt",
      publisher: blankField == "publisher" ? " " : "Sample publisher",
      sourceURL: url, capturedAt: capturedAt, publishedAt: publishedAt, isSample: true
    )
  }
}
