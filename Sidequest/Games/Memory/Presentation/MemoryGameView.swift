import SwiftUI

@MainActor
struct MemoryGameView: View {
  let controller: MemoryController
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if let board = controller.rules {
      VStack(spacing: 16) {
        Text("Find all six pairs.")
          .font(.body)
        Text("\(board.matchedPairCount) of 6 pairs matched")
          .font(.headline)
          .accessibilityIdentifier("memory.progress")
        LazyVGrid(
          columns: Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: dynamicTypeSize.isAccessibilitySize ? 2 : 3), spacing: 12
        ) {
          ForEach(board.symbols.indices, id: \.self) { index in
            tile(index, board: board)
          }
        }
        if board.isCompleted {
          Label("All pairs found!", systemImage: "checkmark.circle.fill")
            .font(.title2.bold())
            .accessibilityIdentifier("memory.completed")
        } else if board.isResolvingMismatch {
          Text("Try another pair when these turn over.")
            .font(.footnote)
        }
      }
      .padding(.horizontal, 4)
    }
  }

  private func tile(_ index: Int, board: MemoryRules) -> some View {
    let revealed = board.isRevealed(index)
    let matched = board.matchedIndices.contains(index)
    let symbol = board.symbols[index]
    return Button {
      controller.flip(index)
    } label: {
      Image(systemName: revealed ? symbol.imageName : "questionmark")
        .font(.largeTitle)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(
          .secondary.opacity(matched ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.3))
        }
    }
    .buttonStyle(.plain)
    .disabled(matched || board.isResolvingMismatch || board.isCompleted)
    .accessibilityLabel(
      matched
        ? "Matched \(symbol.rawValue), card \(index + 1)"
        : revealed
          ? "Revealed \(symbol.rawValue), card \(index + 1)"
          : "Hidden card \(index + 1)"
    )
    .accessibilityHint(matched ? "This pair is complete." : "Flip to find a matching symbol.")
    .accessibilityIdentifier("memory.tile.\(index)")
  }
}

extension MemorySymbol {
  fileprivate var imageName: String {
    switch self {
    case .star: "star.fill"
    case .heart: "heart.fill"
    case .moon: "moon.fill"
    case .sun: "sun.max.fill"
    case .leaf: "leaf.fill"
    case .bolt: "bolt.fill"
    }
  }
}
