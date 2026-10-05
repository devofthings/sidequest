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
    XCTAssertTrue(app.staticTexts["game.successCelebration"].waitForExistence(timeout: 5))
    let success = XCTAttachment(screenshot: app.screenshot())
    success.name = "bubble-success-celebration"
    success.lifetime = .keepAlways
    add(success)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width + 0.001, 44)
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
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width + 0.001, 44)
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
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
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
    let position = app.selectedFeedCardID
    reveal(app.sliders["bubble.aim"], in: app)
    XCTAssertTrue(app.sliders["bubble.aim"].isHittable)
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.75)
    XCTAssertNotEqual(app.staticTexts["bubble.angle"].label, "Aim: 0°")
    XCTAssertEqual(app.selectedFeedCardID, position)
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isHittable)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height + 0.001, 44)
    app.buttons["bubble.fire"].tap()
    waitForShots(1, in: app)
    XCTAssertEqual(app.selectedFeedCardID, position)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].isHittable)
  }

  @MainActor
  func testNativeHorizontalAndDiagonalAimDragsDoNotPage() {
    let app = launch()
    start(app)
    let slider = app.sliders["bubble.aim"]
    reveal(slider, in: app)
    let position = app.selectedFeedCardID
    let center = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let right = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
    center.press(
      forDuration: 0.01, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.1)
    let afterHorizontal = app.staticTexts["bubble.angle"].label
    XCTAssertNotEqual(afterHorizontal, "Aim: 0°")
    XCTAssertEqual(app.selectedFeedCardID, position)
    slider.adjust(toNormalizedSliderPosition: 0.5)
    let diagonal = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.65))
    center.press(
      forDuration: 0.01, thenDragTo: diagonal, withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertNotEqual(app.staticTexts["bubble.angle"].label, "Aim: 0°")
    XCTAssertEqual(app.selectedFeedCardID, position)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    fire(app, aim: 0.5, expectedShots: 1)
    XCTAssertEqual(app.selectedFeedCardID, position)
  }

  @MainActor
  func testShortBoardDragKeepsAttemptAndDirectSkipResetsPendingShot() {
    let app = launch(slowShot: true)
    start(app)
    let board = app.otherElements["bubble.board"]
    reveal(board, in: app)
    let middle = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let short = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
    middle.press(
      forDuration: 0.01, thenDragTo: short, withVelocity: .slow, thenHoldForDuration: 0.2)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    let pager = app.scrollViews["feed.pager"]
    for _ in 0..<3 {
      if app.selectedFeedCardID != "sample-game-bubbleShooter" { break }
      pager.swipeUp(velocity: .fast)
    }
    waitForPosition("sample-news-garden", in: app)
    pager.swipeDown(velocity: .fast)
    waitForPosition("sample-game-bubbleShooter", in: app)
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
    start(app)
    fire(app, aim: 0.5, expectedShots: 1)
  }

  @MainActor
  func testSystemReduceMotionKeepsPendingShotStationary() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
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
      app.terminate()
    }
  }

  @MainActor
  private func waitForPosition(_ position: String, in app: XCUIApplication) {
    let expected = expectation(
      for: NSPredicate(format: "identifier == %@", "feed.selected.\(position)"),
      evaluatedWith: app.selectedFeedCard)
    wait(for: [expected], timeout: 5)
  }

  @MainActor
  private func launch(slowShot: Bool = false, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-bubble-fixtures", "-sidequest-success-feedback-test"]
      + (slowShot ? ["-sidequest-bubble-slow-shot"] : [])
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Bubble shooter"].exists)
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
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
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.width + 0.001, 44)
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
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let needsUp = element.frame.midY > scroll.frame.midY
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: needsUp ? 0.65 : 0.35))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: needsUp ? 0.4 : 0.6))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(element.isHittable)
    XCTAssertTrue(scroll.frame.contains(element.frame))
  }

}
