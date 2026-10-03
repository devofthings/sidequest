import SwiftUI

@MainActor
struct ChessPuzzleView: View {
  let controller: ChessController

  var body: some View {
    VStack(spacing: 16) {
      Text("\(controller.puzzle.sideToMove.name) to move")
        .font(.headline)
        .accessibilityIdentifier("chess.side")
      Text("Find checkmate in one move.")
      board
      if controller.attempt?.isSolved == true {
        Text("Checkmate! \(controller.puzzle.sideToMove.name) wins.")
          .font(.headline)
          .accessibilityIdentifier("chess.completed")
      } else {
        Text(selectionLabel)
          .accessibilityIdentifier("chess.selection")
        pieceControls
        coordinateControls
        if let feedback = controller.attempt?.feedback {
          Text(feedbackLabel(feedback))
            .accessibilityIdentifier("chess.feedback")
        }
      }
    }
  }

  private var board: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8), spacing: 0) {
      ForEach(ChessSquare.displayOrder, id: \.self) { square in
        let displayedBoard = controller.attempt?.board ?? controller.puzzle.board
        let piece = displayedBoard[square]
        Button {
          controller.tap(square)
        } label: {
          VStack(spacing: 0) {
            Text(symbol(piece)).font(.system(size: 26))
            Text(square.coordinate).font(.system(size: 10))
          }
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .background(Color.secondary.opacity((square.file + square.rank) % 2 == 0 ? 0.18 : 0.05))
          .overlay {
            if controller.attempt?.selectedSquare == square {
              Rectangle().stroke(.primary, lineWidth: 3)
            }
          }
        }
        .buttonStyle(.plain)
        .disabled(!controller.canAcceptInput)
        .accessibilityLabel("\(piece?.label ?? "Empty square") on \(square.coordinate)")
        .accessibilityIdentifier("chess.square.\(square.coordinate)")
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Chessboard, a1 at bottom left")
  }

  private var pieceControls: some View {
    VStack(spacing: 8) {
      Text("Select a piece")
        .font(.headline)
      ForEach(
        ChessSquare.displayOrder.filter {
          controller.puzzle.board[$0]?.side == controller.puzzle.sideToMove
        },
        id: \.self
      ) { square in
        Button {
          controller.tap(square)
        } label: {
          Text("\(controller.puzzle.board[square]?.label ?? "Piece") on \(square.coordinate)")
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .disabled(!controller.canAcceptInput)
        .accessibilityIdentifier("chess.piece.\(square.coordinate)")
      }
    }
  }

  private var coordinateControls: some View {
    VStack(spacing: 8) {
      Text("Choose the destination")
        .font(.headline)
      Menu {
        ForEach(0..<8) { file in
          let name = String("abcdefgh".dropFirst(file).prefix(1))
          Button("File \(name.uppercased())") { controller.selectFile(file) }
            .accessibilityIdentifier("chess.file.\(name)")
        }
      } label: {
        Text(
          controller.destinationFile.map {
            "File: \(String("abcdefgh".dropFirst($0).prefix(1)).uppercased())"
          } ?? "File: —"
        )
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
      }
      .accessibilityIdentifier("chess.file")
      .accessibilityHint("Choose a destination file from A through H.")
      Menu {
        ForEach(0..<8) { rank in
          Button("Rank \(rank + 1)") { controller.selectRank(rank) }
            .accessibilityIdentifier("chess.rank.\(rank + 1)")
        }
      } label: {
        Text(controller.destinationRank.map { "Rank: \($0 + 1)" } ?? "Rank: —")
          .frame(maxWidth: .infinity, minHeight: 44)
          .contentShape(Rectangle())
      }
      .accessibilityIdentifier("chess.rank")
      .accessibilityHint("Choose a destination rank from 1 through 8.")
      Button(action: controller.submitCoordinates) {
        Text("Submit move")
          .frame(maxWidth: .infinity, minHeight: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.borderedProminent)
      .disabled(!controller.canSubmitCoordinates)
      .accessibilityIdentifier("chess.submit")
    }
    .buttonStyle(.bordered)
    .disabled(!controller.canAcceptInput || controller.attempt?.selectedSquare == nil)
  }

  private var selectionLabel: String {
    guard let square = controller.attempt?.selectedSquare else { return "No piece selected" }
    return "Selected: \(controller.puzzle.board[square]?.label ?? "Piece") on \(square.coordinate)"
  }

  private func feedbackLabel(_ feedback: ChessFeedback) -> String {
    switch feedback {
    case .chooseMovingPiece: "Select a \(controller.puzzle.sideToMove.name) piece."
    case .illegalMove: "That move is not legal. Try another move."
    case .notCheckmate: "That move is legal, but it is not checkmate. Try again."
    case .checkmate: "Checkmate!"
    }
  }

  private func symbol(_ piece: ChessPiece?) -> String {
    guard let piece else { return "·" }
    return switch (piece.side, piece.kind) {
    case (.white, .king): "♔"
    case (.white, .queen): "♕"
    case (.black, .king): "♚"
    case (.black, .queen): "♛"
    }
  }
}
