enum ChessSide: String, Codable, Sendable {
  case white
  case black

  var name: String { self == .white ? "White" : "Black" }
}

struct ChessSquare: Hashable, Sendable {
  let file: Int
  let rank: Int

  init?(file: Int, rank: Int) {
    guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
    self.file = file
    self.rank = rank
  }

  init?(_ coordinate: String) {
    let bytes = Array(coordinate.utf8)
    guard bytes.count == 2, (97...104).contains(bytes[0]), (49...56).contains(bytes[1]) else {
      return nil
    }
    self.init(file: Int(bytes[0]) - 97, rank: Int(bytes[1]) - 49)
  }

  var coordinate: String {
    String("abcdefgh".dropFirst(file).prefix(1)) + String(rank + 1)
  }

  static let displayOrder: [ChessSquare] = (0..<64).compactMap {
    ChessSquare(file: $0 % 8, rank: 7 - $0 / 8)
  }
}

struct ChessMove: Hashable, Sendable {
  let origin: ChessSquare
  let destination: ChessSquare

  init(origin: ChessSquare, destination: ChessSquare) {
    self.origin = origin
    self.destination = destination
  }

  init?(_ notation: String) {
    guard notation.utf8.count == 4,
      let origin = ChessSquare(String(notation.prefix(2))),
      let destination = ChessSquare(String(notation.suffix(2))), origin != destination
    else { return nil }
    self.init(origin: origin, destination: destination)
  }

  var notation: String { origin.coordinate + destination.coordinate }
}

enum ChessPieceKind: String, Sendable {
  case king
  case queen
}

struct ChessPiece: Equatable, Sendable {
  let side: ChessSide
  let kind: ChessPieceKind

  var label: String { "\(side.name) \(kind.rawValue)" }
}
