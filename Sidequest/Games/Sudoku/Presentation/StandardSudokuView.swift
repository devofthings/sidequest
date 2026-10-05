import SwiftUI

/// A compact overview has secondary cell taps; full-size coordinates are the primary alternative.
@MainActor
struct StandardSudokuView: View {
  let controller: SudokuController
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.dynamicTypeSize) private var textSize
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride
  @Environment(\.sidequestGameLayoutBudget) private var budget
  @State private var chromeHeight: CGFloat = 0

  private var theme: SidequestTheme {
    SidequestTheme(scheme: scheme, contrast: contrastOverride ?? systemContrast)
  }
  private var feedbackAnimation: Animation? {
    guard !(motionOverride ?? systemReduceMotion), canSelect else { return nil }
    return .smooth(duration: 0.16)
  }
  private var spacing: CGFloat { textSize.isAccessibilitySize ? 16 : 8 }
  private var extent: CGFloat {
    guard !textSize.isAccessibilitySize, let budget else { return 300 }
    return max(216, min(300, min(budget.width, budget.height - chromeHeight - spacing)))
  }
  private var canSelect: Bool {
    guard case .playing(let attempt) = controller.runtime.phase else { return false }
    return controller.runtime.acceptsInput(from: attempt)
  }

  var body: some View {
    VStack(spacing: spacing) {
      instruction
      overview
        .frame(width: extent, height: extent)
      coordinates
      numbers
      status
    }
    .frame(maxWidth: .infinity)
    .background(alignment: .top) {
      VStack(spacing: spacing) {
        instruction
        coordinates
        numbers
        status
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

  private var instruction: some View {
    Text("Rows, columns, and 3×3 regions need 1–9.")
      .font(.subheadline)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var overview: some View {
    let board = controller.displayedBoard
    return LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 9), spacing: 0
    ) {
      ForEach(0..<81, id: \.self) { index in
        let value = board.cells[index]
        let given = controller.puzzle.givens[index] != 0
        let conflict = board.conflicts.contains(index)
        let selected = controller.selectedCell == index
        Button {
          controller.selectCell(index)
        } label: {
          Text(value == 0 ? "·" : String(value))
            .font(.system(size: 17, weight: given ? .bold : .medium, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(feedbackAnimation, value: value)
            .frame(width: extent / 9, height: extent / 9)
            .foregroundStyle(
              conflict ? Color(red: 0.6, green: 0.04, blue: 0.18) : SidequestTheme.darkInk
            )
            .background(selected ? SidequestTheme.cyan : (given ? SidequestTheme.lavender : .white))
            .overlay {
              Rectangle().strokeBorder(
                selected ? SidequestTheme.darkInk : theme.border, lineWidth: selected ? 2 : 0.5)
            }
            .animation(feedbackAnimation, value: selected)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSelect || given)
        .accessibilityLabel(
          "Row \(index / 9 + 1), column \(index % 9 + 1)\(given ? ", given" : "")"
        )
        .accessibilityValue(
          "\(value == 0 ? "Empty" : String(value))\(conflict ? ", conflict" : "")"
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("sudoku.cell.\(index)")
      }
    }
    .overlay {
      StandardSudokuRegionDividers().stroke(SidequestTheme.darkInk, lineWidth: 2)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Standard Sudoku, nine rows and nine columns")
    .accessibilityIdentifier("sudoku.board")
  }

  private var coordinates: some View {
    Group {
      if textSize.isAccessibilitySize {
        VStack(spacing: 8) { coordinateButtons }
      } else {
        HStack(spacing: 8) { coordinateButtons }
      }
    }
    .font(textSize.isAccessibilitySize ? .body : .subheadline)
    .buttonStyle(SidequestButtonStyle(compact: true))
    .disabled(!canSelect)
  }

  private var coordinateButtons: some View {
    Group {
      Menu {
        ForEach(0..<9, id: \.self) { row in
          Button("Row \(row + 1)") { controller.selectRow(row) }
            .accessibilityIdentifier("sudoku.row.\(row + 1)")
        }
      } label: {
        Text("Row \(controller.coordinateRow + 1)")
          .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
      }
      .accessibilityIdentifier("sudoku.row")
      Menu {
        ForEach(0..<9, id: \.self) { column in
          Button("Column \(column + 1)") { controller.selectColumn(column) }
            .accessibilityIdentifier("sudoku.column.\(column + 1)")
        }
      } label: {
        Text("Column \(controller.coordinateColumn + 1)")
          .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
      }
      .accessibilityIdentifier("sudoku.column")
    }
  }

  private var numbers: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) { ForEach(1...5, id: \.self) { number($0) } }
      HStack(spacing: 8) {
        ForEach(6...9, id: \.self) { number($0) }
        Button {
          controller.enter(0)
        } label: {
          Text("Clear").font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("Clear selected cell")
        .accessibilityIdentifier("sudoku.clear")
      }
    }
    .buttonStyle(SidequestButtonStyle(compact: true))
    .disabled(!canSelect || controller.selectedCell == nil)
  }

  private func number(_ value: Int) -> some View {
    Button {
      controller.enter(value)
    } label: {
      Text(String(value)).font(.body.monospacedDigit())
        .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
    }
    .accessibilityLabel("Enter \(value)")
    .accessibilityIdentifier("sudoku.number.\(value)")
  }

  private var status: some View {
    StableGameRegion {
      ZStack {
        Text("Choose an empty square by row and column.")
        Text("Conflicts need correction.")
        Text("Sudoku solved!")
      }
    } content: {
      Text(
        controller.displayedBoard.isComplete
          ? "Sudoku solved!"
          : (controller.displayedBoard.conflicts.isEmpty
            ? "Choose an empty square by row and column." : "Conflicts need correction.")
      )
      .accessibilityIdentifier("sudoku.status")
    }
    .font(textSize.isAccessibilitySize ? .body.bold() : .subheadline.bold())
  }
}

private struct StandardSudokuRegionDividers: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    for fraction in [CGFloat(1) / 3, CGFloat(2) / 3] {
      path.move(to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.maxY))
      path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * fraction))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * fraction))
    }
    return path
  }
}
