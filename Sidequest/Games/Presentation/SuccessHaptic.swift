import UIKit

/// The system controls whether supported hardware plays this standard notification pattern.
@MainActor
enum SuccessHaptic {
  static func play() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }
}
