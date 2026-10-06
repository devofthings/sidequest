import SwiftUI
import UIKit

@MainActor
struct BubbleAimControl: UIViewRepresentable {
  let controller: BubbleShooterController

  func makeUIView(context: Context) -> BubbleAimBoardRegion {
    BubbleAimBoardRegion(controller: controller)
  }

  func updateUIView(_ view: BubbleAimBoardRegion, context: Context) {
    view.update(controller: controller)
  }

  static func dismantleUIView(_ view: BubbleAimBoardRegion, coordinator: ()) {
    view.cancelAim()
  }
}

/// Upper target taps yield to native scrolling; only the lower child excludes feed pans.
@MainActor
final class BubbleAimBoardRegion: UIView, UIGestureRecognizerDelegate {
  private var controller: BubbleShooterController
  private let lower: BubbleAimTouchRegion
  private let upper = UIView()
  private let tap = UITapGestureRecognizer()
  private var pendingController: BubbleShooterController?
  private var pendingVisibility: UUID?

  init(controller: BubbleShooterController) {
    self.controller = controller
    lower = BubbleAimTouchRegion(controller: controller)
    super.init(frame: .zero)
    backgroundColor = .clear
    upper.backgroundColor = .clear
    upper.isAccessibilityElement = false
    upper.accessibilityElementsHidden = true
    addSubview(upper)
    addSubview(lower)
    tap.addTarget(self, action: #selector(targetTapped(_:)))
    tap.delegate = self
    upper.addGestureRecognizer(tap)
    update(controller: controller)
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    let top = bounds.width / BubbleGeometry.width * BubbleAimMapping.regionTop
    upper.frame = CGRect(x: 0, y: 0, width: bounds.width, height: top)
    lower.frame = CGRect(x: 0, y: top, width: bounds.width, height: max(0, bounds.height - top))
  }

  func update(controller: BubbleShooterController) {
    if self.controller !== controller { cancelAim() }
    self.controller = controller
    lower.update(controller: controller)
    tap.isEnabled = controller.canAimOrFire
    if !controller.canAimOrFire { cancelAim() }
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil { cancelAim() }
  }

  func cancelAim() {
    lower.cancelAim()
    pendingController = nil
    pendingVisibility = nil
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
    -> Bool
  {
    guard controller.canAimOrFire else { return false }
    pendingController = controller
    pendingVisibility = controller.runtime.visibilityIdentity
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    var ancestor = superview
    while let view = ancestor {
      if let scroll = view as? UIScrollView,
        otherGestureRecognizer === scroll.panGestureRecognizer
      {
        return true
      }
      ancestor = view.superview
    }
    return false
  }

  @objc private func targetTapped(_ recognizer: UITapGestureRecognizer) {
    defer {
      pendingController = nil
      pendingVisibility = nil
    }
    guard recognizer.state == .ended, window != nil,
      let pendingController, pendingController === controller, let pendingVisibility
    else { return }
    let point = recognizer.location(in: self)
    guard
      let degrees = BubbleAimMapping.targetDegrees(
        point: BubblePoint(x: point.x, y: point.y), width: bounds.width),
      let lease = controller.beginAimDrag(visibility: pendingVisibility)
    else { return }
    controller.releaseAimDrag(lease, degrees: degrees)
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

/// One originating finger owns aim and release-to-shoot; cancellation never fires.
@MainActor
final class BubbleAimTouchControl: UIControl, FeedPanExcludingControl {
  private var controller: BubbleShooterController
  private var lease: BubbleAimLease?
  private var origin: CGPoint?
  private var visibility: UUID?

  init(controller: BubbleShooterController) {
    self.controller = controller
    super.init(frame: .zero)
    backgroundColor = .clear
    isMultipleTouchEnabled = false
    isAccessibilityElement = true
    accessibilityIdentifier = "bubble.directAim"
    accessibilityLabel = "Aim and shoot bubble"
    accessibilityHint =
      "Tap above the launcher to aim and shoot, or drag left or right and release inside. Adjust the angle or activate to shoot."
    accessibilityTraits = [.adjustable, .button, .allowsDirectInteraction]
    update(controller: controller)
  }

  required init?(coder: NSCoder) { nil }

  func update(controller: BubbleShooterController) {
    if self.controller !== controller { cancelAim() }
    self.controller = controller
    if !controller.canAimOrFire { cancelAim() }
    // Keep the narrow area a hit-test destination while disabled so it never becomes a feed pan.
    isEnabled = controller.canAimOrFire
    accessibilityValue = "Aim: \(Int(controller.aimDegrees.rounded())) degrees"
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil { cancelAim() }
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    cancelAim()
    guard controller.canAimOrFire, mapped(touch) != nil else { return false }
    origin = touch.location(in: self)
    visibility = controller.runtime.visibilityIdentity
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    guard let origin, let visibility else { return false }
    let point = touch.location(in: self)
    if lease == nil, hypot(point.x - origin.x, point.y - origin.y) <= 10 { return true }
    if lease == nil { lease = controller.beginAimDrag(visibility: visibility) }
    guard let lease else {
      cancelAim()
      return false
    }
    guard let degrees = mapped(touch) else { return true }
    guard controller.updateAimDrag(lease, degrees: degrees) else {
      cancelAim()
      return false
    }
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    defer { cancelAim() }
    guard let touch, origin != nil, let visibility, let horizontal = mapped(touch) else { return }
    let degrees: Double
    if lease != nil {
      degrees = horizontal
    } else {
      let point = touch.location(in: self)
      let scale = bounds.width / BubbleGeometry.width
      guard
        let target = BubbleAimMapping.targetDegrees(
          point: BubblePoint(x: point.x, y: point.y + BubbleAimMapping.regionTop * scale),
          width: bounds.width)
      else { return }
      degrees = target
      lease = controller.beginAimDrag(visibility: visibility)
    }
    guard let lease else { return }
    self.lease = nil
    controller.releaseAimDrag(lease, degrees: degrees)
  }

  override func accessibilityIncrement() {
    controller.aim(degrees: controller.aimDegrees + 5)
    update(controller: controller)
  }

  override func accessibilityDecrement() {
    controller.aim(degrees: controller.aimDegrees - 5)
    update(controller: controller)
  }

  override func accessibilityActivate() -> Bool {
    controller.fire()
  }

  override func cancelTracking(with event: UIEvent?) {
    cancelAim()
    super.cancelTracking(with: event)
  }

  func cancelAim() {
    if let lease { controller.endAimDrag(lease) }
    lease = nil
    origin = nil
    visibility = nil
  }

  private func mapped(_ touch: UITouch) -> Double? {
    let point = touch.location(in: self)
    return BubbleAimMapping.degrees(
      point: BubblePoint(x: point.x, y: point.y), width: bounds.width)
  }
}
