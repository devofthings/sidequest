import Foundation

struct TagesschauNewsSource: NewsFeedSource {
  static let feedURL = URL(
    string: "https://www.tagesschau.de/infoservices/alle-meldungen-100~rss2.xml")
  private let fetch: @Sendable (URL, Int) async throws -> Data
  private let now: @Sendable () -> Date

  init(
    fetch: @escaping @Sendable (URL, Int) async throws -> Data = NewsEphemeralTransport.fetch,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.fetch = fetch
    self.now = now
  }

  @concurrent func load() async throws -> [NewsSnapshot] {
    guard let url = Self.feedURL else { throw NewsFeedError.invalidFeed }
    let data = try await fetch(url, 2_097_152)
    try Task.checkCancellation()
    return try TagesschauRSSParser.parse(data, capturedAt: now())
  }
}

/// Parser instances remain local to off-UI work and never cross concurrency domains.
final class TagesschauRSSParser: NSObject, XMLParserDelegate {
  private var depth = 0
  private var itemDepth: Int?
  private var field: String?
  private var values: [String: String] = [:]
  private var items = 0
  private var snapshots: [NewsSnapshot] = []
  private var seen = Set<CardID>()
  private let capturedAt: Date
  private var failed = false

  private init(capturedAt: Date) { self.capturedAt = capturedAt }

  static func parse(_ data: Data, capturedAt: Date) throws -> [NewsSnapshot] {
    guard data.count <= 2_097_152 else { throw NewsFeedError.oversized }
    // No DTD or entity declaration is part of this selected RSS contract.
    guard let source = String(data: data, encoding: .utf8),
      !source.uppercased().contains("<!DOCTYPE"), !source.uppercased().contains("<!ENTITY")
    else {
      throw NewsFeedError.invalidFeed
    }
    let delegate = TagesschauRSSParser(capturedAt: capturedAt)
    let parser = XMLParser(data: data)
    parser.shouldResolveExternalEntities = false
    parser.delegate = delegate
    guard parser.parse(), !delegate.failed, !delegate.snapshots.isEmpty else {
      throw NewsFeedError.invalidFeed
    }
    return delegate.snapshots
  }

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String]
  ) {
    depth += 1
    guard depth <= 32 else {
      failed = true
      parser.abortParsing()
      return
    }
    if elementName == "item" {
      guard itemDepth == nil else {
        failed = true
        parser.abortParsing()
        return
      }
      items += 1
      guard items <= 200 else {
        failed = true
        parser.abortParsing()
        return
      }
      itemDepth = depth
      values = [:]
    } else if let itemDepth, depth == itemDepth + 1,
      ["title", "description", "link", "pubDate", "content:encoded"].contains(elementName)
    {
      field = elementName
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    append(string, parser: parser)
  }
  func parser(_ parser: XMLParser, foundCDATA block: Data) {
    guard let string = String(data: block, encoding: .utf8) else {
      failed = true
      parser.abortParsing()
      return
    }
    append(string, parser: parser)
  }
  private func append(_ string: String, parser: XMLParser) {
    guard let field else { return }
    let previous = values[field, default: ""]
    guard previous.utf8.count + string.utf8.count <= 65_536 else {
      failed = true
      parser.abortParsing()
      return
    }
    values[field] = previous + string
  }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if elementName == "item" {
      finishItem()
      itemDepth = nil
      field = nil
    }
    if let itemDepth, depth == itemDepth + 1 { field = nil }
    depth -= 1
  }

  private func finishItem() {
    guard snapshots.count < 60,
      let rawURL = values["link"]?.trimmingCharacters(in: .whitespacesAndNewlines),
      let url = URL(string: rawURL), NewsEphemeralTransport.allowed(url),
      url.host?.lowercased() != "images.tagesschau.de", let rawDate = values["pubDate"],
      rawDate.utf8.count <= 128
    else { return }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
    formatter.isLenient = false
    guard
      let published = formatter.date(from: rawDate.trimmingCharacters(in: .whitespacesAndNewlines))
    else { return }
    let headline = NewsHTML.parse(values["title", default: ""]).text
    let excerpt = NewsHTML.parse(values["description", default: ""]).text
    guard headline.utf8.count <= 4096, excerpt.utf8.count <= 16_384 else { return }
    let embedded = NewsHTML.parse(values["content:encoded", default: ""])
    var image: NewsImage?
    if let attributes = embedded.imageAttributes, let src = attributes["src"],
      let imageURL = URL(string: src)
    {
      let caption = attributes["alt", default: ""]
      image = try? NewsImage(url: imageURL, description: caption, credit: caption)
    }
    guard let id = try? CardID("tagesschau-\(url.absoluteString)"), !seen.contains(id),
      let snapshot = try? NewsSnapshot(
        id: id, headline: headline, excerpt: excerpt, publisher: "tagesschau", sourceURL: url,
        capturedAt: capturedAt, publishedAt: published, isSample: false, image: image)
    else { return }
    seen.insert(id)
    snapshots.append(snapshot)
  }
}
