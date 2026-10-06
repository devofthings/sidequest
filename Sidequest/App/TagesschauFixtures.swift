#if DEBUG
  import UIKit

  /// Original fictional data for the live-news lifecycle route; never a production fallback.
  enum TagesschauFixtures {
    static let source = Source()

    @MainActor static func imageData(_ url: URL) throws -> Data {
      guard !CommandLine.arguments.contains("-sidequest-tagesschau-image-failure") else {
        throw NewsFeedError.invalidImage
      }
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 90))
      return renderer.pngData { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 160, height: 90))
        UIColor.systemYellow.setFill()
        context.cgContext.fillEllipse(in: CGRect(x: 55, y: 20, width: 50, height: 50))
      }
    }

    actor Source: NewsFeedSource {
      private var count = 0
      func load() async throws -> [NewsSnapshot] {
        count += 1
        if count > 1 && CommandLine.arguments.contains("-sidequest-tagesschau-refresh-failure") {
          throw NewsFeedError.invalidFeed
        }
        let data = Data(
          """
          <rss xmlns:content="http://purl.org/rss/1.0/modules/content/"><channel><item>
          <title>Test story \(count)</title>
          <description>Original fictional article used only for deterministic news testing.</description>
          <link>https://www.tagesschau.de/test-fixture.html</link>
          <pubDate>Tue, 06 Oct 2026 08:00:00 +0200</pubDate>
          <content:encoded><![CDATA[<img src="https://images.tagesschau.de/test-fixture.png"
          alt="Original teal and yellow illustration | Sidequest test artwork">]]></content:encoded>
          </item></channel></rss>
          """.utf8)
        return try TagesschauRSSParser.parse(
          data, capturedAt: Date(timeIntervalSince1970: 1_791_273_600))
      }
    }
  }
#endif
