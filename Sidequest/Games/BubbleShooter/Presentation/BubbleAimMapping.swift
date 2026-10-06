import Foundation

/// Presentation coordinates use the board's uniform scale; the lower aim area starts at row 7.
struct BubbleAimMapping {
  static let regionTop = 7.0
  static let regionHeight = 5.0

  /// A tap targets the upward ray from the real launcher; obstacles still decide attachment.
  static func targetDegrees(point: BubblePoint, width: Double) -> Double? {
    guard width.isFinite, width > 0, point.x.isFinite, point.y.isFinite else { return nil }
    let scale = width / BubbleGeometry.width
    guard point.x >= 0, point.x <= width, point.y >= 0,
      point.y < BubbleGeometry.launcher.y * scale
    else { return nil }
    let dx = point.x / scale - BubbleGeometry.launcher.x
    let upward = BubbleGeometry.launcher.y - point.y / scale
    return min(60, max(-60, atan2(dx, upward) * 180 / .pi))
  }

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
