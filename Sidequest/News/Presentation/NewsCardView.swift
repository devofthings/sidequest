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

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if snapshot.isSample {
        Label("Fictional sample", systemImage: "info.circle")
          .font(.caption.bold())
          .accessibilityIdentifier("news.sample")
      }
      Text(snapshot.headline)
        .font(.title2.bold())
        .accessibilityAddTraits(.isHeader)
      Text(snapshot.excerpt)
        .font(.body)
        .textSelection(.enabled)
      Text(snapshot.publisher)
        .font(.subheadline.bold())
      Text("Captured \(snapshot.capturedAt.formatted(date: .abbreviated, time: .omitted))")
        .font(.caption)
        .accessibilityIdentifier("news.captured")
      if let published = snapshot.publishedAt {
        Text("Published \(published.formatted(date: .abbreviated, time: .omitted))")
          .font(.caption)
      }
      Link(destination: snapshot.sourceURL) {
        Label("Read original article", systemImage: "arrow.up.right.square")
          .frame(minHeight: 44, alignment: .leading)
      }
      .accessibilityLabel("Read original article from \(snapshot.publisher)")
      .accessibilityIdentifier("news.source")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
  }
}
