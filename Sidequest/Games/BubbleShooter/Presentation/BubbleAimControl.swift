import SwiftUI
import UIKit

@MainActor
struct BubbleAimControl: UIViewRepresentable {
  let controller: BubbleShooterController

  func makeUIView(context: Context) -> BubbleAimTouchRegion {
    BubbleAimTouchRegion(controller: controller)
  }

  func updateUIView(_ view: BubbleAimTouchRegion, context: Context) {
    view.update(controller: controller)
  }

  static func dismantleUIView(_ view: BubbleAimTouchRegion, coordinator: ()) {
    view.cancelAim()
  }
}

/// Keep the same touch-exclusion region after completion, with no remaining aiming control.
@MainActor
final class BubbleAimTouchRegion: UIView, FeedPanExcludingControl {
  private var aimControl: BubbleAimTouchControl?

  init(controller: BubbleShooterController) {
    super.init(frame: .zero)
    backgroundColor = .clear
    isAccessibilityElement = false
    update(controller: controller)
  }

  required init?(coder: NSCoder) { nil }

  func update(controller: BubbleShooterController) {
    guard controller.game.outcome == .playing else {
      cancelAim()
      aimControl?.removeFromSuperview()
      aimControl = nil
      accessibilityElements = []
      accessibilityElementsHidden = true
      return
    }
    accessibilityElementsHidden = false
    accessibilityElements = nil
    if let aimControl {
      aimControl.update(controller: controller)
    } else {
      let control = BubbleAimTouchControl(controller: controller)
      control.frame = bounds
      control.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      addSubview(control)
      aimControl = control
    }
  }

  func cancelAim() {
    aimControl?.cancelAim()
  }
}

/// A single tracked finger owns aiming only. Fire remains a separate explicit action.
@MainActor
final class BubbleAimTouchControl: UIControl, FeedPanExcludingControl {
  private var controller: BubbleShooterController
  private var lease: BubbleAimLease?

  init(controller: BubbleShooterController) {
    self.controller = controller
    super.init(frame: .zero)
    backgroundColor = .clear
    isMultipleTouchEnabled = false
    isAccessibilityElement = true
    accessibilityIdentifier = "bubble.directAim"
    accessibilityLabel = "Touch aiming area"
    accessibilityHint =
      "Drag left or right to aim. Use the Aim slider for precise adjustment. Fire shoots the bubble."
    accessibilityTraits = [.allowsDirectInteraction]
    update(controller: controller)
  }

  required init?(coder: NSCoder) { nil }

  func update(controller: BubbleShooterController) {
    if self.controller !== controller { cancelAim() }
    self.controller = controller
    if !controller.canFire { cancelAim() }
    // Keep the narrow area a hit-test destination while disabled so it never becomes a feed pan.
    isEnabled = controller.canFire
    accessibilityValue = "Aim: \(Int(controller.aimDegrees.rounded())) degrees"
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil { cancelAim() }
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    cancelAim()
    guard let lease = controller.beginAimDrag() else { return false }
    self.lease = lease
    // Launcher-height horizontal gestures are valid; only the touch's x position sets aim.
    if let degrees = mapped(touch) { controller.updateAimDrag(lease, degrees: degrees) }
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    guard let lease else { return false }
    // Out-of-area/nonfinite points preserve the last accepted angle.
    guard let degrees = mapped(touch) else { return true }
    guard controller.updateAimDrag(lease, degrees: degrees) else {
      cancelAim()
      return false
    }
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    if let touch, let lease, let degrees = mapped(touch) {
      controller.updateAimDrag(lease, degrees: degrees)
    }
    cancelAim()
  }

  override func cancelTracking(with event: UIEvent?) {
    cancelAim()
    super.cancelTracking(with: event)
  }

  func cancelAim() {
    if let lease { controller.endAimDrag(lease) }
    lease = nil
  }

  private func mapped(_ touch: UITouch) -> Double? {
    let point = touch.location(in: self)
    return BubbleAimMapping.degrees(
      point: BubblePoint(x: point.x, y: point.y), width: bounds.width)
  }
}
