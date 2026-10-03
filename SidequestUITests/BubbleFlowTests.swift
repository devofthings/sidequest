import XCTest

final class BubbleFlowTests: XCTestCase {
  @MainActor
  func testThreeShotWinRetainsCompletionAndReplayStartsWithoutShot() {
    let app = launch()
    start(app)
    for (index, aim) in [0.5, 0.5, 0.55].enumerated() {
      fire(app, aim: aim, expectedShots: index + 1)
    }
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    reveal(app.buttons["bubble.replay"], in: app)
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
    XCTAssertEqual(app.staticTexts["feed.position"].label, position)
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isHittable)
    app.buttons["bubble.fire"].tap()
    waitForShots(1, in: app)
    XCTAssertEqual(app.staticTexts["feed.position"].label, position)
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.buttons["game.start"].isHittable)
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
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: aim)
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
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
    for _ in 0..<6 {
      if element.isHittable { return }
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(element.isHittable)
  }

}
