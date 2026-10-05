import Foundation
import Observation

@Observable
@MainActor
final class SudokuController {
  let runtime: GameRuntime
  let puzzle: SudokuPuzzle
  let challenge: SudokuChallenge?
  private let initialBoard: SudokuBoard
  private(set) var board: SudokuBoard?
  private(set) var selectedCell: Int?
  private(set) var coordinateRow = 0
  private(set) var coordinateColumn = 0

  var displayedBoard: SudokuBoard { board ?? initialBoard }

  convenience init(
    puzzle: SudokuPuzzle, runtime: GameRuntime, completedBoard: SudokuBoard? = nil,
    selectedCell: Int? = nil
  ) {
    self.init(
      puzzle: puzzle, challenge: nil, runtime: runtime,
      completedBoard: completedBoard, selectedCell: selectedCell)
  }

  convenience init(
    challenge: SudokuChallenge, runtime: GameRuntime, completedBoard: SudokuBoard? = nil,
    selectedCell: Int? = nil
  ) {
    self.init(
      puzzle: challenge.puzzle, challenge: challenge, runtime: runtime,
      completedBoard: completedBoard, selectedCell: selectedCell)
  }

  private init(
    puzzle: SudokuPuzzle, challenge: SudokuChallenge?, runtime: GameRuntime,
    completedBoard: SudokuBoard?, selectedCell: Int?
  ) {
    self.challenge = challenge
    self.puzzle = puzzle
    self.runtime = runtime
    initialBoard = SudokuBoard(puzzle: puzzle)
    board = completedBoard
    self.selectedCell = selectedCell
    if let selectedCell {
      coordinateRow = selectedCell / puzzle.configuration.size
      coordinateColumn = selectedCell % puzzle.configuration.size
    }
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  func selectCell(_ index: Int, visibility: UUID? = nil) {
    guard puzzle.givens.indices.contains(index), puzzle.givens[index] == 0,
      runtime.prepareInteraction(visibility: visibility), let board,
      board.cells.indices.contains(index),
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt)
    else { return }
    selectedCell = index
    coordinateRow = index / puzzle.configuration.size
    coordinateColumn = index % puzzle.configuration.size
  }

  func selectRow(_ row: Int, visibility: UUID? = nil) {
    selectCoordinate(row: row, column: coordinateColumn, visibility: visibility)
  }

  func selectColumn(_ column: Int, visibility: UUID? = nil) {
    selectCoordinate(row: coordinateRow, column: column, visibility: visibility)
  }

  private func selectCoordinate(row: Int, column: Int, visibility: UUID?) {
    let size = puzzle.configuration.size
    guard (0..<size).contains(row), (0..<size).contains(column), runtime.canInteract,
      visibility == nil || visibility == runtime.visibilityIdentity
    else { return }
    let index = row * size + column
    // A given is readable through coordinates but cannot initiate an attempt.
    if puzzle.givens[index] == 0 {
      guard runtime.prepareInteraction(visibility: visibility) else { return }
    }
    coordinateRow = row
    coordinateColumn = column
    selectedCell = puzzle.givens[index] == 0 ? index : nil
  }

  func enter(_ value: Int, visibility: UUID? = nil) {
    guard visibility == nil || visibility == runtime.visibilityIdentity, let selectedCell,
      var board,
      case .playing(let attempt) = runtime.phase, runtime.acceptsInput(from: attempt),
      board.cells[selectedCell] != value,
      board.setValue(value, at: selectedCell)
    else { return }
    self.board = board
    if board.isComplete {
      runtime.complete(attempt: attempt, successful: true)
    } else {
      runtime.feedbackForInteraction(attempt: attempt)
    }
  }

  private func apply(_ effect: GameLifecycleEffect) {
    switch effect {
    case .start:
      board = initialBoard
      selectedCell = nil
      coordinateRow = 0
      coordinateColumn = 0
    case .reset:
      board = nil
      selectedCell = nil
      coordinateRow = 0
      coordinateColumn = 0
    case .stop:
      break
    }
  }
}
