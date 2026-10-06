import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct NewsImageView: View {
  let image: NewsImage
  private let load: @Sendable (URL) async throws -> Data

  init(
    image: NewsImage, load: @escaping @Sendable (URL) async throws -> Data = NewsImageDecoder.load
  ) {
    self.image = image
    self.load = load
  }
  @State private var loaded: UIImage?
  @State private var failed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Color.clear
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .overlay {
          if let loaded {
            Image(uiImage: loaded).resizable().scaledToFill()
          } else {
            Rectangle().fill(.secondary.opacity(0.08))
              .overlay {
                if failed {
                  Image(systemName: "photo").foregroundStyle(.secondary)
                } else {
                  ProgressView()
                }
              }
          }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isImage)
        .accessibilityValue(
          loaded != nil ? "Image loaded" : failed ? "Image unavailable" : "Loading image"
        )
        .accessibilityLabel(image.description.isEmpty ? "Article image" : image.description)
        .accessibilityIdentifier("news.image")
      if !image.credit.isEmpty {
        Text(image.credit).font(.caption).foregroundStyle(.secondary)
          .accessibilityIdentifier("news.imageCredit")
      }
    }
    .task(id: image.url) {
      loaded = nil
      failed = false
      do {
        let data = try await load(image.url)
        try Task.checkCancellation()
        guard let decoded = UIImage(data: data) else { throw NewsFeedError.invalidImage }
        loaded = decoded
      } catch is CancellationError {
        return
      } catch {
        guard !Task.isCancelled else { return }
        failed = true
      }
    }
  }
}

/// Decode/downsample untrusted images off UI; only a bounded thumbnail reaches presentation.
enum NewsImageDecoder {
  @concurrent static func load(_ url: URL) async throws -> Data {
    let original = try await NewsEphemeralTransport.fetch(url, maximumBytes: 4_194_304)
    try Task.checkCancellation()
    return try thumbnail(original)
  }

  static func thumbnail(_ original: Data) throws -> Data {
    guard original.count <= 4_194_304,
      let source = CGImageSourceCreateWithData(original as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int,
      width > 0, height > 0, width <= 8_192, height <= 8_192,
      width <= 16_777_216 / height
    else { throw NewsFeedError.invalidImage }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: 1_024,
      kCGImageSourceShouldCacheImmediately: true,
    ]
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    else {
      throw NewsFeedError.invalidImage
    }
    let result = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        result, UTType.jpeg.identifier as CFString, 1, nil)
    else { throw NewsFeedError.invalidImage }
    CGImageDestinationAddImage(destination, thumbnail, nil)
    guard CGImageDestinationFinalize(destination) else { throw NewsFeedError.invalidImage }
    return result as Data
  }
}
