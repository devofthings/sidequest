import Foundation

/// One request owns one ephemeral session; no cookies, credentials, or persistent cache.
enum NewsEphemeralTransport {
  static func allowed(_ url: URL) -> Bool {
    url.scheme?.lowercased() == "https" && url.user == nil && url.password == nil && url.port == nil
      && ["www.tagesschau.de", "tagesschau.de", "images.tagesschau.de"].contains(
        url.host?.lowercased() ?? "")
  }

  @concurrent static func fetch(_ url: URL, maximumBytes: Int) async throws -> Data {
    guard allowed(url), maximumBytes > 0 else { throw NewsFeedError.invalidResponse }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = nil
    configuration.httpCookieStorage = nil
    configuration.urlCredentialStorage = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 20
    let session = URLSession(
      configuration: configuration,
      delegate: NewsRedirectPolicy(imageOnly: url.host?.lowercased() == "images.tagesschau.de"),
      delegateQueue: nil)
    defer { session.invalidateAndCancel() }
    let (bytes, response) = try await session.bytes(from: url)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
      let finalURL = response.url, allowed(finalURL)
    else { throw NewsFeedError.invalidResponse }
    guard response.expectedContentLength <= Int64(maximumBytes) else {
      throw NewsFeedError.oversized
    }
    var data = Data()
    for try await byte in bytes {
      try Task.checkCancellation()
      guard data.count < maximumBytes else { throw NewsFeedError.oversized }
      data.append(byte)
    }
    return data
  }
}

final class NewsRedirectPolicy: NSObject, URLSessionTaskDelegate {
  private let imageOnly: Bool
  init(imageOnly: Bool) { self.imageOnly = imageOnly }
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    let permitted =
      request.url.map {
        NewsEphemeralTransport.allowed($0)
          && (($0.host?.lowercased() == "images.tagesschau.de") == imageOnly)
      } == true
    completionHandler(permitted ? request : nil)
  }
}
