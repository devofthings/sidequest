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
    let boardPoint = BubblePoint(x: point.x / scale, y: point.y / scale + regionTop)
    let dx = boardPoint.x - BubbleGeometry.launcher.x
    let upward = BubbleGeometry.launcher.y - boardPoint.y
    guard upward > 0 else { return nil }
    let angle = atan2(dx, upward)
    return min(60, max(-60, angle * 180 / .pi))
  }
}
