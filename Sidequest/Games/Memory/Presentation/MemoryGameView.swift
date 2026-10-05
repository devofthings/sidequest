import SwiftUI

@MainActor
struct MemoryGameView: View {
  let controller: MemoryController
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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    let board = controller.displayedRules
    return VStack(spacing: 16) {
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
      StableGameRegion {
        ZStack {
          Label("All pairs found!", systemImage: "checkmark.circle.fill")
            .font(.title2.bold())
          Text("Try another pair when these turn over.").font(.footnote)
        }
      } content: {
        if board.isCompleted {
          Label("All pairs found!", systemImage: "checkmark.circle.fill")
            .font(.title2.bold())
            .accessibilityIdentifier("memory.completed")
        } else if board.isResolvingMismatch {
          Text("Try another pair when these turn over.")
            .font(.footnote)
            .accessibilityIdentifier("memory.feedback")
        }
      }
    }
    .padding(.horizontal, 4)
    .transaction { transaction in
      if case .preview = controller.runtime.phase { transaction.disablesAnimations = true }
      if !controller.runtime.isVisible { transaction.disablesAnimations = true }
    }
  }

  private func tile(_ index: Int, board: MemoryRules) -> some View {
    let visibility = controller.runtime.visibilityIdentity
    let revealed = board.isRevealed(index)
    let matched = board.matchedIndices.contains(index)
    let symbol = board.symbols[index]
    return Button {
      controller.flip(index, visibility: visibility)
    } label: {
      Group {
        if revealed {
          MemorySymbolArtwork(
            symbol: symbol, outline: matched ? SidequestTheme.darkInk : theme.ink,
            increasedContrast: theme.contrast == .increased)
        } else {
          MemoryCardBackArtwork()
        }
      }
      .frame(width: 48, height: 48)
      .accessibilityHidden(true)
      // Concealing a tile removes its answer immediately, even inside an animated update.
      .transaction {
        $0.animation = nil
        $0.disablesAnimations = true
      }
      .frame(maxWidth: .infinity, minHeight: 72)
      .foregroundStyle(revealed && !matched ? theme.ink : SidequestTheme.darkInk)
      .background {
        RoundedRectangle(cornerRadius: 16)
          .fill(matched ? SidequestTheme.lime : (revealed ? theme.surface : SidequestTheme.coral))
          .animation(feedbackAnimation, value: revealed)
          .animation(feedbackAnimation, value: matched)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(
            matched ? SidequestTheme.darkInk : theme.border,
            lineWidth: matched ? 3 : theme.borderWidth
          )
          .animation(feedbackAnimation, value: matched)
      }
    }
    .overlay(alignment: .topTrailing) {
      if matched {
        Image(systemName: "checkmark.circle.fill")
          .font(.caption.bold()).foregroundStyle(SidequestTheme.darkInk)
          .padding(6).accessibilityHidden(true).allowsHitTesting(false)
      }
    }
    .buttonStyle(MemoryTileButtonStyle())
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

private struct MemoryTileButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}
