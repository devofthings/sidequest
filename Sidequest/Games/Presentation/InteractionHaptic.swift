import UIKit

/// A brief accent for committed gameplay; system availability controls physical output.
@MainActor
enum InteractionHaptic {
  static func play() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
}
