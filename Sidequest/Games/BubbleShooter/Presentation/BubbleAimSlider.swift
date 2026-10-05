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
  private var trackingVisibility: UUID?

  init(controller: BubbleShooterController) {
    self.controller = controller
    super.init(frame: .zero)
    minimumValue = 0
    maximumValue = 1
    accessibilityIdentifier = "bubble.aim"
    accessibilityLabel = "Aim"
    accessibilityHint =
      "Aim from 60 degrees left to 60 degrees right of vertical. The dotted guide shows the trajectory."
    addTarget(self, action: #selector(changed), for: .valueChanged)
    update(controller: controller, enabled: true)
  }

  required init?(coder: NSCoder) { nil }

  override var intrinsicContentSize: CGSize {
    CGSize(width: super.intrinsicContentSize.width, height: 44)
  }

  func update(controller: BubbleShooterController, enabled: Bool) {
    self.controller = controller
    isEnabled = enabled && controller.canAimOrFire
    let normalized = Float((controller.aimDegrees + 60) / 120)
    if abs(value - normalized) > 0.000_001 { value = normalized }
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    trackingVisibility = controller.runtime.visibilityIdentity
    return super.beginTracking(touch, with: event)
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    trackingVisibility = nil
  }

  override func cancelTracking(with event: UIEvent?) {
    trackingVisibility = nil
    super.cancelTracking(with: event)
  }

  @objc private func changed() {
    controller.aim(
      degrees: Double(value) * 120 - 60,
      visibility: trackingVisibility ?? controller.runtime.visibilityIdentity)
  }
}
