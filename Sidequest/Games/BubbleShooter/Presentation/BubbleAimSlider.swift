import SwiftUI
import UIKit

/// Own the native slider's actual bounds; a SwiftUI height wrapper alone leaves a 31-point control.
@MainActor
struct BubbleAimSlider: UIViewRepresentable {
  let controller: BubbleShooterController
  @Environment(\.isEnabled) private var isEnabled

  func makeUIView(context: Context) -> BubbleAimSliderControl {
    BubbleAimSliderControl(controller: controller)
  }

  func updateUIView(_ view: BubbleAimSliderControl, context: Context) {
    view.update(controller: controller, enabled: isEnabled)
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize, uiView: BubbleAimSliderControl, context: Context
  ) -> CGSize? {
    CGSize(width: max(44, proposal.width ?? 160), height: 44)
  }
}

@MainActor
final class BubbleAimSliderControl: UISlider {
  private var controller: BubbleShooterController

  init(controller: BubbleShooterController) {
    self.controller = controller
    super.init(frame: .zero)
    minimumValue = 0
    maximumValue = 1
    accessibilityIdentifier = "bubble.aim"
    accessibilityLabel = "Aim"
    accessibilityHint =
      "Aim from 60 degrees left to 60 degrees right of vertical. The angle is shown above."
    addTarget(self, action: #selector(changed), for: .valueChanged)
    update(controller: controller, enabled: true)
  }

  required init?(coder: NSCoder) { nil }

  override var intrinsicContentSize: CGSize {
    CGSize(width: super.intrinsicContentSize.width, height: 44)
  }

  func update(controller: BubbleShooterController, enabled: Bool) {
    self.controller = controller
    isEnabled = enabled && controller.canFire
    let normalized = Float((controller.aimDegrees + 60) / 120)
    if abs(value - normalized) > 0.000_001 { value = normalized }
  }

  @objc private func changed() {
    controller.aim(degrees: Double(value) * 120 - 60)
  }
}
