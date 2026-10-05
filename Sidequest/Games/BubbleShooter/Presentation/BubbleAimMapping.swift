import Foundation

/// Presentation coordinates use the board's uniform scale; the lower aim area starts at row 7.
struct BubbleAimMapping {
  static let regionTop = 7.0
  static let regionHeight = 5.0

  static func degrees(point: BubblePoint, width: Double) -> Double? {
    guard width.isFinite, width > 0, point.x.isFinite, point.y.isFinite else { return nil }
    let scale = width / BubbleGeometry.width
    guard point.x >= 0, point.x <= width, point.y >= 0,
      point.y <= regionHeight * scale
    else { return nil }
    // Absolute horizontal position stays predictable even when a drag starts on the launcher.
    // Vertical movement owns the same touch region but never changes the chosen angle.
    return (point.x / width - 0.5) * 120
  }
}
