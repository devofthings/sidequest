import Foundation
import XCTest

@testable import Sidequest

final class TagesschauNewsSourceTests: XCTestCase {
  private let date = Date(timeIntervalSince1970: 1_791_244_800)
  private func feed(_ item: String) -> Data {
    Data(
      "<rss xmlns:content='http://purl.org/rss/1.0/modules/content/'><channel>\(item)</channel></rss>"
        .utf8)
  }
  private func item(
    link: String = "https://www.tagesschau.de/test/story-100.html",
    image: String = "https://images.tagesschau.de/test.jpg"
  ) -> String {
    """
    <item><title>Fictional &amp; original</title><link>\(link)</link>
    <description><![CDATA[<p>Original &amp; fictional excerpt.</p>]]></description>
    <pubDate>Tue, 06 Oct 2026 10:00:00 +0200</pubDate>
    <content:encoded><![CDATA[<img src='\(image)' alt='Original fictional image | Own credit'>]]></content:encoded></item>
    """
  }

  func testOriginalRSSPreservesSourceTextDateAndImageCredit() throws {
    let stories = try TagesschauRSSParser.parse(feed(item()), capturedAt: date)
    XCTAssertEqual(stories.count, 1)
    XCTAssertEqual(stories[0].headline, "Fictional & original")
    XCTAssertEqual(stories[0].excerpt, "Original & fictional excerpt.")
    XCTAssertEqual(stories[0].image?.credit, "Original fictional image | Own credit")
    XCTAssertEqual(stories[0].capturedAt, date)
    XCTAssertNotNil(stories[0].publishedAt)
    XCTAssertFalse(stories[0].isSample)
  }

  func testUnsafeArticlesAreSkippedAndUnsafeImagesBecomeTextOnly() throws {
    let stories = try TagesschauRSSParser.parse(
      feed(item(link: "https://evil.example/article") + item(image: "https://evil.example/image")),
      capturedAt: date)
    XCTAssertEqual(stories.count, 1)
    XCTAssertNil(stories[0].image)
    XCTAssertThrowsError(
      try TagesschauRSSParser.parse(
        feed(item(link: "https://www.tagesschau.de.evil.example/article")), capturedAt: date))
    XCTAssertFalse(
      NewsEphemeralTransport.allowed(
        try XCTUnwrap(URL(string: "https://secret@www.tagesschau.de/article"))))
  }

  func testDuplicateStoriesDoNotDuplicatePoolAndInvalidFeedsFail() throws {
    XCTAssertEqual(try TagesschauRSSParser.parse(feed(item() + item()), capturedAt: date).count, 1)
    XCTAssertThrowsError(
      try TagesschauRSSParser.parse(
        Data("<!DOCTYPE rss [<!ENTITY test SYSTEM 'file:///etc/passwd'>]><rss/>".utf8),
        capturedAt: date))
    XCTAssertThrowsError(
      try TagesschauRSSParser.parse(Data("<rss><channel>".utf8), capturedAt: date))
    XCTAssertThrowsError(
      try TagesschauRSSParser.parse(Data(repeating: 65, count: 2_097_153), capturedAt: date))
    XCTAssertThrowsError(try TagesschauRSSParser.parse(feed(""), capturedAt: date))
  }

  func testInertHTMLHandlesQuotedGreaterThanAndEntitiesWithoutScriptText() {
    let parsed = NewsHTML.parse(
      "<!-- do > not show --> <script>ignore me</script><p>One&nbsp;two &#x1F525;</p><IMG alt='Credit > example &amp; owner' src=https://images.tagesschau.de/a.jpg>"
    )
    XCTAssertEqual(parsed.text, "One two 🔥")
    XCTAssertEqual(parsed.imageAttributes?["alt"], "Credit > example & owner")
    XCTAssertEqual(parsed.imageAttributes?["src"], "https://images.tagesschau.de/a.jpg")
  }

  func testOptionalImageRoundTripsAndOldSnapshotsRemainCompatible() throws {
    let snapshot = try XCTUnwrap(
      try TagesschauRSSParser.parse(feed(item()), capturedAt: date).first)
    let bytes = try JSONEncoder().encode(snapshot)
    XCTAssertEqual(try JSONDecoder().decode(NewsSnapshot.self, from: bytes), snapshot)
    var object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    object.removeValue(forKey: "image")
    let legacy = try JSONDecoder().decode(
      NewsSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
    XCTAssertNil(legacy.image)
    XCTAssertEqual(legacy.headline, snapshot.headline)
  }

  func testSourceUsesInjectedTransportAndCaptureClock() async throws {
    let bytes = feed(item())
    let captured = date
    let source = TagesschauNewsSource(
      fetch: { url, limit in
        XCTAssertEqual(url, TagesschauNewsSource.feedURL)
        XCTAssertEqual(limit, 2_097_152)
        return bytes
      }, now: { captured })
    let result = try await source.load()
    XCTAssertEqual(result.first?.capturedAt, captured)
  }

  func testImageDecoderRejectsNonImageAndOversizedInput() {
    XCTAssertThrowsError(try NewsImageDecoder.thumbnail(Data("not an image".utf8)))
    XCTAssertThrowsError(try NewsImageDecoder.thumbnail(Data(repeating: 0, count: 4_194_305)))
  }
}
