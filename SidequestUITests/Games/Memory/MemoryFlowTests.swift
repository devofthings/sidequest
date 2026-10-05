import XCTest

@MainActor
final class MemoryFlowTests: XCTestCase {
  func testStartMakesNoFlipAndMatchingAllPairsRetainsCompletion() {
    let app = launch(successFeedback: true)
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].exists)
    XCTAssertFalse(app.buttons["memory.tile.0"].isEnabled)
    app.buttons["game.start"].tap()
    capture(app, name: "normal-started-board")
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
    app.buttons["memory.tile.0"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Revealed star, card 1")
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.1"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Matched star, card 1")
    XCTAssertFalse(app.buttons["memory.tile.0"].isEnabled)
    for index in 2..<12 { tapTile(index, app: app) }
    XCTAssertTrue(app.staticTexts["game.successCelebration"].waitForExistence(timeout: 5))
    capture(app, name: "memory-success-celebration")
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  func testSuccessWithSystemReduceMotionDoesNotRepeatAfterBackground() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(successFeedback: true)
      app.buttons["game.start"].tap()
      for index in 0..<12 { tapTile(index, app: app) }
      XCTAssertTrue(app.staticTexts["game.successCelebration"].waitForExistence(timeout: 5))
      capture(app, name: "memory-success-system-reduce-motion")
      XCUIDevice.shared.press(.home)
      app.activate()
      XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
      XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
      XCTAssertFalse(app.buttons["game.start"].exists)
      app.terminate()
    }
  }

  func testMismatchTurnsOverAndSkippingReturnsToUnflippedPreview() {
    let app = launch()
    app.buttons["game.start"].tap()
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.2"].tap()
    let first = app.buttons["memory.tile.0"]
    let third = app.buttons["memory.tile.2"]
    let concealed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Hidden card 1"), object: first)
    XCTAssertEqual(XCTWaiter.wait(for: [concealed], timeout: 5), .completed)
    XCTAssertEqual(third.label, "Hidden card 3")
    first.tap()
    third.tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].exists)
    XCTAssertFalse(app.buttons["memory.tile.0"].isEnabled)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.buttons["memory.tile.2"].label, "Hidden card 3")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
  }

  func testLargestTextKeepsEveryTileAndNavigationReachable() {
    let app = launch(largeText: true)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    app.buttons["game.start"].tap()
    for index in 0..<12 { tapTile(index, app: app) }
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    reveal(app.staticTexts["memory.completed"], app: app)
    capture(app, name: "largest-text-completed-board")
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.nextFeedCard()
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.previousFeedCard()
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  private func tapTile(_ index: Int, app: XCUIApplication) {
    let tile = app.buttons["memory.tile.\(index)"]
    reveal(tile, app: app)
    XCTAssertTrue(tile.isHittable, "Card \(index + 1) must be reachable.")
    tile.tap()
  }

  private func reveal(_ element: XCUIElement, app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(
      scroll.frame.contains(element.frame), "The control must be fully visible before interacting.")
  }

  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(largeText: Bool = false, successFeedback: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-memory-fixtures"]
      + (largeText ? ["-sidequest-large-text"] : [])
      + (successFeedback ? ["-sidequest-success-feedback-test"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
