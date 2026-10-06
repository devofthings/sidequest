import SwiftUI

@MainActor
struct DailyStreakIndicator: View {
  let model: DailyStreakModel
  @ScaledMetric(relativeTo: .caption) private var scaledFontSize = 12

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "flame.fill")
        .foregroundStyle(model.count > 0 ? Color.orange : Color.secondary)
      Text(model.count > 999 ? "999+" : String(model.count))
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: true)
    }
    // This informational badge reserves room for the exact spoken value without taking
    // space from scalable game headings or the primary 44-point navigation target.
    .font(.system(size: min(scaledFontSize, 18), design: .rounded, weight: .semibold))
    .frame(width: 72, alignment: .leading)
    .foregroundStyle(.secondary)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Daily streak")
    .accessibilityValue(
      "\(model.count) \(model.count == 1 ? "day" : "days")\(model.status == nil ? "" : ", temporary and not saved")"
    )
    .accessibilityIdentifier("streak.daily")
  }
}
