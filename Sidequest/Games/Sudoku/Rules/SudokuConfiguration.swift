/// Explicit formats prevent a standard board from being interpreted as a mini puzzle.
enum SudokuConfiguration: Equatable, Sendable {
  case mini
  case standard

  var regionSize: Int { self == .mini ? 2 : 3 }
  var size: Int { regionSize * regionSize }
  var cellCount: Int { size * size }
}
