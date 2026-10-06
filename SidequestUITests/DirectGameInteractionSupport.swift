import XCTest

@MainActor
extension XCUIApplication {
  var bubbleAim: XCUIElement {
    descendants(matching: .any).matching(identifier: "bubble.directAim").firstMatch
  }

  /// A real lower-board drag releases one shot at the displayed horizontal position.
  func shootBubble(at horizontal: Double = 0.5) {
    let aim = bubbleAim
    XCTAssertTrue(aim.exists)
    XCTAssertTrue(aim.isEnabled)
    XCTAssertTrue(aim.isHittable)
    let start = aim.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = aim.coordinate(withNormalizedOffset: CGVector(dx: horizontal, dy: 0.5))
    start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
  }

  /// Ending beyond the owned area's vertical boundary starts aiming but cancels the shot.
  func cancelBubbleShot(at horizontal: Double = 0.5) {
    let aim = bubbleAim
    XCTAssertTrue(aim.exists)
    XCTAssertTrue(aim.isEnabled)
    XCTAssertTrue(aim.isHittable)
    let start = aim.coordinate(withNormalizedOffset: CGVector(dx: horizontal, dy: 0.5))
    let outside = aim.coordinate(withNormalizedOffset: CGVector(dx: horizontal, dy: -0.1))
    start.press(
      forDuration: 0.01, thenDragTo: outside, withVelocity: .slow, thenHoldForDuration: 0.1)
  }
}
