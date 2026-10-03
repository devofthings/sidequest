import XCTest

@MainActor
enum SystemAccessibilitySupport {
  static func withReduceMotion(_ body: () -> Void) {
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    let original = motionControl(in: settings).value as? String
    XCTAssertTrue(original == "0" || original == "1")
    defer {
      settings.terminate()
      setMotion(original ?? "0", in: settings)
      settings.terminate()
    }
    setMotion("1", in: settings)
    body()
  }

  private static func motionControl(in settings: XCUIApplication) -> XCUIElement {
    settings.launch()
    XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 5))
    let control = settings.switches["Reduce Motion"]
    if !control.exists {
      if !settings.buttons["Motion"].exists {
        let accessibility = settings.buttons["com.apple.settings.accessibility"]
        XCTAssertTrue(accessibility.waitForExistence(timeout: 5))
        accessibility.tap()
      }
      XCTAssertTrue(settings.buttons["Motion"].waitForExistence(timeout: 5))
      settings.buttons["Motion"].tap()
    }
    XCTAssertTrue(control.waitForExistence(timeout: 5))
    return control
  }

  private static func setMotion(_ value: String, in settings: XCUIApplication) {
    let control = motionControl(in: settings)
    for _ in 0..<3 {
      if control.value as? String == value { return }
      XCTAssertTrue(control.isHittable)
      control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
      let changed = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "value == %@", value), object: control)
      if XCTWaiter.wait(for: [changed], timeout: 2) == .completed { return }
    }
    XCTAssertEqual(control.value as? String, value)
  }
}
