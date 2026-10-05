import SwiftUI

/// Original #159 cross/crown artwork; rule identity and spoken names remain game-owned.
struct ChessPieceArtwork: View {
  let piece: ChessPiece
  let increasedContrast: Bool

  var body: some View {
    ChessPieceContour(kind: piece.kind, details: false)
      .fill(piece.side == .white ? Color.white : SidequestTheme.darkInk)
      .overlay {
        ChessPieceContour(kind: piece.kind, details: false).stroke(outline, style: stroke)
        ChessPieceContour(kind: piece.kind, details: true).stroke(outline, style: stroke)
      }
  }

  private var outline: Color { piece.side == .white ? SidequestTheme.darkInk : .white }
  private var stroke: StrokeStyle {
    StrokeStyle(lineWidth: increasedContrast ? 2.75 : 2.2, lineCap: .round, lineJoin: .round)
  }
}

private struct ChessPieceContour: Shape {
  let kind: ChessPieceKind
  let details: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    if details {
      if kind == .king {
        path.move(to: CGPoint(x: 32, y: 3))
        path.addLine(to: CGPoint(x: 32, y: 15))
        path.move(to: CGPoint(x: 26, y: 8))
        path.addLine(to: CGPoint(x: 38, y: 8))
      }
      path.move(to: CGPoint(x: 26, y: 30))
      path.addLine(to: CGPoint(x: 38, y: 30))
    } else {
      switch kind {
      case .king:
        path.move(to: CGPoint(x: 18, y: 24))
        path.addQuadCurve(to: CGPoint(x: 25, y: 14), control: CGPoint(x: 15, y: 14))
        path.addLine(to: CGPoint(x: 39, y: 14))
        path.addQuadCurve(to: CGPoint(x: 46, y: 24), control: CGPoint(x: 49, y: 14))
        path.closeSubpath()
      case .queen:
        polygon(
          [(18, 24), (13, 10), (25, 18), (32, 6), (39, 18), (51, 10), (46, 24)],
          into: &path)
      }
      polygon([(20, 24), (44, 24), (40, 38), (44, 49), (20, 49), (24, 38)], into: &path)
      path.addRoundedRect(
        in: CGRect(x: 14, y: 49, width: 36, height: 10),
        cornerSize: CGSize(width: 4, height: 4))
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
}
