import SwiftUI

@MainActor
struct ChessPuzzleView: View {
  let controller: ChessController
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.sidequestGameLayoutBudget) private var layoutBudget
  @State private var chromeHeight: CGFloat = 0

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

  private var compact: Bool { !dynamicTypeSize.isAccessibilitySize && window.files.count == 4 }
  private var spacing: CGFloat { compact ? 8 : 16 }
  private var boardExtent: CGFloat {
    layoutBudget?.squareBoardExtent(chromeHeight: chromeHeight, columns: 4) ?? 176
  }

  var body: some View {
    VStack(spacing: spacing) {
      instructions
      if compact {
        board.frame(width: boardExtent, height: boardExtent)
      } else {
        board
      }
      selection
      pieceControls
      coordinateControls
      feedback
    }
    .frame(maxWidth: .infinity)
    .background(alignment: .top) {
      if compact {
        // This independent reservation excludes the board and always uses the content width.
        VStack(spacing: spacing) {
          instructions
          selection
          pieceControls
          coordinateControls
          feedback
        }
        .frame(maxWidth: .infinity)
        .hidden().accessibilityHidden(true).allowsHitTesting(false)
        .onGeometryChange(for: CGFloat.self) {
          $0.size.height
        } action: { height in
          if abs(chromeHeight - height) > 0.5 { chromeHeight = height }
        }
      }
    }
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private var instructions: some View {
    VStack(spacing: compact ? 4 : 16) {
      Text(
        compact
          ? "\(controller.puzzle.sideToMove.name) to move · Mate in one"
          : "\(controller.puzzle.sideToMove.name) to move"
      )
      .font(.headline)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityIdentifier("chess.side")
      if !compact { Text("Find checkmate in one move.") }
      Text("Focus area \(window.coordinateRange) · Standard 8×8 rules")
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("chess.focus")
    }
  }

  private var selection: some View {
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
      Text(selectionLabel).accessibilityIdentifier("chess.selection")
    }
    .font(compact ? .subheadline : .body)
  }

  private var feedback: some View {
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
          .font(.headline).accessibilityIdentifier("chess.completed")
      } else if let feedback = controller.attempt?.feedback {
        Text(feedbackLabel(feedback)).accessibilityIdentifier("chess.feedback")
      }
    }
    .font(compact ? .subheadline : .body)
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
            Group {
              if let piece {
                ChessPieceArtwork(piece: piece, increasedContrast: theme.contrast == .increased)
              } else {
                Color.clear
              }
            }
            .frame(
              width: compact ? min(40, boardExtent / 4 - 20) : (window.files.count == 4 ? 40 : 26),
              height: compact ? min(40, boardExtent / 4 - 20) : (window.files.count == 4 ? 40 : 26)
            )
            .accessibilityHidden(true)
            .scaleEffect(destination && !reduceMotion ? 1.12 : 1)
            .animation(feedbackAnimation, value: destination)
            Text(square.coordinate).font(.system(size: window.files.count == 4 ? 13 : 10))
          }
          .frame(maxWidth: .infinity)
          .frame(width: compact ? boardExtent / 4 : nil, height: compact ? boardExtent / 4 : nil)
          .aspectRatio(1, contentMode: .fit)
          .contentShape(Rectangle())
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
        .buttonStyle(ChessSquareButtonStyle())
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
    Group {
      if compact {
        HStack(spacing: 8) { pieceButtons }
      } else {
        VStack(spacing: 8) {
          Text("Select a piece").font(.headline)
          pieceButtons
        }
      }
    }
  }

  private var pieceButtons: some View {
    ForEach(movingSquares, id: \.self) { square in
      Button {
        controller.tap(square)
      } label: {
        let piece = controller.puzzle.board[square]
        Text(
          compact
            ? "\(piece?.kind.rawValue.capitalized ?? "Piece") \(square.coordinate)"
            : "\(piece?.label ?? "Piece") on \(square.coordinate)"
        )
        .font(compact ? .subheadline : .headline)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(SidequestButtonStyle(compact: true))
      .disabled(!controller.canAcceptInput)
      .accessibilityLabel(
        "\(controller.puzzle.board[square]?.label ?? "Piece") on \(square.coordinate)"
      )
      .accessibilityIdentifier("chess.piece.\(square.coordinate)")
    }
  }

  private var coordinateControls: some View {
    Group {
      if compact {
        HStack(spacing: 8) { destinationControls }
      } else {
        VStack(spacing: 8) {
          Text("Choose the destination").font(.headline)
            .fixedSize(horizontal: false, vertical: true)
          destinationControls
        }
      }
    }
    .buttonStyle(SidequestButtonStyle(compact: true))
    .disabled(!controller.canAcceptInput || controller.attempt?.selectedSquare == nil)
  }

  private var destinationControls: some View {
    Group {
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
        Text(compact ? "Submit" : "Submit move")
          .frame(maxWidth: .infinity, minHeight: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(SidequestButtonStyle(prominent: true, compact: true))
      .disabled(!controller.canSubmitCoordinates)
      .accessibilityLabel("Submit move")
      .accessibilityIdentifier("chess.submit")
    }
    .font(compact ? .subheadline : .headline)
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
}

private struct ChessSquareButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}
