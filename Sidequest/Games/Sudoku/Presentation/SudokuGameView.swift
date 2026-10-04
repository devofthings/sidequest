import SwiftUI

@MainActor
struct SudokuGameView: View {
  let controller: SudokuController

  var body: some View {
    if let board = controller.board {
      VStack(spacing: 16) {
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
          SudokuRegionDividers().stroke(.primary, lineWidth: 2)
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
        .buttonStyle(.bordered)
        .disabled(controller.selectedCell == nil || board.isComplete)
        Button {
          controller.enter(0)
        } label: {
          Text("Clear selected cell")
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
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
        .fontWeight(given ? .bold : .regular)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, minHeight: 44)
        .aspectRatio(1, contentMode: .fit)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8).stroke(
            selected ? Color.primary : Color.clear, lineWidth: 3)
        )
        .foregroundStyle(conflict ? Color.red : Color.primary)
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
