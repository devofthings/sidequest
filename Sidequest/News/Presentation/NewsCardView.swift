import SwiftUI

@MainActor
struct NewsCardView: View {
  let snapshot: NewsSnapshot

  var body: some View {
    ScrollView { NewsCardContent(snapshot: snapshot) }
  }
}

/// Unscrolled content lets the feed own one vertical card scroller.
@MainActor
struct NewsCardContent: View {
  let snapshot: NewsSnapshot
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrastOverride ?? systemContrast)
  }

  private var imageLoader: @Sendable (URL) async throws -> Data {
    #if DEBUG
      if CommandLine.arguments.contains("-sidequest-tagesschau-fixtures") {
        return { url in try await TagesschauFixtures.imageData(url) }
      }
    #endif
    return NewsImageDecoder.load
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if snapshot.isSample {
        Label("Fictional sample", systemImage: "info.circle")
          .font(.caption.bold())
          .foregroundStyle(theme.secondaryInk)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(theme.utilityCanvas, in: Capsule())
          .accessibilityIdentifier("news.sample")
      }
      if let image = snapshot.image { NewsImageView(image: image, load: imageLoader) }
      Text(snapshot.headline)
        .font(.system(.title2, design: .serif, weight: .heavy))
        .accessibilityIdentifier("news.headline")
        .accessibilityAddTraits(.isHeader)
      VStack(alignment: .leading, spacing: 4) {
        Text(snapshot.publisher)
          .font(.subheadline.bold())
        Text("Captured \(snapshot.capturedAt.formatted(date: .abbreviated, time: .omitted))")
          .font(.caption)
          .foregroundStyle(theme.secondaryInk)
          .accessibilityIdentifier("news.captured")
        if let published = snapshot.publishedAt {
          Text("Published \(published.formatted(date: .abbreviated, time: .omitted))")
            .font(.caption)
            .foregroundStyle(theme.secondaryInk)
        }
      }
      Rectangle()
        .fill(theme.border)
        .frame(height: theme.borderWidth + 1)
        .accessibilityHidden(true)
      Text(snapshot.excerpt)
        .font(.body)
        .lineSpacing(3)
        .textSelection(.enabled)
      Link(destination: snapshot.sourceURL) {
        Label(
          snapshot.isSample ? "Open sample placeholder" : "Read original article",
          systemImage: "arrow.up.right.square"
        )
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      }
      .accessibilityLabel(
        snapshot.isSample
          ? "Open fictional sample placeholder from \(snapshot.publisher)"
          : "Read original article from \(snapshot.publisher)"
      )
      .buttonStyle(SidequestButtonStyle(neutral: true))
      .accessibilityIdentifier("news.source")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .foregroundStyle(theme.ink)
    .background(theme.utilitySurface, in: RoundedRectangle(cornerRadius: 24))
    .overlay {
      RoundedRectangle(cornerRadius: 24)
        .strokeBorder(theme.border, lineWidth: theme.borderWidth)
    }
  }
}
