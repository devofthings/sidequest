import XCTest

final class BubbleFlowTests: XCTestCase {
  @MainActor
  func testThreeShotWinRetainsCompletionAndReplayStartsWithoutShot() {
    let app = launch()
    start(app)
    for (index, aim) in [0.5, 0.5, 0.65].enumerated() {
      fire(app, aim: aim, expectedShots: index + 1)
    }
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width, 44)
    app.buttons["bubble.replay"].tap()
    XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(
      (app.otherElements["bubble.board"].value as? String)?.hasPrefix("9 bubbles remaining.")
        == true)
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
  }

  @MainActor
  func testSevenStraightShotsLoseAndReplayRestoresChallenge() {
    let app = launch()
    start(app)
    for count in 1...7 { fire(app, aim: 0.5, expectedShots: count) }
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You lost")
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width, 44)
    app.buttons["bubble.replay"].tap()
    XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
  }

  @MainActor
  func testSkippingAnActiveShotReturnsToPreviewAndCannotCommitLate() {
    let app = launch(slowShot: true)
    start(app)
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["bubble.fire"].exists)
    start(app)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    // Finishing a fresh current shot also proves the old animation never commits into this attempt.
    fire(app, aim: 0.5, expectedShots: 1)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 1 of 8")
  }

  @MainActor
  func testLargestTextAimAndFireRemainUsableWithoutNavigating() {
    let app = launch(largeText: true)
    start(app)
    let position = app.staticTexts["feed.position"].label
    reveal(app.sliders["bubble.aim"], in: app)
    XCTAssertTrue(app.sliders["bubble.aim"].isHittable)
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.75)
    XCTAssertNotEqual(app.staticTexts["bubble.angle"].label, "Aim: 0°")
    XCTAssertEqual(app.staticTexts["feed.position"].label, position)
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isHittable)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height, 44)
    app.buttons["bubble.fire"].tap()
    waitForShots(1, in: app)
    XCTAssertEqual(app.staticTexts["feed.position"].label, position)
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.buttons["game.start"].isHittable)
  }

  @MainActor
  func testSystemReduceMotionKeepsPendingShotStationary() {
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    continueAfterFailure = false
    let reduceMotion = openMotionSettings(settings)
    let originalValue = reduceMotion.value as? String
    XCTAssertTrue(originalValue == "0" || originalValue == "1")
    defer {
      // Relaunch Settings so restoration observes its current foreground hierarchy.
      settings.terminate()
      setReduceMotion(originalValue ?? "0", in: settings)
      settings.terminate()
    }
    setReduceMotion("1", in: settings)
    let app = launch(slowShot: true)
    start(app)
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    let first = app.otherElements["bubble.board"].screenshot()
    let second = app.otherElements["bubble.board"].screenshot()
    XCTAssertEqual(first.pngRepresentation, second.pngRepresentation)
    let attachment = XCTAttachment(screenshot: second)
    attachment.name = "Bubble flight with system Reduce Motion"
    attachment.lifetime = .keepAlways
    add(attachment)
    waitForShots(1, in: app)
  }

  @MainActor
  private func openMotionSettings(_ settings: XCUIApplication) -> XCUIElement {
    settings.launch()
    XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 5))
    let reduceMotion = settings.switches["Reduce Motion"]
    if !reduceMotion.exists {
      if !settings.buttons["Motion"].exists {
        let accessibility = settings.buttons["com.apple.settings.accessibility"]
        XCTAssertTrue(accessibility.waitForExistence(timeout: 5))
        accessibility.tap()
      }
      XCTAssertTrue(settings.buttons["Motion"].waitForExistence(timeout: 5))
      settings.buttons["Motion"].tap()
    }
    XCTAssertTrue(reduceMotion.waitForExistence(timeout: 5))
    return reduceMotion
  }

  @MainActor
  private func setReduceMotion(_ value: String, in settings: XCUIApplication) {
    let control = openMotionSettings(settings)
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

  @MainActor
  private func launch(slowShot: Bool = false, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-bubble-fixtures"]
      + (slowShot ? ["-sidequest-bubble-slow-shot"] : [])
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Bubble shooter"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].exists)
    return app
  }

  @MainActor
  private func start(_ app: XCUIApplication) {
    app.buttons["game.start"].tap()
    XCTAssertTrue(app.otherElements["bubble.board"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  private func fire(_ app: XCUIApplication, aim: Double, expectedShots: Int) {
    reveal(app.sliders["bubble.aim"], in: app)
    if aim != 0.5 { app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.9) }
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: aim)
    if aim != 0.5 {
      let angle = Double(app.staticTexts["bubble.angle"].label.dropFirst(5).dropLast())
      XCTAssertNotNil(angle)
      XCTAssertTrue(
        (6...30).contains(angle ?? -60), "Actual aiming must reach the demonstrated winning window."
      )
    }
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.width, 44)
    app.buttons["bubble.fire"].tap()
    waitForShots(expectedShots, in: app)
  }

  @MainActor
  private func waitForShots(_ count: Int, in app: XCUIApplication) {
    let committed = expectation(
      for: NSPredicate(format: "label == %@", "Shots: \(count) of 8"),
      evaluatedWith: app.staticTexts["bubble.shots"])
    wait(for: [committed], timeout: 10)
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews.firstMatch
    for _ in 0..<8 {
      if element.isHittable && scroll.frame.contains(element.frame) { return }
      scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        .press(
          forDuration: 0.05,
          thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)))
    }
    XCTAssertTrue(element.isHittable)
    XCTAssertTrue(scroll.frame.contains(element.frame))
  }

}
