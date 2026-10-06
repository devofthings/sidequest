import SwiftUI

@MainActor
struct DailyStreakIndicator: View {
  let model: DailyStreakModel

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "flame.fill")
        .foregroundStyle(model.count > 0 ? Color.orange : Color.secondary)
      ZStack(alignment: .trailing) {
        Text("888+").hidden().accessibilityHidden(true)
        Text(model.count > 999 ? "999+" : String(model.count))
      }
      .monospacedDigit()
      .lineLimit(1)
    }
    .font(.system(.caption, design: .rounded, weight: .semibold))
    .fixedSize(horizontal: true, vertical: true)
    .foregroundStyle(.secondary)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Daily streak")
    .accessibilityValue(
      "\(model.count) \(model.count == 1 ? "day" : "days")\(model.status == nil ? "" : ", temporary and not saved")"
    )
    .accessibilityIdentifier("streak.daily")
  }
}
