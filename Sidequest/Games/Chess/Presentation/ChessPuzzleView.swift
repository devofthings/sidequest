import SwiftUI

@MainActor
struct ChessPuzzleView: View {
  let controller: ChessController
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrastOverride ?? systemContrast)
  }
  private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
  private var feedbackAnimation: Animation? {
    guard !reduceMotion, controller.runtime.isVisible else { return nil }
    if case .preview = controller.runtime.phase { return nil }
    return .smooth(duration: 0.16)
  }

  private var window: ChessBoardWindow { ChessBoardWindow(puzzle: controller.puzzle) }

  var body: some View {
    VStack(spacing: 16) {
      Text("\(controller.puzzle.sideToMove.name) to move")
        .font(.headline)
        .accessibilityIdentifier("chess.side")
      Text("Find checkmate in one move.")
      Text("Focus area \(window.coordinateRange) · Standard 8×8 rules")
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("chess.focus")
      board
      StableGameRegion {
        ZStack {
          Text("No piece selected")
          ForEach(movingSquares, id: \.self) { square in
            Text(
              "Selected: \(controller.puzzle.board[square]?.label ?? "Piece") on \(square.coordinate)"
            )
          }
        }
      } content: {
        Text(selectionLabel)
          .accessibilityIdentifier("chess.selection")
      }
      pieceControls
      coordinateControls
      StableGameRegion {
        ZStack {
          Text(feedbackLabel(.chooseMovingPiece))
          Text(feedbackLabel(.illegalMove))
          Text(feedbackLabel(.notCheckmate))
          Text(feedbackLabel(.checkmate))
          Text("Checkmate! \(controller.puzzle.sideToMove.name) wins.").font(.headline)
        }
      } content: {
        if controller.attempt?.isSolved == true {
          Text("Checkmate! \(controller.puzzle.sideToMove.name) wins.")
            .font(.headline)
            .accessibilityIdentifier("chess.completed")
        } else if let feedback = controller.attempt?.feedback {
          Text(feedbackLabel(feedback))
            .accessibilityIdentifier("chess.feedback")
        }
      }
    }
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private var board: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: window.files.count),
      spacing: 0
    ) {
      ForEach(window.displayOrder, id: \.self) { square in
        let displayedBoard = controller.attempt?.board ?? controller.puzzle.board
        let piece = displayedBoard[square]
        let selected = controller.attempt?.selectedSquare == square
        let destination = controller.attempt?.solution?.destination == square
        Button {
          controller.tap(square)
        } label: {
          VStack(spacing: 0) {
            Text(symbol(piece)).font(
              .system(size: window.files.count == 4 ? 40 : 26, weight: .semibold)
            )
            .scaleEffect(destination && !reduceMotion ? 1.12 : 1)
            .animation(feedbackAnimation, value: destination)
            Text(square.coordinate).font(.system(size: window.files.count == 4 ? 13 : 10))
          }
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .foregroundStyle(SidequestTheme.darkInk)
          .background(
            selected
              ? SidequestTheme.cyan
              : (destination
                ? SidequestTheme.lime
                : ((square.file + square.rank) % 2 == 0 ? SidequestTheme.lavender : Color.white))
          )
          .animation(feedbackAnimation, value: selected)
          .animation(feedbackAnimation, value: destination)
          .overlay {
            if selected || destination {
              Rectangle().strokeBorder(SidequestTheme.darkInk, lineWidth: 3)
            }
          }
        }
        .buttonStyle(.plain)
        .disabled(!controller.canAcceptInput)
        .accessibilityLabel("\(piece?.label ?? "Empty square") on \(square.coordinate)")
        .accessibilityIdentifier("chess.square.\(square.coordinate)")
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12).strokeBorder(theme.border, lineWidth: theme.borderWidth)
        .allowsHitTesting(false)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Chessboard focus area \(window.coordinateRange), standard 8 by 8 rules")
  }

  private var movingSquares: [ChessSquare] {
    ChessSquare.displayOrder.filter {
      controller.puzzle.board[$0]?.side == controller.puzzle.sideToMove
    }
  }

  private var pieceControls: some View {
    VStack(spacing: 8) {
      Text("Select a piece")
        .font(.headline)
      ForEach(
        movingSquares,
        id: \.self
      ) { square in
        Button {
          controller.tap(square)
        } label: {
          Text("\(controller.puzzle.board[square]?.label ?? "Piece") on \(square.coordinate)")
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(SidequestButtonStyle(compact: true))
        .disabled(!controller.canAcceptInput)
        .accessibilityIdentifier("chess.piece.\(square.coordinate)")
      }
    }
  }

  private var coordinateControls: some View {
    VStack(spacing: 8) {
      Text("Choose the destination")
        .font(.headline)
        .fixedSize(horizontal: false, vertical: true)
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
      .buttonStyle(SidequestButtonStyle(prominent: true, compact: true))
      .disabled(!controller.canSubmitCoordinates)
      .accessibilityIdentifier("chess.submit")
    }
    .buttonStyle(SidequestButtonStyle(compact: true))
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
