import SwiftUI

/// Original #159 vector contours, normalized from a 64-point design canvas.
struct MemorySymbolArtwork: View {
  let symbol: MemorySymbol
  let outline: Color
  let increasedContrast: Bool

  var body: some View {
    MemorySymbolContour(symbol: symbol, details: false)
      .fill(fill)
      .overlay {
        MemorySymbolContour(symbol: symbol, details: false)
          .stroke(outline, style: stroke)
        MemorySymbolContour(symbol: symbol, details: true)
          .stroke(outline, style: stroke)
      }
  }

  private var stroke: StrokeStyle {
    StrokeStyle(lineWidth: increasedContrast ? 3.75 : 3, lineCap: .round, lineJoin: .round)
  }

  private var fill: Color {
    switch symbol {
    case .star, .leaf: SidequestTheme.lime
    case .heart, .sun: SidequestTheme.coral
    case .moon: SidequestTheme.lavender
    case .bolt: SidequestTheme.cyan
    }
  }
}

private struct MemorySymbolContour: Shape {
  let symbol: MemorySymbol
  let details: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    if details {
      switch symbol {
      case .sun:
        for ray in [
          (32.0, 3.0, 32.0, 8.0), (32, 56, 32, 61), (3, 32, 8, 32), (56, 32, 61, 32),
          (11, 11, 15, 15), (49, 49, 53, 53), (11, 53, 15, 49), (49, 15, 53, 11),
        ] {
          path.move(to: CGPoint(x: ray.0, y: ray.1))
          path.addLine(to: CGPoint(x: ray.2, y: ray.3))
        }
      case .leaf:
        path.move(to: CGPoint(x: 12, y: 56))
        path.addLine(to: CGPoint(x: 40, y: 26))
      default: break
      }
    } else {
      switch symbol {
      case .star:
        polygon(
          [
            (32, 5), (40, 23), (60, 25), (45, 39), (49, 59), (32, 49), (15, 59),
            (19, 39), (4, 25), (24, 23),
          ], into: &path)
      case .heart:
        path.move(to: CGPoint(x: 32, y: 56))
        curve(23, 49, 6, 37, 6, 23, into: &path)
        curve(6, 6, 25, 3, 32, 17, into: &path)
        curve(39, 3, 58, 6, 58, 23, into: &path)
        curve(58, 37, 41, 49, 32, 56, into: &path)
        path.closeSubpath()
      case .moon:
        path.move(to: CGPoint(x: 48, y: 8))
        curve(38, 10, 30, 19, 30, 31, into: &path)
        curve(30, 42, 39, 50, 51, 50, into: &path)
        curve(45, 60, 30, 61, 19, 54, into: &path)
        curve(3, 43, 3, 23, 16, 12, into: &path)
        curve(25, 4, 37, 2, 48, 8, into: &path)
        path.closeSubpath()
      case .sun:
        path.addEllipse(in: CGRect(x: 17, y: 17, width: 30, height: 30))
      case .leaf:
        path.move(to: CGPoint(x: 53, y: 7))
        curve(25, 5, 9, 20, 10, 39, into: &path)
        curve(11, 53, 25, 59, 38, 49, into: &path)
        curve(51, 39, 53, 20, 53, 7, into: &path)
        path.closeSubpath()
      case .bolt:
        polygon([(36, 4), (10, 35), (28, 35), (23, 60), (54, 25), (35, 25)], into: &path)
      }
    }
    let scale = min(rect.width, rect.height) / 64
    return path.applying(
      CGAffineTransform(
        a: scale, b: 0, c: 0, d: scale,
        tx: rect.midX - 32 * scale, ty: rect.midY - 32 * scale))
  }

  private func polygon(_ points: [(CGFloat, CGFloat)], into path: inout Path) {
    guard let first = points.first else { return }
    path.move(to: CGPoint(x: first.0, y: first.1))
    for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
    path.closeSubpath()
  }

  private func curve(
    _ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
    _ x: CGFloat, _ y: CGFloat, into path: inout Path
  ) {
    path.addCurve(
      to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1),
      control2: CGPoint(x: x2, y: y2))
  }
}

/// Every hidden tile uses the same decoration, independent of its answer.
struct MemoryCardBackArtwork: View {
  var body: some View {
    MemoryCardBackContour()
      .fill(SidequestTheme.darkInk)
      .overlay {
        Circle()
          .fill(SidequestTheme.cyan)
          .overlay {
            Circle().strokeBorder(SidequestTheme.darkInk, lineWidth: 3)
          }
          .frame(width: 14, height: 14)
      }
  }
}

private struct MemoryCardBackContour: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    for center in [
      CGPoint(x: 22, y: 7), CGPoint(x: 35, y: 14), CGPoint(x: 35, y: 30),
      CGPoint(x: 22, y: 37), CGPoint(x: 9, y: 30), CGPoint(x: 9, y: 14),
    ] {
      path.addEllipse(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
    }
    let scale = min(rect.width, rect.height) / 44
    return path.applying(
      CGAffineTransform(
        a: scale, b: 0, c: 0, d: scale,
        tx: rect.midX - 22 * scale, ty: rect.midY - 22 * scale))
  }
}
