import SwiftUI
import UIKit

/// A start request belongs to the visible preview that received its touch, not a later revisit.
@MainActor
struct PreviewStartRequest {
  private let runtime: GameRuntime
  private let visibilityIdentity: UUID

  init?(runtime: GameRuntime) {
    guard runtime.isVisible, runtime.phase == .preview else { return nil }
    self.runtime = runtime
    visibilityIdentity = runtime.visibilityIdentity
  }

  func activate() {
    guard runtime.isVisible, runtime.phase == .preview,
      runtime.visibilityIdentity == visibilityIdentity
    else { return }
    runtime.start()
  }
}

/// Intercepts the initiating tap while the real board remains visible and its inputs disabled.
/// Accessible and keyboard activation use the separately reserved, plainly styled Start game hint.
@MainActor
struct GamePreviewSurface: UIViewRepresentable {
  let runtime: GameRuntime

  func makeCoordinator() -> Coordinator { Coordinator(runtime: runtime) }

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    view.isAccessibilityElement = false
    view.accessibilityElementsHidden = true
    let tap = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.recognized(_:)))
    tap.numberOfTouchesRequired = 1
    tap.delegate = context.coordinator
    view.addGestureRecognizer(tap)
    return view
  }

  func updateUIView(_ view: UIView, context: Context) {
    context.coordinator.runtime = runtime
    view.isUserInteractionEnabled = runtime.isVisible && runtime.phase == .preview
    if !view.isUserInteractionEnabled { context.coordinator.cancel() }
  }

  static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
    coordinator.cancel()
    view.isUserInteractionEnabled = false
  }

  @MainActor
  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    var runtime: GameRuntime
    private var request: PreviewStartRequest?

    init(runtime: GameRuntime) { self.runtime = runtime }

    func cancel() { request = nil }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
      -> Bool
    {
      request = PreviewStartRequest(runtime: runtime)
      return request != nil
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      // Both existing scrollers retain their native delegates and pan ownership. A content drag
      // or outward page must win before this preview tap can become an explicit start.
      var ancestor = gestureRecognizer.view?.superview
      while let view = ancestor {
        if let scroller = view as? UIScrollView,
          otherGestureRecognizer === scroller.panGestureRecognizer
        {
          return true
        }
        ancestor = view.superview
      }
      return false
    }

    @objc func recognized(_ tap: UITapGestureRecognizer) {
      defer { cancel() }
      guard tap.state == .ended, tap.view?.window != nil else { return }
      request?.activate()
    }
  }
}
