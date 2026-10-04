import Observation

@MainActor
@Observable
final class ChessController {
  let puzzle: ChessPuzzle
  let runtime: GameRuntime
  private(set) var attempt: ChessAttempt?
  private(set) var destinationFile: Int?
  private(set) var destinationRank: Int?
  private var attemptID: GameAttemptID?

  init(puzzle: ChessPuzzle, runtime: GameRuntime) {
    self.puzzle = puzzle
    self.runtime = runtime
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  var canAcceptInput: Bool {
    guard let attemptID else { return false }
    return runtime.acceptsInput(from: attemptID)
  }

  var canSubmitCoordinates: Bool {
    canAcceptInput && attempt?.selectedSquare != nil
      && destinationFile != nil && destinationRank != nil
  }

  func tap(_ square: ChessSquare) {
    guard canAcceptInput else { return }
    attempt?.tap(square)
    clearCoordinates()
    finishIfSolved()
  }

  func selectFile(_ file: Int) {
    guard canAcceptInput, attempt?.selectedSquare != nil, (0..<8).contains(file) else { return }
    destinationFile = file
  }

  func selectRank(_ rank: Int) {
    guard canAcceptInput, attempt?.selectedSquare != nil, (0..<8).contains(rank) else { return }
    destinationRank = rank
  }

  func submitCoordinates() {
    guard canSubmitCoordinates, let file = destinationFile, let rank = destinationRank,
      let destination = ChessSquare(file: file, rank: rank)
    else { return }
    attempt?.submit(to: destination)
    clearCoordinates()
    finishIfSolved()
  }

  private func finishIfSolved() {
    guard attempt?.isSolved == true, let attemptID else { return }
    runtime.complete(attempt: attemptID)
  }

  private func clearCoordinates() {
    destinationFile = nil
    destinationRank = nil
  }

  private func apply(_ effect: GameLifecycleEffect) {
    switch effect {
    case .start(let id):
      attemptID = id
      attempt = ChessAttempt(puzzle: puzzle)
      clearCoordinates()
    case .reset:
      attemptID = nil
      attempt = nil
      clearCoordinates()
    case .stop:
      attemptID = nil
      clearCoordinates()
    }
  }
}
