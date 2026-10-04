import SwiftUI

@MainActor
struct SudokuGameView: View {
  let controller: SudokuController
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

  var body: some View {
    let board = controller.displayedBoard
    return VStack(spacing: 16) {
      Text("Each row, column, and 2×2 region needs 1–4.")
        .font(.subheadline)
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8
      ) {
        ForEach(0..<16, id: \.self) { index in
          cell(index, board: board)
        }
      }
      .overlay {
        SudokuRegionDividers().stroke(theme.ink.opacity(0.65), lineWidth: 2)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      HStack(spacing: 8) {
        ForEach(1...4, id: \.self) { value in
          Button {
            controller.enter(value)
          } label: {
            Text(String(value))
              .lineLimit(1)
              .minimumScaleFactor(0.6)
              .frame(maxWidth: .infinity, minHeight: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("Enter \(value)")
          .accessibilityIdentifier("sudoku.number.\(value)")
        }
      }
      .buttonStyle(SidequestButtonStyle(compact: true))
      .disabled(controller.selectedCell == nil || board.isComplete)
      Button {
        controller.enter(0)
      } label: {
        Text("Clear selected cell")
          .frame(maxWidth: .infinity, minHeight: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(SidequestButtonStyle(compact: true))
      .disabled(controller.selectedCell == nil || board.isComplete)
      .accessibilityIdentifier("sudoku.clear")
      StableGameRegion {
        ZStack {
          Text("Sudoku solved!")
          Text("Select an empty cell, then enter a number.")
          Text("Conflicts need correction.")
        }
        .font(.body.bold())
      } content: {
        Text(
          board.isComplete
            ? "Sudoku solved!"
            : (board.conflicts.isEmpty
              ? "Select an empty cell, then enter a number." : "Conflicts need correction.")
        )
        .font(.body.bold())
        .accessibilityIdentifier("sudoku.status")
      }
    }
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private func cell(_ index: Int, board: SudokuBoard) -> some View {
    let value = board.cells[index]
    let given = controller.puzzle.givens[index] != 0
    let conflict = board.conflicts.contains(index)
    let selected = controller.selectedCell == index
    return Button {
      controller.selectCell(index)
    } label: {
      Text(value == 0 ? "·" : String(value))
        .font(.title3.monospacedDigit())
        .contentTransition(.numericText())
        .animation(feedbackAnimation, value: value)
        .fontWeight(given ? .bold : .regular)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, minHeight: 44)
        .aspectRatio(1, contentMode: .fit)
        .foregroundStyle(
          conflict
            ? (selected || given || scheme == .light
              ? Color(red: 0.6, green: 0.04, blue: 0.18) : SidequestTheme.coral)
            : (selected || given ? SidequestTheme.darkInk : theme.ink)
        )
        .background(
          selected
            ? SidequestTheme.lavender
            : (given ? SidequestTheme.lavender : theme.surface),
          in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12).strokeBorder(
            selected ? SidequestTheme.darkInk : theme.border,
            lineWidth: selected ? 3 : theme.borderWidth)
        )
        .animation(feedbackAnimation, value: selected)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(given || board.isComplete)
    .accessibilityLabel("Row \(index / 4 + 1), column \(index % 4 + 1)\(given ? ", given" : "")")
    .accessibilityValue("\(value == 0 ? "Empty" : String(value))\(conflict ? ", conflict" : "")")
    .accessibilityAddTraits(selected ? .isSelected : [])
    .accessibilityIdentifier("sudoku.cell.\(index)")
  }
}

private struct SudokuRegionDividers: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}
